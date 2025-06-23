import { Duration, RemovalPolicy } from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import {
	Function as CFFunction,
	FunctionCode,
	FunctionEventType,
	FunctionRuntime,
	OriginRequestPolicy,
	ResponseHeadersPolicy,
	ViewerProtocolPolicy,
} from "aws-cdk-lib/aws-cloudfront";
import { S3BucketOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import { PolicyStatement, ServicePrincipal } from "aws-cdk-lib/aws-iam";
import {} from "aws-cdk-lib/aws-lambda";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { BucketDeployment, Source } from "aws-cdk-lib/aws-s3-deployment";
import {} from "aws-cdk-lib/custom-resources";
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

		const _deployment = new BucketDeployment(this, "BucketDeployment", {
			destinationBucket: bucket.bucket,
			sources: [Source.asset(source)],
			distribution: cdn.distribution,
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
}
