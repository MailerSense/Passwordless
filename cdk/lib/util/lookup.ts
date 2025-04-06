import { Environment } from "./environment";

export interface HostedZoneConfig {
  hostedZoneId: string;
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
      hostedZoneId: "",
      domains: {
        primary: "dev.passwordless.tools",
        cdn: "cdn.dev.passwordless.tools",
        www: "www.dev.passwordless.tools",
      },
    },
    hostedZoneCom: {
      hostedZoneId: "",
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
      POOL_SIZE: "10",
    },
    generalSecretArn:
      "arn:aws:secretsmanager:eu-west-1:728247919352:secret:general-application-config-uL5n4J",
    hostedZone: {
      hostedZoneId: "Z0737569361XQK32FNWPX",
      domains: {
        primary: "eu.passwordless.tools",
        cdn: "cdn.eu.passwordless.tools",
        www: "www.eu.passwordless.tools",
      },
    },
    hostedZoneCom: {
      hostedZoneId: "Z06750861RW0K8GN2HE9G",
      domains: {
        primary: "eu.passwordlesstools.com",
        email: "eu.passwordlesstools.com",
      },
    },
  },
};
