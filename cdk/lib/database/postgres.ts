import { Duration, RemovalPolicy } from "aws-cdk-lib";
import { InstanceType, SubnetType, Vpc } from "aws-cdk-lib/aws-ec2";
import {
	Credentials,
	DatabaseInstance,
	DatabaseInstanceEngine,
	DatabaseInstanceReadReplica,
	PostgresEngineVersion,
} from "aws-cdk-lib/aws-rds";
import { ISecret, Secret } from "aws-cdk-lib/aws-secretsmanager";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface PostgresProps {
	vpc: Vpc;
	name: string;
	instanceType: InstanceType;
	replicaType?: InstanceType;
	removalPolicy: RemovalPolicy;
	backupRetention: Duration;
	deletionProtection: boolean;
}

export class Postgres extends Construct {
	// Database instance
	public readonly db: DatabaseInstance;
	public readonly port: number;

	// Replication instance
	public readonly replica?: DatabaseInstanceReadReplica;
	public readonly replicaPort?: number;

	// Secret storing admin credentials
	public readonly secret: ISecret;
	public readonly secretName: string;

	public constructor(
		scope: Construct,
		id: string,
		props: Readonly<PostgresProps>
	) {
		super(scope, id);

		const port = 5432;
		const engine = DatabaseInstanceEngine.postgres({
			version: PostgresEngineVersion.VER_17,
		});

		const {
			vpc,
			name,
			instanceType,
			replicaType,
			removalPolicy,
			deletionProtection,
			backupRetention,
		} = props;

		this.secretName = `${name}-db-admin`;
		this.secret = new Secret(this, this.secretName, {
			secretName: this.secretName,
			description: `Credentials for database admin of ${name}`,
			generateSecretString: {
				secretStringTemplate: JSON.stringify({ username: "postgres" }),
				passwordLength: 24,
				generateStringKey: "password",
				excludePunctuation: true,
			},
			removalPolicy,
		});

		const credentials = Credentials.fromSecret(this.secret);

		this.port = port;
		this.db = new DatabaseInstance(this, name, {
			vpc,
			vpcSubnets: { subnetType: SubnetType.PRIVATE_WITH_EGRESS },
			instanceType,
			engine,
			port,
			databaseName: name,
			credentials,
			backupRetention,
			deletionProtection,
			deleteAutomatedBackups: deletionProtection,
			removalPolicy,
			storageEncrypted: true,
			publiclyAccessible: false,
			enablePerformanceInsights: true,
			monitoringInterval: Duration.seconds(10),
			allowMajorVersionUpgrade: true,
		});

		if (replicaType) {
			this.replicaPort = port;
			this.replica = new DatabaseInstanceReadReplica(this, `${name}-replica`, {
				vpc,
				vpcSubnets: { subnetType: SubnetType.PRIVATE_WITH_EGRESS },
				instanceType,
				sourceDatabaseInstance: this.db,
				storageEncrypted: true,
				deletionProtection,
				deleteAutomatedBackups: deletionProtection,
				removalPolicy,
				publiclyAccessible: false,
				enablePerformanceInsights: true,
				monitoringInterval: Duration.seconds(10),
			});
		}

		NagSuppressions.addResourceSuppressions(this, [
			{
				id: "AwsSolutions-RDS11",
				reason: "Come on, it's the default port after all",
			},
		]);
	}
}
