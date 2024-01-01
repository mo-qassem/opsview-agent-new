#!/bin/bash

VNSTAT_BIN="/usr/bin/vnstat"

INTERFACE="ens18"  # Change this to your server's interface

MONTHLY_QUOTA_GB=100  # Adjust this to your desired quota

reset_bandwidth() {
    systemctl stop vnstatd
    rm -f /var/lib/vnstat/vnstat.db
    systemctl stop vnstatd
    #$VNSTAT_BIN --reset -i $INTERFACE

}
check_bandwidth_quota() {
    usage=$($VNSTAT_BIN -i $INTERFACE -m --oneline | awk -F ';' '{print $11}')
    usage_without=$(echo $usage | awk '{print $1}')
    #echo $usage_without
    unit=$(echo $usage | awk '{print $2}')
    #echo $unit
    case "$unit" in
           KiB)    
                usage_GB=$(echo "$usage_without/1024/1024" | bc -l)
                #echo $usage_GB
          ;;
           MiB)    
                usage_GB=$(echo "$usage_without/1024" | bc -l)
                #echo $usage_GB
          ;;
            GiB)   
                usage_GB=$usage_without
                #echo $usage_GB
          ;;
           TiB)    
                usage_GB=$(echo "$usage_without*1024" | bc -l)
                #echo $usage_GB
          ;;
    esac
    #usage_without=$(echo $usage | awk '{print substr($0, 1, length($0)-4)}')
    #echo $usage
    #echo $usage_without
    if (( $(echo "$usage_GB > $MONTHLY_QUOTA_GB" | bc -l) )); then
        echo "CRITICAL - Bandwidth quota exceeded: ${usage} used (Quota: ${MONTHLY_QUOTA_GB}GB)"
        exit 2
    else
        echo "OK - Bandwidth usage is ${usage} (Quota: ${MONTHLY_QUOTA_GB}GB)"
        exit 0
    fi
}

# Check if it's the first day of the month and reset bandwidth if needed
if [[ $(date '+%d') -eq 01 ]]; then
    reset_bandwidth
fi

check_bandwidth_quota
DUDE!
