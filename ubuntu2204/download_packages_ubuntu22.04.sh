#!/bin/bash

#--------- change values of variables to "yes" only
SAVE_DIR=
BASIC=no
GUI=no
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
	if [ -z ${GUI} ] ; then
		logger -s "[Error] GUI is not defined." ; ERROR_PRESENCE=1 ; fi
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

		if [ "${OS_DIST}" == "ubuntu22.04" ] ; then
			logger -s "[INFO] OS distribution matches ubuntu22.04"
		else
			logger -s "[Error] OS distribution doesn't match ubuntu22.04"
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

	# create directories for saving packages
	ls ${SAVE_DIR} > /dev/null
	# check whether the directory don't exist
	if [ $? -ne 0 ] ; then
		logger -s "[Error] ./${SAVE_DIR} doesn't exist"
		exit 1
	else
		if [ ! -d ${SAVE_DIR} ] ; then
			logger -s "[Error] ${SAVE_DIR} is not a directory"
			exit 1
		fi
		logger -s "[NOTICE] Starting to create essential subdirectories"
		read -p "${SAVE_DIR} is gonna be removed and recreated. Are you ok with it?(yes/no)" ANSWER
		case "$ANSWER" in
			[yY][eE][sS] | [yY])
				mkdir -p ${SAVE_DIR}/basic/archives/partial
				mkdir -p ${SAVE_DIR}/gui/archives/partial
				mkdir -p ${SAVE_DIR}/gpu/archives/partial
				mkdir -p ${SAVE_DIR}/docker/archives/partial
				mkdir -p ${SAVE_DIR}/nvidia-container-toolkit/archives/partial
				;;
			[nN][oO] | [nN])
				logger -s "[INFO] Exiting Program..."
				exit 1
				;;
			*)
				logger -s "[Error] Wrong input..."
				exit 1
				;;
		esac
	fi
}

#--------- call checking functions
func_check_variable
func_check_prerequisite

#----------- download basic packages
if [ ${BASIC} == "yes" ] ; then
	apt update
	apt reinstall -y net-tools xfsprogs --download-only -o Dir::Cache="./${SAVE_DIR}/basic"
fi

#----------- download gui packages
if [ ${GUI} == "yes" ] ; then
	apt reinstall -y s-generic dkms --download-only -o Dir::Cache="./${SAVE_DIR}/gui"
fi

#----------- download gpu related packages
if [ ${GPU_RELATED} == "yes" ] ; then
	apt reinstall -y build-essential linux-headers-generic dkms --download-only -o Dir::Cache="./${SAVE_DIR}/gpu"
fi

#----------- download docker packages
if [ ${DOCKER} == "yes" ] ; then
	apt reinstall -y ca-certificates curl gnupg lsb-release --download-only -o Dir::Cache="./${SAVE_DIR}/docker"
	apt install -y ca-certificates curl gnupg lsb-release
	mkdir -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt update
	apt reinstall -y docker-ce docker-ce-cli containerd.io docker-compose-plugin --download-only -o Dir::Cache="./${SAVE_DIR}/docker"
fi

#----------- download nvidia-container-toolkit packages
if [ ${NVIDIA_CONTAINER_TOOLKIT} == "yes" ] ; then
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
	curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
	apt update
	apt reinstall -y nvidia-container-toolkit --download-only -o Dir::Cache="./${SAVE_DIR}/nvidia-container-toolkit"
fi
