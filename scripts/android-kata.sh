#!/bin/bash

config_network()
{
	ipCfgDir=/home/pcl/android-data/android-kata/misc/ethernet
	ipCfgFile=$ipCfgDir/ipconfig.txt
	if [ ! -e $ipCfgDir ]; then
		mkdir -p $ipCfgDir
	fi

	export DOCKDROID_LIB_DIR=/opt/dockdroid/libs
	export TRANSLATORS_PATH=$DOCKDROID_LIB_DIR/libtranslator
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TRANSLATORS_PATH:$DOCKDROID_LIB_DIR/libangle:$DOCKDROID_LIB_DIR/libencturbo:$DOCKDROID_LIB_DIR/libffmpeg:$DOCKDROID_LIB_DIR/libastc-codes
	export MESA_GL_VERSION_OVERRIDE=4.3

	/opt/dockdroid/bin/dockdroid  generate-ip-config --ip=172.17.0.2 --gateway=172.17.0.1 --cidr=16 --ipcfg=$ipCfgFile
 	if [ $? != 0 ]; then
		echo error: config ip failed.
		exit -1
	fi
}

create_container()
{
	docker run -d -it \
	--runtime kata-runtime \
	--cap-add=SYS_ADMIN \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_MODULE \
	--cap-add=SYS_NICE \
	--cap-add=SYS_TIME \
	--cap-add=SYS_TTY_CONFIG \
	--cap-add=NET_BROADCAST \
	--cap-add=IPC_LOCK \
	--cap-add=SYS_RESOURCE \
	--security-opt="apparmor=unconfined" \
	--security-opt="seccomp=/var/lib/kubelet/seccomp/android.json" \
	--name android-kata \
	-e PATH=/system/bin:/system/xbin \
	-e ANDROID_DATA=/data            \
	--volume=/home/pcl/android-data/android-kata:/data:rw \
	-p 6007:6007 \
	android /openvmi-init.sh
}

if [[ $1 == start ]]; then
	config_network
	create_container
elif [[ $1 == reboot ]]; then
	docker stop android-kata
	docker rm android-kata
	config_network
	create_container
else
	docker stop android-kata
	docker rm android-kata
	sudo rm ~/android-data/android-kata -rf
fi
