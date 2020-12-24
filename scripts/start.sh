docker run \
--entrypoint "/openvmi-init.sh" \
-e ANDROID_NAME="qwq_test" -e PATH="/system/bin:/system/xbin" -e ANDROID_DATA="/data" \
-e ANDROID_BINDER_IDX=2 \
-e KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443 \
-e KUBERNETES_PORT_443_TCP_PROTO=tcp \
-e KUBERNETES_PORT_443_TCP_PORT=443 \
-e KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1 \
-e KUBERNETES_SERVICE_HOST=10.96.0.1 \
-e KUBERNETES_SERVICE_PORT=443 \
-e KUBERNETES_SERVICE_PORT_HTTPS=443 \
-e KUBERNETES_PORT=tcp://10.96.0.1:443 \
-v /openvmi:/opt/openvmi/android-env/docker -v /dev/qemu_pipe:/opt/openvmi/android-socket/$ANDROID_NAME/sockets/qemu_pipe \
-v /dev/openvmi_bridge:/opt/openvmi/android-socket/$ANDROID_NAME/sockets/openvmi_bridge \
-v /dev/input/event0:/opt/openvmi/android-socket/$ANDROID_NAME/input/event0 \
-v /dev/input/event1:/opt/openvmi/android-socket/$ANDROID_NAME/input/event1 \
-v /dev/input/event2:/opt/openvmi/android-socket/$ANDROID_NAME/input/event2 \
-v /data:/opt/openvmi/android-data/$ANDROID_NAME/data \
-v /dev/tun:/dev/net/tun \
android:openvmi

#PATH=/system/bin:/system/xbin
#HOSTNAME=openvmi-01-0
#ANDROID_BINDER_IDX=21
#ANDROID_DATA=/data
#ANDROID_NAME=openvmi-01
#KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
#KUBERNETES_PORT_443_TCP_PROTO=tcp
#KUBERNETES_PORT_443_TCP_PORT=443
#KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
#KUBERNETES_SERVICE_HOST=10.96.0.1
#KUBERNETES_SERVICE_PORT=443
#KUBERNETES_SERVICE_PORT_HTTPS=443
#KUBERNETES_PORT=tcp://10.96.0.1:443
#HOME=/