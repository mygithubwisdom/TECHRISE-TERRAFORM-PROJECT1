#!/bin/bash
# Update the package list
sudo apt-get update -y

# Install Nginx
sudo apt-get install -y nginx

# Start and enable Nginx service
sudo systemctl start nginx
sudo systemctl enable nginx

# Create a simple HTML page
echo "<h1>Welcome to Nginx on AWS EC2</h1>" | sudo tee /var/www/html/index.html
