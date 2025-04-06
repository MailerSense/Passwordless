#!/usr/bin/env node
import { AppStagingSynthesizer } from "@aws-cdk/app-staging-synthesizer-alpha";
import * as cdk from "aws-cdk-lib";
import { BucketEncryption } from "aws-cdk-lib/aws-s3";

import { PasswordlessTools } from "../lib/passwordless-tools";
import { PasswordlessToolsCertificates } from "../lib/passwordless-tools-certificates";

const env = process.env.DEPLOYMENT_ENV;

const certificates = new PasswordlessToolsCertificates(
  new cdk.App(),
  `${env}-certificate-stack`,
  {
    env: { region: "us-east-1" },
    crossRegionReferences: true,
  },
);

const app = new cdk.App({
  defaultStackSynthesizer: AppStagingSynthesizer.defaultResources({
    appId: "passwordless-tools",
    stagingBucketEncryption: BucketEncryption.S3_MANAGED,
    imageAssetVersionCount: 10, // Keep 10 latest images
  }),
});

const _stack = new PasswordlessTools(app, `${env}-stack`, {
  certificates,
  crossRegionReferences: true,
});
