import { CfnWebACL, CfnWebACLAssociation } from "aws-cdk-lib/aws-wafv2";
import { Construct } from "constructs";

export interface WAFProps {
  name: string;
  associationArns: {
    name: string;
    arn: string;
  }[];
  allowedPathPrefixes: string[];
  blockedPathPrefixes: string[];
}

export class WAF extends Construct {
  public readonly waf: CfnWebACL;

  public constructor(scope: Construct, id: string, props: Readonly<WAFProps>) {
    super(scope, id);

    const { name, associationArns, allowedPathPrefixes, blockedPathPrefixes } =
      props;

    const inc = (v: number) => {
      let e = v;
      return () => e++;
    };

    const nextPriority = inc(0);

    const slugify = (str: string): string =>
      String(str)
        .normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "")
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9 -]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-");

    const allowedPathRules = allowedPathPrefixes.map((prefix) => ({
      name: `${name}-waf-allow-path-prefix-${slugify(prefix)}`,
      priority: nextPriority(),
      statement: {
        byteMatchStatement: {
          fieldToMatch: {
            uriPath: {},
          },
          positionalConstraint: "STARTS_WITH",
          searchString: prefix,
          textTransformations: [{ priority: 0, type: "LOWERCASE" }],
        },
      },
      action: {
        allow: {},
      },
      visibilityConfig: {
        cloudWatchMetricsEnabled: true,
        metricName: `${name}-waf-allow-path-prefix-${slugify(prefix)}-metric`,
        sampledRequestsEnabled: true,
      },
    })) as CfnWebACL.RuleProperty[];

    const blockedPathRules = blockedPathPrefixes.map((prefix) => ({
      name: `${name}-waf-block-path-prefix-${slugify(prefix)}`,
      priority: nextPriority(),
      statement: {
        byteMatchStatement: {
          fieldToMatch: {
            uriPath: {},
          },
          positionalConstraint: "STARTS_WITH",
          searchString: prefix,
          textTransformations: [{ priority: 0, type: "LOWERCASE" }],
        },
      },
      action: {
        block: {},
      },
      visibilityConfig: {
        cloudWatchMetricsEnabled: true,
        metricName: `${name}-waf-block-path-prefix-${slugify(prefix)}-metric`,
        sampledRequestsEnabled: true,
      },
    })) as CfnWebACL.RuleProperty[];

    this.waf = new CfnWebACL(this, `${name}-waf`, {
      defaultAction: {
        allow: {},
      },
      name: `${name}-waf`,
      scope: "REGIONAL",
      description: `Web Application Firewall for ${name}`,
      visibilityConfig: {
        cloudWatchMetricsEnabled: true,
        metricName: `${name}-waf-metric`,
        sampledRequestsEnabled: true,
      },
      rules: [
        ...allowedPathRules,
        ...blockedPathRules,
        {
          name: `${name}-waf-crs-rule`,
          priority: nextPriority(),
          statement: {
            managedRuleGroupStatement: {
              name: "AWSManagedRulesCommonRuleSet",
              vendorName: "AWS",
              excludedRules: [
                {
                  name: "SizeRestrictions_BODY",
                },
              ],
            },
          },
          visibilityConfig: {
            cloudWatchMetricsEnabled: true,
            metricName: `${name}-waf-crs-metric`,
            sampledRequestsEnabled: true,
          },
          overrideAction: {
            none: {},
          },
        },
        {
          name: `${name}-waf-bad-inputs-rule`,
          priority: nextPriority(),
          statement: {
            managedRuleGroupStatement: {
              name: "AWSManagedRulesKnownBadInputsRuleSet",
              vendorName: "AWS",
            },
          },
          visibilityConfig: {
            cloudWatchMetricsEnabled: true,
            metricName: `${name}-waf-bad-inputs-metric`,
            sampledRequestsEnabled: true,
          },
          overrideAction: {
            none: {},
          },
        },
      ],
    });

    for (const { name: assocName, arn } of associationArns) {
      const assoc = new CfnWebACLAssociation(
        this,
        `${name}-waf-${assocName}-protected-entity`,
        {
          resourceArn: arn,
          webAclArn: this.waf.attrArn,
        },
      );

      assoc.addDependency(this.waf);
    }
  }
}
