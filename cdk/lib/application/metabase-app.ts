import { Duration } from "aws-cdk-lib";
import { Certificate } from "aws-cdk-lib/aws-certificatemanager";
import { SubnetType } from "aws-cdk-lib/aws-ec2";
import { Cluster, ContainerImage, Secret } from "aws-cdk-lib/aws-ecs";
import { ApplicationLoadBalancedFargateService } from "aws-cdk-lib/aws-ecs-patterns";
import { ApplicationProtocol } from "aws-cdk-lib/aws-elasticloadbalancingv2";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

export interface MetabaseAppProps {
	name: string;
	zone: IHostedZone;
	domain: string;
	cluster: Cluster;
	cpuLimit: number;
	certificate: Certificate;
	memoryLimit: number;
	container: AppContainer;
	healthCheckPath: string;
}

export interface AppContainer {
	image: ContainerImage;
	secrets: Record<string, Secret>;
	environment: Record<string, string>;
	containerPort: number;
}

export class MetabaseApp extends Construct {
	public readonly service: ApplicationLoadBalancedFargateService;

	public constructor(
		scope: Construct,
		id: string,
		props: Readonly<MetabaseAppProps>
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
			container,
			healthCheckPath,
		} = props;

		this.service = new ApplicationLoadBalancedFargateService(this, name, {
			cluster,
			taskImageOptions: {
				image: container.image,
				secrets: container.secrets,
				environment: container.environment,
				containerPort: container.containerPort,
			},
			taskSubnets: {
				subnetType: SubnetType.PRIVATE_WITH_EGRESS,
			},
			cpu: cpuLimit,
			protocol: ApplicationProtocol.HTTPS,
			memoryLimitMiB: memoryLimit,
			loadBalancerName: `${name}-lb`,
			publicLoadBalancer: true,
			redirectHTTP: true,
			certificate,
			domainName: domain,
			domainZone: zone,
		});

		// Drop invalid headers rather than route to target
		this.service.loadBalancer.setAttribute(
			"routing.http.drop_invalid_header_fields.enabled",
			"true"
		);

		this.service.targetGroup.configureHealthCheck({
			path: healthCheckPath,
			interval: Duration.seconds(5),
			timeout: Duration.seconds(3),
		});
	}
}
