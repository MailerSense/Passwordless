import * as cdk from "aws-cdk-lib";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

import { Certificate } from "./network/certificate";
import { Environment } from "./util/environment";
import { domainLookupMap, lookupMap } from "./util/lookup";
import { Region } from "./util/region";

export class PasswordlessToolsCertificates extends cdk.Stack {
  public cdn: Record<Region, Record<Environment, Certificate>>;
  public com: Record<Region, Record<Environment, Certificate>>;

  public constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const env = process.env.DEPLOYMENT_ENV
      ? (process.env.DEPLOYMENT_ENV as Environment)
      : Environment.DEV;

    const envLookup = lookupMap[env];

    const zone = PublicHostedZone.fromHostedZoneAttributes(
      this,
      `${env}-app-zone`,
      {
        zoneName: envLookup.hostedZone.name,
        hostedZoneId: envLookup.hostedZone.id,
      },
    );

    const comZone = PublicHostedZone.fromHostedZoneAttributes(
      this,
      `${env}-app-come-zone`,
      {
        zoneName: envLookup.hostedZoneCom.name,
        hostedZoneId: envLookup.hostedZoneCom.id,
      },
    );

    this.cdn = {} as Record<Region, Record<Environment, Certificate>>;
    this.com = {} as Record<Region, Record<Environment, Certificate>>;

    for (const [region, value] of Object.entries(domainLookupMap)) {
      const reg = region as Region;
      const { cdn, com } = value[env];

      if (!this.cdn[reg]) {
        this.cdn[reg] = {} as Record<Environment, Certificate>;
      }

      if (!this.com[reg]) {
        this.com[reg] = {} as Record<Environment, Certificate>;
      }

      const cdnName = `${reg}-${env}-cdn-certificate`;
      this.cdn[reg][env] = new Certificate(this, cdnName, {
        name: cdnName,
        zone,
        domain: cdn.domain,
      });

      const comName = `${reg}-${env}-com-certificate`;
      this.com[reg][env] = new Certificate(this, comName, {
        name: comName,
        zone: comZone,
        domain: com.domain,
      });
    }
  }
}
