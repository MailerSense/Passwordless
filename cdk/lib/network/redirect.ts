import { RemovalPolicy } from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import { Distribution, ViewerProtocolPolicy } from "aws-cdk-lib/aws-cloudfront";
import { S3StaticWebsiteOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import {
	ARecord,
	AaaaRecord,
	IHostedZone,
	RecordTarget,
} from "aws-cdk-lib/aws-route53";
import { CloudFrontTarget } from "aws-cdk-lib/aws-route53-targets";
import {
	BlockPublicAccess,
	Bucket,
	RedirectProtocol,
} from "aws-cdk-lib/aws-s3";
import { md5hash } from "aws-cdk-lib/core/lib/helpers-internal";
import { Construct } from "constructs";

export interface RedirectProps {
	name: string;
	zone: IHostedZone;
	cert: acm.ICertificate;
	toDomain: string;
	fromDomains: string[];
	removalPolicy: RemovalPolicy;
}

export class Redirect extends Construct {
	public readonly distribution: Distribution;

	public constructor(
		scope: Construct,
		id: string,
		props: Readonly<RedirectProps>
	) {
		super(scope, id);

		const { name, cert, zone, toDomain, fromDomains, removalPolicy } = props;

		const bucket = new Bucket(this, `${name}-redirect-bucket`, {
			websiteRedirect: {
				hostName: toDomain,
				protocol: RedirectProtocol.HTTPS,
			},
			removalPolicy,
			blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
		});

		this.distribution = new Distribution(this, `${name}-distribution`, {
			defaultBehavior: {
				origin: new S3StaticWebsiteOrigin(bucket),
				viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
			},
			domainNames: fromDomains,
			certificate: cert,
			comment: `Redirect to ${toDomain} from ${fromDomains.join(", ")}`,
		});

		fromDomains.forEach((domainName) => {
			const hash = md5hash(domainName).slice(0, 6);
			const aliasProps = {
				zone,
				target: RecordTarget.fromAlias(new CloudFrontTarget(this.distribution)),
				recordName: domainName,
			};

			new ARecord(this, `redirect-alias-${hash}`, aliasProps);
			new AaaaRecord(this, `redirect-alias-six-${hash}`, aliasProps);
		});
	}
}
