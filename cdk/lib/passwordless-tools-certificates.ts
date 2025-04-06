import * as cdk from "aws-cdk-lib";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

import { Certificate } from "./network/certificate";
import { Environment } from "./util/environment";
import { lookupMap } from "./util/lookup";

export class PasswordlessToolsCertificates extends cdk.Stack {
  public constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const env = process.env.DEPLOYMENT_ENV
      ? (process.env.DEPLOYMENT_ENV as Environment)
      : Environment.DEV;

    const envLookup = lookupMap[env];

    const appName = "passwordless-tools";

    const zone = PublicHostedZone.fromHostedZoneAttributes(
      this,
      `${env}-app-zone`,
      {
        zoneName: envLookup.hostedZone.domains.primary,
        hostedZoneId: envLookup.hostedZone.hostedZoneId,
      },
    );

    if (envLookup.hostedZone.domains.cdn) {
      const cdnCertificate = new Certificate(this, `${env}-cdn-certificate`, {
        name: `${appName}-certificate`,
        zone,
        domain: envLookup.hostedZone.domains.cdn,
      });
    }
  }
}
