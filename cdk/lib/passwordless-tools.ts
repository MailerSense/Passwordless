import { join } from "node:path";
import * as cdk from "aws-cdk-lib";
import { Duration, RemovalPolicy, aws_backup as bk } from "aws-cdk-lib";
import {
	BehaviorOptions,
	CachePolicy,
	OriginRequestPolicy,
	ResponseHeadersPolicy,
	ViewerProtocolPolicy,
} from "aws-cdk-lib/aws-cloudfront";
import {
	LoadBalancerV2Origin,
	S3BucketOrigin,
} from "aws-cdk-lib/aws-cloudfront-origins";
import {
	InstanceClass,
	InstanceSize,
	InstanceType,
	Port,
} from "aws-cdk-lib/aws-ec2";
import { Platform } from "aws-cdk-lib/aws-ecr-assets";
import {
	Cluster,
	ContainerImage,
	ContainerInsights,
	Secret,
} from "aws-cdk-lib/aws-ecs";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { HttpMethods } from "aws-cdk-lib/aws-s3";
import * as sm from "aws-cdk-lib/aws-secretsmanager";
import { PrivateDnsNamespace } from "aws-cdk-lib/aws-servicediscovery";
import { Construct } from "constructs";

import {
	AppContainer,
	PublicFargateApp,
} from "./application/public-fargate-app";
import { Backup } from "./database/backup";
import { Postgres } from "./database/postgres";
import { Redis } from "./database/redis";
import { SES } from "./email/ses";
import { Migration } from "./lambda/migration";
import { CDN } from "./network/cdn";
import { Certificate } from "./network/certificate";
import { VPC } from "./network/vpc";
import { WAF } from "./network/waf";
import { PasswordlessToolsCertificates } from "./passwordless-tools-certificates";
import { ContainerScanning } from "./pattern/container-scanning";
import { CachedImage } from "./storage/cached-image";
import { PrivateBucket } from "./storage/private-bucket";
import { Environment } from "./util/environment";
import { domainLookupMap, lookupMap } from "./util/lookup";
import { Region } from "./util/region";

export interface PasswordlessToolsProps extends cdk.StackProps {
	region: Region;
	certificates: PasswordlessToolsCertificates;
}

export class PasswordlessTools extends cdk.Stack {
	public constructor(
		scope: Construct,
		id: string,
		props: PasswordlessToolsProps
	) {
		super(scope, id, props);

		const { region, certificates } = props;

		const env = process.env.DEPLOYMENT_ENV
			? (process.env.DEPLOYMENT_ENV as Environment)
			: Environment.DEV;

		const envLookup = lookupMap[env];

		const domainLookup = domainLookupMap[region][env];

		const removalPolicy =
			env === Environment.PROD ? RemovalPolicy.DESTROY : RemovalPolicy.DESTROY;

		const backupRetention = Duration.days(env === Environment.PROD ? 30 : 0);

		const rdsInstanceType =
			env === Environment.PROD
				? InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO)
				: InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO);

		const redisInstanceType =
			env === Environment.PROD
				? InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO)
				: InstanceType.of(InstanceClass.T4G, InstanceSize.MICRO);

		const logRetention =
			env === Environment.PROD
				? RetentionDays.ONE_WEEK
				: RetentionDays.ONE_WEEK;

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

		const namespace = new PrivateDnsNamespace(
			this,
			`${env}-cluster-namespace`,
			{
				name: clusterNamespaceRoot,
				vpc: vpc.vpc,
				description: `Private DNS namespace ${clusterNamespaceRoot} for the ECS cluster`,
			}
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
			containerInsightsV2: ContainerInsights.ENHANCED,
		});

		const zone = PublicHostedZone.fromHostedZoneAttributes(
			this,
			`${env}-app-zone`,
			{
				zoneName: envLookup.hostedZone.name,
				hostedZoneId: envLookup.hostedZone.id,
			}
		);

		const comZone = PublicHostedZone.fromHostedZoneAttributes(
			this,
			`${env}-app-com-zone`,
			{
				zoneName: envLookup.hostedZoneCom.name,
				hostedZoneId: envLookup.hostedZoneCom.id,
			}
		);

		const generalSecret = sm.Secret.fromSecretCompleteArn(
			this,
			"general-secrets",
			envLookup.generalSecretArn
		);

		const obanAuthKey = process.env.OBAN_PRO_AUTH_KEY;
		if (!obanAuthKey) {
			throw new Error("OBAN_PRO_AUTH_KEY is required");
		}

		const certificate = new Certificate(this, `${env}-app-certificate`, {
			name: `${appName}-certificate`,
			zone,
			domain: envLookup.hostedZone.domains.primary,
		});

		const customerMediaName = `${env}-customer-media`;
		const customerMedia = new PrivateBucket(this, customerMediaName, {
			name: customerMediaName,
			cors: [
				{
					allowedMethods: [HttpMethods.PUT],
					allowedOrigins: [`https://${domainLookup.main.domain}`],
					allowedHeaders: ["*"],
				},
			],
			removalPolicy,
		});

		const { domain: cdnDomain, certificate: cdnCert } =
			certificates.cdn[region][env];

		const { domain: appCdnDomain, certificate: appCdnCert } =
			certificates.appCdn[region][env];

		const ses = new SES(this, `${env}-app-ses`, {
			name: `${appName}-app-ses`,
			domains: [
				{
					zone: comZone,
					domain: domainLookup.email.domain,
					domainFromPrefix: "envelope",
					ruaEmail: `dmarc@${comZone.zoneName}`,
					rufEmail: `dmarc@${comZone.zoneName}`,
				},
			],
			tracking: {
				zone: comZone,
				cert: certificates.tracking[region][env].certificate,
				domain: domainLookup.tracking.domain,
			},
			removalPolicy,
		});

		const imageName = "passwordless-tools-image";
		const cachedImage = new CachedImage(this, imageName, {
			exclude: ["node_modules", "deps", "_build", ".git"],
			assetName: imageName,
			directory: join(__dirname, "../../"),
			buildArgs: {
				OBAN_PRO_AUTH_KEY: obanAuthKey,
			},
			platform: Platform.LINUX_ARM64,
		});

		const appEnv = {
			AWS_REGION: cdk.Stack.of(this).region,
			AWS_ACCOUNT: cdk.Stack.of(this).account,
			CDN_HOST: appCdnDomain,
			CUSTOMER_MEDIA_BUCKET: customerMedia.bucket.bucketName,
			CUSTOMER_MEDIA_CDN_URL: `https://${cdnDomain}/`,
			SES_QUEUE_URL: ses.eventQueue.queueUrl,
			SES_QUEUE_ARN: ses.eventQueue.queueArn,
		};

		const appContainer: AppContainer = {
			image: ContainerImage.fromDockerImageAsset(cachedImage),
			secrets: {
				// Postgres
				POSTGRES_USER: Secret.fromSecretsManager(postgres.secret, "username"),
				POSTGRES_PASSWORD: Secret.fromSecretsManager(
					postgres.secret,
					"password"
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
					"SECRET_KEY_BASE"
				),
				// OpenAI
				OPEN_AI_KEY: Secret.fromSecretsManager(generalSecret, "OPEN_AI_KEY"),
				// IPStack
				IPSTACK_ACCESS_TOKEN: Secret.fromSecretsManager(
					generalSecret,
					"IPSTACK_ACCESS_TOKEN"
				),
				// Google
				GOOGLE_OAUTH_CLIENT_ID: Secret.fromSecretsManager(
					generalSecret,
					"GOOGLE_OAUTH_CLIENT_ID"
				),
				GOOGLE_OAUTH_SECRET: Secret.fromSecretsManager(
					generalSecret,
					"GOOGLE_OAUTH_SECRET"
				),
				// Github
				GITHUB_OAUTH_CLIENT_ID: Secret.fromSecretsManager(
					generalSecret,
					"GITHUB_OAUTH_CLIENT_ID"
				),
				GITHUB_OAUTH_SECRET: Secret.fromSecretsManager(
					generalSecret,
					"GITHUB_OAUTH_SECRET"
				),
			},
			command: "/app/bin/server",
			environment: {
				// Static config
				...envLookup.appConfig,
				// Dynamic config
				...appEnv,
			},
			containerPort: 8000,
			minHealthyPercent: 50,
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

		const app = new PublicFargateApp(this, appName, {
			name: appName,
			zone,
			domain: envLookup.hostedZone.domains.primary,
			cluster,
			cpuLimit: 1024,
			memoryLimit: 2048,
			certificate: certificate.certificate,
			desiredCount: 1,
			container: appContainer,
			healthCheckCmd: "/app/bin/health",
			healthCheckPath: "/health/ready",
			logRetention,
			namespace,
		});

		const scaling = app.service.service.autoScaleTaskCount({
			minCapacity: 1,
			maxCapacity: 3,
		});

		scaling.scaleOnCpuUtilization(`${env}-app-cpu-scaling`, {
			targetUtilizationPercent: 50,
			scaleInCooldown: Duration.minutes(1),
			scaleOutCooldown: Duration.minutes(1),
		});

		app.node.addDependency(migration);

		generalSecret.grantRead(app.service.taskDefinition.taskRole);

		customerMedia.bucket.grantReadWrite(app.service.taskDefinition.taskRole);

		postgres.db.connections.allowFrom(
			migration.lambda,
			Port.tcp(postgres.port),
			`Allow traffic from migration lambda to Postres RDS on port ${postgres.port}`
		);

		postgres.db.connections.allowFrom(
			app.service.service,
			Port.tcp(postgres.port),
			`Allow traffic from app to Postres RDS on port ${postgres.port}`
		);

		redis.securityGroup.connections.allowFrom(
			app.service.service,
			Port.tcp(redis.port),
			`Allow traffic from app to Redis on port ${redis.port}`
		);

		for (const domain of ses.domainIdentities) {
			domain.grant(
				app.service.taskDefinition.taskRole,
				"ses:SendEmail",
				"ses:SendRawEmail"
			);
		}

		ses.eventQueue.grantConsumeMessages(app.service.taskDefinition.taskRole);

		const _waf = new WAF(this, "main-waf", {
			name: `${appName}-waf`,
			associationArns: [
				{
					name: `${appName}-alb`,
					arn: app.service.loadBalancer.loadBalancerArn,
				},
			],
			allowedPathPrefixes: ["/webhook"],
			blockedPathPrefixes: ["/health"],
		});

		const emptyAppCDNBucketName = `${env}-empty-app-cdn-bucket`;
		const emptyAppCDNBucket = new PrivateBucket(this, emptyAppCDNBucketName, {
			name: emptyAppCDNBucketName,
			removalPolicy,
		});

		const albBehavior: BehaviorOptions = {
			origin: new LoadBalancerV2Origin(app.service.loadBalancer),
			viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
			cachePolicy: CachePolicy.USE_ORIGIN_CACHE_CONTROL_HEADERS_QUERY_STRINGS,
			originRequestPolicy: OriginRequestPolicy.ALL_VIEWER,
			responseHeadersPolicy:
				ResponseHeadersPolicy.CORS_ALLOW_ALL_ORIGINS_WITH_PREFLIGHT,
		};

		const _appCdn = new CDN(this, `${env}-app-cdn`, {
			name: `${appName}-app-cdn`,
			zone,
			cert: appCdnCert,
			domain: appCdnDomain,
			defaultBehavior: {
				origin: S3BucketOrigin.withOriginAccessControl(
					emptyAppCDNBucket.bucket
				),
				viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
			},
			additionalBehaviors: {
				"assets/*": albBehavior,
				"images/*": albBehavior,
				"fonts/*": albBehavior,
				"json/*": albBehavior,
			},
		});

		const _mediaCdn = new CDN(this, `${env}-customer-media-cdn`, {
			name: `${appName}-customer-media-cdn`,
			zone: comZone,
			cert: cdnCert,
			domain: cdnDomain,
			defaultBehavior: {
				origin: S3BucketOrigin.withOriginAccessControl(customerMedia.bucket),
				viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
			},
			additionalBehaviors: {},
		});

		const containerScanningName = `${env}-app`;
		const _containerScanning = new ContainerScanning(
			this,
			containerScanningName,
			{
				name: containerScanningName,
			}
		);
	}
}
