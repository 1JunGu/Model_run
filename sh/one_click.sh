#!/bin/bash
#########################################################################
# This script setup SW-MPAS runs
#
# Jun Gu, gj99@mail.ustc.edu.cn; 22-Jun-2021
#
# History:
# version 1.0 08-Mar-2023
    # version 1.1 13-Mar-2023 one_click version, restart version to be done
#########################################################################
function check_sfc(){
    sfc_name="./input/surface_update.nc"
    sfc_flag=$(grep -nir "Finished running the init_atmosphere core" ./sfc.init_atmosphere.*.out)

    if [[ -n ${sfc_flag} && -e ${sfc_name} ]];then
        sfc_success=0
    else
        sfc_success=1
    fi
}

function check_init(){
    outfi_dir="./input/init_final"
    init_flag=$(grep -nir "Finished running the init_atmosphere core" ./log.init_atmosphere.*.out)

    if [[ -n ${init_flag} && -d ${outfi_dir} && -e ${outfi_dir/0.nc} ]];then
    #if [[ -n ${init_flag} && -d ${outfi_dir}  ]];then
        init_success=0
    else
        init_success=1
    fi
}
if [ $# -lt 1 ]; then
        TARGET="first"
    else
        TARGET="$@"
fi

echo "***************************"
echo "One click shell"
#exp configuration
export QUEUE_NAME=q_share
export start_time='2020-06-10_00:00:00'
export stop_time='2020-07-10_00:00:00'
export run_duration="\'30_00:00:00\'"
#if restart please not use this script
##&restart(checkpoint)
export do_restart=false

exp_name=${PWD#*2020_Kyushu/}
export exp_name=${exp_name////.}

read -p "Available resolution for run atmosphere:
        [1]uniform 3km
        [2]variable 3km_25N127E
        [3]variable 4km_28N117E
        [4]uniform 60km
        [5]uniform 15km
        Please select resolution: " option
export option_1=${option}

if [[ ${TARGET} = "first" ]];then
    ##surface
    export namelist="namelist.init_atmosphere_sfc"
    export JOB_NAME=sfc.${exp_name}
    ./run_surface.sh
    sfc_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset namelist
    unset JOB_NAME
    #
    ##final
    export namelist="namelist.init_atmosphere_final"
    export JOB_NAME=init.${exp_name}
    ./run_init.sh
    init_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset namelist
    unset JOB_NAME
    #
    check_init
    check_sfc
    echo "sfc success? ${sfc_success}"
    echo "init success? ${init_success}"
    #check per 10 s
    while [[ ${init_success} -ne 0 || ${sfc_success} -ne 0 ]];do
        sleep 30
        echo "Waiting ....."
        check_init
        check_sfc
    done
    #until [[ ${init_success} -eq 0 && ${sfc_success} -eq 0 ]];do
    #    sleep 5
    #    echo "....."
    #    check_init
    #    check_sfc
    #done
    echo "sfc success? ${sfc_success}"
    echo "init success? ${init_success}"

    ##atmosphere
    export JOB_NAME=atm.${exp_name}
    ./run_atmosphere.sh
    atm_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset JOB_NAME
elif [[ $TARGET != "first" && $TARGET = "atm" ]];then
    ##atmosphere
    export JOB_NAME=atm.${exp_name}
    ./run_atmosphere.sh
    atm_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset JOB_NAME
elif [[ $TARGET != "first" && $TARGET = "sfc" ]];then
    ##surface
    export namelist="namelist.init_atmosphere_sfc"
    export JOB_NAME=sfc.${exp_name}
    ./run_surface.sh
    sfc_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset namelist
    unset JOB_NAME
elif [[ $TARGET != "first" && $TARGET != "atm" && $TARGET = "init" ]];then
    ##final
    export namelist="namelist.init_atmosphere_final"
    export JOB_NAME=init.${exp_name}
    ./run_init.sh
    init_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset namelist
    unset JOB_NAME

    check_init
    echo "init success? ${init_success}"
    while [[ ${init_success} -ne 0 ]];do
        sleep 60
        echo "Waiting ....."
        check_init
    done
    echo "init success? ${init_success}"

    ##atmosphere
    export JOB_NAME=atm.${exp_name}
    ./run_atmosphere.sh
    atm_jobid=$(bjobs -J ${JOB_NAME}|tail -n 1|awk '{print $1}')
    unset JOB_NAME
fi
