Preconfigure(){
    #Create a user
    useradd -m -r todo-app && passwd -l todo-app
    
    # Move files to proper position
    mv /home/admin/todoapp.service /lib/systemd/system/todoapp.service
    mv /home/admin/nginx.conf /etc/nginx/nginx.conf
    
    # Firewall configuration
    firewall-cmd --zone=public --add-port=80/tcp
    firewall-cmd --runtime-to-permanent

    # Disable SELinux
    setenforce 0
    sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
}

SetUpApplication(){
    # Application Setup
    su todo-app -c "mkdir ~/app"
    cd /home/todo-app/app
    su todo-app -c "git clone https://github.com/timoguic/ACIT4640-todo-app.git ."
    su todo-app -c "npm install"
    echo "module.exports = {localUrl: 'mongodb://localhost/acit4640'};" > /home/todo-app/app/config/database.js
    
    chmod o+rx /home/todo-app/
    chmod o+rx /home/todo-app/app/
    
    # Production application setup
    systemctl restart nginx
    systemctl start mongod
    
    # Running NodeJS as a daemon with systemd
    systemctl daemon-reload
    systemctl enable todoapp
    systemctl start todoapp
}

Preconfigure
SetUpApplication