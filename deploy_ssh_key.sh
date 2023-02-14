#!/bin/bash 
###################################################################
#Script Name : deploy_ssh_key
#Description : batch processing with custom command 
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
Usage: $0 [server ip list] [password]...
Example: $0 server_list '1q2w3e' '4r5t6y'
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
echo "[ job started at $(date) : $0 ]" | tee -a $task_date.log

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
    ok=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip 'echo ok')
  done

  # get server info
  host_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip hostname)
  os_name=$(sshpass -p$pw ssh -o StrictHostKeyChecking=no root@$ip cat /etc/*release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
  echo -e "HOSTNAME : "$host_name  | tee -a $task_date.log
  echo -e "IP\t : "$ip | tee -a $task_date.log
  echo -e "OS\t : "$os_name | tee -a $task_date.log
  rule | tee -a $task_date.log

  if [ "$ok" != "ok" ]; then
    echo "SSH LOGIN FAILED !!!" | tee -a $task_date.log
    rule * | tee -a $task_date.log
    continue
  fi

  # deploy pub key
  pubKey="$HOME/.ssh/id_rsa.pub"
  result=$(sshpass -p$pw ssh-copy-id -i $pubKey root@$ip)
  echo $result | tee -a $task_date.log
done
rule = | tee -a $task_date.log

# show log
less $task_date.log
