# Stage 1 Task - Node.js App Deployment

## 🚀 Project Overview

This project is a **Node.js web application** containerized using **Docker** and deployed on an **Ubuntu server**. Nginx is used as a **reverse proxy** to serve the app on port 80. The deployment is fully automated using a `deploy.sh` script.

Key features:

* Automated code pull from Git repository
* Dockerized application
* Nginx reverse proxy configuration
* Health check and service validation
* Easy redeployment with a single script

---

## 🛠️ Prerequisites

Before running the deployment, ensure you have the following:

* Ubuntu server (tested on 24.04 LTS)
* SSH access with a private key
* Docker installed (the script can install if missing)
* Docker Compose installed (the script can install if missing)
* Nginx installed (the script can install if missing)

Local environment:

* Git
* Bash shell


---

## ⚒️ Deployment

### 1. Set Environment Variables

Edit the `.env` file or update variables inside `deploy.sh`:

```bash
APP_PORT=3000
SERVER_USER=ubuntu
SERVER_IP=16.171.17.234
SSH_KEY=stage-1.pem
```

### 2. Make Script Executable

```bash
chmod +x deploy.sh
```

### 3. Run Deployment Script

```bash
./deploy.sh
```

The script will automatically:

1. Pull the latest code from the repository
2. Build the Docker image
3. Run the container
4. Configure Nginx as a reverse proxy
5. Validate Docker and Nginx services
6. Test the app using `curl`

---

## 🌍 Accessing the App

Once deployment completes successfully, open your browser and go to:

```
http://16.171.17.234
```

The app should load and serve content via Nginx.

---

## 🧩 Nginx Configuration

The deployment script generates the following Nginx configuration:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

* This ensures that Nginx forwards HTTP requests to your Dockerized Node.js app.
* The configuration is placed in `/etc/nginx/sites-available/app.conf` and symlinked to `/etc/nginx/sites-enabled/app.conf`.

---

## 📦 Docker

The application is containerized:

```bash
docker build -t app_web .
docker run -d -p $APP_PORT:$APP_PORT --name stage1-task app_web
```

* Port `3000` inside the container is mapped to `$APP_PORT` on the host.
* The script handles cleanup of previous containers and networks automatically.

---

## 🔍 Validation

After deployment, the script runs:

```bash
sudo systemctl status docker
sudo systemctl status nginx
curl -I http://localhost
```

Expected result:

* Docker: container `stage1-task` running
* Nginx: service active (running)
* App: `HTTP/1.1 200 OK`

---

## ⚙️ Troubleshooting

* **Nginx errors**: Ensure the Nginx config in `deploy.sh` has correct `proxy_set_header` syntax.
* **Permission errors**: Use `sudo` or ensure correct file ownership for `/etc/nginx/sites-available/` and `/etc/nginx/sites-enabled/`.
* **Port conflicts**: Make sure no other service is running on `$APP_PORT` (default 3000).

---

## 💡 Notes

* Redeploying is as simple as running `./deploy.sh` again.
* The script updates the server packages automatically before deployment.
* Nginx warnings about `server_name "_"` can be ignored unless multiple server blocks exist.

---

## 🔖 License

This project is open-source and available under the **MIT License**.
