import { RemovalPolicy } from "aws-cdk-lib";
import { ISecret, Secret } from "aws-cdk-lib/aws-secretsmanager";
import { Construct } from "constructs";

export interface UserProps {
	name: string;
	permission: Permission;
	removalPolicy: RemovalPolicy;
}

export enum Permission {
	READ = "READ",
	READ_WRITE = "READ_WRITE",
}

export class User extends Construct {
	public readonly secret: ISecret;
	public readonly secretName: string;

	public constructor(scope: Construct, id: string, props: Readonly<UserProps>) {
		super(scope, id);

		const { name: username, permission, removalPolicy } = props;

		this.secretName = `${username}-db-user`;
		this.secret = new Secret(this, this.secretName, {
			secretName: this.secretName,
			description: `Credentials for database user ${username}`,
			generateSecretString: {
				secretStringTemplate: JSON.stringify({ username, permission }),
				passwordLength: 24,
				generateStringKey: "password",
				excludePunctuation: true,
			},
			removalPolicy,
		});
	}
}
