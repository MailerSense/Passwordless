import * as acm from "aws-cdk-lib/aws-certificatemanager";
import {
	BehaviorOptions,
	Distribution,
	DistributionProps,
} from "aws-cdk-lib/aws-cloudfront";
import {
	ARecord,
	AaaaRecord,
	IHostedZone,
	RecordTarget,
} from "aws-cdk-lib/aws-route53";
import { CloudFrontTarget } from "aws-cdk-lib/aws-route53-targets";
import { CfnWebACL } from "aws-cdk-lib/aws-wafv2";
import { Construct } from "constructs";

export type CDNProps = {
	name: string;
	zone: IHostedZone;
	cert: acm.ICertificate;
	domain: string;
	additionalBehaviors: Record<string, BehaviorOptions>;
	webApplicationFirewall?: CfnWebACL;
} & Pick<
	DistributionProps,
	"errorResponses" | "defaultBehavior" | "defaultRootObject"
>;

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
			errorResponses,
			defaultBehavior,
			defaultRootObject,
			additionalBehaviors,
			webApplicationFirewall: webApplicationFirewal,
		} = props;

		this.distribution = new Distribution(this, `${name}-cf-distribution`, {
			webAclId: webApplicationFirewal?.attrArn,
			domainNames: [domain],
			certificate: cert,
			errorResponses,
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
