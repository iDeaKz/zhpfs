#!/bin/bash

# Zkaedi Healing Prediction Factor Score (ZHPFS) Docker Setup Script
PROJECT_DIR="/mnt/b/zhpfs_project"
REPO_URL="https://iDeaKz:$GITHUB_TOKEN@github.com/iDeaKz/zhpfs.git"
DB_PASSWORD="YourSecurePassword123!"

function error_exit {
    echo -e "\e[31mERROR: $1\e[0m" 1>&2
    exit 1
}

function success_msg {
    echo -e "\e[32mSUCCESS: $1\e[0m"
}

function info_msg {
    echo -e "\e[34mINFO: $1\e[0m"
}

info_msg "Starting ZHPFS Docker setup..."

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    error_exit "Please run as root or with sudo privileges."
fi

# Verify WSL environment
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    info_msg "WSL environment detected."
else
    error_exit "This script is intended to run on WSL Kali Linux 2."
fi

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    info_msg "Docker not found. Installing Docker..."
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo usermod -aG docker $USER
    info_msg "Docker installed successfully."
else
    info_msg "Docker is already installed."
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    info_msg "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    success_msg "Docker Compose installed successfully."
else
    info_msg "Docker Compose is already installed."
fi

# Ensure Docker daemon starts
info_msg "Ensuring Docker daemon is running..."
sudo service docker start
if [ $? -ne 0 ]; then
    error_exit "Failed to start Docker. Make sure Docker is correctly installed."
else
    success_msg "Docker daemon started successfully."
fi

# Clone the repository if not already cloned
if [ ! -d "$PROJECT_DIR" ]; then
    info_msg "Cloning the ZHPFS project repository..."
    git clone "$REPO_URL" "$PROJECT_DIR" || error_exit "Failed to clone repository."
    success_msg "Repository cloned successfully."
else
    info_msg "Project directory already exists. Skipping clone."
fi

# Navigate to the project directory
cd "$PROJECT_DIR" || error_exit "Failed to navigate to project directory."

# Run Docker Compose to build and start services
info_msg "Starting Docker Compose services with database initialization..."
sudo docker-compose up -d --build || error_exit "Failed to start Docker Compose services."

# Wait for services to initialize
sleep 10

# Run the SQL initialization script if it's the first run
info_msg "Running database initialization..."
sudo docker-compose exec -T db psql -U zhpfs_user -d zhpfs_db < init.sql || error_exit "Failed to initialize the database."

success_msg "ZHPFS setup completed successfully!"
info_msg "Visit the application at http://localhost:5000 for backend and http://localhost:3000 for frontend."
