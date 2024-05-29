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
echo "Run atmosphere_model"

#QUEUE_NAME=q_share
#start_time='2021-09-10_00:00:00'
#run_duration="\'00_12:00:00\'"
##&restart(checkpoint)
#do_restart=false

#read -p "Available resolution for run atmosphere:
#        [1]uniform 3km
#        [2]variable 3km_25N127E
#        [3]variable 4km_28N117E
#        [4]uniform 60km
#        Please select resolution: " option_1

##&io
if [ $option_1 -eq 1 ];then
    echo "selected resolution: [1]uniform 3km"
    config_dt=15
    len_disp=3000.0 
    apvm_upwinding=0.0 # the default value is 0.5, this may only need to be changed to 0 for extreme high resolution, such as 3-15km, 4-32km meshes 
    #u3km 60000
    num_io_task=2000
    io_stride=30
    num_proc=60000
    rstfq=24:00:00 #restart frequency in hours #hardcoding in stream files
elif [ $option_1 -eq 2 ];then
    echo "selected resolution: [2]variable 3km_25N127E"
    len_disp=2000.0 
    config_dt=10
    apvm_upwinding=0.0 # the default value is 0.5, this may only need to be changed to 0 for extreme high resolution, such as 3-15km, 4-32km meshes 
    #v3km 3000
    num_io_task=200
    io_stride=30
    num_proc=6000
    rstfq=48:00:00
elif [ $option_1 -eq 3 ];then
    echo "selected resolution: [3]variable 4km_28N117E"
    config_dt=20
    len_disp=4000.0 
    apvm_upwinding=0.0
    #v4km 3000
    num_io_task=100
    io_stride=30
    num_proc=3000
    rstfq=48:00:00
elif [ $option_1 -eq 4 ];then
    echo "selected resolution: [4]uniform 60km"
    config_dt=100
    apvm_upwinding=0.5
    len_disp=60000.0
    #u60km 1200
    num_io_task=40
    io_stride=30
    num_proc=1200
    rstfq=120:00:00
elif [ $option_1 -eq 5 ];then
    echo "selected resolution: [5]uniform 15km"
    config_dt=75
    len_disp=15000.0 
    apvm_upwinding=0.5
    #u15km 3840
    num_io_task=64
    io_stride=60
    num_proc=3840
    rstfq=48:00:00
else
    echo "Wrong Number! "
    exit 1
fi

local_num_io_task=1
local_io_stride=$io_stride


###########################################
#              PROGRAM START              #
###########################################
echo ${do_restart}
if [ ${do_restart} != 'true' ];then
    echo "no restart"
elif [ ${do_restart} = 'true' ];then
    read -p "Are you sure for restart? y or n" option
    if [ $option = "n" ];then
        echo "please re run this script!"
        exit 1;
    elif [ $option = "y" ];then
        echo "Yes restart!"
    else
        echo "Wrong input"
        exit 2
    fi
fi
#check num_proc .ge. num_io_task*io_stride
var=`expr $num_io_task \* $io_stride`
if [ $var -gt $num_proc  ] ;then
    echo "io_task and io_stride set error"
    exit 1
fi
#namelist.atmosphere
sed -i "/config_dt/ c\config_dt = ${config_dt}" namelist.atmosphere
sed -i "/config_len_disp/ c\config_len_disp = ${len_disp}" namelist.atmosphere
sed -i "/config_apvm_upwinding/ c\config_apvm_upwinding = ${apvm_upwinding}" namelist.atmosphere
sed -i "/config_start_time/ c\config_start_time = ${start_time}" namelist.atmosphere
sed -i "/config_run_duration/ c\config_run_duration = ${run_duration}" namelist.atmosphere
sed -i "/config_do_restart/ c\config_do_restart = ${do_restart}" namelist.atmosphere


sed -i "/config_pio_num_iotasks/ c\config_pio_num_iotasks = ${num_io_task}" namelist.atmosphere
sed -i "/config_pio_stride/ c\config_pio_stride = ${io_stride}" namelist.atmosphere
sed -i "/config_pio_local_num_iotasks/ c\config_pio_local_num_iotasks = ${local_num_io_task}" namelist.atmosphere
sed -i "/config_pio_local_stride/ c\config_pio_local_stride = ${local_io_stride}" namelist.atmosphere


##streams.atmosphere
sed -i "/restart/, /output_interval/ s/[0-9][0-9]:[0-6][0-9]:[0-6][0-9]/${rstfq}/" streams.atmosphere

if [ -e ./input/surface_update.nc -a  -d ./input/init_final ]
then
    echo "sfc period:"
    echo "{"
    xtime ./input/surface_update.nc |grep -A 1 "xtime ="
    echo "......"
    xtime ./input/surface_update.nc |grep -B 1 "}"
    echo "init_final initial time:"
    xtime ./input/init_final/0.nc  |grep -A 1 "xtime ="
    if [[ $do_restart = true ]]; then
        echo "checkpoint time:"
        echo $start_time
    fi
    #sed -n "/config_start_time/p" namelist.atmosphere
    echo "***************************"
else
    echo "!!surface_update.nc or init_final NOT Exist!!"
    echo "***************************"
    exit 1
fi

#exp_name=${PWD#*TCs/}

#JOB_NAME=atm.${exp_name////.}.${num_proc}

OUT_FILE=out.${exp_name}.${num_proc}.atm
rm -rf $OUT_FILE

#EXE=$HOME/haoxiaoyu/MPAS/source/mpas-sw-chem-seasalt-O3/atmosphere_model
EXE=$HOME/jungu/MPAS/model/OK/mpas-sw-chem-seasalt-O3/atmosphere_model

echo bsub -J ${JOB_NAME} -b -o ${OUT_FILE} -pr -q ${QUEUE_NAME} \
    -n ${num_proc} -np 6 -cgsp 64 -share_size 13500 \
    -host_stack 2148 -cache_size 32 \
    ${EXE}
bsub -J ${JOB_NAME} -b -o ${OUT_FILE} -pr -q ${QUEUE_NAME} \
    -n ${num_proc} -np 6 -cgsp 64 -share_size 13500 \
    -host_stack 2148 -cache_size 32 \
    ${EXE}

