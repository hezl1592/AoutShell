#!/bin/bash

# 该脚本为项目程序启动脚本
# 作者：hz Liang
# 创建时间：2019年6月25日
# 最后修改时间：2019年8月13日18:12:41

# 1. 检查IP是否畅通;
# 2. 后台启动主程序;
# 3. 后台启动CAN程序;
# 4. 后台启动守护程序;
# 5. 后台启动一次文件清理程序;

# 可设置项为：
# 1. DETEC_IP: 		摄像机IP;
# 2. Timeout: 		Ping超时时间[单位：s];
# 3. DIR:		    程序所在目录;
# 4. LogDIR:        所有日志文件存放目录;
# 5. Program_name:	主程序名;
# 6. Program_Log: 	主程序日志文件;
# 7. Can_name:      CAN程序名;
# 8. CAN_Log: 		CAN程序日志文件; 
# 9. Daemon_name:	守护程序名;
#10. Daemon_Log: 	守护程序日志文件;
#11. Clean_name:	清理脚本名;
#12. Clean_Log: 	清理脚本日志文件;

DETEC_IP=192.168.1.94
Timeout=20
DIR=/home/username/xxx/targetFolder/
LogDIR=$DIR'../0_Log/'
MainDIR=$DIR'../'
Program_name=v1.1.0720
Can_name=emuc_64
Daemon_name=daemonv1.1
Clean_name=auto_clean.sh
Program_Log=$LogDIR'main_log.txt'
CAN_Log=$LogDIR'CAN_log.txt'
Daemon_Log=$LogDIR'Daemon_log.txt'
Clean_Log=$LogDIR'Clean_log.txt'

if [ ! -d $DIR ]
then
	echo '文件夹不存在，退出程序，请检查目录：' $DIR
	exit 0
fi

if [ ! -d $LogDIR ]
then
	echo '日志文件夹不存在，创建文件夹：' $LogDIR
	mkdir $LogDIR	
fi

echo '\n---------------------------------------------------\n'
echo `date "+启动时间：%Y/%m/%d %H:%M:%S"`
echo '当前目录：' `pwd`

#第一阶段，检查IP
echo "[Step 1]: 检查摄像机IP是否畅通，IP：" $DETEC_IP
starttime=`date '+%s'`

while true
do
	if ping -c 3 $DETEC_IP > /dev/null 2>&1
	then
		echo `date "+\t[%H:%M:%S]:"` "Successfully connect to" $DETEC_IP
		break
	else
		nowtime=`date '+%s'`		
		time_gap=$((nowtime-starttime))

		if [ $time_gap -gt $Timeout ]
		then
			echo `date "+\t[%H:%M:%S]:"` "连接超时，请检查IP, 退出程序."
			exit 0
		else
			echo `date "+\t[%H:%M:%S]:"` "Uable to connect to" $DETEC_IP ", ping again!"
			sleep 1
		fi
	fi
done
echo `date "+\t[%H:%M:%S]:"` "检测摄像机IP过程完毕"

#第2阶段，运行清理脚本
echo "[Step 2]: 运行清理脚本."
echo `date "+\t[%H:%M:%S]:"` "切换目录至:" $MainDIR
cd $MainDIR

if [ -f $Clean_name ]
then
	nohup sh ./$Clean_name >>$Clean_Log 2>&1 &
	echo `date "+\t[%H:%M:%S]:"` '已后台运行文件清理脚本：' $Clean_name
else
	echo `date "+\t[%H:%M:%S]:"` '文件清理脚本不存在，请检查脚本名是否正确：' $Clean_name
	exit 0
fi
echo `date "+\t[%H:%M:%S]:"` "启动清理脚本过程完毕"

#第3阶段，启动程序
echo "[Step 3]: 启动程序."
echo `date "+\t[%H:%M:%S]:"` "切换目录至:" $DIR
cd $DIR
if [ -f $Program_name ]
then
	nohup ./$Program_name >>$Program_Log 2>&1 &
	echo `date "+\t[%H:%M:%S]:"` '已后台运行主程序：' $Program_name
else
	echo `date "+\t[%H:%M:%S]:"` '程序不存在，请检查程序名是否正确：' $Program_name
	exit 0
fi

sleep 2

if [ -d Sample_EMUC2 ]
then
	cd Sample_EMUC2
	if [ -f emuc_64 ]
	then
		nohup ./emuc_64 ../temp >>$CAN_Log 2>&1 &
		echo `date "+\t[%H:%M:%S]:"` '已后台运行CAN程序：emuc_64'
	else
		echo `date "+\t[%H:%M:%S]:"` 'CAN程序不存在，请检查.'
		exit 0
	fi
else
	echo '文件夹不存在，请检查文件夹'
	exit 0
fi
echo `date "+\t[%H:%M:%S]:"` "启动主程序、CAN程序过程完毕"

sleep 30
#第4阶段，启动守护程序
echo "[Step 4]: 启动守护程序."

echo `date "+\t[%H:%M:%S]:"` "切换目录至:" $MainDIR
cd $MainDIR
if [ -f $Daemon_name ]
then
	nohup ./$Daemon_name >>$Daemon_Log 2>&1 &
	echo `date "+\t[%H:%M:%S]:"` '已后台运行守护程序：' $Daemon_name
else
	echo `date "+\t[%H:%M:%S]:"` '守护程序不存在，请检查程序名是否正确：' $Daemon_name
	exit 0
fi
echo `date "+\t[%H:%M:%S]:"` "启动守护过程完毕"



echo `date "+结束时间：%Y/%m/%d %H:%M:%S"`
exit 0
