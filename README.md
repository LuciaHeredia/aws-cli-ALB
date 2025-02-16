# Introduction:
This is a guide for creating an **AWS CLI script** that automates the deployment of an **Application Load Balancer (ALB)**. \
**ALB** will be configured with 2 **Target Groups**, each associated with a different **EC2** instance. \
The instances will run a basic web server with HTML content. 

# Steps:
### First:  Connecting AWS:
  ```
  $ aws configure
  ```
  Login with IAM user credentials (access/secret key) and configure region id (can be found beside the region name in your AWS account):
  ```
  AWS Access Key ID [None]: accesskey
  AWS Secret Access Key [None]: secretkey
  Default region name [None]: us-west-2
  Default output format [None]:
  ```
### Step 1:  Creating a Security Group:
  * Allow *inbound traffic* on *port 80 (HTTP)*.
  * When creating  **EC2 instances**, associated this **Security Group** with them. 
### Step 2:  Creating 2 Target Groups:
  * Create 2 target groups, one for the "/red" path and the other for the "/blue" path, Configure each target group to use HTTP on port 80.
### Step 3:  Creating 2 EC2 Instances:
* Launch two EC2 instances, one for each target group.
* Associate the previously created security group with the instances.
* Install and configure Apache on each instance.
* Create an HTML file on each instance ("/var/www/html/index.html") with content indicating the color associated with the instance ("/red" or "/blue").
### Step 4:  Register each EC2 instance with its corresponding Target Group:
* TODO: ???
### Step 5:  Creating a Load Balancer:
* TODO: Create an Application Load Balancer (ALB) with a unique name.
* TODO: Configure the ALB to use two subnets, one for each Availability Zone.
* TODO: Associate the previously created security group with the ALB.
### Step 6:  Creating 2 Listeners:
* TODO: Create two listeners on the ALB, one for the "/red" path and the other for the "/blue" path.
* TODO: Associate each listener with the respective target group.
