#!/bin/bash 

###################################################################
#Script Name : daily_check.sh          
#Description : daily system check, resource, disk usage, message log
#Args : [server ip list] [password]...
#Author : Kim Jinhyeok
#Email : snare909@gmail.com
###################################################################
# util function
## Print a horizontal rule
rule () {
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}
## Print horizontal ruler with message
rulem ()  {
	if [ $# -eq 0 ]; then
		echo "Usage: rulem MESSAGE [RULE_CHARACTER]"
		return 1
	fi
	# Fill line with ruler character ($2, default "-"), reset cursor, move 2 cols right, print message
  # $ rulem "[ How about that? ]"
	printf -v _hr "%*s" $(tput cols) && echo -en ${_hr// /${2--}} && echo -e "\r\033[2C$1"
}
###################################################################
usage(){
  cat <<EOF
Usage: custom_batch.sh [server ip list] [password]...
Example: custom_batch.sh songdo_list '1q2w3e' 
Example: custom_batch.sh songdo_list '1q2w3e' '4r5t6y'
EOF
  exit
}
if [[ $# -eq 0 ]]; then
  usage
fi
###################################################################

# read file and turn into array
readarray -t servers < $1

# assign date, log start time
task_date=$(date "+%y%m%d%H")
rule =  | tee -a $task_date.log
echo "[ job started at $(date) ]" | tee -a $task_date.log

# loop over servers
args=("$@")
for ip in ${servers[@]}; do
  rule = | tee -a $task_date.log
  # password check for retry next pw
  pwi=1
  pw="${args[$pwi]}"
  ok=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  while [ "$ok" != "ok" ] && [ $pwi -le $(($#-1)) ]; do
    ((pwi++))
    pw="${args[$pwi]}"
    ok=$(sshpass -p"$pw" ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  done

  # get server info
  host_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip hostname)
  os_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip cat /etc/*release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
  cpu_usage=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip mpstat | tail -1 | awk '{print 100-$NF}')
  mem_usage=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip free -m | grep 'Mem' | awk '{ print 100-$7/$2*100 }')
  disk_usage=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip df | sed 's/%//g' | awk '{ if ($5 > 90 && $1 != "/dev/sr0" ) print $1 "\t" $5 "%\t" $6}')
  msg_log=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip cat /var/log/messages | grep -Ei 'invalid|no|error|critical|fail|fault|warning|problem|unexpected|false|bad|deny|denied|inappropriate|illegal|broken|too\smany|dead|die|corrupt|memory' | tail -n 100)

  echo -e "HOSTNAME : "$host_name  | tee -a $task_date.log
  echo -e "IP\t : "$ip | tee -a $task_date.log
  echo -e "OS\t : "$os_name | tee -a $task_date.log
  echo "[ RESOURCE USAGE ]" | tee -a $task_date.log
  echo -e "CPU\t : "$cpu_usage"%" | tee -a $task_date.log
  echo -e "MEMORY\t : "$mem_usage"%" | tee -a $task_date.log
  echo "$disk_usage" | tee -a $task_date.log
  echo "[ MESSAGE LOG ]" | tee -a $task_date.log
  echo "$msg_log" | tee -a $task_date.log

  if [ "$ok" != "ok" ]; then
    echo "SSH LOGIN FAILED !!!" | tee -a $task_date.log
  fi
done
rule =  | tee -a $task_date.log

# show log
less $task_date.log
