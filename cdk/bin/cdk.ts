#!/usr/bin/env node
import { AppStagingSynthesizer } from "@aws-cdk/app-staging-synthesizer-alpha";
import * as cdk from "aws-cdk-lib";
import { BucketEncryption } from "aws-cdk-lib/aws-s3";

import { PasswordlessTools } from "../lib/passwordless-tools";
import { PasswordlessToolsCertificates } from "../lib/passwordless-tools-certificates";
import { Region } from "../lib/util/region";

const env = process.env.DEPLOYMENT_ENV;
const app = new cdk.App({
  defaultStackSynthesizer: AppStagingSynthesizer.defaultResources({
    appId: "passwordless-tools",
    stagingBucketEncryption: BucketEncryption.S3_MANAGED,
    imageAssetVersionCount: 10,
  }),
});

const certificates = new PasswordlessToolsCertificates(
  app,
  `${env}-certificate-stack`,
  {
    env: { region: "us-east-1" },
    crossRegionReferences: true,
  },
);

const _stack = new PasswordlessTools(app, `${env}-stack`, {
  env: { region: "eu-west-1" },
  region: Region.EU,
  certificates: undefined,
  crossRegionReferences: true,
});
