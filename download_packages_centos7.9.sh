#!/bin/bash

yum install -y epel-release --downloadonly --downloaddir=centos7.9/gpu/

yum install -y epel-release

yum install -y net-tools createrepo pciutils --downloadonly --downloaddir=centos7.9/basic/

yum update -y --downloadonly --downloaddir=centos7.9/update/

yum install -y kernel-devel --downloadonly --downloaddir=centos7.9/gpu/

yum install -y dkms --downloadonly --downloaddir=centos7.9/gpu/

yum install -y yum-utils --downloadonly --downloaddir=centos7.9/docker/

yum install -y yum-utils

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin --downloadonly --downloaddir=centos7.9/docker/

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo

yum clean expire-cache

yum install -y nvidia-container-toolkit --downloadonly --downloaddir=centos7.9/nvidia-container-toolkit/
