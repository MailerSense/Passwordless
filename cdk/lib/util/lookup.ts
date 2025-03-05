import { Environment } from "./environment";

export type DevDomain =
  | "cdn.dev.passwordless.tools"
  | "dev.passwordless.tools"
  | "dev.passwordlesstools.com"
  | "www.dev.passwordless.tools";
export type ProdDomain =
  | "cdn.passwordless.tools"
  | "passwordless.tools"
  | "passwordlesstools.com"
  | "www.passwordless.tools";

export interface HostedZoneConfig<D extends string> {
  hostedZoneId: string;
  domains: {
    primary: D;
    www?: D;
    cdn?: D;
    email?: D;
  };
}

export interface BaseEnvConfig<D extends string> {
  cidr: string;
  appConfig: Record<string, string>;
  metabaseDomain: string;
  metabaseVersion: string;
  generalSecretArn: string;
  hostedZoneIo: HostedZoneConfig<D>;
  hostedZoneCom: HostedZoneConfig<D>;
}

export type EnvConfigMap = {
  [E in Environment]: BaseEnvConfig<
    E extends Environment.DEV ? DevDomain : ProdDomain
  >;
};

export const lookupMap: EnvConfigMap = {
  [Environment.DEV]: {
    cidr: "10.0.0.0/16",
    appConfig: {
      PORT: "8000",
      PHX_HOST: "dev.passwordless.tools",
      POOL_SIZE: "10",
    },
    metabaseDomain: "metabase.dev.passwordless.tools",
    metabaseVersion: "v0.50.23",
    generalSecretArn: "",
    hostedZoneIo: {
      hostedZoneId: "",
      domains: {
        primary: "dev.passwordless.tools",
        email: "dev.passwordless.tools",
        cdn: "cdn.dev.passwordless.tools",
        www: "www.dev.passwordless.tools",
      },
    },
    hostedZoneCom: {
      hostedZoneId: "",
      domains: {
        primary: "dev.passwordlesstools.com",
        email: "dev.passwordlesstools.com",
      },
    },
  },
  [Environment.PROD]: {
    cidr: "10.1.0.0/16",
    appConfig: {
      PORT: "8000",
      PHX_HOST: "passwordless.tools",
      POOL_SIZE: "20",
    },
    metabaseDomain: "metabase.passwordless.tools",
    metabaseVersion: "v0.50.23",
    generalSecretArn:
      "arn:aws:secretsmanager:us-east-1:699475934458:secret:general-application-config-lZ3xbr",
    hostedZoneIo: {
      hostedZoneId: "Z069101327DIGA805H5Y3",
      domains: {
        primary: "passwordless.tools",
        email: "passwordless.tools",
        cdn: "cdn.passwordless.tools",
        www: "www.passwordless.tools",
      },
    },
    hostedZoneCom: {
      hostedZoneId: "Z05899811FOGMTHC2HEW3",
      domains: {
        primary: "passwordlesstools.com",
        email: "passwordlesstools.com",
      },
    },
  },
};
