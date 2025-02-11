#!/bin/bash

##### Arguments
COLOR=$1

##### Apache Server Setup
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

##### HTML Setup

HTML_CONTENT="<html><body><h1>Instance Color: "${COLOR}"</h1></body></html>"
INDEX_FILE="/var/www/html/index.html"

sudo echo "${HTML_CONTENT}" > "${INDEX_FILE}"
