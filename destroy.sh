#!/bin/bash
source temp.conf # variables file

######################## Terminate EC2 Instances ########################
echo "Terminating EC2 Instances..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID_RED $INSTANCE_ID_BLUE
echo "--> Waiting to finish..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID_RED $INSTANCE_ID_BLUE
######################## Delete Listener ########################
echo "Deleting Listener..."
aws elbv2 delete-listener --listener-arn $LISTENER_ARN
######################## Delete Application Load Balancer ########################
echo "Deleting Application Load Balancer..."
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
######################## Delete Target Groups ########################
echo "Deleting Target Groups..."
aws elbv2 delete-target-group --target-group-arn $TG_ARN_RED
aws elbv2 delete-target-group --target-group-arn $TG_ARN_BLUE
######################## Delete Security Group ########################
echo "Deleting Security Group..."
echo "--> Waiting 60 seconds..." 
sleep 60 
aws ec2 delete-security-group --group-id $SG_ID
######################## Clear Temporary Variables File ########################
echo "Clearing Temporary Variables File..."
> temp.conf