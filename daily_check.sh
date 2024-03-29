#!/bin/bash 

###################################################################
#Script Name : daily_check.sh          
#Description : daily system check, resource, disk usage, message log
#Args : [server ip list]
#Author : Kim Jinhyeok
#Email : snare909@gmail.com
###################################################################
# util function
## Print a horizontal rule
rule() {
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}
## Print horizontal ruler with message
rulem()  {
  # $ rulem "[ How about that? ]"
	printf -v _hr "%*s" $(tput cols) && echo -en ${_hr// /${2--}} && echo -e "\r\033[2C$1"
}
###################################################################
usage(){
  cat <<EOF
Usage: $filename [server ip list]
Example: $filename server_list
EOF
  exit
}
if [[ $# -eq 0 ]]; then
  usage
fi
###################################################################
# functions
printInfo() {
  # printInfo $hostname $ip $os
  echo "[ SERVER INFO ]"
  echo -e "HOSTNAME : "$1
  echo -e "IP\t : "$2
  echo -e "OS\t : "$3
}
printRes() {
  # printInfo $hostname $ip $os
  echo "[ RESOURCE USAGE ]" 
  echo -e "CPU\t : "$1"%"
  echo -e "MEMORY\t : "$2"%"
  echo "$3"
}

# read file and turn into array
readarray -t servers < $1

# assign date, log start time
task_date=$(date "+%y%m%d%H%M")
rule =  | tee -a $task_date.log
echo "[ job started at $(date) : $0 ]" | tee -a $task_date.log

# loop over servers
args=("$@")
for ip in ${servers[@]}; do
  rule = | tee -a $task_date.log
  # ssh login check
  ok=$(timeout 5s sshpass ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  if [ "$ok" != "ok" ]; then
    rule "#" | tee -a $task_date.tmp
    echo -e "IP\t : "$ip | tee -a $task_date.tmp
    echo "SSH LOGIN FAILED !!!" | tee -a $task_date.tmp
    rule "#" | tee -a $task_date.tmp
    continue;
  fi

  # server info
  host_name=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip hostname)
  os_name=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip cat /etc/*release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
  printInfo $host_name $ip "$os_name" | tee -a $task_date.log

  # resource
  cpu_usage=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip mpstat | tail -1 | awk '{print 100-$NF}')
  mem_usage=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip free -m | grep 'Mem' | awk '{ print 100-$7/$2*100 }')
  disk_usage=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip df | sed 's/%//g' | awk '{ if ($5 > 90 && $1 != "/dev/sr0" && $1 != "/dev/loop0") print $1 "\t" $5 "%\t" $6}')
  #printRes $cpu_usage $mem_usage "$disk_usage" | tee -a $task_date.log

  echo "[ MESSAGE LOG ]" | tee -a $task_date.log
  msg_log=$(sshpass ssh -o StrictHostKeyChecking=no root@$ip cat /var/log/messages | grep -Ei 'invalid|no|error|critical|fail|fault|warning|problem|unexpected|false|bad|deny|denied|inappropriate|illegal|broken|too\smany|dead|die|corrupt|memory' | tail -n 100)
  echo "$msg_log" | tee -a $task_date.log


  if [ $(printf %.0f $cpu_usage) -ge 90 ] || [ $(printf %.0f $mem_usage) -ge 90 ] || [ $(echo "$disk_usage" | wc -l) -ge 2 ] ; then
    rule = >> $task_date.tmp
    printInfo $host_name $ip "$os_name" >> $task_date.tmp
    printRes $cpu_usage $mem_usage "$disk_usage" >> $task_date.tmp
  fi
done
# print over 90%
rule =  | tee -a $task_date.log
echo "[ OVER 90% ]" | tee -a $task_date.log
cat $task_date.tmp | tee -a $task_date.log
rm $task_date.tmp
rule =  | tee -a $task_date.log

# show log
less $task_date.log
