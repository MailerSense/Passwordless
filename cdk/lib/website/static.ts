import { Duration, RemovalPolicy } from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import {
	Function as CFFunction,
	Distribution,
	FunctionCode,
	FunctionEventType,
	FunctionRuntime,
	OriginRequestPolicy,
	ResponseHeadersPolicy,
	ViewerProtocolPolicy,
} from "aws-cdk-lib/aws-cloudfront";
import { S3BucketOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import { PolicyStatement, ServicePrincipal } from "aws-cdk-lib/aws-iam";
import { Code, Runtime } from "aws-cdk-lib/aws-lambda";
import { NodejsFunction } from "aws-cdk-lib/aws-lambda-nodejs";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { BucketDeployment, Source } from "aws-cdk-lib/aws-s3-deployment";
import {
	AwsCustomResource,
	AwsCustomResourcePolicy,
	PhysicalResourceId,
} from "aws-cdk-lib/custom-resources";
import { Construct } from "constructs";
import { CDN } from "../network/cdn";
import { PrivateBucket } from "../storage/private-bucket";

export interface StaticWebsiteProps {
	name: string;
	source: string;
	zone: IHostedZone;
	cert: acm.ICertificate;
	domain: string;
	removalPolicy: RemovalPolicy;
	patchRootObject?: boolean;
}

const INDEX = "index.html";

export class StaticWebsite extends Construct {
	public constructor(scope: Construct, id: string, props: StaticWebsiteProps) {
		super(scope, id);

		const { name, source, zone, cert, domain, removalPolicy, patchRootObject } =
			props;

		const bucketName = `${name}-static-website`;
		const bucket = new PrivateBucket(this, bucketName, {
			name: bucketName,
			removalPolicy,
		});

		const deployment = new BucketDeployment(this, "BucketDeployment", {
			destinationBucket: bucket.bucket,
			sources: [Source.asset(source)],
		});

		const cdnName = `${name}-cdn`;
		const cdn = new CDN(this, cdnName, {
			name: cdnName,
			zone,
			cert,
			domain,
			defaultBehavior: {
				origin: S3BucketOrigin.withOriginAccessControl(bucket.bucket),
				viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
				originRequestPolicy: OriginRequestPolicy.CORS_S3_ORIGIN,
				responseHeadersPolicy:
					ResponseHeadersPolicy.CORS_ALLOW_ALL_ORIGINS_WITH_PREFLIGHT,
				functionAssociations: [
					...(patchRootObject
						? [
								{
									eventType: FunctionEventType.VIEWER_REQUEST,
									function: this.patchRootObject(name),
								},
							]
						: []),
				],
			},
			defaultRootObject: INDEX,
			additionalBehaviors: {},
			errorResponses: [
				{
					httpStatus: 403,
					responseHttpStatus: 200,
					responsePagePath: `/${INDEX}`,
					ttl: Duration.seconds(0),
				},
				{
					httpStatus: 404,
					responseHttpStatus: 200,
					responsePagePath: `/${INDEX}`,
					ttl: Duration.seconds(0),
				},
			],
		});

		bucket.bucket.addToResourcePolicy(
			new PolicyStatement({
				actions: ["s3:GetObject"],
				resources: [bucket.bucket.bucketArn, `${bucket.bucket.bucketArn}/*`],
				principals: [new ServicePrincipal("cloudfront.amazonaws.com")],
				conditions: {
					StringEquals: {
						"aws:SourceArn": cdn.distribution.distributionArn,
					},
				},
			})
		);

		this.invalidateDeployment(name, cdn.distribution, deployment);
	}

	private patchRootObject(name: string): CFFunction {
		const functionName = `${name}-patch-root-object`;
		return new CFFunction(this, functionName, {
			functionName,
			comment: "Patch root object to add index.html",
			code: FunctionCode.fromInline(`
        function handler(event) {
          const request = event.request;
          const uri = request.uri;

          if (uri.endsWith("/")) {
            request.uri += "index.html";
          } else if (!uri.includes('.')) {
            request.uri += '/index.html';
          }

          return request;
        }
      `),
			runtime: FunctionRuntime.JS_2_0,
		});
	}

	private invalidateDeployment(
		name: string,
		cdn: Distribution,
		deployment: BucketDeployment
	): void {
		const functionName = `${name}-invalidate-lambda`;
		const invalidateLambda = new NodejsFunction(this, functionName, {
			functionName,
			runtime: Runtime.NODEJS_LATEST,
			handler: "index.handler",
			code: Code.fromInline(`
        const { CloudFront } = require('@aws-sdk/client-cloudfront');
        
        var cloudfront = new CloudFront();
        exports.handler = async function(event, context) {
          await cloudfront.createInvalidation({
            DistributionId: '${cdn.distributionId}',
            InvalidationBatch: { 
              CallerReference: new Date().getTime().toString(),
              Paths: { 
                Quantity: 1, 
                Items: ['/*']
              }
            }
          });
        };
      `),
		});

		cdn.grantCreateInvalidation(invalidateLambda);

		const deploymentDate = new Date().toISOString();
		const resourceName = `${name}-invalidate-resource`;
		const physicalName = `${name}-invalidate-resource-${deploymentDate}`;

		const invalidateResource = new AwsCustomResource(this, resourceName, {
			onCreate: {
				service: "Lambda",
				action: "invoke",
				parameters: {
					FunctionName: invalidateLambda.functionName,
				},
				physicalResourceId: PhysicalResourceId.of(physicalName),
			},
			onUpdate: {
				service: "Lambda",
				action: "invoke",
				parameters: {
					FunctionName: invalidateLambda.functionName,
				},
				physicalResourceId: PhysicalResourceId.of(physicalName),
			},
			timeout: Duration.minutes(5),
			policy: AwsCustomResourcePolicy.fromSdkCalls({
				resources: AwsCustomResourcePolicy.ANY_RESOURCE,
			}),
		});

		invalidateResource.node.addDependency(invalidateLambda);
		invalidateResource.node.addDependency(deployment);
	}
}
