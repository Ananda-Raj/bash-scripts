#!/bin/bash

# Script to create cpu and statuscheck alarm for given instance
# Author: Ananda Raj
# Date: 30 Oct 2020

#Read parameters. Enter instance name (Cloud-test-Instance) and AWS profile name.
echo "Enter the Instance Name : ";
read iname;
echo "Enter the Profile Name : ";
read iprofile;

#Return available SNS topics
echo "SNS topics available for $iprofile :";
aws sns --profile $iprofile list-subscriptions | grep TopicArn | awk '{print $2}' | cut -d '"' -f2;

#Return EC2 instance ID for curresponding name. Multiple ID indicates possible autoscaling.
echo "Instance ID of instances named $iname : ";
aws ec2 --profile $iprofile describe-instances --filters Name=tag:Name,Values="$iname" --output table | grep InstanceId | awk '{print $4}';

#Read parameters for configuring alarm
echo "Enter the Alarm Name : ";
read alarmname;
echo "Confirm the Instance ID : ";
read iid;
echo "Confirm the SNS Name : ";
read sns;
region=$(cut -d ":" -f4 <<< $sns);

#Enable CPU utilization alarm
aws cloudwatch --profile $iprofile put-metric-alarm --alarm-name $alarmname"-cpu" --alarm-description "$alarmname-cpu" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 90 --comparison-operator GreaterThanOrEqualToThreshold --dimensions  Name=InstanceId,Value=$iid --evaluation-periods 1 --alarm-actions "$sns" && echo "CPUUtilization Alarm created SUCCESSFULLY" || echo "CPUUtilization Alarm creation FAILED";

#Enable Status check alarm
aws cloudwatch --profile $iprofile put-metric-alarm --alarm-name $alarmname"-statuscheck" --alarm-description "$alarmname-statuscheck" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Average --period 300 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --dimensions  Name=InstanceId,Value=$iid --evaluation-periods 1 --alarm-actions "arn:aws:automate:$region:ec2:reboot" "$sns" && echo "StatusCheckFailed Alarm created SUCCESSFULLY" || echo "StatusCheckFailed Alarm creation FAILED";
