import { RemovalPolicy } from "aws-cdk-lib";
import { Bucket, BucketEncryption } from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface PrivateBucketProps {
  name: string;
  removalPolicy: RemovalPolicy;
}

export class PrivateBucket extends Construct {
  public readonly bucket: Bucket;

  public constructor(scope: Construct, id: string, props: PrivateBucketProps) {
    super(scope, id);

    this.bucket = new Bucket(this, `${props.name}-private`, {
      versioned: true,
      enforceSSL: true,
      encryption: BucketEncryption.S3_MANAGED,
      removalPolicy: props.removalPolicy,
    });

    NagSuppressions.addResourceSuppressions(this, [
      {
        id: "AwsSolutions-IAM5",
        reason: "This is for in the context of S3 buckets",
      },
    ]);
  }
}
