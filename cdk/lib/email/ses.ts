import { CfnOutput, RemovalPolicy, aws_ses as ses, Stack } from "aws-cdk-lib";
import { ICertificate } from "aws-cdk-lib/aws-certificatemanager";
import { CachePolicy, Distribution } from "aws-cdk-lib/aws-cloudfront";
import { HttpOrigin } from "aws-cdk-lib/aws-cloudfront-origins";
import {
  ARecord,
  CnameRecord,
  IHostedZone,
  MxRecord,
  RecordTarget,
  TxtRecord,
} from "aws-cdk-lib/aws-route53";
import { CloudFrontTarget } from "aws-cdk-lib/aws-route53-targets";
import { EmailSendingEvent, IConfigurationSet } from "aws-cdk-lib/aws-ses";
import { Topic } from "aws-cdk-lib/aws-sns";
import { SqsSubscription } from "aws-cdk-lib/aws-sns-subscriptions";
import { Queue } from "aws-cdk-lib/aws-sqs";
import { Construct } from "constructs";
import { parse } from "tldts";

export interface SESProps {
  name: string;
  domains: DomainIdentity[];
  tracking?: TrackingIdentity;
  removalPolicy: RemovalPolicy;
}

export interface DomainIdentity {
  zone: IHostedZone;
  domain: string;
  domainFromPrefix: string;
  ruaEmail?: string;
  rufEmail?: string;
}

export interface TrackingIdentity {
  zone: IHostedZone;
  cert: ICertificate;
  domain: string;
}

const allowedEventTypes: EmailSendingEvent[] = [
  EmailSendingEvent.SEND,
  EmailSendingEvent.REJECT,
  EmailSendingEvent.BOUNCE,
  EmailSendingEvent.COMPLAINT,
  EmailSendingEvent.DELIVERY,
  EmailSendingEvent.RENDERING_FAILURE,
  EmailSendingEvent.DELIVERY_DELAY,
  EmailSendingEvent.SUBSCRIPTION,
];

export class SES extends Construct {
  public readonly configSet: ses.ConfigurationSet;
  public readonly eventQueue: Queue;
  public readonly domainIdentities: ses.IEmailIdentity[];
  public readonly clickDistribution?: Distribution;

  public constructor(scope: Construct, id: string, props: Readonly<SESProps>) {
    super(scope, id);

    const region = Stack.of(this).region;
    const { name, removalPolicy, tracking } = props;

    if (tracking) {
      const { domain, zone, cert } = tracking;

      this.clickDistribution = new Distribution(
        this,
        `${name}-ses-click-distribution`,
        {
          defaultBehavior: {
            origin: new HttpOrigin(`r.${region}.awstrack.me`),
            cachePolicy: new CachePolicy(this, `${name}-ses-cache`, {
              cachePolicyName: `${name}-ses-cache-policy`,
              comment: "Policy to cache host header",
              headerBehavior: {
                behavior: "whitelist",
                headers: ["Host"],
              },
            }),
          },
          domainNames: [domain],
          certificate: cert,
        },
      );

      const trackingRecord = new ARecord(this, `${name}-ses-click-record`, {
        recordName: domain,
        zone,
        target: RecordTarget.fromAlias(
          new CloudFrontTarget(this.clickDistribution),
        ),
      });
    }

    // Create the configuration set (add pool once we have it)
    const configSetName = `${name}-config-set`;
    this.configSet = new ses.ConfigurationSet(this, configSetName, {
      configurationSetName: configSetName,
      reputationMetrics: true,
      tlsPolicy: ses.ConfigurationSetTlsPolicy.REQUIRE,
      sendingEnabled: true,
      suppressionReasons: ses.SuppressionReasons.BOUNCES_AND_COMPLAINTS,
      customTrackingRedirectDomain: tracking?.domain,
    });

    if (this.clickDistribution) {
      this.configSet.node.addDependency(this.clickDistribution);
    }

    // Create default domain identities
    this.domainIdentities = props.domains.map((identity) =>
      this.createDomainIdentity(identity, this.configSet),
    );

    // Create the event topic name
    const eventTopicName = `${name}-email-notifications`;
    const eventTopic = new Topic(this, eventTopicName, {
      topicName: eventTopicName,
      displayName: "SES Email Notifications",
    });

    // Bind it to the configuration set
    const eventDestinationName = `${name}-notification-destination`;
    const _eventDestination = new ses.ConfigurationSetEventDestination(
      this,
      eventDestinationName,
      {
        events: allowedEventTypes,
        destination: ses.EventDestination.snsTopic(eventTopic),
        configurationSet: this.configSet,
        configurationSetEventDestinationName: eventDestinationName,
      },
    );

    // Create the SQS queue for notifications
    const queueName = `${name}-email-notifications`;
    const notificationQueue = new Queue(this, queueName, {
      queueName,
      enforceSSL: true,
      removalPolicy,
    });

    // Subscribe the queue to the topic
    eventTopic.addSubscription(new SqsSubscription(notificationQueue));

    this.eventQueue = notificationQueue;
  }

  private createDomainIdentity(
    { zone, domain, domainFromPrefix, ruaEmail, rufEmail }: DomainIdentity,
    configurationSet: IConfigurationSet,
  ): ses.IEmailIdentity {
    const slugify = (str: string): string =>
      String(str)
        .normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "")
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9 -]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-");

    const { domain: rootDomain, subdomain } = parse(domain);

    if (rootDomain === null || subdomain === null) {
      throw new Error(`Invalid domain: ${domain}`);
    }

    const domainSlug = slugify(domain);
    const domainIdentityName = `${domainSlug}-identity`;
    const identity = new ses.EmailIdentity(this, domainIdentityName, {
      identity: ses.Identity.domain(domain),
      mailFromDomain: `${domainFromPrefix}.${domain}`,
      configurationSet,
      mailFromBehaviorOnMxFailure:
        ses.MailFromBehaviorOnMxFailure.REJECT_MESSAGE,
    });

    const dkimTokens = [
      [identity.dkimDnsTokenName1, identity.dkimDnsTokenValue1],
      [identity.dkimDnsTokenName2, identity.dkimDnsTokenValue2],
      [identity.dkimDnsTokenName3, identity.dkimDnsTokenValue3],
    ];

    dkimTokens.forEach(([tokenName, tokenValue], i) => {
      const recordName = `${tokenName}.`;
      const domainName = tokenValue;
      const _record = new CnameRecord(
        this,
        `${domainSlug}-dkim-token-${i + 1}`,
        {
          recordName,
          domainName,
          comment: `SES DKIM Record ${i + 1} for ${domain}`,
          zone,
        },
      );

      new CfnOutput(this, `${domainSlug}-dkim-token-value-${i + 1}`, {
        description: `SES DKIM CNAME Record ${i + 1}`,
        value: `${recordName} CNAME ${tokenValue}.dkim.amazonses.com`,
      });
    });

    const spfValue = "v=spf1 include:amazonses.com ~all";
    let dmarcValue = "v=DMARC1; p=none; ";

    if (ruaEmail) {
      dmarcValue += `rua=mailto:${ruaEmail}; `;
    }

    if (rufEmail) {
      dmarcValue += `ruf=mailto:${rufEmail}; `;
    }

    dmarcValue = dmarcValue.trim();

    const _txtRecord = new TxtRecord(this, `${domainSlug}-txt-recordset`, {
      recordName: `${domainFromPrefix}.${subdomain}`,
      values: [spfValue, dmarcValue],
      zone,
    });

    const _mxRecord = new MxRecord(this, `${domainSlug}-mx-recordset`, {
      recordName: `${domainFromPrefix}.${subdomain}`,
      values: [
        {
          priority: 10,
          hostName: `feedback-smtp.${Stack.of(this).region}.amazonses.com`,
        },
      ],
      zone,
    });

    return identity;
  }
}
