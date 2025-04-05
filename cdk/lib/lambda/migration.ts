import { Duration } from "aws-cdk-lib";
import { SubnetType, Vpc } from "aws-cdk-lib/aws-ec2";
import { PolicyStatement } from "aws-cdk-lib/aws-iam";
import {
  Architecture,
  Code,
  Function,
  Handler,
  Runtime,
} from "aws-cdk-lib/aws-lambda";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { ISecret } from "aws-cdk-lib/aws-secretsmanager";
import {
  AwsCustomResource,
  AwsCustomResourcePolicy,
  PhysicalResourceId,
} from "aws-cdk-lib/custom-resources";
import { Construct } from "constructs";

import { CachedImage } from "../storage/cached-image";

export interface MigrationProps {
  vpc: Vpc;
  name: string;
  image: CachedImage;
  generalSecret: ISecret;
  posgresSecret: ISecret;
  logRetention: RetentionDays;
  environment: Record<string, string>;
}

export class Migration extends Construct {
  public readonly lambda: Function;

  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<MigrationProps>,
  ) {
    super(scope, id);

    const { vpc, name, image, generalSecret, posgresSecret, environment } =
      props;

    this.lambda = new Function(this, name, {
      vpc: vpc,
      vpcSubnets: {
        subnetType: SubnetType.PRIVATE_WITH_EGRESS,
      },
      code: Code.fromEcrImage(image.repository, {
        tagOrDigest: image.imageTag,
      }),
      functionName: name,
      runtime: Runtime.FROM_IMAGE,
      handler: Handler.FROM_IMAGE,
      architecture: Architecture.ARM_64,
      environment: {
        // Migration
        DATABASE_MIGRATION: "true",
        // Postgres
        POSTGRES_USER: posgresSecret
          .secretValueFromJson("username")
          .unsafeUnwrap(),
        POSTGRES_PASSWORD: posgresSecret
          .secretValueFromJson("password")
          .unsafeUnwrap(),
        POSTGRES_HOST: posgresSecret.secretValueFromJson("host").unsafeUnwrap(),
        POSTGRES_PORT: posgresSecret.secretValueFromJson("port").unsafeUnwrap(),
        POSTGRES_DB_NAME: posgresSecret
          .secretValueFromJson("dbname")
          .unsafeUnwrap(),
        // Phoenix
        SECRET_KEY_BASE: generalSecret
          .secretValueFromJson("SECRET_KEY_BASE")
          .unsafeUnwrap(),
        // Rest
        ...environment,
      },
      timeout: Duration.minutes(5),
      memorySize: 512,
    });

    if (!this.lambda.role) {
      throw new Error("lambda role not defined");
    }

    generalSecret.grantRead(this.lambda);

    this.lambda.addToRolePolicy(
      new PolicyStatement({
        actions: ["cloudformation:DescribeStacks"],
        resources: ["*"],
      }),
    );

    this.lambda.node.addDependency(image);

    const deploymentDate = new Date().toISOString();
    const resourceId = `${name}-${deploymentDate}`;

    new AwsCustomResource(this, `${name}-custom-resource`, {
      onCreate: {
        service: "Lambda",
        action: "invoke",
        parameters: {
          FunctionName: this.lambda.functionName,
        },
        physicalResourceId: PhysicalResourceId.of(resourceId),
      },
      onUpdate: {
        service: "Lambda",
        action: "invoke",
        parameters: {
          FunctionName: this.lambda.functionName,
        },
        physicalResourceId: PhysicalResourceId.of(resourceId),
      },
      policy: AwsCustomResourcePolicy.fromStatements([
        new PolicyStatement({
          actions: ["lambda:InvokeFunction"],
          resources: [this.lambda.functionArn],
        }),
      ]),
    });
  }
}
