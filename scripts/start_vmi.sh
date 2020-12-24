#!/bin/bash

OPENVMI=/opt/openvmi/bin/openvmi
SESSIONMANAGER="$OPENVMI session-manager"
BINDMOUNTDIR="/opt/openvmi/android-data"
SOCKETDIR="/opt/openvmi/android-socket"
RUNTIME_SOCKET_DIR="/opt/openvmi/android-socket"
DOCKDROID_LOG_DIR=/tmp/openvmi
DOCKDROID_ALLLOG="" # Populated dynamically
DOCKDROID_LOG_LEVEL="info"
SESSIONMANAGERPID=""
FRAMEBUFFERPID=""
START=""
STOP=""
VNC="true"
instance=0
instance=""
EXECUTIONS=0
FAILED=255
ENABLE_GPU=1
LINUX_PASSWORD=pcl12    #ubuntu sudo password
SUPPORTEDINSTANCES=200 # Restricted by Class C networking (!1 && !255)
                       # Remember Robox IP addresses start at <MASK>.2


function error()
{
    echo -e "[$(date +%T)] \e[01;31m$INSTANCENUM: $@ \e[0m" >> $DOCKDROID_ALLLOG
    echo -e "\e[01;31m$INSTANCENUM: $@ \e[0m"
}

function warning()
{
    echo -e "[$(date +%T)] \e[01;33m$INSTANCENUM: $@ \e[0m" >> $DOCKDROID_ALLLOG
    echo -e "\e[01;33m$INSTANCENUM: $@ \e[0m"
}

function out()
{
    echo -e "[$(date +%T)] $INSTANCENUM: $@" >> $DOCKDROID_ALLLOG
    echo -e "$INSTANCENUM: $@"
}

function debug()
{
    echo -e "[$(date +%T)] $INSTANCENUM: $@" >> $DOCKDROID_ALLLOG
    #echo -e "$INSTANCENUM: $@"
}


function start_binder_ashmem_encoder()
{
    BINDERNODE=/dev/binder$INSTANCENUM
    ASHMEMNODE=/dev/ashmem
    ENCODERNODE=/dev/enc_fb$INSTANCENUM
    KERNEL_DIR=$(pwd)
    out $KERNEL_DIR
    out "STARTING load binder and ashmem kernel and encoder module"

    lsmod | grep enc_fb > /dev/null
    if [[ $? -ne 0 ]]; then
        echo $LINUX_PASSWORD | sudo -S insmod $KERNEL_DIR/kernel/encoder/enc_fb.ko num_devices=$(($SUPPORTEDINSTANCES+1))
    fi
    lsmod | grep binder_linux > /dev/null
    if [[ $? -ne 0 ]]; then
        echo $LINUX_PASSWORD | sudo -S insmod $KERNEL_DIR/kernel/binder/binder_linux.ko num_devices=$(($SUPPORTEDINSTANCES+1))
    fi
    lsmod | grep ashmem_linux > /dev/null
    if [[ $? -ne 0 ]]; then
        echo $LINUX_PASSWORD | sudo -S insmod $KERNEL_DIR/kernel/ashmem/ashmem_linux.ko
    fi

    echo $LINUX_PASSWORD | sudo -S chmod 0777 $BINDERNODE
    echo $LINUX_PASSWORD | sudo -S chmod 0777 $ASHMEMNODE
}

function start_framebuffer()
{
       display=":$INSTANCENUM"
       out "STARTING Frame Buffer"

       ps aux | grep Xvfb | grep "Xvfb[[:space:]]*:$INSTANCENUM " > /dev/null
       if [[ $? -eq 0 ]]; then
           OUT=`ps aux | grep Xvfb | grep "Xvfb[[:space:]]*:$INSTANCENUM "`
           out $OUT
           warning "Xvfb :$INSTANCENUM is already running"
           return
       fi

       cmd="Xvfb $display -ac -screen 0 720x1280x24"

       debug $cmd
       $cmd &>> $DOCKDROID_ALLLOG &
       FRAMEBUFFERPID=$!
       disown

       if [[ ! -d /proc/$FRAMEBUFFERPID ]]; then
           error "FAILED to start the Frame Buffer"
           return $FAILED
       fi
       sleep 3
       export DISPLAY=$display
}

function check_session_status()
{
    TIMEOUT=0
    while true; do
        if [[ -S $SOCKETDIR/$INSTANCE/sockets/qemu_pipe ]] &&
           [[ -S $SOCKETDIR/$INSTANCE/sockets/opvmi_bridge ]] &&
           [[ -S $SOCKETDIR/$INSTANCE/input/event0 ]] &&
           [[ -S $SOCKETDIR/$INSTANCE/input/event1 ]] &&
           [[ -S $SOCKETDIR/$INSTANCE/input/event2 ]]; then
            break
        else
            if [[ $TIMEOUT -gt 20 ]]; then
                error "FAILED: Timed out waiting for sockets"
                return $FAILED
            else
                debug "Not all sockets are present - zzzz!"
                sleep 1
                TIMEOUT=$(($TIMEOUT+1))
            fi
        fi
    done
}

function start_session_manager()
{
    out "STARTING Session Manager"

    ps aux | grep -v grep | grep "$SESSIONMANAGER" | grep "run-multiple=$INSTANCE:$INSTANCENUM"  > /dev/null
    if [[ $? -eq 0 ]]; then
        OUT=`ps aux | grep -v grep | grep "$SESSIONMANAGER" | grep "$INSTANCE:$INSTANCENUM"`
        out $OUT
        warning "$INSTANCE:$INSTANCENUM is already running"
        return
    fi
    adbport=$(($INSTANCENUM + 20000))

    cmd="$SESSIONMANAGER --run-multiple=$INSTANCE:$INSTANCENUM --standalone --experimental --software-rendering  --single-window --window-size=540,960 --no-touch-emulation"
    debug $cmd

    sleep 3
   # $cmd &
    $cmd &>> $DOCKDROID_ALLLOG &
    SESSIONMANAGERPID=$!
    disown

    TIMEOUT=0
    while true; do
        ps -h $SESSIONMANAGERPID > /dev/null
        if [[ $? -gt 0 ]]; then
            if [[ $TIMEOUT -gt 2 ]]; then
                warning "FAILED to start the Session Manager"
                return $FAILED
            else
                TIMEOUT=$(($TIMEOUT+1))
            fi
            sleep 2
        else
            break
        fi
    done
}

function start_vnc_server()
{
    out "STARTING VNC Server"

    ps aux | grep -v grep | grep "x11vnc" | grep "display :$INSTANCENUM"  > /dev/null
    if [[ $? -eq 0 ]]; then
        OUT=`ps aux | grep -v grep | grep "x11vnc" | grep "display :$INSTANCENUM"`
        out $OUT
        warning "x11vnc display:$INSTANCENUM is already running"
        return
    fi

    cmd="x11vnc -display $DISPLAY -N -forever -shared -reopen  -desktop $INSTANCE -bg"

    debug $cmd

    # VNC is too noisy to have in the debug log
    $cmd -q &> /dev/null

    if [[ $? -ne 0 ]]; then
        error "FAILED to start the VNC Server"
        return $FAILED
    fi
}

function start_vnc_server1()
{
	out "STARTING VNC Server"

	ps aux | grep -v grep | grep -w "x11vnc" | grep -w "display :$ANDROID_IDX"  > /dev/null
	if [[ $? -eq 0 ]]; then
		warning "x11vnc display:$ANDROID_IDX is already running"
		return
	fi

	rm -rf /tmp/.X11-unix/X$ANDROID_IDX &> /dev/null
	rm -rf /tmp/.X$ANDROID_IDX-lock &> /dev/null

	cmd="x11vnc -display :$ANDROID_IDX -rfbport $X11VNC_PORT -forever -shared -reopen -desktop $ANDROID_NAME -bg"
	$cmd -q &> /dev/null
	if [[ $? -ne 0 ]]; then
		error "FAILED to start the VNC Server"
	fi
}

function configure_networking()
{
    unique_ip=$INSTANCENUM
    unique_ip=$(($unique_ip + 1))

    quotient=$(($unique_ip / 254))
    remainder=$(($unique_ip % 254))
    final_ip=172.17.$quotient.$remainder

    out "CREATING network configuration (using $final_ip)"

    mkdir -p $BINDMOUNTDIR/$INSTANCE/data/misc/ethernet

    cmd="$OPENVMI generate-ip-config --ip=$final_ip --cidr=16 --gateway=172.17.0.1 --dns=8.8.8.8 --ipcfg=$(pwd)/ipconfig.txt"
    debug $cmd

    $cmd
    if [[ $? -ne 0 ]]; then
        warning "FAILED to configure Networking"
        return $FAILED
    fi

    mv ipconfig.txt $BINDMOUNTDIR/$INSTANCE/data/misc/ethernet
}

function start_docker()
{
    out "STARTING Docker container"

    docker ps -a | grep $INSTANCE$ > /dev/null
    if [[ $? -eq 0 ]]; then
        OUT=`docker ps -a | grep $INSTANCE$`
        out $OUT
        warning "docker containera:$INSTANCE is already running"
        return
    fi

    cmd="docker run -d -it \
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
        --name $INSTANCE \
        -e PATH=/system/bin:/system/xbin \
        -e ANDROID_DATA=/data            \
        --device=$BINDERNODE:/dev/binder:rwm \
        --device=$ASHMEMNODE:/dev/ashmem:rwm \
        --device=$ENCODERNODE:/dev/enc_fb:rwm \
        --device=/dev/fuse:/dev/fuse:rwm \
        --volume=$SOCKETDIR/$INSTANCE/sockets/qemu_pipe:/dev/qemu_pipe \
        --volume=$SOCKETDIR/$INSTANCE/sockets/opvmi_bridge:/dev/opvmi_bridge:rw \
        --volume=$SOCKETDIR/$INSTANCE/input/event0:/dev/input/event0:rw \
        --volume=$SOCKETDIR/$INSTANCE/input/event1:/dev/input/event1:rw \
        --volume=$SOCKETDIR/$INSTANCE/input/event2:/dev/input/event2:rw \
        --volume=$BINDMOUNTDIR/$INSTANCE/cache:/cache:rw \
        --volume=$BINDMOUNTDIR/$INSTANCE/data:/data:rw \
        android /openvmi-init.sh"

    debug $cmd

    $cmd &>> $DOCKDROID_ALLLOG
    if [[ $? -ne 0 ]]; then
        error "FAILED to start the Docker Container"
        return $FAILED
    fi

}

function start()
{
    DIR=/opt/openvmi/libs/
    export SWIFTSHADER_PATH=$DIR/libswiftshader
    export TRANSLATORS_PATH=$DIR/libtranslator/
    export DOCKDROID_LOG_LEVEL=$DOCKDROID_LOG_LEVEL
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TRANSLATORS_PATH:$DIR/libangle/:$DIR/libffmpeg/:$DIR/libencturbo/:$DIR/libastc-codes
    export RUNTIME_SOCKET_DIR=$RUNTIME_SOCKET_DIR
    export MESA_GL_VERSION_OVERRIDE=4.3

    # Raise system resource limits - required for many containers
    echo $LINUX_PASSWORD | sudo -S sysctl -w fs.inotify.max_user_instances=8192 > /dev/null
    echo $LINUX_PASSWORD | sudo -S sysctl -w fs.file-max=1000000 > /dev/null
    echo $LINUX_PASSWORD | sudo -S sysctl -w kernel.shmmni=24576 > /dev/null
    echo $LINUX_PASSWORD | sudo -S sysctl -w kernel.pid_max=4119481 > /dev/null

    ulimit -n 4096
    ulimit -s unlimited

    # Enable core dumps
    ulimit -c unlimited

    start_binder_ashmem_encoder
    if [[ $? -eq $FAILED ]]; then
        return $FAILED
    fi

    start_framebuffer
    if [[ $? -eq $FAILED ]]; then
        return $FAILED
    fi

    start_session_manager
    if [[ $? -eq $FAILED ]]; then
        return $FAILED
    fi

    configure_networking
    if [[ $? -eq $FAILED ]]; then
        return $FAILED
    fi

    start_docker
    if [[ $? -eq $FAILED ]]; then
        return $FAILED
    fi
}

function stop()
{
    # Stop VNC Server
#   PID=$(ps aux | grep x11vnc | grep "display.*:$INSTANCENUM " | column -t | cut -d$' ' -f3)
#    if [[ "$PID" != "" ]]; then
#        out "STOPPING VNC Server ($PID)"
#        echo $LINUX_PASSWORD | sudo -S kill -INT $PID
#    else
#        warning "NOT stopping VNC Server, it's not running"
#    fi

    # Stop Session Manager
    PID=$(ps aux | grep session-manager | grep "$INSTANCE:$INSTANCENUM \|$INSTANCE:$INSTANCENUM$" | column -t | cut -d$' ' -f3)
    if [[ "$PID" != "" ]]; then
        out "STOPPING Session Manager ($PID)"
        if [[ "$PERF" == "true" ]]; then
            kill -INT $PID
        else
            kill -9 $PID
        fi
    else
        warning "NOT stopping Session Manager, it's not running"
    fi

    # echo $LINUX_PASSWORD | sudo -S rm -rf $XDG_RUNTIME_DIR/$INSTANCE
    echo $LINUX_PASSWORD | sudo -S rm -rf $SOCKETDIR/$INSTANCE
    echo $LINUX_PASSWORD | sudo -S rm -rf $BINDMOUNTDIR/$INSTANCE

    # Stop Frame Buffer
    PID=$(ps aux | grep Xvfb | grep "Xvfb[[:space:]]*:$INSTANCENUM " | column -t | cut -d$' ' -f3)
    if [[ "$PID" != "" ]]; then
        out "STOPPING Frame Buffer ($PID)"
        echo $LINUX_PASSWORD | sudo -S kill -9 $PID
    else
        warning "NOT stopping Frame Buffer, it's not running"
    fi

    rm -f /tmp/.X$INSTANCENUM-lock

    # Remove unattached shared memory (VNC does not free it properly)
    IDS=`ipcs -m | grep '^0x' | grep $USER | awk '{print $2, $6}' | grep ' 0$' | awk '{print $1}'`
    for id in $IDS; do
        ipcrm shm $id &> /dev/null
    done

    # Stop and remove Docker
    docker ps -a | grep $INSTANCE$ > /dev/null
    if [[ $? -eq 0 ]]; then
        out "STOPPING Docker ($INSTANCE)"
        docker rm -f $INSTANCE &>> $DOCKDROID_ALLLOG
        if [[ $? -ne 0 ]]; then
            error "FAILED to remove Docker container"
        fi
    else
        warning "NOT stopping Docker, it's not running"
    fi

    # remove log
    rm $DOCKDROID_LOG_DIR/$INSTANCE -rf
}

main ()
{
    if [[ $# < 3 && $1 != "start" && $1 != "stop" ]]; then
        echo "usage: $0 start|stop <name> <idx>(1-$SUPPORTEDINSTANCES)"
        return $FAILED
    fi

    INSTANCE=$2
    INSTANCENUM=$3

    if [[ "$DOCKDROID_ALLLOG" == "" ]]; then
        DOCKDROID_ALLLOG=$DOCKDROID_LOG_DIR/$INSTANCE/$(date +%F-%H%p)
        mkdir -p $DOCKDROID_LOG_DIR/$INSTANCE
    fi

    if [[ $INSTANCENUM -gt $SUPPORTEDINSTANCES ]] || [[ $INSTANCENUM -lt 1 ]]; then
        error "Instance should be between 1 and $SUPPORTEDINSTANCES ($INSTANCENUM)"
        return $FAILED
    fi

    # Ensure we have current sudo privileges
    if [[ $EUID -ne 0 ]]; then
        out $LINUX_PASSWORD | sudo -S ls > /dev/null
    fi

    if [[ $1 == "start" ]]; then
        out "Attempting to start instance $INSTANCE"
        start
    elif  [[ $1 == "stop" ]]; then
        out "Attempting to stop instance $INSTANCE"
        stop
    fi

    return $?
}

main $@
exit $?
