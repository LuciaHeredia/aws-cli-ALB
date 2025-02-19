#!/bin/bash
source config.conf # private variables file

######################## Variables ########################
AMI_ID=$UBUNTU_AMI_ID
RANDOM_STR=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)
SG_NAME="aws6-sg-$RANDOM_STR"
ALB_NAME="aws6-alb-$RANDOM_STR"
USER_DATA_RED="ApacheServerHTML_red.sh"
USER_DATA_BLUE="ApacheServerHTML_blue.sh"
TG_NAME_RED="/red"
TG_NAME_BLUE="/blue"

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

######################## 3. Target Groups ########################
# • Create 2 target groups: "/red" & "/blue" path. #
# • Configure each to use HTTP on port 80. #

echo "3. Creating 2 Target Groups..."
TG_ARN_RED=$(aws elbv2 create-target-group \
	--name "$TG_NAME_RED" \
	--protocol HTTP --port 80 \
	--vpc-id "$VPC_ID" \
	--target-type ip \
	--query 'TargetGroups[0].TargetGroupArn' --output text)
TG_ARN_BLUE=$(aws elbv2 create-target-group \
	--name "$TG_NAME_BLUE" \
	--protocol HTTP --port 80 \
	--vpc-id "$VPC_ID" \
	--target-type ip \
	--query 'TargetGroups[1].TargetGroupArn' --output text)

######################## 4. EC2 Instances ########################
# • Launch 2 EC2 instances. #
# • Associate SGs with the instances. #
# • Install & configure Apache on each instance. #
# • Create HTML file on each instance ("/var/www/html/index.html") with content indicating color associated with the instance ("/red" or "/blue"). # 

echo "4. Launching EC2 instances..."
INSTANCE_ID_RED=$(aws ec2 run-instances \
	--image-id "$AMI_ID" --count 1 --instance-type t2.micro \
	--security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_1" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=red}]' \
	--user-data file://"$USER_DATA_RED" )

INSTANCE_ID_BLUE=$(aws ec2 run-instances \
	--image-id "$AMI_ID" --count 1 --instance-type t2.micro \
    --security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_2" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=blue}]' \
	--user-data file://"$USER_DATA_BLUE" )

echo "waiting for instances to run.."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

######################## 5. Register Targets ########################
# • Register each EC2 instance with its corresponding target group. #

echo "5. Registering EC2 instances with Target Groups..."
aws elbv2 register-targets \
	--target-group-arn "$TG_ARN_RED" --targets Id="$INSTANCE_ID_RED"
aws elbv2 register-targets \
	--target-group-arn "$TG_ARN_BLUE" --targets Id="$INSTANCE_ID_BLUE"

######################## 6. Listeners ########################
# • Create listeners on the ALB, for "/red" & "/blue" path. #
# • Associate each listener with the respective Target Group. #

: << 'COMMENT'
echo "Creating listeners..."
aws elbv2 create-listener \
	--load-balancer-arn "$ALB_ARN" \
	--protocol HTTP --port 80 \
	--default-actions '[{"Type": "forward", "Order": 1, "ForwardConfig": {"TargetGroups": [ {"TargetGroupArn": "\'${TG_ARN_RED}\'", "Weight": 50}, {"TargetGroupArn": "\'${TG_ARN_BLUE}\'", "Weight": 50} ] } }]' \
  --query 'Listeners[].ListenerArn' \
  --output text)

COMMENT

echo "Deployment complete"
