#!/bin/bash
# Script to Check AMI and delete unused.
# Authors: Ananda Raj
# Date: 02 Apr 2024

aws_config_file="/home/$username/.aws/config"

for profile in $(cat $aws_config_file | grep "\[profile " | awk '{print $2}' | cut -d "]" -f1)
do

echo -e "\n########## Taking profile $profile ##########\n"

# Take the account ID
acc_id=$(aws --profile $profile sts get-caller-identity | jq -r '.Account')
echo -e "Account ID: $acc_id"

# List of AMI without Deletion Protection enabled
aws --profile $profile ec2 describe-images --query "Images[?!(Tags[?Key=='DeletionProtection' && Value=='Yes'] || starts_with(ImageLocation, '$acc_id/AwsBackup_')) && OwnerId=='$acc_id'].ImageId" --output text | tr '\t' '\n' > AMI_List

echo "Completed taking AMI list"
cat AMI_List

for ami_id in `cat AMI_List`;
do 

echo -e "\nTaking AMI $ami_id"

### Check if the AMI is used by any EC2 instances
instance_count=0
instance_count=$(aws --profile $profile ec2 describe-instances --filters "Name=image-id,Values=$ami_id" --query "length(Reservations[].Instances[])" --output text)
if [ $instance_count -gt 0 ]; then
    echo "This AMI is currently in use for Instance."
fi

### Check if the AMI is used by any Auto Scaling groups
auto_scaling_count=0
auto_scaling_count=$(aws --profile $profile autoscaling describe-auto-scaling-groups --query "length(AutoScalingGroups[?LaunchConfigurationName == '$ami_id'])" --output text)
if [ $auto_scaling_count -gt 0 ]; then
    echo "This AMI is currently in use for AutoScaling."
fi

### Check if the AMI is used by any launch configurations
launch_config_count=0
launch_configurations=$(aws --profile $profile autoscaling describe-launch-configurations --query "LaunchConfigurations[?ImageId == '$ami_id'].{LaunchConfigurationName: LaunchConfigurationName}" --output json)
launch_config_count=$(echo "$launch_configurations" | jq length)

if [ $launch_config_count -gt 0 ]; then
    launch_configurations=$(echo "$launch_configurations" | jq -r '.[].LaunchConfigurationName')
    echo "This AMI is currently in use for the Launch Configurations: $launch_configurations"
fi

### Check if the AMI is used by any launch templates
launch_template_count=0
launch_templates=$(aws --profile $profile ec2 describe-launch-templates --query 'LaunchTemplates[*].[LaunchTemplateName, LaunchTemplateId]' --output json)
# Iterate through each launch template
for lt_info in $(echo "$launch_templates" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${lt_info}" | base64 --decode | jq -r "${1}"
    }

    lt_name=$(_jq '.[0]')
    lt_id=$(_jq '.[1]')

    # Describe first two versions of the launch template
    versions=$(aws --profile $profile ec2 describe-launch-template-versions --launch-template-id $lt_id --max-items 2 --query 'LaunchTemplateVersions[*].[LaunchTemplateId, LaunchTemplateName, LaunchTemplateData.ImageId]' --output json)

    # Check if the AMI ID is used by any version of the launch template
    if echo "$versions" | jq -r '.[][] | select(. == "'"$ami_id"'")' | grep -q .; then
        echo "This AMI is currently in use for Launch Template: $lt_name"
        launch_template_count=1
    fi
done

### Check if the AMI is used by any Elastic Beanstalk environments
elastic_beanstalk_count=0
elastic_beanstalk_count=$(aws --profile $profile elasticbeanstalk describe-environments --query "length(Environments[?PlatformArn | contains('$ami_id')])" --output text)
if [ $elastic_beanstalk_count -gt 0 ]; then
    echo "This AMI is currently in use for Elastic Beanstalk."
fi

### Check if the AMI is used by any Spot Instance requests
spot_instance_count=None
spot_instance_count=$(aws --profile $profile ec2 describe-spot-instance-requests --filters Name=launch.image-id,Values="$ami_id" --query "SpotInstanceRequests[1].Tags[*].[Value]" --output text)
if [ "$spot_instance_count" != "None" ]; then
    echo "This AMI is currently in use for Spot Instance requests $spot_instance_count."
fi


##########  Delete the AMI from here  ###  IMPORTANT  ##########
################################################################

if [ $instance_count -gt 0 ] || [ $auto_scaling_count -gt 0 ] || [ $launch_config_count -gt 0 ] || [ $launch_template_count -gt 0 ] || [ $elastic_beanstalk_count -gt 0 ] || [ "$spot_instance_count" != "None" ]; then
    echo "IN USE - This AMI $ami_id is currently in use, so not deleting."
else
    echo "NOT IN USE - This AMI $ami_id is not in use, so deleting."
    echo "Do you want to proceed with deletion? (Y/N)"
    read -r confirm_delete
    if [ "$confirm_delete" = "Y" ] || [ "$confirm_delete" = "y" ]; then
        echo "==================================="
        echo "$ami_id" # delete
        snapshots_list="$(aws ec2 --profile $profile describe-images --image-ids $ami_id --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)"
        aws --profile $profile ec2 deregister-image --image-id $ami_id
        for snapshot in $snapshots_list; do 
            echo $snapshot
            aws --profile $profile ec2 delete-snapshot --snapshot-id $snapshot
        echo "==================================="
        done
    else
        echo "Deletion canceled. Exiting..."
    fi
fi

done
done

echo "Script completed execution"
