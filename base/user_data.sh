#!/bin/bash -xe

exec > >(tee /var/log/cloud-init-output.log | logger -t user-data -s 2>/dev/console) 2>&1

# 1) ALB DNS name injected via Terraform
LB_DNS_NAME='${LB_DNS_NAME}'

# 2) Query IMDSv1 for availability‐zone → strip the last letter to get region
REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[?Name==`ghost_content`].FileSystemId' --region $REGION --output text)
echo "EFS_ID: $EFS_ID"
echo "REGION: $REGION"

# 3) Install Node.js 18.x
echo "Installing Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 4) Install EFS utils and Ghost-CLI
echo "Installing amazon-efs-utils and ghost-cli..."
sudo yum install -y amazon-efs-utils
sudo npm install -g ghost-cli@latest

# 5) Create ghost_user if it doesn’t exist
if ! id "ghost_user" &>/dev/null; then
    echo "Adding user ghost_user"
    sudo adduser ghost_user
    sudo usermod -aG wheel ghost_user
else
    echo "User ghost_user already exists. Skipping user creation."
fi

# 6) Create /home/ghost_user/ghost directory and set ownership
if [ ! -d "/home/ghost_user/ghost" ]; then
    echo "Creating ghost folder"
    sudo mkdir -p /home/ghost_user/ghost
    sudo chown -R ghost_user:ghost_user /home/ghost_user/ghost
else
    echo "Folder already exists. Skipping ghost folder creation."
fi

# 7) Switch to ghost_user to install Ghost 5 in local mode
echo "Installing ghost..."
sudo su - ghost_user -c "cd /home/ghost_user/ghost && ghost install --version 5 local --no-setup-nginx --no-setup-ssl --no-prompt"

# 8) Mount EFS to Ghost content directory
echo "Mounting EFS..."
echo "EFS_ID: $EFS_ID"
sudo mkdir -p /home/ghost_user/ghost/content/data
sudo mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

echo "Adjusting permissions..."
sudo chown -R ghost_user:ghost_user /home/ghost_user/ghost/content
sudo chmod -R u+rwX /home/ghost_user/ghost/content

# 9) Create Ghost config with ALB URL, listening on 2368
echo "Creating config.development.json"
cat << EOF > /home/ghost_user/ghost/config.development.json
{
  "url": "http://${LB_DNS_NAME}",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "/home/ghost_user/ghost/content/data/ghost-local.db"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": ["file","stdout"]
  },
  "process": "local",
  "paths": {
    "contentPath": "/home/ghost_user/ghost/content"
  }
}
EOF

sudo chown ghost_user:ghost_user /home/ghost_user/ghost/config.development.json
sudo chmod 600 /home/ghost_user/ghost/config.development.json

# 10) Stop (in case it auto-started) and then start Ghost under ghost_user
echo "Stopping Ghost (if running)…"
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost stop || true"

echo "Starting Ghost…"
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost start"

echo "Done! User-data script complete."
