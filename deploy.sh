#!/bin/bash
# ==========================
# HNG DevOps Stage 1 Task - Automated Deployment Script
# ==========================

set -e

# ---- STEP 1: Setup logging ----
LOG_FILE="deploy_$(date +%Y%m%d).log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "🚀 Starting automated deployment..."
echo "Log file: $LOG_FILE"

# ---- STEP 2: Define Deployment Variables ----
REPO_URL="https://github.com/ajalaadetola/stage-1-task.git"
PAT="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"   # optional if repo is public
BRANCH="main"

SERVER_USER="ubuntu"          # or your server username
SERVER_IP="16.171.17.234"
SSH_KEY="stage-1.pem"
APP_PORT="3000"

echo "✅ All configuration values loaded!"
# Ensure SSH key uses absolute path
if [[ "$SSH_KEY" != /* ]]; then
  SSH_KEY="$(pwd)/$SSH_KEY"
fi

echo "Using SSH key at: $SSH_KEY"
# ---- STEP 1: Setup logging ----
LOG_FILE="deploy_$(date +%Y%m%d).log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "🚀 Starting automated deployment..."
echo "Log file: $LOG_FILE"

# ---- STEP 2: Define Deployment Variables ----
REPO_URL="https://github.com/ajalaadetola/stage-1-task.git"
PAT="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"   # optional if repo is public
BRANCH="main"

SERVER_USER="ubuntu"          # or your server username
SERVER_IP="16.171.17.234"
SSH_KEY="stage-1.pem"
APP_PORT="3000"

echo "✅ All configuration values loaded!"
# Ensure SSH key uses absolute path
if [[ "$SSH_KEY" != /* ]]; then
  SSH_KEY="$(pwd)/$SSH_KEY"
fi

echo "Using SSH key at: $SSH_KEY"

# ---- STEP 3: Clone or update repository ----
REPO_NAME=$(basename -s .git "$REPO_URL")

if [ -d "$REPO_NAME" ]; then
  echo "📂 Repository already exists. Pulling latest changes..."
  cd "$REPO_NAME"
  git pull
  else
  echo "📥 Cloning repository..."
  git clone ${REPO_URL}
  cd "$REPO_NAME"
fi

git checkout "$BRANCH"

# Verify Docker configuration
if [[ -f "Dockerfile" || -f "docker-compose.yml" ]]; then
  echo "✅ Docker configuration found."
else
  echo "❌ No Dockerfile or docker-compose.yml found. Exiting..."
  exit 1
fi

# ---- STEP 4: Test SSH connection ----
echo "Using SSH key at: $SSH_KEY"
ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER_IP} "echo SSH connection successful" || {
  echo "❌ SSH connection failed!"
  exit 1
}

# ---- STEP 5: Prepare remote environment ----
ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} <<EOF
  set -e
  echo "🔧 Updating system packages..."
  sudo apt update -y

  echo "🐳 Installing Docker, Compose, and Nginx..."
  sudo apt install -y docker.io docker-compose nginx

  sudo usermod -aG docker \$USER
    sudo systemctl enable docker
  sudo systemctl start docker
  sudo systemctl enable nginx
  sudo systemctl start nginx

  docker --version
  docker-compose --version
EOF

# ---- STEP 6: Transfer project files ----
echo "📦 Copying project files to remote server..."
scp -i "$SSH_KEY" -r . ${SERVER_USER}@${SERVER_IP}:/home/${SERVER_USER}/app

# ---- STEP 7: Build and run Docker app ----
ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} <<EOF
  cd ~/app
  if [ -f docker-compose.yml ]; then
    echo "🚀 Starting with docker-compose..."
    sudo docker-compose down || true
    sudo docker-compose up -d --build
  else
    echo "🚀 Building and running with Dockerfile..."
    sudo docker build -t app_image .
    sudo docker stop app_container || true
    sudo docker rm app_container || true
    sudo docker run -d -p ${APP_PORT}:${APP_PORT} --name app_container app_image
  fi

  sudo docker ps
EOF

# ---- STEP 8: Configure Nginx ----
ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} <<'EOF_REMOTE'
echo "🧩 Configuring Nginx..."

# Write Nginx server block safely
sudo tee /etc/nginx/sites-available/app.conf > /dev/null <<'EOL'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Enable site and test config
sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
sudo nginx -t

# Reload Nginx safely
sudo systemctl reload nginx
EOF_REMOTE

# ---- STEP 9: Validate deployment ----
ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} <<EOF
  echo "🔍 Checking services..."
  sudo systemctl status docker --no-pager
  sudo systemctl status nginx --no-pager

  echo "🌍 Testing app..."
    curl -I http://localhost
EOF

echo "🎉 Deployment completed successfully!"
