#!/bin/bash
#########################################################################
# This script setup SW-MPAS runs
#
# Jun Gu, gj99@mail.ustc.edu.cn; 22-Jun-2021
#
# History:
# version 1.0 08-Mar-2023
#########################################################################
echo "***************************"
echo "For surface_update.nc"

#start_time='2015-08-22_12:00:00'
#stop_time='2015-08-23_12:00:00'
#QUEUE_NAME=q_share
#namelist="namelist.init_atmosphere_sfc"
#read -p "Available resolution for surface PIO select:
#        [1]uniform 3km
#        [2]variable 3km_25N127E
#        [3]variable 4km_28N117E
#        [4]uniform 60km
#        Please select resolution: " option_1

##&io
if [ $option_1 -eq 1 ];then
    echo "selected resolution: [1]uniform 3km"
    #u3km 12000
    num_io_task=400
    io_stride=30
    num_proc=12000
elif [ $option_1 -eq 2 ];then
    echo "selected resolution: [2]variable 3km_25N127E"
    #v3km 3000
    num_io_task=40
    io_stride=30
    num_proc=1200
elif [ $option_1 -eq 3 ];then
    echo "selected resolution: [3]variable 4km_28N117E"
    #v4km 1200
    num_io_task=40
    io_stride=30
    num_proc=1200
elif [ $option_1 -eq 4 ];then
    echo "selected resolution: [4]uniform 60km"
    #u60km 300
    num_io_task=10
    io_stride=30
    num_proc=300
elif [ $option_1 -eq 5 ];then
    echo "selected resolution: [5]uniform 15km"
    #u60km 300
    num_io_task=32
    io_stride=30
    num_proc=960
else
    echo "Wrong Number! "
    exit 1
fi

local_num_io_task=1
local_io_stride=${io_stride}


###########################################
#              PROGRAM START              #
###########################################
var=`expr $num_io_task \* $io_stride`
if [ $var -gt $num_proc  ] ;then
    echo "io_task and io_stride set error"
    exit 1
fi

echo "*****start_time "${start_time}

#important check start_time
sed -i "/config_start_time/ c\    config_start_time = ${start_time}" ${namelist}
sed -i "/config_stop_time/ c\    config_stop_time = ${stop_time}" ${namelist}
sed -i "/config_pio_num_iotasks/ c\    config_pio_num_iotasks = ${num_io_task}" ${namelist}
sed -i "/config_pio_stride/ c\    config_pio_stride = ${io_stride}" ${namelist}
sed -i "/config_pio_local_num_iotasks/ c\config_pio_local_num_iotasks = ${local_num_io_task}" ${namelist}
sed -i "/config_pio_local_stride/ c\config_pio_local_stride = ${local_io_stride}" ${namelist}



OUT_FILE=out.${exp_name}.${num_proc}.sfc
rm -rf $OUT_FILE

#EXE=$HOME/jungu/MPAS/model/mpas-sw-MPE/init_atmosphere_model ##surface_update
EXE="$MPAS/model/MPAS_SW/mpas_init/mpas-sw-chem-seasalt-debug/init_atmosphere_model_O2_box_sfc -n ${namelist}"


echo bsub -J ${JOB_NAME} -b -o ${OUT_FILE} -pr -q ${QUEUE_NAME} \
    -n ${num_proc} -np 6 -cgsp 64 -share_size 13500 \
    -host_stack 2148 -cache_size 32 \
    ${EXE}
bsub -J ${JOB_NAME} -b -o ${OUT_FILE} -pr -q ${QUEUE_NAME} \
    -n ${num_proc} -np 6 -cgsp 64 -share_size 13500 \
    -host_stack 2148 -cache_size 32 \
    ${EXE}
