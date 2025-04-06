import * as cdk from "aws-cdk-lib";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

import { Certificate } from "./network/certificate";
import { Environment } from "./util/environment";
import { certificateConfig, lookupMap } from "./util/lookup";
import { Region } from "./util/region";

export class PasswordlessToolsCertificates extends cdk.Stack {
  public certificates: Record<Region, Record<Environment, Certificate>>;

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
        zoneName: envLookup.hostedZone.domains.primary,
        hostedZoneId: envLookup.hostedZone.hostedZoneId,
      },
    );

    this.certificates = {} as Record<Region, Record<Environment, Certificate>>;

    for (const [region, value] of Object.entries(certificateConfig)) {
      const reg = region as Region;
      const { cdn } = value[env];
      const certName = `${reg}-${env}-cdn-certificate`;

      if (!this.certificates[reg]) {
        this.certificates[reg] = {} as Record<Environment, Certificate>;
      }

      this.certificates[reg][env] = new Certificate(this, certName, {
        name: certName,
        zone,
        domain: cdn,
      });
    }
  }
}
