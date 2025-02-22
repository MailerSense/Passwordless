#!/usr/bin/env node
import { AppStagingSynthesizer } from "@aws-cdk/app-staging-synthesizer-alpha";
import * as cdk from "aws-cdk-lib";
import { BucketEncryption } from "aws-cdk-lib/aws-s3";

import { LiveCheck } from "../lib/live-check";

const env = process.env.DEPLOYMENT_ENV;

const app = new cdk.App({
  defaultStackSynthesizer: AppStagingSynthesizer.defaultResources({
    appId: "live-check",
    stagingBucketEncryption: BucketEncryption.S3_MANAGED,
    imageAssetVersionCount: 10, // Keep 10 latest images
  }),
});
const _stack = new LiveCheck(app, `${env}-stack`);
