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
      com: DomainAttributes;
    };
  };
};

export const domainLookup: DomainConfig = {
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
        zone: ZoneType.TOOLS,
        domain: "cdn.eu.dev.passwordless.tools",
      },
      com: {
        zone: ZoneType.COM,
        domain: "dev.eu.passwordlesstools.com",
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
        zone: ZoneType.TOOLS,
        domain: "cdn.eu.passwordless.tools",
      },
      com: {
        zone: ZoneType.COM,
        domain: "eu.passwordlesstools.com",
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
        zone: ZoneType.TOOLS,
        domain: "cdn.us.dev.passwordless.tools",
      },
      com: {
        zone: ZoneType.COM,
        domain: "us.dev.passwordlesstools.com",
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
        zone: ZoneType.TOOLS,
        domain: "cdn.us.passwordless.tools",
      },
      com: {
        zone: ZoneType.COM,
        domain: "us.passwordlesstools.com",
      },
    },
  },
};
