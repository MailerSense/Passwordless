import { RemovalPolicy } from "aws-cdk-lib";
import {
  FlowLog,
  FlowLogDestination,
  FlowLogResourceType,
  FlowLogTrafficType,
  GatewayVpcEndpointAwsService,
  InterfaceVpcEndpointAwsService,
  IpAddresses,
  SubnetType,
  Vpc,
} from "aws-cdk-lib/aws-ec2";
import * as iam from "aws-cdk-lib/aws-iam";
import { LogGroup, LogStream, RetentionDays } from "aws-cdk-lib/aws-logs";
import { Construct } from "constructs";

export interface VPCProps {
  cidr: string;
  name: string;
  cidrMask: number;
  publicSubnet: string;
  privateSubnet: string;
  logRetention: RetentionDays;
  removalPolicy: RemovalPolicy;
}

export class VPC extends Construct {
  public readonly vpc: Vpc;
  public readonly logGroup: LogGroup;
  public readonly logStream: LogStream;
  public readonly flowLogs: FlowLog;

  public constructor(scope: Construct, id: string, props: Readonly<VPCProps>) {
    super(scope, id);

    const {
      cidr,
      name,
      cidrMask,
      publicSubnet,
      privateSubnet,
      logRetention,
      removalPolicy,
    } = props;

    this.vpc = new Vpc(this, name, {
      maxAzs: 3,
      vpcName: name,
      ipAddresses: IpAddresses.cidr(cidr),
      subnetConfiguration: [
        {
          cidrMask,
          name: publicSubnet,
          subnetType: SubnetType.PUBLIC,
          mapPublicIpOnLaunch: true,
        },
        {
          cidrMask,
          name: privateSubnet,
          subnetType: SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
      enableDnsSupport: true,
      enableDnsHostnames: true,
    });

    const vpcRole = new iam.Role(this, `${name}-vpc-role`, {
      assumedBy: new iam.ServicePrincipal("vpc-flow-logs.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName("CloudWatchFullAccess"),
      ],
    });

    this.logGroup = new LogGroup(this, `${name}-flow-log-group`, {
      retention: logRetention,
      removalPolicy,
    });

    this.logStream = new LogStream(this, `${name}-flow-log-stream`, {
      logGroup: this.logGroup,
      removalPolicy,
    });

    this.flowLogs = new FlowLog(this, `${name}-flow-log`, {
      resourceType: FlowLogResourceType.fromVpc(this.vpc),
      destination: FlowLogDestination.toCloudWatchLogs(this.logGroup, vpcRole),
      trafficType: FlowLogTrafficType.ALL,
    });

    this.vpc.addGatewayEndpoint(`${name}-s3-endpoint`, {
      service: GatewayVpcEndpointAwsService.S3,
    });

    this.vpc.addInterfaceEndpoint(`${name}-ecs-endpoint`, {
      service: InterfaceVpcEndpointAwsService.ECS,
    });

    this.vpc.addInterfaceEndpoint(`${name}-ecs-agent-endpoint`, {
      service: InterfaceVpcEndpointAwsService.ECS_AGENT,
    });

    this.vpc.addInterfaceEndpoint(`${name}-ecs-telementry-endpoint`, {
      service: InterfaceVpcEndpointAwsService.ECS_TELEMETRY,
    });

    this.vpc.addInterfaceEndpoint(`${name}-ecr-endpoint`, {
      service: InterfaceVpcEndpointAwsService.ECR,
    });

    this.vpc.addInterfaceEndpoint(`${name}-ecr-docker-endpoint`, {
      service: InterfaceVpcEndpointAwsService.ECR_DOCKER,
    });

    this.vpc.addInterfaceEndpoint(`${name}-secrets-manager-endpoint`, {
      service: InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
    });

    this.vpc.addInterfaceEndpoint(`${name}-secrets-sqs-endpoint`, {
      service: InterfaceVpcEndpointAwsService.SQS,
    });
  }
}
