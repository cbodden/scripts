#!/bin/bash
## originally taken from : https://wiki.archlinux.org/index.php/Spectrwm
## changed to add dynamic wifi device name and to support more than one battery

# test for acpi, sensors, & cpufreq-info
[[ -z $(which acpi) ]] && { echo "acpi not present"; exit 1; }
[[ -z $(which cpufreq-info) ]] && { echo "cpufreq-info not present"; exit 1; }
[[ -z $(which sensors) ]] && { echo "sensors not present"; exit 1; }

# sleep interval for text output
SLEEP_WAIT=5

BATTERY(){
  BATT_COUNT=`$(which acpi) | wc -l`
  if [ ${BATT_COUNT} -eq 2 ]; then
    LINE1=`acpi | awk 'NR>1{exit};1'`
    LINE2=`acpi | awk 'END{print}'`
    POWER_OUT="${LINE1} -- ${LINE2}"
  else
    POWER_OUT="$(acpi)"
  fi
}

CPU(){
  PROC_COUNT=`cat /proc/cpuinfo | awk '/proc/' | wc -l`
  COUNT=1
  SPEED_OUT=""
  while [ ${COUNT} -le ${PROC_COUNT} ]; do
    CPUN=$(( $COUNT - 1 ))
    SPEED=`echo CPU${CPUN}: $(cpufreq-info -c ${CPUN} | \
      awk -F'[is]' '/t CPU/ {print $3}')`
    SPEED_OUT="${SPEED_OUT} ${SPEED}"
    (( COUNT++ ))
  done
  CPUFREQ_OUT="CPU Speeds: ${SPEED_OUT}"
  CPULOAD_OUT="$(awk '{print "Load:", $1, $2, $3}' /proc/loadavg)"
}

MEM(){
  eval $(awk '/^MemTotal/ {printf "MEM_TOT=%s;", $2}' /proc/meminfo)
  eval $(awk '/^MemFree/ {printf "MEM_FREE=%s;",$2}' /proc/meminfo)
  MEM_USED=$(( $MEM_TOT - $MEM_FREE ))
  MEM_USED_PCT=$(( ($MEM_USED * 100) / $MEM_TOT ))
  MEM_OUT="Memory Used: ${MEM_USED_PCT}% -- ${MEM_USED} kB"
}

TEMPERATURE(){
  eval $(sensors | awk '/^Core 0/ {gsub(/°/,""); printf "CPU0=%s;", $3}')
  eval $(sensors | awk '/^Core 2/ {gsub(/°/,""); printf "CPU2=%s;", $3}')
  eval $(sensors | awk '/^fan1/ {printf "FANSPD=%s;",$2}')
  TEMP_OUT="Temps: CPU0: ${CPU0}  CPU1: ${CPU2}  Fanspeed: ${FANSPD} rpm"
}

WLAN(){
  IWCONFIG=/sbin/iwconfig
  PROC_WIFI=/proc/net/wireless
  WLAN_IFACE=$(cat ${PROC_WIFI} | awk 'END{gsub(":","",$1); print $1}')
  ESSID=`${IWCONFIG} $(echo $WLAN_IFACE) | awk 'NR>1 {exit} {print $NF}'`
  eval $(cat ${PROC_WIFI} | awk 'gsub(/\./,"") {printf "WLAN_QLT=%s;", $3}')
  eval $(cat ${PROC_WIFI} | awk 'gsub(/\./,"") {printf "WLAN_SIG=%s;", $4}')
  eval $(cat ${PROC_WIFI} | awk 'gsub(/\./,"") {printf "WLAN_NS=%s;", $5}')
  BCSCRIPT="scale=0;a=100*$WLAN_QLT/70;print a"
  WLAN_QPC=`echo $BCSCRIPT | bc -l`
  POWER=`${IWCONFIG} 2>/dev/null | awk -F= '/Tx-Power/ {print $3}'`
  WLAN_OUT="$ESSID Q=${WLAN_QPC}% S/N=${WLAN_SIG}/${WLAN_NS} dBm Tx=${POWER}"
}

while :; do
  BATTERY ; CPU ; MEM ; TEMPERATURE ; WLAN
  printf -- "%s\n" "$POWER_OUT" ; sleep $SLEEP_WAIT
  printf -- "%s\n" "$TEMP_OUT" ; sleep $SLEEP_WAIT
  printf -- "%s\n" "$CPUFREQ_OUT" ; sleep $SLEEP_WAIT
  printf -- "%s\n" "$CPULOAD_OUT" ; sleep $SLEEP_WAIT
  printf -- "%s\n" "$MEM_OUT" ; sleep $SLEEP_WAIT
  printf -- "%s\n" "$WLAN_OUT" ; sleep $SLEEP_WAIT
done
