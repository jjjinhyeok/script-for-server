#!/bin/bash 
###################################################################
#Script Name : custom_batch.sh
#Description : batch processing with custom command 
#Args : [server ip list] [command] [password]...
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
Usage: custom_batch.sh [server ip list] [command] [password]...
Example: custom_batch.sh songdo_list 'yum -y install telnet' '1q2w3e' 
Example: custom_batch.sh songdo_list 'yum -y install telnet' '1q2w3e' '4r5t6y'
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
task_date=$(date "+%y%m%d%H%M")
rule = | tee -a $task_date.log
echo "[ job started at $(date) ]" | tee -a $task_date.log

# loop over servers
args=("$@")
for ip in ${servers[@]}; do
  rule = | tee -a $task_date.log
  # password check for retry next pw
  pwi=2
  pw="${args[$pwi]}"
  ok=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  while [ "$ok" != "ok" ] && [ $pwi -le $(($#-2)) ]; do
    ((pwi++))
    pw="${args[$pwi]}"
    ok=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  done

  # get server info
  host_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip hostname)
  os_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip cat /etc/*release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
  echo -e "HOSTNAME : "$host_name  | tee -a $task_date.log
  echo -e "IP\t : "$ip | tee -a $task_date.log
  echo -e "OS\t : "$os_name | tee -a $task_date.log
  echo -e "COMMAND\t : "$2 | tee -a $task_date.log
  rule | tee -a $task_date.log

  if [ "$ok" != "ok" ]; then
    echo "SSH LOGIN FAILED !!!" | tee -a $task_date.log
  fi

  # execute command
  sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip $2 | tee -a $task_date.log
done
rule = | tee -a $task_date.log

# show log
less $task_date.log
