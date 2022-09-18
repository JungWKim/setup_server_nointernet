#!/bin/bash

user_home=/root

update=no
gpu_presence=no
docker_install=no
nvidia_docker_install=no


#----------- install basic packages
yum localinstall -y centos7.9/basic/*.rpm

#----------- mount disks
if [ ${update} = yes ] || [ ${update} = y ] ; then

	yum localinstall -y centos7.9/update/*.rpm

fi

#----------- prerequisite for installation of nvidia driver / cuda / cudnn

if [ ${gpu_presence} = yes ] || [ ${gpu_presence} = y ] ; then

	yum localinstall -y centos7.9/gpu/*.rpm

	touch /etc/modprobe.d/blacklist.conf
	cat >> /etc/modprobe.d/blacklist.conf << EOF
blacklist nouveau 
options nouveau modeset=0
EOF

	mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-backup.img
	dracut

	sed -i 's/rhgb quiet/rhgb quiet nouveau.modeset=0 modprobe.blacklist=nouveau rd.driver.blacklist=nouveau/g' /etc/default/grub

	grub2-mkconfig -o /boot/grub2/grub.cfg
	grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

	cat >> ${user_home}/.bashrc << EOF
## CUDA and cuDNN paths
export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
EOF

	source ${user_home}/.bashrc

	rmmod nouveau
	
fi

#------------- install docker -------------
if [ ${docker_install} = yes ] || [ ${docker_install} == y ]; then

	yum localinstall -y centos7.9/docker/*.rpm
	systemctl start docker
	systemctl enable docker
	
	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version

fi

#------------- install nvidia docker -------------
if [ ${nvidia_docker_install} = yes ] || [ ${nvidia_docker_install} == y ]; then

	yum localinstall -y centos7.9/nvidia-container-toolkit/*.rpm
	systemctl restart docker
	
	echo -e "\n\n\n------------------------------------------ docker images -----------------------------------------------"
	docker images
	echo -e "\n\n\n----------------------------------------- docker --version ---------------------------------------------"
	docker --version
	echo -e "\n\n\n------------------------------------- nvidia-docker --version ------------------------------------------"
	nvidia-container-toolkit

fi

