import { RemovalPolicy } from "aws-cdk-lib";
import { InstanceType, SecurityGroup, Vpc } from "aws-cdk-lib/aws-ec2";
import * as redis from "aws-cdk-lib/aws-elasticache";
import { ISecret, Secret } from "aws-cdk-lib/aws-secretsmanager";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export interface RedisProps {
	vpc: Vpc;
	name: string;
	machine: InstanceType;
	removalPolicy: RemovalPolicy;
}

export class Redis extends Construct {
	public readonly port: number;
	public readonly secret: ISecret;
	public readonly cluster: redis.CfnReplicationGroup;
	public readonly subnetGroup: redis.CfnSubnetGroup;
	public readonly securityGroup: SecurityGroup;

	public constructor(
		scope: Construct,
		id: string,
		props: Readonly<RedisProps>
	) {
		super(scope, id);

		const { vpc, name, machine, removalPolicy } = props;
		const port = 6379;

		const cacheSubnetGroupName = `${name}-redis-subnet-group`;
		this.subnetGroup = new redis.CfnSubnetGroup(this, cacheSubnetGroupName, {
			cacheSubnetGroupName,
			subnetIds: vpc.privateSubnets.map((subnet) => subnet.subnetId),
			description: `Subnet group for the ${name} redis cluster`,
		});

		const securityGroupName = `${name}-redis-security-group`;
		this.securityGroup = new SecurityGroup(this, securityGroupName, {
			vpc,
			securityGroupName,
		});

		const secretName = `${name}-redis-auth-token`;
		this.secret = new Secret(this, secretName, {
			secretName,
			description: `AUTH token for ${name} Redis Cluster`,
			generateSecretString: {
				passwordLength: 24,
				generateStringKey: "auth_token",
				excludePunctuation: true,
				secretStringTemplate: JSON.stringify({}),
			},
			removalPolicy,
		});

		const authToken = this.secret
			.secretValueFromJson("auth_token")
			.unsafeUnwrap()
			.toString();

		this.port = port;
		this.cluster = new redis.CfnReplicationGroup(this, name, {
			port: port,
			engine: "valkey",
			engineVersion: "7.2",
			authToken,
			clusterMode: "disabled",
			replicationGroupDescription: `${name} Redis Cluster`,
			numCacheClusters: 1,
			cacheNodeType: `cache.${machine.toString()}`,
			cacheSubnetGroupName: this.subnetGroup.cacheSubnetGroupName,
			cacheParameterGroupName: "default.valkey7",
			securityGroupIds: [this.securityGroup.securityGroupId],
			automaticFailoverEnabled: false,
			autoMinorVersionUpgrade: true,
			atRestEncryptionEnabled: true,
			transitEncryptionEnabled: true,
		});
		this.cluster.addDependency(this.subnetGroup);
		this.cluster.node.addDependency(this.secret);

		NagSuppressions.addResourceSuppressions(this, [
			{
				id: "AwsSolutions-AEC5",
				reason: "Come on, it's the default port after all",
			},
		]);
	}
}
