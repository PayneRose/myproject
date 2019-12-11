#!/bin/bash

# this scripts run in CPM Cloud Physical Machine.

. ./common.sh
#
#  for uefi boot order 

uefi_boot() {
    printlog "Bios Logs..."
    #OF=uefi.txt 
    OF="hardware.txt"
    MSG_COMPRESS="\\.gz"
    if [[ -d "/sys/firmware/efi/vars/" ]]; then 
        log_item  $OF  "UEFI_orders" '/usr/sbin/efibootmgr -v'
        log_item  $OF  "UEFI_ITEMS"  'ls -R  /boot/efi/EFI'
        echolog Done
    else
        #echo "Legacy Boot..."
        echolog Skipped
    fi 
}

# LSI raid info
lsi_raid_info () {
        # for LSI RAID
        ## 03:00.0 RAID bus controller: LSI Logic / Symbios Logic MegaRAID SAS-3 3108 [Invader] (rev 02)
        printlog "LSI RAID logs..."
        #OF="lsi.txt"
        OF="hardware.txt"
        MSG_COMPRESS="\\.gz"
        
        events="$LOG/{events.log}"
        sindown="$LOG/{sindown.log}"
        sinboot="$LOG/{sinboot.log}"
        deleted="$LOG/{deleted.log}"
        
        if lspci | grep -iq  raid; then
            if [[ -f "/usr/local/agenttools/agent/lsi/MegaCli" ]]; then 
                TOOLS="/usr/local/agenttools/agent/lsi/MegaCli"
                log_item "$OF" "Adp_Count" "$TOOLS -adpCount"
                log_item "$OF" "Adp_Info" "$TOOLS -AdpAllInfo -aALL"
                log_item "$OF" "FwTermLog" "$TOOLS -FwTermLog -Dsply -aALL"
                log_item "$OF" "PDList" "$TOOLS -PDList -aALL"
                log_item "$OF" "PDGetNum" "$TOOLS -PDGetNum -aALL"
                log_item "$OF" "EncInfo" "$TOOLS -EncInfo -aALL"
                log_item "$OF" "LDInfo" "$TOOLS -LDInfo -Lall -aALL"
                log_item "$OF" "LdPdInfo" "$TOOLS -LdPdInfo -aALL"
                log_item "$OF" "LDGetNum" "$TOOLS -LDGetNum -aALL"
                log_item "$OF" "CfgDsply" "$TOOLS -CfgDsply -aALL"
                log_item "$OF" "CfgFreeSpaceinfo" "$TOOLS -CfgFreeSpaceinfo -aALL"
                log_item "$OF" "GetEventLogInfo" "$TOOLS -AdpEventLog -GetEventLogInfo -aALL"
                log_item "$OF" "GetEvents" "$TOOLS -AdpEventLog -GetEvents -f $events -aALL"
                log_item "$OF" "cat_GetEvents" "cat $events"
                log_item "$OF" "GetSinceShutdown" "$TOOLS -AdpEventLog -GetSinceShutdown -f $sindown -aALL"
                log_item "$OF" "Event_GetSinceShutdown " "cat $sindown"
                log_item "$OF" "Cat_GetSinceReboot" "$TOOLS -AdpEventLog -GetSinceReboot -f $sinboot -aALL"
                log_item "$OF" "Event_GetSinceReboot" "cat $sinboot"
                log_item "$OF" "AdpEventLog_deleted" "$TOOLS -AdpEventLog -IncludeDeleted -f $deleted -aALL"
                log_item "$OF" "cat_AdpEventLog_deleted" "cat  $deleted"
                sync
                [[ -f "$events" ]] && rm  "$events"
                [[ -f "$sindown" ]] && rm "$sindown"
                [[ -f "$sinboot" ]] && rm "$sinboot"
                [[ -f "$deleted" ]]  && rm "$deleted"
                echolog Done
            else
                #echo "not LSI RAID Card or not install agent"
                echolog Skipped
            fi
        else
            #echo "not LSI RAID"
            echolog Skipped
       fi
 }

hba_info() {
        # for HBA  SAS3008  

        # 04:00.0 Serial Attached SCSI controller: LSI Logic / Symbios Logic SAS3008 PCI-Express Fusion-MPT SAS-3 (rev 02)
        printlog "HBA logs..."
        #OF="sashba.txt"
        OF="hardware.txt"
        MSG_COMPRESS="\\.gz"
        if lspci | grep -iq "SAS3008" ;then 
            echo "HBA SAS3008 crards"
            if [[ -f "/usr/local/agenttools/agent/plugins/sas3rcu" ]]; then
                unset sas3rcu
                local sas3rcu="/usr/local/agenttools/agent/plugins/sas3rcu"
                local adpCnt=`$sas3ircu LIST | grep "SAS3008" | grep -v "Adapter" | wc -l`

                for((adpNum=0;adpNum<adpCnt;adpNum++));do 
                    log_item  "$OF" "SAS3IRCU_DISPLAY"  "${sas3ircu} $adpNum display" 
                    #log_cmd $OF "${sas3flash} -c $adpNum -list" 
                    log_item "$OF" "SAS3IRCU_STATUS"  "${sas3ircu}  $adpNum status" 
                    #log_cmd $OF "${sas3ircu}  $adpNum logir upload"   
                done
                echolog Done
             fi
        else
            #echo "not HBA or not find  sas3rcu" 
            echolog Skipped
       fi 
}

hpsa_raid_info() {
        # assumes that hpssacli was already installed in the OS
        printlog "HPSA Logs..."
        #OF="hpsa.txt"
        OF="hardware.txt"
        MSG_COMPRESS="\\.gz"
        if  dmidecode -s system-product-name | grep -v '^#' | grep -wq ProLiant ; then
            # echolog "HP or HPE Server"
            log_cmd $OF "dmidecode -s system-product-name | grep -v '^#'"
            log_cmd $OF "dmidecode -s system-serial-number | grep -v '^#'"
            if [[ -f "/usr/sbin/hpssacli" ]] ; then 
                hpcmd="/usr/sbin/hpssacli"
            elif [[ -z "$hpcmd" && -f "/usr/local/agenttools/agent/hp/hpacucli" ]] ; then 
                hpcmd="/usr/local/agenttools/agent/hp/hpacucli" 
                log_item $OF "Ctrl_Config_Detail"   "$hpcmd ctrl all show config detail"
                [[ -f "adureport.zip" ]] && rm "adureport.zip"
                log_item "$OF" "ADU_REPORT" "$hpcmd ctrl all diag file=adureport.zip"
                cp adureport.zip "${LOG}"
                echolog Done
            else 
                #echo  "hpacucli is not installed"
                echolog Skipped
            fi 
        else
            echolog Skipped
        fi 
}

nvme_info() {
    # use iSSDCM_Linux64 tools for NVMe SSD
    printlog "NVMe Logs..."
    #OF="nvme.txt"
    OF="hardware.txt"
    MSG_COMPRESS="\\.gz"
    if lsmod | grep -iwq nvme ; then 
        #echo "NVMe SSD "
        if [[ -f "/usr/local/agenttools/agent/plugins/titan_tools/iSSDCM_Linux64" ]] ; then 
            nvmecmd="/usr/local/agenttools/agent/plugins/titan_tools/iSSDCM_Linux64"
        else
            echo "iSSDCM_Linux64 is not installed"  >> $OF
            echolog Skipped
        fi
        log_cmd $OF "$nvmecmd -drive_list"
        local indexCnt=`$nvmecmd -drive_list  | grep "Drive Index"  | wc -l`
        for((indexNum=0;indexNum<indexCnt;indexNum++)) ; do
             log_item $OF "Drive_getlog" "$nvmecmd -drive_index $indexNum -get_log 2" 
        done
        echolog Done
    else 
        #echo "not NVMe SSD or no iSSDCM_Linux64 tool"
        echolog Skipped
    fi
}

hardware_info() {

    if dmidecode -s system-product-name | grep -iwq bochs ; then
        printlog "not a Physical Machine and exit"
        echolog Skipped
        exit 1
    else
        #printlog "Hardware..."
        uefi_boot
        lsi_raid_info
        hba_info
        hpsa_raid_info
        nvme_info 
        
        #echolog Done
    fi  
}
hardware_info

