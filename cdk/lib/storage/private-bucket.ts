import { RemovalPolicy } from "aws-cdk-lib";
import { Bucket, CorsRule } from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface PrivateBucketProps {
  name: string;
  cors?: CorsRule[];
  versioned?: boolean;
  removalPolicy: RemovalPolicy;
}

export class PrivateBucket extends Construct {
  public readonly bucket: Bucket;

  public constructor(scope: Construct, id: string, props: PrivateBucketProps) {
    super(scope, id);

    const { name, cors, versioned, removalPolicy } = props;

    this.bucket = new Bucket(this, `${name}-private`, {
      enforceSSL: true,
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
