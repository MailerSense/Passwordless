import { Bucket, BucketEncryption, BucketProps } from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export type PrivateBucketProps = {
	name: string;
} & Pick<
	BucketProps,
	"cors" | "versioned" | "removalPolicy" | "websiteIndexDocument"
>;

export class PrivateBucket extends Construct {
	public readonly bucket: Bucket;

	public constructor(scope: Construct, id: string, props: PrivateBucketProps) {
		super(scope, id);

		const { name, cors, versioned, removalPolicy, websiteIndexDocument } =
			props;

		this.bucket = new Bucket(this, `${name}-private`, {
			enforceSSL: true,
			encryption: BucketEncryption.S3_MANAGED,
			websiteIndexDocument,
			removalPolicy,
			versioned,
			cors,
		});

		NagSuppressions.addResourceSuppressions(this, [
			{
				id: "AwsSolutions-IAM5",
				reason: "This is for in the context of S3 buckets",
			},
		]);
	}
}
