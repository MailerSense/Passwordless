import { aws_backup as bk, Duration, aws_events as events } from "aws-cdk-lib";
import { Construct } from "constructs";

export interface BackupProps {
  resources: bk.BackupResource[];
  backupPlanName: string;
  backupRateHour: number;
  backupCompletionWindow: Duration;
  deleteBackupAfter: Duration;
}

export class Backup extends Construct {
  public readonly backupPlan: bk.BackupPlan;

  public constructor(scope: Construct, id: string, props: BackupProps) {
    super(scope, id);

    const hourlyRate = `0/${props.backupRateHour}`;
    const completionWindow = props.backupCompletionWindow;
    const startWindow = Duration.hours(completionWindow.toHours() - 1);

    if (completionWindow.toHours() - startWindow.toHours() < 1) {
      throw Error(
        "Backup completion window must be at least 60 minutes greater than backup start window",
      );
    }

    const scheduledBkRule = new bk.BackupPlanRule({
      completionWindow,
      startWindow,
      deleteAfter: props.deleteBackupAfter || Duration.days(30),
      scheduleExpression: events.Schedule.cron({
        minute: "0",
        hour: hourlyRate,
      }),
    });

    this.backupPlan = new bk.BackupPlan(this, props.backupPlanName, {
      backupPlanName: props.backupPlanName,
      backupPlanRules: [scheduledBkRule],
    });

    this.backupPlan.addSelection(`${props.backupPlanName}-selection`, {
      resources: props.resources,
    });
  }
}
