import { RemovalPolicy } from "aws-cdk-lib";
import {
  BlockPublicAccess,
  Bucket,
  BucketEncryption,
} from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface PublicBucketProps {
  name: string;
  removalPolicy: RemovalPolicy;
}

export class PublicBucket extends Construct {
  public readonly bucket: Bucket;

  public constructor(scope: Construct, id: string, props: PublicBucketProps) {
    super(scope, id);

    this.bucket = new Bucket(this, `${props.name}-public`, {
      removalPolicy: props.removalPolicy,
      publicReadAccess: true,
      blockPublicAccess: new BlockPublicAccess({
        blockPublicAcls: false,
        ignorePublicAcls: false,
        blockPublicPolicy: false,
        restrictPublicBuckets: false,
      }),
      encryption: BucketEncryption.S3_MANAGED,
      enforceSSL: true,
      versioned: true,
    });

    NagSuppressions.addResourceSuppressions(this, [
      {
        id: "AwsSolutions-IAM5",
        reason: "This is for in the context of S3 buckets",
      },
    ]);
  }
}
