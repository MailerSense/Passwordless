import { Duration } from "aws-cdk-lib";
import { Certificate } from "aws-cdk-lib/aws-certificatemanager";
import { Port, SubnetType } from "aws-cdk-lib/aws-ec2";
import {
  Cluster,
  ContainerDependencyCondition,
  ContainerImage,
  CpuArchitecture,
  LogDrivers,
  OperatingSystemFamily,
  Secret,
} from "aws-cdk-lib/aws-ecs";
import { ApplicationLoadBalancedFargateService } from "aws-cdk-lib/aws-ecs-patterns";
import {
  ApplicationProtocol,
  ListenerAction,
  ListenerCondition,
} from "aws-cdk-lib/aws-elasticloadbalancingv2";
import { PolicyStatement } from "aws-cdk-lib/aws-iam";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import {
  DnsRecordType,
  INamespace,
  RoutingPolicy,
  Service,
} from "aws-cdk-lib/aws-servicediscovery";
import { Construct } from "constructs";

export interface PublicFargateAppProps {
  name: string;
  zone: IHostedZone;
  domain: string;
  cluster: Cluster;
  cpuLimit: number;
  certificate: Certificate;
  memoryLimit: number;
  namespace?: INamespace;
  container: AppContainer;
  initContainer?: AppContainer;
  healthCheckCmd?: string;
  healthCheckPath: string;
  logRetention: RetentionDays;
  desiredCount: number;
}

export interface AppContainer {
  image: ContainerImage;
  command: string;
  secrets: Record<string, Secret>;
  environment: Record<string, string>;
  containerPort: number;
  minHealthyPercent: number;
}

export class PublicFargateApp extends Construct {
  public readonly service: ApplicationLoadBalancedFargateService;

  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<PublicFargateAppProps>,
  ) {
    super(scope, id);

    const {
      name,
      zone,
      domain,
      cluster,
      cpuLimit,
      certificate,
      memoryLimit,
      namespace,
      container,
      initContainer,
      healthCheckCmd,
      healthCheckPath,
      logRetention,
      desiredCount,
    } = props;

    this.service = new ApplicationLoadBalancedFargateService(this, name, {
      cluster,
      serviceName: name,
      desiredCount,
      taskImageOptions: {
        image: container.image,
        command: [container.command],
        secrets: container.secrets,
        environment: container.environment,
        containerPort: container.containerPort,
      },
      runtimePlatform: {
        operatingSystemFamily: OperatingSystemFamily.LINUX,
        cpuArchitecture: CpuArchitecture.ARM64,
      },
      taskSubnets: {
        subnetType: SubnetType.PRIVATE_WITH_EGRESS,
      },
      cpu: cpuLimit,
      protocol: ApplicationProtocol.HTTPS,
      memoryLimitMiB: memoryLimit,
      minHealthyPercent: container.minHealthyPercent,
      circuitBreaker: { rollback: true },
      loadBalancerName: `${name}-lb`,
      enableExecuteCommand: true,
      publicLoadBalancer: true,
      redirectHTTP: true,
      certificate,
      domainName: domain,
      domainZone: zone,
      healthCheck: healthCheckCmd
        ? {
            command: [healthCheckCmd],
            interval: Duration.seconds(5),
            timeout: Duration.seconds(3),
            startPeriod: Duration.seconds(10),
          }
        : undefined,
      enableECSManagedTags: true,
    });

    // Allow connections to itself
    this.service.service.connections.allowFrom(
      this.service.service,
      Port.allTcp(),
    );

    // Drop invalid headers rather than route to target
    this.service.loadBalancer.setAttribute(
      "routing.http.drop_invalid_header_fields.enabled",
      "true",
    );

    // Redirect www to non-www
    this.service.listener.addAction(`${name}-redirect-www-to-naked`, {
      action: ListenerAction.redirect({ host: domain, permanent: true }),
      priority: 1,
      conditions: [ListenerCondition.hostHeaders([`www.${domain}`])],
    });

    this.service.taskDefinition.addToTaskRolePolicy(
      new PolicyStatement({
        sid: "ServerAdhocSSH",
        actions: [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ],
        resources: ["*"],
      }),
    );

    this.service.taskDefinition.addToTaskRolePolicy(
      new PolicyStatement({
        sid: "DomainManagement",
        actions: [
          "ses:GetEmailIdentity",
          "ses:ListEmailIdentities",
          "ses:CreateEmailIdentity",
          "ses:PutEmailIdentityMailFromAttributes",
          "ses:PutEmailIdentityConfigurationSetAttributes",
          "ses:DeleteEmailIdentity",
          "ses:GetConfigurationSet",
          "ses:GetConfigurationSetEventDestinations",
          "ses:CreateConfigurationSet",
          "ses:CreateConfigurationSetEventDestination",
          "ses:PutConfigurationSetDeliveryOptions",
          "ses:PutConfigurationSetReputationOptions",
          "ses:PutConfigurationSetSendingOptions",
          "ses:PutConfigurationSetTrackingOptions",
          "ses:DeleteConfigurationSet",
          "ses:DeleteConfigurationSetEventDestination",
          "ses:GetIdentityDkimAttributes",
          "ses:GetIdentityVerificationAttributes",
          "ses:GetIdentityMailFromDomainAttributes",
          "ses:PutEmailIdentityDkimSigningAttributes",
          "ses:PutEmailIdentityMailFromAttributes",
          "ses:PutEmailIdentityFeedbackAttributes",
          "ses:SetIdentityMailFromDomain",
          "ses:SetIdentityFeedbackForwardingEnabled",
          "ses:SetIdentityHeadersInNotificationsEnabled",
          "ses:VerifyDomainIdentity",
          "ses:VerifyDomainDkim",
          "ses:TagResource",
        ],
        resources: ["*"],
      }),
    );

    this.service.taskDefinition.addToTaskRolePolicy(
      new PolicyStatement({
        sid: "SenderAddressManagement",
        actions: [
          "ses:DeleteIdentity",
          "ses:GetEmailIdentity",
          "ses:GetIdentityVerificationAttributes",
          "ses:VerifyEmailAddress",
          "ses:VerifyEmailIdentity",
          "ses:ListIdentities",
          "ses:ListIdentityPolicies",
          "ses:ListVerifiedEmailAddresses",
          "ses:DeleteVerifiedEmailAddress",
          "ses:ListConfigurationSets",
        ],
        resources: ["*"],
      }),
    );

    this.service.taskDefinition.addToTaskRolePolicy(
      new PolicyStatement({
        sid: "SendingStatistics",
        actions: [
          "ses:GetAccountSendingEnabled",
          "ses:GetSendStatistics",
          "ses:GetSendQuota",
        ],
        resources: ["*"],
      }),
    );

    this.service.taskDefinition.addToTaskRolePolicy(
      new PolicyStatement({
        sid: "EmailSending",
        actions: ["ses:SendEmail", "ses:SendRawEmail"],
        resources: ["*"],
      }),
    );

    this.service.targetGroup.configureHealthCheck({
      path: healthCheckPath,
      interval: Duration.seconds(5),
      timeout: Duration.seconds(3),
    });

    if (initContainer) {
      const init = this.service.taskDefinition.addContainer("init", {
        essential: false,
        image: initContainer.image,
        command: [initContainer.command],
        logging: LogDrivers.awsLogs({
          streamPrefix: `${name}-init`,
          logRetention,
        }),
        secrets: initContainer.secrets,
        environment: initContainer.environment,
      });

      if (!this.service.taskDefinition.defaultContainer) {
        throw new Error("Default container is not set");
      }

      this.service.taskDefinition.defaultContainer.addContainerDependencies({
        container: init,
        condition: ContainerDependencyCondition.SUCCESS,
      });
    }

    if (namespace) {
      const internalService = new Service(this, "app-service", {
        name,
        namespace,
        dnsRecordType: DnsRecordType.A,
        routingPolicy: RoutingPolicy.WEIGHTED,
        loadBalancer: true,
      });

      internalService.registerLoadBalancer("app-lb", this.service.loadBalancer);
    }
  }
}
