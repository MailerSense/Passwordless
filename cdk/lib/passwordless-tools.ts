import * as cdk from "aws-cdk-lib";
import { aws_backup as bk, Duration, RemovalPolicy } from "aws-cdk-lib";
import { AutoScalingGroup } from "aws-cdk-lib/aws-autoscaling";
import { InstanceClass, InstanceSize, InstanceType } from "aws-cdk-lib/aws-ec2";
import {
  AmiHardwareType,
  AsgCapacityProvider,
  Cluster,
  ContainerInsights,
  EcsOptimizedImage,
} from "aws-cdk-lib/aws-ecs";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { PrivateDnsNamespace } from "aws-cdk-lib/aws-servicediscovery";
import { Construct } from "constructs";

import { Backup } from "./database/backup";
import { Postgres } from "./database/postgres";
import { Redis } from "./database/redis";
import { VPC } from "./network/vpc";
import { Environment } from "./util/environment";
import { lookupMap } from "./util/lookup";

export class PasswordlessTools extends cdk.Stack {
  public constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const env = process.env.DEPLOYMENT_ENV
      ? (process.env.DEPLOYMENT_ENV as Environment)
      : Environment.DEV;

    const envLookup = lookupMap[env];

    const removalPolicy =
      env == Environment.PROD ? RemovalPolicy.DESTROY : RemovalPolicy.DESTROY;

    const backupRetention = Duration.days(env == Environment.PROD ? 30 : 0);

    const rdsInstanceType =
      env == Environment.PROD
        ? InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO)
        : InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO);

    const rdsReplicaType =
      env == Environment.PROD
        ? InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO)
        : InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO);

    const redisInstanceType =
      env == Environment.PROD
        ? InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO)
        : InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO);

    const logRetention =
      env == Environment.PROD ? RetentionDays.ONE_WEEK : RetentionDays.ONE_WEEK;

    const deletionProtection = false;

    const dbName = "passwordlesstools";
    const appName = "passwordless-tools";
    const clusterNamespaceRoot = "passwordless.tools.internal";

    const vpcName = `${env}-vpc`;
    const vpc = new VPC(this, vpcName, {
      name: vpcName,
      cidr: envLookup.cidr,
      cidrMask: 18,
      publicSubnet: "public",
      privateSubnet: "private",
      logRetention,
      removalPolicy,
    });

    const _clusterNamespace = new PrivateDnsNamespace(
      this,
      `${env}-cluster-namespace`,
      {
        name: clusterNamespaceRoot,
        vpc: vpc.vpc,
        description: `Private DNS namespace ${clusterNamespaceRoot} for the ECS cluster`,
      },
    );

    const postgres = new Postgres(this, `${env}-postgres`, {
      vpc: vpc.vpc,
      name: dbName,
      instanceType: rdsInstanceType,
      removalPolicy,
      backupRetention,
      deletionProtection,
    });

    const _backup = new Backup(this, `${env}-postgres-backup`, {
      backupPlanName: `${appName}-backup`,
      backupRateHour: 6,
      deleteBackupAfter: Duration.days(30),
      backupCompletionWindow: cdk.Duration.hours(2),
      resources: [bk.BackupResource.fromRdsDatabaseInstance(postgres.db)],
    });

    const redis = new Redis(this, `${env}-redis-cache`, {
      vpc: vpc.vpc,
      name: `${appName}-redis`,
      machine: redisInstanceType,
      removalPolicy,
    });

    const cluster = new Cluster(this, `${env}-cluster`, {
      vpc: vpc.vpc,
      clusterName: `${appName}-cluster`,
      containerInsights: true,
      containerInsightsV2: ContainerInsights.ENHANCED,
    });

    const capacityProviders = {
      "t4g-nano-asg-capacity-provider": new AsgCapacityProvider(
        this,
        "t4g-nano-asg-capacity-provider",
        {
          autoScalingGroup: new AutoScalingGroup(
            this,
            "t4g-nano-autoscaling-group",
            {
              vpc: vpc.vpc,
              instanceType: InstanceType.of(
                InstanceClass.T4G,
                InstanceSize.NANO,
              ),
              machineImage: EcsOptimizedImage.amazonLinux2023(
                AmiHardwareType.ARM,
              ),
              minCapacity: 2,
              maxCapacity: 2,
            },
          ),
          enableManagedTerminationProtection: true,
          enableManagedScaling: true,
        },
      ),
    };

    for (const [_, capacityProvider] of Object.entries(capacityProviders)) {
      cluster.addAsgCapacityProvider(capacityProvider);
    }

    const zone = PublicHostedZone.fromHostedZoneAttributes(
      this,
      `${env}-app-zone`,
      {
        zoneName: envLookup.hostedZone.domains.primary,
        hostedZoneId: envLookup.hostedZone.hostedZoneId,
      },
    );

    const comZone = PublicHostedZone.fromHostedZoneAttributes(
      this,
      `${env}-app-come-zone`,
      {
        zoneName: envLookup.hostedZoneCom.domains.primary,
        hostedZoneId: envLookup.hostedZoneCom.hostedZoneId,
      },
    );

    /* 
     
    const generalSecret = sm.Secret.fromSecretCompleteArn(
      this,
      "general-secrets",
      envLookup.generalSecretArn,
    );

    const obanAuthKey = process.env.OBAN_PRO_AUTH_KEY;
    if (!obanAuthKey) {
      throw new Error("OBAN_PRO_AUTH_KEY is required");
    }

    const imageName = "passwordless-tools-image";
    const cachedImage = new CachedImage(this, imageName, {
      exclude: ["node_modules", "deps", "_build", ".git"],
      assetName: imageName,
      directory: join(__dirname, "../../"),
      file: "Dockerfile",
      buildArgs: {
        OBAN_PRO_AUTH_KEY: obanAuthKey,
      },
      platform: Platform.LINUX_ARM64,
    });

    const ioCertificate = new Certificate(this, "main-certificate", {
      name: `${appName}-certificate`,
      zone: ioZone,
      domain: envLookup.hostedZoneIo.domains.primary,
    });

    const comCertificate = new Certificate(this, "com-certificate", {
      name: `${appName}-com-certificate`,
      zone: comZone,
      domain: envLookup.hostedZoneCom.domains.primary,
    });

    const publicSharing = new PublicBucket(this, "sharing-bucket", {
      name: "sharing",
      removalPolicy,
    });

    const appContainer: AppContainer = {
      image: ContainerImage.fromDockerImageAsset(cachedImage),
      secrets: {
        // Postgres
        POSTGRES_USER: Secret.fromSecretsManager(postgres.secret, "username"),
        POSTGRES_PASSWORD: Secret.fromSecretsManager(
          postgres.secret,
          "password",
        ),
        POSTGRES_HOST: Secret.fromSecretsManager(postgres.secret, "host"),
        POSTGRES_PORT: Secret.fromSecretsManager(postgres.secret, "port"),
        POSTGRES_DB_NAME: Secret.fromSecretsManager(postgres.secret, "dbname"),
        // Redis
        REDIS_HOST: Secret.fromSecretsManager(generalSecret, "REDIS_HOST"),
        REDIS_PORT: Secret.fromSecretsManager(generalSecret, "REDIS_PORT"),
        REDIS_AUTH_TOKEN: Secret.fromSecretsManager(redis.secret, "auth_token"),
        // General
        SECRET_KEY_BASE: Secret.fromSecretsManager(
          generalSecret,
          "SECRET_KEY_BASE",
        ),
        // Contentful
        CONTENTFUL_ACCESS_TOKEN: Secret.fromSecretsManager(
          generalSecret,
          "CONTENTFUL_ACCESS_TOKEN",
        ),
        // OpenAI
        OPEN_AI_KEY: Secret.fromSecretsManager(generalSecret, "OPEN_AI_KEY"),
        // Google
        GOOGLE_OAUTH_CLIENT_ID: Secret.fromSecretsManager(
          generalSecret,
          "GOOGLE_OAUTH_CLIENT_ID",
        ),
        GOOGLE_OAUTH_SECRET: Secret.fromSecretsManager(
          generalSecret,
          "GOOGLE_OAUTH_SECRET",
        ),
      },
      command: "/app/bin/server",
      environment: {
        // Static config
        ...envLookup.appConfig,
      },
      stopTimeout: Duration.seconds(30),
      containerPort: 8000,
      memoryReservation: 512,
    };

    const migrationName = "passwordless-tools-migration-lambda";
    const migration = new Migration(this, migrationName, {
      vpc: vpc.vpc,
      name: migrationName,
      image: cachedImage,
      generalSecret,
      posgresSecret: postgres.secret,
      logRetention,
      environment: { ...envLookup.appConfig, POOL_SIZE: "10" },
    });

    const app = new PublicEC2App(this, appName, {
      name: appName,
      zone: ioZone,
      domain: envLookup.hostedZoneIo.domains.primary,
      cluster,
      desiredCount: 2,
      certificate: ioCertificate.certificate,
      container: appContainer,
      healthCheckCmd: "/app/bin/health",
      healthCheckPath: "/health/ready",
      logRetention,
      capacityProviderStrategies: [
        {
          capacityProvider:
            capacityProviders["t4g-micro-asg-capacity-provider"]
              .capacityProviderName,
          weight: 100,
        },
      ],
    });
    app.node.addDependency(migration);

    postgres.db.connections.allowFrom(
      migration.lambda,
      Port.tcp(postgres.port),
      `Allow traffic from migration lambda to Postres RDS on port ${postgres.port}`,
    );

    postgres.db.connections.allowFrom(
      app.service.service,
      Port.tcp(postgres.port),
      `Allow traffic from app to Postres RDS on port ${postgres.port}`,
    );

    redis.securityGroup.connections.allowFrom(
      app.service.service,
      Port.tcp(redis.port),
      `Allow traffic from app to Redis on port ${redis.port}`,
    );

    const _waf = new WAF(this, "main-waf", {
      name: `${appName}-waf`,
      associationArns: [
        {
          name: `${appName}-alb`,
          arn: app.service.loadBalancer.loadBalancerArn,
        },
      ],
      allowedPathPrefixes: ["/api", "/webhook"],
      blockedPathPrefixes: ["/health"],
    });

    if (envLookup.hostedZoneIo.domains.cdn) {
      const _cdn = new CDN(this, "main-cdn", {
        name: `${appName}-cdn`,
        zone: ioZone,
        cert: ioCertificate.certificate,
        domain: envLookup.hostedZoneIo.domains.cdn,
        defaultBehavior: {
          origin: new LoadBalancerV2Origin(app.service.loadBalancer),
          viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: CachePolicy.USE_ORIGIN_CACHE_CONTROL_HEADERS,
          originRequestPolicy: OriginRequestPolicy.ALL_VIEWER,
        },
        additionalBehaviors: {
          "public-sharing/*": {
            origin: S3BucketOrigin.withOriginAccessControl(
              publicSharing.bucket,
            ),
            viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          },
        },
      });
    }

    if (envLookup.hostedZoneIo.domains.email) {
      const domain = envLookup.hostedZoneIo.domains.email;
      const sesIo = new SES(this, "main-ses", {
        name: `${appName}-ses`,
        zone: ioZone,
        domains: [
          {
            domain,
            subDomain: "email",
            domainFromPrefix: "envelope",
            ruaEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
            rufEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
          },
          {
            domain,
            subDomain: "support",
            domainFromPrefix: "envelope",
            ruaEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
            rufEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
          },
        ],
      });

      for (const domainIdentity of sesIo.domainIdentities) {
        domainIdentity.grant(
          app.service.taskDefinition.taskRole,
          "ses:SendEmail",
          "ses:SendRawEmail",
        );
      }
    }

    if (envLookup.hostedZoneCom.domains.email) {
      const domain = envLookup.hostedZoneCom.domains.email;
      const sesCom = new SES(this, "com-ses", {
        name: `${appName}-ses-com`,
        zone: comZone,
        domains: [
          {
            domain,
            subDomain: "support",
            domainFromPrefix: "envelope",
            ruaEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
            rufEmail: `dmarc@${envLookup.hostedZoneCom.domains.primary}`,
          },
        ],
      });

      for (const domainIdentity of sesCom.domainIdentities) {
        domainIdentity.grant(
          app.service.taskDefinition.taskRole,
          "ses:SendEmail",
          "ses:SendRawEmail",
        );
      }
    }

    const redirectName = "com-to-io";
    const _redirect = new Redirect(this, redirectName, {
      name: redirectName,
      zone: comZone,
      cert: comCertificate.certificate,
      toDomain: envLookup.hostedZoneIo.domains.primary,
      fromDomains: [envLookup.hostedZoneCom.domains.primary],
      removalPolicy,
    });

    if (envLookup.hostedZoneIo.domains.www) {
      const wwwRedirectName = "www-to-io";
      const _wwwRedirect = new Redirect(this, wwwRedirectName, {
        name: wwwRedirectName,
        zone: ioZone,
        cert: ioCertificate.certificate,
        toDomain: envLookup.hostedZoneIo.domains.primary,
        fromDomains: [envLookup.hostedZoneIo.domains.www],
        removalPolicy,
      });
    } */
  }
}
