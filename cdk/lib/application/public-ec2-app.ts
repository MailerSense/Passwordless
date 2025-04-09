import { Duration } from "aws-cdk-lib";
import { Certificate } from "aws-cdk-lib/aws-certificatemanager";
import { Port } from "aws-cdk-lib/aws-ec2";
import {
  AppProtocol,
  AvailabilityZoneRebalancing,
  CapacityProviderStrategy,
  Cluster,
  ContainerDependencyCondition,
  ContainerImage,
  LogDrivers,
  NetworkMode,
  Secret,
} from "aws-cdk-lib/aws-ecs";
import {
  ApplicationProtocol,
  ListenerAction,
  ListenerCondition,
} from "aws-cdk-lib/aws-elasticloadbalancingv2";
import { PolicyStatement } from "aws-cdk-lib/aws-iam";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { INamespace } from "aws-cdk-lib/aws-servicediscovery";
import { Construct } from "constructs";

import { ApplicationLoadBalancedEC2App } from "../pattern/application-load-balanced-ec2-app";

export interface PublicEC2AppProps {
  cpu?: number;
  name: string;
  zone: IHostedZone;
  domain: string;
  daemon?: boolean;
  cluster: Cluster;
  namespace?: INamespace;
  certificate: Certificate;
  desiredCount?: number;
  container: AppContainer;
  initContainer?: AppContainer;
  healthCheckCmd?: string[];
  healthCheckPath: string;
  logRetention: RetentionDays;
  capacityProviderStrategies?: CapacityProviderStrategy[];
}

export interface AppContainer {
  image: ContainerImage;
  command: string;
  secrets: Record<string, Secret>;
  environment: Record<string, string>;
  stopTimeout?: Duration;
  containerPort: number;
  minHealthyPercent: number;
  memoryReservation: number;
}

export class PublicEC2App extends Construct {
  public readonly service: ApplicationLoadBalancedEC2App;

  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<PublicEC2AppProps>,
  ) {
    super(scope, id);

    const {
      cpu,
      name,
      zone,
      domain,
      daemon,
      cluster,
      namespace,
      certificate,
      desiredCount,
      container,
      initContainer,
      healthCheckCmd,
      healthCheckPath,
      logRetention,
      capacityProviderStrategies,
    } = props;

    const containerMappingName = "web";

    this.service = new ApplicationLoadBalancedEC2App(this, name, {
      daemon,
      cluster,
      serviceName: name,
      taskImageOptions: {
        image: container.image,
        command: [container.command],
        secrets: container.secrets,
        environment: container.environment,
        containerPort: container.containerPort,
        logDriver: LogDrivers.awsLogs({
          streamPrefix: `${name}-web`,
          logRetention,
        }),
      },
      cpu,
      desiredCount,
      stopTimeout: container.stopTimeout,
      protocol: ApplicationProtocol.HTTPS,
      networkMode: NetworkMode.AWS_VPC,
      circuitBreaker: { rollback: true },
      minHealthyPercent: container.minHealthyPercent,
      memoryReservationMiB: container.memoryReservation,
      availabilityZoneRebalancing: AvailabilityZoneRebalancing.ENABLED,
      loadBalancerName: `${name}-lb`,
      enableExecuteCommand: true,
      publicLoadBalancer: true,
      redirectHTTP: true,
      certificate,
      domainName: domain,
      domainZone: zone,
      healthCheck: healthCheckCmd
        ? {
            command: healthCheckCmd,
            interval: Duration.seconds(10),
            timeout: Duration.seconds(5),
            startPeriod: Duration.seconds(30),
          }
        : undefined,
      capacityProviderStrategies,
      containerMappingName,
      containerMappingProtocol: AppProtocol.http2,
      serviceConnectConfiguration: namespace
        ? {
            namespace: namespace.namespaceName,
            logDriver: LogDrivers.awsLogs({
              streamPrefix: `${name}-service`,
            }),
            services: [
              {
                port: container.containerPort,
                dnsName: name,
                discoveryName: name,
                portMappingName: containerMappingName,
                perRequestTimeout: Duration.seconds(10),
              },
            ],
          }
        : undefined,
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
          "ses:CreateEmailIdentity",
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
        memoryReservationMiB: initContainer.memoryReservation,
      });

      if (!this.service.taskDefinition.defaultContainer) {
        throw new Error("Default container is not set");
      }

      this.service.taskDefinition.defaultContainer.addContainerDependencies({
        container: init,
        condition: ContainerDependencyCondition.SUCCESS,
      });
    }
  }
}
