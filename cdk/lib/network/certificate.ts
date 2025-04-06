import * as acm from "aws-cdk-lib/aws-certificatemanager";
import { IHostedZone } from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

export interface CertificateProps {
  name: string;
  zone: IHostedZone;
  domain: string;
}

export class Certificate extends Construct {
  public readonly domain: string;
  public readonly certificate: acm.Certificate;

  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<CertificateProps>,
  ) {
    super(scope, id);

    const { name, zone, domain } = props;

    this.domain = domain;
    this.certificate = new acm.Certificate(this, `${name}-domain-certificate`, {
      domainName: domain,
      subjectAlternativeNames: [`*.${domain}`],
      validation: acm.CertificateValidation.fromDns(zone),
    });
  }
}
