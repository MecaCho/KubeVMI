+ FAILED=255
+ WORKDIR=/openvmi
+ INIT_QUEUE_FILE=/openvmi/init.queue
+ DATA_DIR=/openvmi/data/virtualmobilephone-sample
+ INIT_CFG_FILE=/openvmi/data/virtualmobilephone-sample/init_cfg
+ INIT_STATUS_FILE=/openvmi/data/virtualmobilephone-sample/init_status
+ '[' '!' -d /openvmi/data/virtualmobilephone-sample ]
+ touch /openvmi/data/virtualmobilephone-sample/init_cfg
+ echo -n 
+ echo androidName:virtualmobilephone-sample
+ echo androidIdx:
+ echo vncPort:5400
+ echo adbPort:5200
+ echo binderIdx:
+ echo screenWidth:720
+ echo screenHeight:1080
+ ifconfig eth0
+ grep 'inet addr'
+ cut -f 2 -d :
+ cut -f 1 -d ' '
+ echo ipAddr:10.244.0.18
+ ifconfig
+ grep inet
+ sed -n 1p
+ awk '{print $4}'
+ awk -F : '{print $2}'
+ echo netmask:255.255.255.0
+ echo -n 
+ echo virtualmobilephone-sample
+ true
+ '[' '!' -s /openvmi/data/virtualmobilephone-sample/init_status ]
+ sleep 3
+ continue
+ true
+ '[' '!' -s /openvmi/data/virtualmobilephone-sample/init_status ]
+ cat /openvmi/data/virtualmobilephone-sample/init_status
+ status=255
+ '[' 255 '=' 0 ]
+ init_failed
+ '[' '!=' 0 ]
sh: 0: unknown operand
+ sleep 3
+ true
+ '[' '!' -s /openvmi/data/virtualmobilephone-sample/init_status ]
+ cat /openvmi/data/virtualmobilephone-sample/init_status
+ status=255
+ '[' 255 '=' 0 ]
+ init_failed
+ '[' '!=' 0 ]
sh: 0: unknown operand