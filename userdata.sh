#!/bin/bash

######################## Variables ########################
REGION="us-east-1"
AMAZON_LINUX_2_AMI_ID="ami-00f251754ac5da7f0"
AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners amazon \
	--filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
	--query 'Images | [0].ImageId' --output text)
VPC_ID="vpc-0972501efe359a4ce"
SUBNET_ID_1="subnet-031215afa3e7c2aa6"
SUBNET_ID_2="subnet-0fa6439bbb687acf1"
RANDOM_STR=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)
SG_NAME="aws6-sg-$RANDOM_STR"
ALB_NAME="aws6-alb-$RANDOM_STR"
TG_NAME_RED="red"
TG_NAME_BLUE="blue"
USER_DATA_FILE_NAME="ApacheServerAndHTML.sh"

######################## 1. Security Group ########################
# • Create a security group to be associated with the 2 EC2 instances. Allow inbound traffic on port 80 (HTTP). #

echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" \
	--description "SG for EC2 instancewith inbound HTTP traffic" \
	--region "$REGION" --vpc-id "$VPC_ID" --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
	--region "$REGION" --protocol tcp --port 80 --cidr 0.0.0.0/0

######################## 2. Application Load Balancer(ALB) ########################
# • Create ALB with a unique name. #
# • Use two subnets, one for each Availability Zone. #
# • Associate SGs with ALB. #

echo "Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer --name "$ALB_NAME" \
	--subnets "$SUBNET_ID_1" "$SUBNET_ID_2" --security-groups "$SG_ID" \
	--query 'LoadBalancers[0].LoadBalancerArn' --output text)

######################## 3. Target Groups ########################
# • Create 2 target groups: "/red" & "/blue" path. #
# • Configure each to use HTTP on port 80. #

echo "Creating 2 Target Groups..."
TG_ARN_RED=$(aws elbv2 create-target-group --region "$REGION" --name "$TG_NAME_RED" \
	--protocol HTTP --port 80 --vpc-id "$VPC_ID" \
	--query 'TargetGroups[0].TargetGroupArn' --output text)
TG_ARN_BLUE=$(aws elbv2 create-target-group --region "$REGION" --name "$TG_NAME_BLUE" \
	--protocol HTTP --port 80 --vpc-id "$VPC_ID" \
	--query 'TargetGroups[1].TargetGroupArn' --output text)

######################## 4. EC2 Instances ########################
# • Launch 2 EC2 instances. Use Amazon Linux 2 AMI (you can choose another AMI if preferred). #
# • Associate SGs with the instances. #
# • Install & configure Apache on each instance. #
# • Create HTML file on each instance ("/var/www/html/index.html") with content indicating color associated with the instance ("/red" or "/blue"). # 

echo "Launching EC2 instances..."
INSTANCE_ID_RED=$(aws ec2 run-instances --region "$REGION" --image-id "$AMI_ID" --count 1 --instance-type t2.micro \
	--security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_1" \
	--user-data file://"$USER_DATA_FILE_NAME" \
	--query 'Instances[0].InstanceId' --output text)
INSTANCE_ID_BLUE=$(aws ec2 run-instances --region "$REGION" --image-id "$AMI_ID" --count 1 --instance-type t2.micro \
       	--security-group-id "$SG_ID" --subnet-id "$SUBNET_ID_2" \
	--user-data file://"$USER_DATA_FILE_NAME" \
	--query 'Instances[0].InstanceId' --output text)

echo "waiting 60 seconds for instances to run"
sleep 60

######################## 5. Register Targets ########################
# • Register each EC2 instance with its corresponding target group. #

echo "Registering EC2 instances with Target Groups..."
aws elbv2 register-targets --region "$REGION" --target-group-arn "$TG_ARN_RED" --targets Id="$INSTANCE_ID_RED"
aws elbv2 register-targets --region "$REGION" --target-group-arn "$TG_ARN_BLUE" --targets Id="$INSTANCE_ID_BLUE"

######################## 6. Listeners ########################
# • Create 2 listeners on the ALB, for "/red" & "/blue" path. #
# • Associate each listener with the respective target group. #

echo "Creating listeners..."
aws elbv2 create-listener --region "$REGION" --load-balancer-arn "$ALB_ARN" \
	--protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN_RED" --output text
aws elbv2 create-listener --region "$REGION" --load-balancer-arn "$ALB_ARN" \
	--protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN_BLUE" --output text

echo "Deployment complete"

