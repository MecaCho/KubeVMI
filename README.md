# KubeVMI


# How to use

## build 

go build -o bin/manager main.go

## install CRD

make install

## start controller 

make run

## kustomize

kustomize build config/default


# TODO list

1.unit tests 
2.perf
3.format, goreport

# Mem


        command: [ "/openvmi-init.sh"]
        name: android
        securityContext:
          capabilities:
            add: [ "SYS_ADMIN", "NET_ADMIN", "SYS_MODULE", "SYS_NICE", "SYS_TIME", "SYS_TTY_CONFIG", "NET_BROADCAST", "IPC_LOCK", "SYS_RESOURCE" ]
        env:
        - name: ANDROID_NAME
          value: $ANDROID_NAME
        - name: PATH
          value: /system/bin:/system/xbin
        - name: ANDROID_DATA
          value: /data
        lifecycle:
          preStop:
            exec:
              command: [ "/openvmi/android-env-uninit.sh" ]
        readinessProbe:
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 30
          exec:
            command: [ "sh", "-c", "getprop sys.boot_completed | grep 1" ]
        volumeMounts:
        - mountPath: /openvmi
          name: volume-openvmi
        - mountPath: /dev/qemu_pipe
          name: volume-pipe
        - mountPath: /dev/openvmi_bridge:rw
          name: volume-bridge
        - mountPath: /dev/input/event0:rw
          name: volume-event0
        - mountPath: /dev/input/event1:rw
          name: volume-event1
        - mountPath: /dev/input/event2:rw
          name: volume-event2
        - mountPath: /data:rw
          name: volume-data
        - mountPath: /dev/tun:rw
          name: volume-tun
      volumes:
      - name: volume-openvmi
        hostPath:
          path: /opt/openvmi/android-env/docker
      - name: volume-pipe
        hostPath:
          path: /opt/openvmi/android-socket/$ANDROID_NAME/sockets/qemu_pipe
      - name: volume-bridge
        hostPath:
          path: /opt/openvmi/android-socket/$ANDROID_NAME/sockets/openvmi_bridge
      - name: volume-event0
        hostPath:
          path: /opt/openvmi/android-socket/$ANDROID_NAME/input/event0
      - name: volume-event1
        hostPath:
          path: /opt/openvmi/android-socket/$ANDROID_NAME/input/event1
      - name: volume-event2
        hostPath:
          path: /opt/openvmi/android-socket/$ANDROID_NAME/input/event2
      - name: volume-data
        hostPath:
          path: /opt/openvmi/android-data/$ANDROID_NAME/data
      - name: volume-tun
        hostPath:
           path: /dev/net/tun

 docker run --privileged -d -p 6080:6080 -p 5554:5554 -p 5555:5555 -e DEVICE="Samsung Galaxy S6" --name android-container budtmo/docker-android-x86-8.1


```bash
docker run \
--entrypoint "/openvmi-init.sh" \
-e ANDROID_NAME="qwq_test" -e PATH="/system/bin:/system/xbin" -e ANDROID_DATA="/data" \
-v /openvmi:/opt/openvmi/android-env/docker -v /dev/qemu_pipe:/opt/openvmi/android-socket/$ANDROID_NAME/sockets/qemu_pipe \
-v /dev/openvmi_bridge:/opt/openvmi/android-socket/$ANDROID_NAME/sockets/openvmi_bridge \ 
-v /dev/input/event0:/opt/openvmi/android-socket/$ANDROID_NAME/input/event0 \ 
-v /dev/input/event1:/opt/openvmi/android-socket/$ANDROID_NAME/input/event1 \
-v /dev/input/event2:/opt/openvmi/android-socket/$ANDROID_NAME/input/event2 \
-v /data:/opt/openvmi/android-data/$ANDROID_NAME/data \
-v /dev/tun:/dev/net/tun \
android:openvmi
```

