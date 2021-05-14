#!/bin/bash

# 该脚本为项目空间清理脚本
# 作者：hz Liang
# 创建时间：2019年8月10日
# 最后修改时间：2019年8月13日18:12:41

# 1. 检查硬盘空间，获取存储空间使用率;
# 2. 若存储空间不足，清理程序运行过程中产生的文件及文件夹;
# 3. 若程序运行日志文件过大，自动清空日志文件;

# 可设置项为：
# 1. DEVICE: 		需要监控的硬盘，格式如：/dev/sdb1，linux下可用`df -h`获取；
# 2. Maindir: 		程序主目录，格式如：/home/zzz/0714/；
# 3. DIR:		    检测目录
# 4. dayago:        设置天数，格式为数字，如：3；
# 5. std_percent:	设定的使用率阈值，格式如：50
# 6. size: 	        日志文件大小阈值，格式如：20M，10k，1G


DEVICE=/dev/sdb1                        #检测硬盘
Maindir=/home/user/xxx/                 #主目录
DIR=$Maindir'targetFolder/'        #监测文件夹
dayago=2                                #设定删除(n+1)天前的文件夹
std_percent=50                          #磁盘使用率的设定阈值，根据需求设定
size=20M                                #日志文件大小阈值：MB(M),kb(k),GB(G)

#相关函数定义
# 函数1：获取所检测硬盘信息
devinformation(){
    local total=`df -hl | grep $1 | awk '{print $2}'`
    local used=`df -hl | grep $1 | awk '{print $3}'`
    #used_percent=`df -hl | grep $1 | awk '{print $5}'`
    local var_used=`echo | awk "{print $used}"`
    local var_total=`echo | awk "{print $total}"`
    used_percent=`echo | awk "{print int(($var_used/$var_total)*100)+1}"`    #向上取整
    echo '\t所检测磁盘为:\t'$1
    echo '\t已占用容量:\t'$used'/'$total
    echo '\t当前使用率为:\t'$used_percent'%'
}

# 函数2：查询所检测文件夹，删除设定时间以前的文件夹
delete_file_dir(){
    cd $1
    # 创建临时变量储存文件夹数目
    local num_dir_total=`find ./ -type d -name "*_*" | wc -l`
    local num_dir=`find ./ -type d -name "*_*" -mtime +$2 | wc -l`
    #num_dir_total=`expr $num_dir_total - 1`
    
    if [ $num_dir -gt 0 ]
    then
        echo "\t目标目录下共含有"$num_dir_total"个文件夹；其中"$2"天前的文件夹共"$num_dir"个:"

        # 列出名称包含"_"并且创建时间大于$2天的文件夹。
        for file in `find ./ -type d -name "*_*" -mtime +$2`
        do
            echo '\t\t'$file
        done

        # 执行删除命令
        find ./ -type d -name "*_*" -mtime +$2 -exec rm -rf {} \; 2>/dev/null
        echo "\t已删除以上文件夹！"
    else
        echo "\t目标目录下共含有"$num_dir_total"个文件夹，不存在"$2"天前的文件夹;"
        echo "\t不执行操作，退出！"
    fi
}

# 函数3：删除过大的日志文件
delete_logfile(){
    cd $1
    local num_log_total=`find ./ -type f -name "*log.txt*" | wc -l`
    local num_log=`find ./ -type f -name "*log.txt*" -size +$2 | wc -l`
    
    if [ $num_log -gt 0 ]
    then
        echo "\t目标目录下共含有"$num_log_total"个日志文件；其中文件大小大于"$2"的日志文件共"$num_log"个:"

        for file in `find ./ -type f -name "*log.txt*" -size +$2`
        do
            echo '\t\t'$file
        done
        find ./ -type f -name "*log.txt*" -size +$2 -exec truncate -s 0 {} \; 2>/dev/null
        echo "\t已清空以上日志！"
    else
        echo "\t目标目录下共含有"$num_log_total"个日志文件，文件大小均小于"$2";"
        echo "\t不执行操作，退出！"
    fi
}

echo '\n---------------------------------------------------\n'
echo `date "+启动时间：%Y/%m/%d %H:%M:%S"`
echo '[Step 0]: 脚本配置'
echo "\t检测硬盘：\t\t"$DEVICE
echo "\t硬盘使用率阈值：\t"$std_percent"%"
echo "\t检测目标文件夹：\t"$DIR
echo "\t执行删除操作时间：\t"$dayago"天之前文件"


echo '[Step 1]: 检测硬盘'`date "+\t\t\t[%H:%M:%S]"`
if [ ! -e $DEVICE ]
then
    echo "\t设备"$DEVICE"不存在，请检查设置，已退出程序！"
    echo `date "+结束时间：%Y/%m/%d %H:%M:%S"`
    exit 0
else
    devinformation $DEVICE
fi


echo '[Step 2]: 检查日志文件大小'`date "+\t\t[%H:%M:%S]"`
if [ ! -d $Maindir ]
then
    echo "目标文件夹"$Maindir"不存在，请检查设置，已退出程序！"
    echo `date "+结束时间：%Y/%m/%d %H:%M:%S"`
    exit 0
else
    delete_logfile $Maindir $size
fi


echo '[Step 3]: 检测目标文件夹'`date "+\t\t[%H:%M:%S]"`
if [ ! -d $DIR ]
then
    echo "目标文件夹"$DIR"不存在，请检查设置，已退出程序！"
else
    if [ $used_percent -gt $std_percent ]
    then
        echo "\t硬盘使用率:"$used_percent"% > 设定阈值:"$std_percent"%"
        delete_file_dir $DIR $dayago
    else
        echo "\t硬盘使用率:"$used_percent"% < 设定阈值:"$std_percent"%"
        echo "\t不执行操作，退出！"
    fi
fi


echo `date "+结束时间：%Y/%m/%d %H:%M:%S"`
exit 0
