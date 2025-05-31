import { RemovalPolicy } from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import { ViewerProtocolPolicy } from "aws-cdk-lib/aws-cloudfront";
import { S3BucketOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { BucketDeployment, Source } from "aws-cdk-lib/aws-s3-deployment";
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
}

export class StaticWebsite extends Construct {
	public constructor(scope: Construct, id: string, props: StaticWebsiteProps) {
		super(scope, id);

		const { name, source, zone, cert, domain, removalPolicy } = props;

		const bucketName = `${name}-static-website`;
		const bucket = new PrivateBucket(this, bucketName, {
			name: bucketName,
			removalPolicy,
		});

		new BucketDeployment(this, "BucketDeployment", {
			destinationBucket: bucket.bucket,
			sources: [Source.asset(source)],
		});

		const cdnName = `${name}-cdn`;
		const _cdn = new CDN(this, cdnName, {
			name: cdnName,
			zone,
			cert,
			domain,
			defaultBehavior: {
				origin: S3BucketOrigin.withOriginAccessControl(bucket.bucket),
				viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
			},
			additionalBehaviors: {},
		});
	}
}
