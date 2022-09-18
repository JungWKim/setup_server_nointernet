#!/bin/bash

user_home=/home/gpuadmin

disk_presence=no
gpu_presence=no
docker_install=no
nvidia_docker_install=no


#----------- prevent package auto upgrade
sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades

#----------- install basic packages
dpkg -i ./ubuntu2004/basic/archives/*.deb

#----------- mount disks
if [ ${disk_presence} = yes ] || [ ${disk_presence} = y ] ; then

	parted -s -a optimal -- /dev/sdb mklabel gpt mkpart primary xfs 1 -1
	mkdir /data
	mkfs.xfs /dev/sdb1
	UUID=$(blkid /dev/sdb1 | awk '{print $2}')
	#UUID=$(blkid -s UUID -o value /dev/sdb1)
	echo "$UUID	/data	xfs	defaults	0	0" >> /etc/fstab
	mount -a

fi

#----------- install nvidia driver / cuda / cudnn

if [ ${gpu_presence} = yes ] || [ ${gpu_presence} = y ] ; then

#----------- download nvidia driver / cuda / cudnn installation files

	dpkg -i ./ubuntu2004/gpu/archives/*.deb

	cat >> /etc/modprobe.d/blacklist.conf << EOF
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
EOF

	echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
	update-initramfs -u

	cat >> ${user_home}/.bashrc << EOF
## CUDA and cuDNN paths
export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
EOF

	rmmod nouveau

fi

#------------ install docker
if [ ${docker_install} = yes ] || [ ${docker_install} = y ] ; then

	dpkg -i ./ubuntu2004/docker/archives/*.deb

	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version

fi

#------------- install nvidia docker
if [ ${nvidia_docker_install} = yes ] || [ ${nvidia_docker_install} = y ] ; then

	dpkg -i ./ubuntu2004/nvidia-container-toolkit/archives/*.deb
	systemctl restart docker

	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version
	echo -e "\n\n\n------------------------------------- nvidia-docker --version ------------------------------------------"
	nvidia-container-toolkit

fi
