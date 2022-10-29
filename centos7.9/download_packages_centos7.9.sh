#!/bin/bash

#--------- variables
#--------- change to "yes" only
SAVE_DIR=
BASIC=no
GPU_RELATED=no
DOCKER=no
NVIDIA_CONTAINER_TOOLKIT=no

#--------- function whether variables are deinfed
func_check_variable() {

	local ERROR_PRESENCE=0

	if [ -z ${SAVE_DIR} ] ; then
		logger -s "[Error] SAVE_DIR is not defined." ; ERROR_PRESENCE=1 ; fi
	if [ -z ${BASIC} ] ; then
		logger -s "[Error] BASIC is not defined." ; ERROR_PRESENCE=1 ; fi
	if [ -z ${GPU_RELATED} ] ; then
		logger -s "[Error] GPU_RELATED is not defined." ; ERROR_PRESENCE=1 ; fi
	if [ -z ${DOCKER} ] ; then
		logger -s "[Error] DOCKER is not defined." ; ERROR_PRESENCE=1 ; fi
	if [ -z ${NVIDIA_CONTAINER_TOOLKIT} ] ; then
		logger -s "[Error] NVIDIA_CONTAINER_TOOLKIT is not defined." ; ERROR_PRESENCE=1 ; fi

	if [ ${ERROR_PRESENCE} -eq 1 ] ; then
		exit 1
	fi	
}

#----------- prerequisite checking function definition
func_check_prerequisite() {

	# /etc/os-release file existence check
	if [ ! -e "/etc/os-release" ] ; then
		logger -s "[Error] /etc/os-release doesn't exist. OS is unrecognizable."
		exit 1
	else
		# check OS distribution
		local OS_DIST=$(. /etc/os-release;echo $ID$VERSION_ID)

		if [ "${OS_DIST}" == "centos7" ] ; then
			logger -s "[INFO] OS distribution matches centos7"
		else
			logger -s "[Error] OS distribution doesn't match centos7"
			exit 1
		fi
	fi

	# Internet connection check
	ping -c 5 8.8.8.8 > /dev/null
	if [ $? -ne "0" ] ; then
		logger -s "[Error] Network is unreachable."
		exit 1
	else
		logger -s "[INFO] Network is reachable."
	fi

	# check that directory for saving packages exists
	ls ${SAVE_DIR}
	if [ $? -ne 0 ] ; then
		logger -s "[Error] ${SAVE_DIR} doesn't exist"
		exit 1
	fi
}

#--------- call checking functions
func_check_variable
func_check_prerequisite

#----------- download basic packages
if [ ${BASIC} == "yes" ] ; then
	yum install -y epel-release --downloadonly --downloaddir=${SAVE_DIR}/gpu/
	yum install -y epel-release
	yum install -y net-tools createrepo pciutils --downloadonly --downloaddir=${SAVE_DIR}/basic/
fi

#----------- download gpu related packages
if [ ${GPU_RELATED} == "yes" ] ; then
	yum update -y --downloadonly --downloaddir=${SAVE_DIR}/update/
	yum groupinstall -y "Development Tools" --downloadonly --downloaddir=${SAVE_DIR}/gpu/
	yum install -y kernel-devel --downloadonly --downloaddir=${SAVE_DIR}/gpu/
	yum install -y dkms --downloadonly --downloaddir=${SAVE_DIR}/gpu/
fi

#----------- download docker packages
if [ ${DOCKER} == "yes" ] ; then
	yum install -y yum-utils --downloadonly --downloaddir=${SAVE_DIR}/docker/
	yum install -y yum-utils
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin --downloadonly --downloaddir=${SAVE_DIR}/docker/
fi

#----------- download nvidia-container-toolkit packages
if [ ${NVIDIA_CONTAINER_TOOLKIT} == "yes" ] ; then
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
	yum clean expire-cache
	yum install -y nvidia-container-toolkit --downloadonly --downloaddir=${SAVE_DIR}/nvidia-container-toolkit/
fi
