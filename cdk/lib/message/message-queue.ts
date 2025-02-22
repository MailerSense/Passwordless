import { RemovalPolicy } from "aws-cdk-lib";
import { Queue } from "aws-cdk-lib/aws-sqs";
import { Construct } from "constructs";

export interface MessageQueueProps {
  name: string;
  designation: string;
  removalPolicy: RemovalPolicy;
}

export class MessageQueue extends Construct {
  public readonly queue: Queue;

  public constructor(
    scope: Construct,
    id: string,
    props: Readonly<MessageQueueProps>,
  ) {
    super(scope, id);

    const { name, designation, removalPolicy } = props;

    const queueName = `${name}-${designation}-queue`;
    this.queue = new Queue(this, queueName, {
      queueName,
      enforceSSL: true,
      removalPolicy,
    });
  }
}
