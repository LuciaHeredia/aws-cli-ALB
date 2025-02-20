#!/bin/bash
source temp.conf # variables file

######################## Terminate EC2 Instances ########################
echo "Terminating EC2 Instances..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID_RED $INSTANCE_ID_BLUE
echo "Waiting..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID_RED $INSTANCE_ID_BLUE
######################## Delete Application Load Balancer ########################
echo "Deleting Application Load Balancer..."
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
######################## Delete Target Groups ########################
echo "Deleting Target Groups..."
aws elbv2 delete-target-group --target-group-arn $TG_ARN_RED
aws elbv2 delete-target-group --target-group-arn $TG_ARN_BLUE
######################## Delete Security Group ########################
echo "Deleting Security Group..."
echo "Waiting 60 seconds..." #TODO: check this
sleep 60 #TODO: check this
aws ec2 delete-security-group --group-id $SG_ID
######################## Clear Temporary Variables File ########################
echo "Clearing Temporary Variables File..."
> temp.conf