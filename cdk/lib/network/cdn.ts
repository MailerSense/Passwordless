import * as acm from "aws-cdk-lib/aws-certificatemanager";
import { BehaviorOptions, Distribution } from "aws-cdk-lib/aws-cloudfront";
import {
	ARecord,
	AaaaRecord,
	IHostedZone,
	RecordTarget,
} from "aws-cdk-lib/aws-route53";
import { CloudFrontTarget } from "aws-cdk-lib/aws-route53-targets";
import { CfnWebACL } from "aws-cdk-lib/aws-wafv2";
import { Construct } from "constructs";

export interface CDNProps {
	name: string;
	zone: IHostedZone;
	cert: acm.ICertificate;
	domain: string;
	defaultBehavior: BehaviorOptions;
	defaultRootObject?: string;
	additionalBehaviors: Record<string, BehaviorOptions>;
	webApplicationFirewall?: CfnWebACL;
}

export class CDN extends Construct {
	public readonly distribution: Distribution;
	public readonly aRecord: ARecord;
	public readonly aaaaRecord: AaaaRecord;

	public constructor(scope: Construct, id: string, props: Readonly<CDNProps>) {
		super(scope, id);

		const {
			name,
			zone,
			cert,
			domain,
			defaultBehavior,
			defaultRootObject,
			additionalBehaviors,
			webApplicationFirewall: webApplicationFirewal,
		} = props;

		this.distribution = new Distribution(this, `${name}-cf-distribution`, {
			webAclId: webApplicationFirewal?.attrArn,
			domainNames: [domain],
			certificate: cert,
			defaultBehavior,
			defaultRootObject,
			additionalBehaviors,
		});

		this.aRecord = new ARecord(this, `${name}-cf-a-record`, {
			zone,
			target: RecordTarget.fromAlias(new CloudFrontTarget(this.distribution)),
			recordName: `${domain}.`,
		});

		this.aaaaRecord = new AaaaRecord(this, `${name}-cf-aaaa-record`, {
			zone,
			target: RecordTarget.fromAlias(new CloudFrontTarget(this.distribution)),
			recordName: `${domain}.`,
		});
	}
}
