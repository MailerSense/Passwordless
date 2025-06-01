import { RemovalPolicy } from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import {
	LambdaEdgeEventType,
	OriginRequestPolicy,
	ResponseHeadersPolicy,
	ViewerProtocolPolicy,
	experimental,
} from "aws-cdk-lib/aws-cloudfront";
import { S3BucketOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import { PolicyStatement, ServicePrincipal } from "aws-cdk-lib/aws-iam";
import { Code, IVersion, Runtime } from "aws-cdk-lib/aws-lambda";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { BucketDeployment, Source } from "aws-cdk-lib/aws-s3-deployment";
import { Construct } from "constructs";
import { CDN } from "../network/cdn";
import { PrivateBucket } from "../storage/private-bucket";
import path = require("node:path");

export interface StaticWebsiteProps {
	name: string;
	source: string;
	zone: IHostedZone;
	cert: acm.ICertificate;
	domain: string;
	removalPolicy: RemovalPolicy;
	patchRootObject?: boolean;
}

export class StaticWebsite extends Construct {
	public constructor(scope: Construct, id: string, props: StaticWebsiteProps) {
		super(scope, id);

		const { name, source, zone, cert, domain, removalPolicy, patchRootObject } =
			props;

		const bucketName = `${name}-static-website`;
		const bucket = new PrivateBucket(this, bucketName, {
			name: bucketName,
			removalPolicy,
			websiteIndexDocument: "index.html",
		});

		new BucketDeployment(this, "BucketDeployment", {
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
				edgeLambdas: [
					...(patchRootObject
						? [
								{
									eventType: LambdaEdgeEventType.VIEWER_REQUEST,
									functionVersion: this.patchRootObject(name),
								},
							]
						: []),
				],
			},
			defaultRootObject: "index.html",
			additionalBehaviors: {},
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

	private patchRootObject(name: string): IVersion {
		const lambda = new experimental.EdgeFunction(
			this,
			`${name}-patch-root-object`,
			{
				runtime: Runtime.NODEJS_LATEST,
				handler: "index.handler",
				code: Code.fromAsset(path.join(__dirname, "edge/patch-root-object")),
			}
		);

		return lambda.currentVersion;
	}
}
