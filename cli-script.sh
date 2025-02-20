#!/bin/bash
source config.conf # private variables file

######################## Variables ########################
AMI_ID=$UBUNTU_AMI_ID
RANDOM_STR=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)
SG_NAME="aws6-sg-$RANDOM_STR"
ALB_NAME="aws6-alb-$RANDOM_STR"
USER_DATA_RED="user-data/ApacheServerHTML_red.sh"
USER_DATA_BLUE="user-data/ApacheServerHTML_blue.sh"
RED_NAME="red"
BLUE_NAME="blue"
INSTANCE_ID_RED_NAME="$RED_NAME-i-$RANDOM_STR"
INSTANCE_ID_BLUE_NAME="$BLUE_NAME-i-$RANDOM_STR"
TEMPORARY_VARS_FILE="temp.conf"

######################## 1. Security Group ########################
# • Allow inbound traffic on port 80 (HTTP). #
# • When creating EC2 instances, associated this Security Group with them. #

echo "1. Creating security group..."
SG_ID=$(aws ec2 create-security-group \
	--group-name "$SG_NAME" \
	--description "SG with inbound HTTP traffic" \
	--vpc-id "$VPC_ID" \
	--output text)
aws ec2 authorize-security-group-ingress \
	--group-id "$SG_ID" \
	--protocol tcp --port 80 --cidr 0.0.0.0/0
echo "SG_ID=$SG_ID" > $TEMPORARY_VARS_FILE

######################## 2. Application Load Balancer(ALB) ########################
# • Create ALB with a unique name. #
# • Use two subnets, one for each Availability Zone. #
# • Associate SG with ALB. #

echo "2. Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
	--name "$ALB_NAME" \
	--security-groups "$SG_ID" \
	--subnets "$SUBNET_ID_1" "$SUBNET_ID_2" \
	--query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "ALB_ARN=$ALB_ARN" >> $TEMPORARY_VARS_FILE

######################## 3. Target Groups ########################
# • Create 2 target groups: "/red" & "/blue" path. #
# • Configure each to use HTTP on port 80. #

echo "3. Creating 2 Target Groups..."
TG_ARN_RED=$(aws elbv2 create-target-group \
	--name "$RED_NAME" \
	--protocol HTTP --port 80 \
	--vpc-id "$VPC_ID" \
	--target-type instance \
	--query 'TargetGroups[0].TargetGroupArn' --output text)
echo "TG_ARN_RED=$TG_ARN_RED" >> $TEMPORARY_VARS_FILE

TG_ARN_BLUE=$(aws elbv2 create-target-group \
	--name "$BLUE_NAME" \
	--protocol HTTP --port 80 \
	--vpc-id "$VPC_ID" \
	--target-type instance \
	--query 'TargetGroups[0].TargetGroupArn' --output text)
echo "TG_ARN_BLUE=$TG_ARN_BLUE" >> $TEMPORARY_VARS_FILE

######################## 4. EC2 Instances ########################
# • Launch 2 EC2 instances. #
# • Associate SGs with the instances. #
# • Install & configure Apache on each instance. #
# • Create HTML file on each instance ("/var/www/html/index.html") with content indicating color associated with the instance ("/red" or "/blue"). # 

echo "4. Launching EC2 instances..."
aws ec2 run-instances \
	--image-id "$AMI_ID" --count 1 --instance-type t2.micro \
	--security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_1" \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_ID_RED_NAME}]" \
	--user-data file://"$USER_DATA_RED"
INSTANCE_ID_RED=$(aws ec2 describe-instances \
	--filters "Name=tag:Name,Values=$INSTANCE_ID_RED_NAME" \
	--query 'Reservations[*].Instances[*].InstanceId' --output text )
echo "INSTANCE_ID_RED=$INSTANCE_ID_RED" >> $TEMPORARY_VARS_FILE

aws ec2 run-instances \
	--image-id "$AMI_ID" --count 1 --instance-type t2.micro \
	--security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_2" \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_ID_BLUE_NAME}]" \
	--user-data file://"$USER_DATA_BLUE"
INSTANCE_ID_BLUE=$(aws ec2 describe-instances \
	--filters "Name=tag:Name,Values=$INSTANCE_ID_BLUE_NAME" \
	--query 'Reservations[*].Instances[*].InstanceId' --output text )
echo "INSTANCE_ID_BLUE=$INSTANCE_ID_BLUE" >> $TEMPORARY_VARS_FILE

######################## 5. Register Targets ########################
# • Register each EC2 instance with its corresponding target group. #
# • Make sure the instances are in a running state. #

echo "5. Registering EC2 instances with Target Groups..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID_RED $INSTANCE_ID_BLUE
aws elbv2 register-targets \
	--target-group-arn "$TG_ARN_RED" --targets Id="$INSTANCE_ID_RED"
aws elbv2 register-targets \
	--target-group-arn "$TG_ARN_BLUE" --targets Id="$INSTANCE_ID_BLUE"

######################## 6. Listeners ########################
# • Create listener on the ALB with rules for "/red" & "/blue" path. #
# • Associate each rule with the respective Target Group. #

<< 'COMMENT'
echo "6. Creating listener and rules..."
LISTENER_ARN=$(aws elbv2 create-listener \
	--load-balancer-arn "$ALB_ARN" \
	--protocol HTTP --port 80 \
    --default-actions Type=forward,TargetGroupArn="$TG_ARN_RED" \
	--query 'Listeners[*].ListenerArn' --output text )
echo "LISTENER_ARN=$LISTENER_ARN" >> $TEMPORARY_VARS_FILE
aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --conditions Field=path-pattern,Values="/$RED_NAME" \
    --actions Type=forward,TargetGroupArn="$TG_ARN_RED"
aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --conditions Field=path-pattern,Values="/$BLUE_NAME" \
    --actions Type=forward,TargetGroupArn="$TG_ARN_BLUE"
COMMENT

echo "Deployment complete"
