docker run -d -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=SYS_MODULE \
--cap-add=SYS_NICE --cap-add=SYS_TIME --cap-add=SYS_TTY_CONFIG --cap-add=NET_BROADCAST \
--cap-add=IPC_LOCK --cap-add=SYS_RESOURCE --security-opt=apparmor=unconfined \
--security-opt=seccomp=/var/lib/kubelet/seccomp/android.json --name qwq \
-e PATH=/system/bin:/system/xbin -e ANDROID_DATA=/data \
--device=/dev/binder1:/dev/binder:rwm --device=/dev/ashmem:/dev/ashmem:rwm \
--device=/dev/enc_fb1:/dev/enc_fb:rwm --device=/dev/fuse:/dev/fuse:rwm \
--volume=/opt/openvmi/android-socket/qwq/sockets/qemu_pipe:/dev/qemu_pipe \
--volume=/opt/openvmi/android-socket/qwq/sockets/opvmi_bridge:/dev/opvmi_bridge:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event0:/dev/input/event0:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event1:/dev/input/event1:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event2:/dev/input/event2:rw \
--volume=/opt/openvmi/android-data/qwq/cache:/cache:rw \
--volume=/opt/openvmi/android-data/qwq/data:/data:rw android:v101 /openvmi-init.sh
+ docker run -d -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=SYS_MODULE --cap-add=SYS_NICE --cap-add=SYS_TIME --cap-add=SYS_TTY_CONFIG --cap-add=NET_BROADCAST --cap-add=IPC_LOCK --cap-add=SYS_RESOURCE --security-opt=apparmor=unconfined --security-opt=seccomp=/var/lib/kubelet/seccomp/android.json --name qwq -e PATH=/system/bin:/system/xbin -e ANDROID_DATA=/data --device=/dev/binder1:/dev/binder:rwm --device=/dev/ashmem:/dev/ashmem:rwm --device=/dev/enc_fb1:/dev/enc_fb:rwm --device=/dev/fuse:/dev/fuse:rwm --volume=/opt/openvmi/android-socket/qwq/sockets/qemu_pipe:/dev/qemu_pipe --volume=/opt/openvmi/android-socket/qwq/sockets/opvmi_bridge:/dev/opvmi_bridge:rw --volume=/opt/openvmi/android-socket/qwq/input/event0:/dev/input/event0:rw --volume=/opt/openvmi/android-socket/qwq/input/event1:/dev/input/event1:rw --volume=/opt/openvmi/android-socket/qwq/input/event2:/dev/input/event2:rw --volume=/opt/openvmi/android-data/qwq/cache:/cache:rw --volume=/opt/openvmi/android-data/qwq/data:/data:rw android:v101 /openvmi-init.sh



docker run -d -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=SYS_MODULE \
--cap-add=SYS_NICE --cap-add=SYS_TIME --cap-add=SYS_TTY_CONFIG --cap-add=NET_BROADCAST \
--cap-add=IPC_LOCK --cap-add=SYS_RESOURCE --security-opt=apparmor=unconfined \
--security-opt=seccomp=/var/lib/kubelet/seccomp/android.json --name qwq \
-e PATH=/system/bin:/system/xbin -e ANDROID_DATA=/data \
--device=/dev/binder1:/dev/binder:rwm --device=/dev/ashmem:/dev/ashmem:rwm \
--device=/dev/fuse:/dev/fuse:rwm \
--volume=/opt/openvmi/android-socket/qwq/sockets/qemu_pipe:/dev/qemu_pipe \
--volume=/opt/openvmi/android-socket/qwq/sockets/opvmi_bridge:/dev/opvmi_bridge:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event0:/dev/input/event0:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event1:/dev/input/event1:rw \
--volume=/opt/openvmi/android-socket/qwq/input/event2:/dev/input/event2:rw \
--volume=/opt/openvmi/android-data/qwq/cache:/cache:rw \
--volume=/opt/openvmi/android-data/qwq/data:/data:rw android:v101 /openvmi-init.sh

# /dev/openvmi/sockets

docker run -d -it \
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
	--device=/dev/binder2:/dev/binder:rwm --device=/dev/ashmem:/dev/ashmem:rwm \
  --device=/dev/fuse:/dev/fuse:rwm \
	--security-opt="seccomp=/var/lib/kubelet/seccomp/android.json" \
	--name android-test \
	-e PATH=/system/bin:/system/xbin \
	-e ANDROID_DATA=/data            \
	--volume=/opt/openvmi/sockets/qemu_pipe:/dev/qemu_pipe \
  --volume=/opt/openvmi/sockets/opvmi_bridge:/dev/opvmi_bridge:rw \
  --volume=/opt/openvmi/input/event0:/dev/input/event0:rw \
  --volume=/opt/openvmi/input/event1:/dev/input/event1:rw \
  --volume=/opt/openvmi/input/event2:/dev/input/event2:rw \
  --volume=/opt/openvmi/cache:/cache:rw \
  --volume=/opt/openvmi/data:/data:rw android:v101 /openvmi-init.sh
	-p 6007:6007 \
	android:v101 /openvmi-init.sh