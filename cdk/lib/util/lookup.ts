import { Environment } from "./environment";
import { Region } from "./region";

export interface HostedZoneConfig {
	id: string;
	name: string;
	domains: {
		primary: string;
		www?: string;
		cdn?: string;
		email?: string;
	};
}

export interface BaseEnvConfig {
	cidr: string;
	appConfig: Record<string, string>;
	generalSecretArn: string;
	hostedZone: HostedZoneConfig;
	hostedZoneCom: HostedZoneConfig;
}

export type EnvConfigMap = {
	[E in Environment]: BaseEnvConfig;
};

export const lookupMap: EnvConfigMap = {
	[Environment.DEV]: {
		cidr: "10.0.0.0/16",
		appConfig: {
			PORT: "8000",
			PHX_HOST: "eu.dev.passwordless.tools",
			POOL_SIZE: "10",
		},
		generalSecretArn: "",
		hostedZone: {
			id: "",
			name: "",
			domains: {
				primary: "dev.passwordless.tools",
				cdn: "cdn.dev.passwordless.tools",
				www: "www.dev.passwordless.tools",
			},
		},
		hostedZoneCom: {
			id: "",
			name: "",
			domains: {
				primary: "dev.eu.passwordlesstools.com",
				email: "dev.eu.passwordlesstools.com",
			},
		},
	},
	[Environment.PROD]: {
		cidr: "10.1.0.0/16",
		appConfig: {
			PORT: "8000",
			PHX_HOST: "eu.passwordless.tools",
			POOL_SIZE: "20",
		},
		generalSecretArn:
			"arn:aws:secretsmanager:eu-west-1:728247919352:secret:general-application-config-uL5n4J",
		hostedZone: {
			id: "Z0737569361XQK32FNWPX",
			name: "passwordless.tools",
			domains: {
				primary: "eu.passwordless.tools",
				cdn: "cdn.eu.passwordless.tools",
				www: "www.eu.passwordless.tools",
			},
		},
		hostedZoneCom: {
			id: "Z06750861RW0K8GN2HE9G",
			name: "passwordlesstools.com",
			domains: {
				primary: "eu.passwordlesstools.com",
				email: "eu.passwordlesstools.com",
			},
		},
	},
};

export enum ZoneType {
	TOOLS = "tools",
	COM = "com",
}

export interface DomainAttributes {
	zone: ZoneType;
	domain: string;
}

export type DomainConfig = {
	[R in Region]: {
		[E in Environment]: {
			main: DomainAttributes;
			www: DomainAttributes;
			cdn: DomainAttributes;
			appCdn: DomainAttributes;
			com: DomainAttributes;
			email: DomainAttributes;
			tracking: DomainAttributes;
		};
	};
};

export const rootDomainLookupMap = {
	[Environment.DEV]: {
		com: {
			domain: "dev.passwordlesstools.com",
			zone: ZoneType.COM,
		},
		main: {
			domain: "dev.passwordless.tools",
			zone: ZoneType.TOOLS,
		},
		cdn: {
			domain: "cdn.dev.passwordlesstools.com",
			zone: ZoneType.COM,
		},
		www: {
			domain: "www.dev.passwordless.tools",
			zone: ZoneType.TOOLS,
		},
		docs: {
			domain: "docs.dev.passwordless.tools",
			zone: ZoneType.TOOLS,
		},
	},
	[Environment.PROD]: {
		com: {
			domain: "passwordlesstools.com",
			zone: ZoneType.COM,
		},
		main: {
			domain: "passwordless.tools",
			zone: ZoneType.TOOLS,
		},
		cdn: {
			domain: "cdn.passwordlesstools.com",
			zone: ZoneType.COM,
		},
		www: {
			domain: "www.passwordless.tools",
			zone: ZoneType.TOOLS,
		},
		docs: {
			domain: "docs.passwordless.tools",
			zone: ZoneType.TOOLS,
		},
	},
};

export const domainLookupMap: DomainConfig = {
	[Region.EU]: {
		[Environment.DEV]: {
			main: {
				zone: ZoneType.TOOLS,
				domain: "eu.dev.passwordless.tools",
			},
			www: {
				zone: ZoneType.TOOLS,
				domain: "www.eu.dev.passwordless.tools",
			},
			cdn: {
				zone: ZoneType.COM,
				domain: "cdn.eu.dev.passwordlesstools.com",
			},
			appCdn: {
				zone: ZoneType.TOOLS,
				domain: "cdn.eu.dev.passwordless.tools",
			},
			com: {
				zone: ZoneType.COM,
				domain: "dev.eu.passwordlesstools.com",
			},
			email: {
				zone: ZoneType.COM,
				domain: "auth.eu.dev.passwordlesstools.com",
			},
			tracking: {
				zone: ZoneType.COM,
				domain: "click.eu.dev.passwordlesstools.com",
			},
		},
		[Environment.PROD]: {
			main: {
				zone: ZoneType.TOOLS,
				domain: "eu.passwordless.tools",
			},
			www: {
				zone: ZoneType.TOOLS,
				domain: "www.eu.passwordless.tools",
			},
			cdn: {
				zone: ZoneType.COM,
				domain: "cdn.eu.passwordlesstools.com",
			},
			appCdn: {
				zone: ZoneType.TOOLS,
				domain: "cdn.eu.passwordless.tools",
			},
			com: {
				zone: ZoneType.COM,
				domain: "eu.passwordlesstools.com",
			},
			email: {
				zone: ZoneType.COM,
				domain: "auth.eu.passwordlesstools.com",
			},
			tracking: {
				zone: ZoneType.COM,
				domain: "click.eu.passwordlesstools.com",
			},
		},
	},
	[Region.US]: {
		[Environment.DEV]: {
			main: {
				zone: ZoneType.TOOLS,
				domain: "us.dev.passwordless.tools",
			},
			www: {
				zone: ZoneType.TOOLS,
				domain: "www.us.dev.passwordless.tools",
			},
			cdn: {
				zone: ZoneType.COM,
				domain: "cdn.us.dev.passwordlesstools.com",
			},
			appCdn: {
				zone: ZoneType.TOOLS,
				domain: "cdn.us.dev.passwordless.tools",
			},
			com: {
				zone: ZoneType.COM,
				domain: "us.dev.passwordlesstools.com",
			},
			email: {
				zone: ZoneType.COM,
				domain: "auth.us.dev.passwordlesstools.com",
			},
			tracking: {
				zone: ZoneType.COM,
				domain: "click.us.dev.passwordlesstools.com",
			},
		},
		[Environment.PROD]: {
			main: {
				zone: ZoneType.TOOLS,
				domain: "us.passwordless.tools",
			},
			www: {
				zone: ZoneType.TOOLS,
				domain: "www.us.passwordless.tools",
			},
			cdn: {
				zone: ZoneType.COM,
				domain: "cdn.us.passwordlesstools.com",
			},
			appCdn: {
				zone: ZoneType.TOOLS,
				domain: "cdn.us.passwordless.tools",
			},
			com: {
				zone: ZoneType.COM,
				domain: "us.passwordlesstools.com",
			},
			email: {
				zone: ZoneType.COM,
				domain: "auth.us.passwordlesstools.com",
			},
			tracking: {
				zone: ZoneType.COM,
				domain: "click.us.passwordlesstools.com",
			},
		},
	},
};
