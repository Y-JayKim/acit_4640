# Configure sudoers file
sed -i 's/^#\s*\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' /etc/sudoers
sed -i 's/^\(Defaults    requiretty\)/#\1/' /etc/sudoers

# Application Setup
echo "module.exports = {localUrl: 'mongodb://localhost/acit4640'};" > /home/todo-app/app/config/database.js
