# Introduction:
This is a guide for creating an **AWS CLI script** that automates the deployment of an **Application Load Balancer (ALB)** on **AWS**. \
**ALB** will be configured with 2 **Target Groups**, each associated with a different **EC2** instance. \
The instances will run a basic web server with HTML content. 

# Steps:
### Step 1:  Creating a Security Group:
* TODO: associated SG with the **EC2 instances**, Allow *inbound traffic* on *port 80 (HTTP)*.
### Step 2:  Creating a Load Balancer:
* TODO: Create an Application Load Balancer (ALB) with a unique name.
* TODO: Configure the ALB to use two subnets, one for each Availability Zone.
* TODO: Associate the previously created security group with the ALB.
### Step 3:  Creating 2 Target Groups:
* TODO: create 2 target groups, one for the "/red" path and the other for the "/blue" path, Configure each target group to use HTTP on port 80.
### Step 4:  Creating 2 EC2 Instances:
* TODO:  Launch two EC2 instances, one for each target group.
* TODO: Use the Amazon Linux 2 AMI (you can choose another AMI if preferred).
* TODO: Associate the previously created security group with the instances.
* TODO: Install and configure Apache on each instance.
* TODO: Create an HTML file on each instance ("/var/www/html/index.html") with content indicating the color associated with the instance ("/red" or "/blue").
### Step 5:  Register each EC2 instance with its corresponding Target Group:
* TODO: ???
### Step 6:  Creating 2 Listeners:
* TODO: Create two listeners on the ALB, one for the "/red" path and the other for the "/blue" path.
* TODO: Associate each listener with the respective target group.
