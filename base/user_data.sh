#!/bin/bash -xe

exec > >(tee /var/log/cloud-init-output.log |logger -t user-data -s 2>/dev/console) 2>&1
### Update this to match your ALB DNS name
LB_DNS_NAME='${LB_DNS_NAME}'

REGION='${REGION}'
SSM_DB_PASSWORD="/ghost/dbpassw"
DB_PASSWORD=$(aws ssm get-parameter --name $SSM_DB_PASSWORD --query Parameter.Value --with-decryption --region $REGION --output text)
DB_USER='${DB_USER}'
DB_NAME='${DB_NAME}'
DB_URL='${DB_URL}'
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

# # Check if the Ghost posts table exists
# EXIST=$(mysql -h "$DB_URL" \
#              -u "$DB_USER" -p"$DB_PASSWORD" \
#              -D "$DB_NAME" \
#              -sse "SELECT COUNT(*) FROM information_schema.tables
#                    WHERE table_schema='$DB_NAME' AND table_name='posts';")

# if [ "$EXIST" -eq 0 ]; then
#   echo "Database is empty – running Ghost install with migrations"
#   sudo -u ghost_user ghost install --version 5 local \
#     --no-setup-nginx --no-setup-ssl --no-prompt
# else
#   echo "Database already initialized – skipping install/migration"
# fi

echo "Installing ghost..."
cd /home/ghost_user/
# sudo -u ghost_user ghost install --version 5 local --no-setup-nginx --no-setup-ssl --no-prompt || true

######################
# sudo su - ghost_user -c "cd /home/ghost_user/ghost && ghost install --version 5 local"
sudo su - ghost_user -c "cd /home/ghost_user/ghost && ghost install --db mysql --dbhost $DB_URL --dbuser $DB_USER --dbpass $DB_PASSWORD --dbname $DB_NAME --no-prompt --no-setup-nginx --no-setup-ssl"

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
    "client": "mysql",
    "connection": {
      "host": "${DB_URL}",
      "port": 3306,
      "user": "${DB_USER}",
      "password": "$DB_PASSWORD",
      "database": "${DB_NAME}"
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
sudo cat /home/ghost_user/ghost/config.development.json

echo "Starting Ghost..."
sudo -u ghost_user bash -c "cd /home/ghost_user/ghost && ghost start"
