import { RemovalPolicy } from "aws-cdk-lib";
import {
  BlockPublicAccess,
  Bucket,
  BucketEncryption,
  CorsRule,
} from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface PublicBucketProps {
  name: string;
  cors?: CorsRule[];
  removalPolicy: RemovalPolicy;
}

export class PublicBucket extends Construct {
  public readonly bucket: Bucket;

  public constructor(scope: Construct, id: string, props: PublicBucketProps) {
    super(scope, id);

    const { name, cors, removalPolicy } = props;

    this.bucket = new Bucket(this, `${name}-public`, {
      removalPolicy,
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
