#!/bin/bash -xe

exec > >(tee /var/log/cloud-init-output.log |logger -t user-data -s 2>/dev/console) 2>&1
### Update this to match your ALB DNS name
LB_DNS_NAME='${LB_DNS_NAME}'

# 2) Query IMDSv1 for availability‐zone → strip the last letter to get region
REGION='${REGION}'
EFS_ID='${EFS_ID}'
echo "EFS_ID: $EFS_ID"
echo "REGION: $REGION"
\
### Install pre-reqs
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
yum install -y nodejs amazon-efs-utils
npm install ghost-cli@latest -g

if ! id "ghost_user" &>/dev/null; then
        echo "Adding user ghost_user"
        sudo adduser ghost_user
        sudo usermod -aG wheel ghost_user
    else
        echo "User ghost_user already exists. Skipping user creation."
    fi

  # Create the directory and set ownership (run as root or ec2-user)
  if [ ! -d "/home/ghost_user/ghost" ]; then
      echo "Creating ghost folder"
      sudo mkdir -p /home/ghost_user/ghost
      sudo chown -R ghost_user:ghost_user /home/ghost_user/ghost
  else
      echo "Folder already exists. Skipping ghost folder creation."
  fi

echo "Installing ghost..."
cd /home/ghost_user/
# sudo -u ghost_user ghost install --version 5 local --no-setup-nginx --no-setup-ssl --no-prompt || true
sudo su - ghost_user -c "cd /home/ghost_user/ghost && ghost install --version 5 local"

# sudo mkdir -p /home/ghost_user/ghost/content/data
# sudo chown -R ghost_user:ghost_user /home/ghost_user/ghost/content

# sudo chmod -R u+rwX /home/ghost_user/ghost/content

# sudo ls -la /home/ghost_user/ghost/content
# sudo ls -la /home/ghost_user/ghost/content/data

echo "Creating config.development.json"

cat << EOF > config.development.json

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
    "transports": [
      "file",
      "stdout"
    ]
  },
  "process": "local",
  "paths": {
    "contentPath": "/home/ghost_user/ghost/content"
  }
}
EOF

# sudo -u ghost_user ghost stop
# sudo -u ghost_user ghost start

# Ensure ghost commands are executed in the correct directory
echo "Stopping Ghost..."
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost stop"

sudo mv config.development.json /home/ghost_user/ghost

echo "Starting Ghost..."
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost start"