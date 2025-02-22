import {
  DockerImageAsset,
  type DockerImageAssetProps,
} from "aws-cdk-lib/aws-ecr-assets";
import type { Construct } from "constructs";

export type CachedImageProps = Exclude<
  DockerImageAssetProps,
  "cacheFrom" | "cacheTo"
> &
  Required<Pick<DockerImageAssetProps, "assetName">>;

export class CachedImage extends DockerImageAsset {
  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<CachedImageProps>,
  ) {
    super(scope, id, {
      ...props,

      // Add GitHub Actions caching in CI
      ...(isCi()
        ? {
            cacheTo: {
              type: "gha",
              params: { mode: "max", scope: props.assetName },
            },
            cacheFrom: [{ type: "gha", params: { scope: props.assetName } }],
            outputs: ["type=docker"], // equivalent to `--load`, which exports the image to the local Docker daemon
          }
        : {}),
    });
  }
}

function isCi(): boolean {
  // CI=true is set by GitHub Actions, CircleCI, etc.
  return process.env.CI !== undefined;
}
