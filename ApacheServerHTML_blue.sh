#!/bin/bash

##### Apache2 Server Setup
sudo apt update
sudo apt install apache2 -y
sudo systemctl status apache2

##### HTML Setup
HTML_CONTENT="<html><body style='background-color: blue;'><h1>Instance Color: blue </h1></body></html>"
INDEX_FILE="/var/www/html/index.html"
sudo echo "${HTML_CONTENT}" > "${INDEX_FILE}"
