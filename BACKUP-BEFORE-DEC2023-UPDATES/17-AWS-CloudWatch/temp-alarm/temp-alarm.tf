provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_metric_alarm" "temp" {
  
}

/* Create my terraform import command
terraform import aws_cloudwatch_metric_alarm.temp temp-alarm
terraform import aws_cloudwatch_metric_alarm.temp Synthetics-Alarm-my-manual-canary2-1
*/