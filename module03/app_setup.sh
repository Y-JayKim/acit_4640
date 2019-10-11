#!/bin/bash -x

yum update -y
yum upgrade -y
yum install -y wget jq

# Additional user account
useradd -m -r admin
echo "P@ssw0rd" | passwd --stdin admin
usermod -aG wheel admin

mkdir /home/admin/.ssh
cd /home/admin/.ssh
wget https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub
chown -R admin /home/admin/.ssh
chgrp -R admin /home/admin/.ssh
chmod 700 /home/admin/.ssh
chmod 600 /home/admin/.ssh/*

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers
yum install -y epel-release vim git tcpdump curl net-tools bzip2
yum update -y
# Firewall configuration
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --zone=public --add-port=22/tcp
firewall-cmd --zone=public --add-port=443/tcp
firewall-cmd --runtime-to-permanent

# Disable SELinux
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

# Service user & required packages
useradd -m -r todo-app && passwd -l todo-app
yum install -y nodejs npm
printf "[MongoDB]\nname=MongoDB Repository\nbaseurl=http://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.0/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/mongodb.repo
yum install -y mongodb-org
systemctl enable mongod && systemctl start mongod

# Application Setup

su todo-app -c "mkdir ~/app"
cd /home/todo-app/app
su todo-app -c "git clone https://github.com/timoguic/ACIT4640-todo-app.git ."

cd ACIT4640-todo-app
su todo-app -c "npm install"
echo "module.exports = {localUrl: 'mongodb://localhost:27017/'};" > ./config/database.js

# Production application setup
yum install -y nginx
systemctl enable nginx && systemctl start nginx
sed -i 's#/usr/share/nginx/html#/home/todo-app/app/public#' /etc/nginx/nginx.conf 
sed -i "s#^[^#]*location / {#\tlocation / { \n\t    index index.html;#" /etc/nginx/nginx.conf
sed -i "s#^[^#]*error_page 404#\tlocation /api/todos { proxy_pass http://localhost:8080; }\n\n\terror_page 404#" /etc/nginx/nginx.conf
systemctl restart nginx

# Running NodeJS as a daemon with systemd
printf "[Unit]\nDescription=Todo app, ACIT4640\nAfter=network.target\n\n[Service]\nEnvironment=NODE_PORT=8080\nWorkingDirectory=/home/todo-app/app\nType=simple\nUser=todo-app\nExecStart=/usr/bin/node /home/todo-app/app/server.js\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /lib/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp