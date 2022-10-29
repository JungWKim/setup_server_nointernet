#!/bin/bash

#----------- input admin account's absolute home directory path
USER_HOME=
SAVE_DIR=

#----------- change from 'no' to '""yes""'
BASIC_SETUP=no
DISK_PRESENCE=no
GPU_PRESENCE=no
DOCKER_INSTALL=no
NVIDIA_CONTAINER_TOOLKIT_INSTALL=no

#----------- check variables are defined
func_check_variable() {

	local ERROR_PRESENCE=0

	if [[ -z ${USER_HOME} ]] ; then
		logger -s "[Error] USER_HOME is not defined." ; ERROR_PRESENCE=1 ; fi
	if [[ -z ${BASIC_SETUP} ]] ; then
		logger -s "[Error] BASIC_SETUP is not defined." ; ERROR_PRESENCE=1 ; fi
	if [[ -z ${DISK_PRESENCE} ]] ; then
		logger -s "[Error] DISK_PRESENCE is not defined." ; ERROR_PRESENCE=1 ; fi
	if [[ -z ${GPU_PRESENCE} ]] ; then
		logger -s "[Error] GPU_PRESENCE is not defined." ; ERROR_PRESENCE=1 ; fi
	if [[ -z ${DOCKER_INSTALL} ]] ; then
		logger -s "[Error] DOCKER_INSTALL is not defined." ; ERROR_PRESENCE=1 ; fi
	if [[ -z ${NVIDIA_CONTAINER_TOOLKIT_INSTALL} ]] ; then
		logger -s "[Error] NVIDIA_CONTAINER_TOOLKIT_INSTALL is not defined." ; ERROR_PRESENCE=1 ; fi

	if [ ${ERROR_PRESENCE} -eq 1 ] ; then
		exit 1
	fi	
}

#----------- prerequisite checking function definition
func_check_prerequisite () {

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
			logger -s "[Error] OS distribution doesn't matche centos7"
			exit 1
		fi
	fi
	
	# USER HOME existence check
	ls ${USER_HOME} > /dev/null
	if [ $? -ne "0" ] ; then
		logger -s "[Error] USER HOME directory doesn't exist"
		exit 1
	else
		logger -s "[INFO] USER HOME directory exists."
	fi

	# SAVE_DIR and its subdirectories existence check
	# 1. check SAVE_DIR exists and is a directory
	if [ ! -d ${SAVE_DIR} ] ; then
		logger -s "[Error] ${SAVE_DIR} doesn't exist or is not a directory"
		exit 1
	else
		# 2. check subdirectories exist and are directory
		if [ ! -d ${SAVE_DIR}/basic ] ; then
			logger -s "[Error] ${SAVE_DIR}/basic doesn't exist."
			exit 1 ; fi
		if [ ! -d ${SAVE_DIR}/update ] ; then
			logger -s "[Error] ${SAVE_DIR}/update doesn't exist."
			exit 1 ; fi
		if [ ! -d ${SAVE_DIR}/gpu ] ; then
			logger -s "[Error] ${SAVE_DIR}/gpu doesn't exist."
			exit 1 ; fi
		if [ ! -d ${SAVE_DIR}/docker ] ; then
			logger -s "[Error] ${SAVE_DIR}/docker doesn't exist."
			exit 1 ; fi
		if [ ! -d ${SAVE_DIR}/nvidia-container-toolkit ] ; then
			logger -s "[Error] ${SAVE_DIR}/nvidia-container-toolkit doesn't exist."
			exit 1 ; fi
		logger -s "[INFO] ${SAVE_DIR} exixts."
	fi
}

#----------- call checking functions
func_check_variable
func_check_prerequisite

#----------- basic setup
if [ ${BASIC_SETUP} == "yes" ] ; then

	# prevent package auto upgrade
	sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades
	# install basic packages
	yum localinstall -y centos7/basic/*.rpm
fi

#----------- formatting & apply FS & mount disks
if [ ${DISK_PRESENCE} == "yes" ] ; then

	local FS="xfs"
	local MOUNT_POINT="/data"
	local UUID=$(blkid /dev/sdb1 | awk '{print $2}')
	#local UUID=$(blkid -s UUID -o value /dev/sdb1)

	parted -s -a optimal -- /dev/sdb mklabel gpt mkpart primary ${FS} 1 -1
	mkdir ${MOUNT_POINT}
	mkfs.${FS} /dev/sdb1
	echo "$UUID	${MOUNT_POINT}	${FS}	defaults	0	0" >> /etc/fstab
	mount -a
fi

#----------- update packages
if [ ${update} = yes ] || [ ${update} = y ] ; then

	yum localinstall -y ${SAVE_DIR}/update/*.rpm

fi

#----------- install nvidia driver / cuda / cudnn
if [ ${GPU_PRESENCE} = yes ] ; then

	yum localinstall -y ${SAVE_DIR}/update/*.rpm
	yum localinstall -y ${SAVE_DIR}/gpu/*.rpm

	# disable nouveau embedded display driver
	rmmod nouveau

	# blacklist nouveau driver
	ls /etc/modprobe.d/blacklist.conf > /dev/null
	if [ "$?" -ne "0" ] ; then
		touch /etc/modprobe.d/blacklist.conf
	fi
	cat >> /etc/modprobe.d/blacklist.conf << EOF
blacklist nouveau 
options nouveau modeset=0
EOF

	mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-backup.img
	dracut

	sed -i 's/rhgb quiet/rhgb quiet nouveau.modeset=0 modprobe.blacklist=nouveau rd.driver.blacklist=nouveau/g' /etc/default/grub

	grub2-mkconfig -o /boot/grub2/grub.cfg
	grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

	# install nvidia driver / cuda / cudnn
	cat >> ${USER_HOME}/.bashrc << EOF
## CUDA and cuDNN paths
export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
EOF
fi

#------------ install docker
if [ ${DOCKER_INSTALL} == "yes" ] ; then

	yum localinstall -y centos7/docker/*.rpm
	systemctl start docker
	systemctl enable docker

	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version
fi

#------------- install nvidia container toolkit
if [ ${NVIDIA_CONTAINER_TOOLKIT_INSTALL} = "yes" ] ; then

	yum localinstall -y centos7/nvidia-container-toolkit/*.rpm
	systemctl restart docker

	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version
	echo -e "\n\n\n------------------------------------- nvidia-container-toolkit -----------------------------------------"
	nvidia-container-toolkit
fi
