import * as cdk from "aws-cdk-lib";
import { PublicHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

import { Certificate } from "./network/certificate";
import { Redirect } from "./network/redirect";
import { Environment } from "./util/environment";
import { domainLookupMap, lookupMap, rootDomainLookupMap } from "./util/lookup";
import { Region } from "./util/region";

export class PasswordlessToolsCertificates extends cdk.Stack {
  public cdn: Record<Region, Record<Environment, Certificate>>;
  public com: Record<Region, Record<Environment, Certificate>>;
  public tracking: Record<Region, Record<Environment, Certificate>>;
  public mainCert: Certificate;
  public wwwCert: Certificate;
  public comCert: Certificate;

  public constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const env = process.env.DEPLOYMENT_ENV
      ? (process.env.DEPLOYMENT_ENV as Environment)
      : Environment.DEV;

    const removalPolicy =
      env == Environment.PROD
        ? cdk.RemovalPolicy.DESTROY
        : cdk.RemovalPolicy.DESTROY;

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
    this.tracking = {} as Record<Region, Record<Environment, Certificate>>;

    for (const [region, value] of Object.entries(domainLookupMap)) {
      const reg = region as Region;
      const { cdn, com, tracking } = value[env];

      if (!this.cdn[reg]) {
        this.cdn[reg] = {} as Record<Environment, Certificate>;
      }

      if (!this.com[reg]) {
        this.com[reg] = {} as Record<Environment, Certificate>;
      }

      if (!this.tracking[reg]) {
        this.tracking[reg] = {} as Record<Environment, Certificate>;
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

      const trackingName = `${reg}-${env}-tracking-certificate`;
      this.tracking[reg][env] = new Certificate(this, trackingName, {
        name: trackingName,
        zone: comZone,
        domain: tracking.domain,
      });
    }

    const rootDomains = rootDomainLookupMap[env];

    const mainName = `${env}-main-certificate`;
    this.mainCert = new Certificate(this, mainName, {
      name: mainName,
      zone,
      domain: rootDomains.main.domain,
    });

    const wwwName = `${env}-www-certificate`;
    this.wwwCert = new Certificate(this, wwwName, {
      name: wwwName,
      zone,
      domain: rootDomains.www.domain,
    });

    const comName = `${env}-com-certificate`;
    this.comCert = new Certificate(this, comName, {
      name: comName,
      zone: comZone,
      domain: rootDomains.com.domain,
    });

    const comToMain = "com-to-main";
    const _comRedirect = new Redirect(this, comToMain, {
      name: comToMain,
      zone: comZone,
      cert: this.comCert.certificate,
      toDomain: rootDomains.main.domain,
      fromDomains: [rootDomains.com.domain],
      removalPolicy,
    });

    const wwwToMain = "www-to-main";
    const _wwwRedirect = new Redirect(this, wwwToMain, {
      name: wwwToMain,
      zone,
      cert: this.mainCert.certificate,
      toDomain: rootDomains.main.domain,
      fromDomains: [rootDomains.www.domain],
      removalPolicy,
    });
  }
}
