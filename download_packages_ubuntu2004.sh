#!/bin/bash

mkdir -p ubuntu2004

mkdir ubuntu2004/basic ubuntu2004/gpu ubuntu2004/docker ubuntu2004/nvidia-container-toolkit

apt update

apt reinstall -y net-tools xfsprogs --download-only -o Dir::Cache="./ubuntu2004/basic"

apt reinstall -y build-essential linux-headers-generic dkms --download-only -o Dir::Cache="./ubuntu2004/gpu"

apt reinstall -y ca-certificates curl gnupg lsb-release --download-only -o Dir::Cache="./ubuntu2004/docker"

apt install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
	
apt reinstall -y docker-ce docker-ce-cli containerd.io docker-compose-plugin --download-only -o Dir::Cache="./ubuntu2004/docker"

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -

curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

apt update

apt reinstall -y nvidia-container-toolkit --download-only -o Dir::Cache="./ubuntu2004/nvidia-container-toolkit"
