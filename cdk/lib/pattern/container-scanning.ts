import { Duration } from "aws-cdk-lib";
import { PolicyStatement } from "aws-cdk-lib/aws-iam";
import {
	AwsCustomResource,
	AwsCustomResourcePolicy,
	PhysicalResourceId,
} from "aws-cdk-lib/custom-resources";
import { Construct } from "constructs";

export interface ContainerScanningProps {
	name: string;
}

export class ContainerScanning extends Construct {
	public constructor(
		scope: Construct,
		id: string,
		props: ContainerScanningProps
	) {
		super(scope, id);

		const { name } = props;

		const onCreateParam = {
			scanType: "ENHANCED",
			rules: [
				{
					repositoryFilters: [
						{
							filter: "*",
							filterType: "WILDCARD",
						},
					],
					scanFrequency: "SCAN_ON_PUSH",
				},
			],
		};

		const onDeleteParam = {
			scanType: "BASIC",
			rules: [
				{
					repositoryFilters: [
						{
							filter: "*",
							filterType: "WILDCARD",
						},
					],
					scanFrequency: "SCAN_ON_PUSH",
				},
			],
		};

		const enableScanningName = `enable-ecr-scan-${name}`;
		const enableScanning = new AwsCustomResource(this, enableScanningName, {
			onCreate: {
				service: "ECR",
				action: "putRegistryScanningConfiguration",
				parameters: onCreateParam,
				physicalResourceId: PhysicalResourceId.of(enableScanningName),
			},
			onDelete: {
				service: "ECR",
				action: "putRegistryScanningConfiguration",
				parameters: onDeleteParam,
				physicalResourceId: PhysicalResourceId.of(enableScanningName),
			},
			timeout: Duration.minutes(5),
			policy: AwsCustomResourcePolicy.fromSdkCalls({
				resources: AwsCustomResourcePolicy.ANY_RESOURCE,
			}),
		});

		enableScanning.grantPrincipal.addToPrincipalPolicy(
			new PolicyStatement({
				actions: [
					"inspector2:ListAccountPermissions",
					"inspector2:Enable",
					"iam:CreateServiceLinkedRole",
				],
				resources: ["*"],
			})
		);
	}
}
