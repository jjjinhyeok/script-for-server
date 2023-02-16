#!/bin/bash 
###################################################################
#Script Name : deploy_ssh_key_manual.sh
#Description : batch processing with custom command 
#Args : [server ip list]
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
Usage: $0 [server ip list]
Example: $0 server_list
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
pubKey="$HOME/.ssh/id_rsa.pub"
for ip in ${servers[@]}; do
  rule = | tee -a $task_date.log
  echo -e "IP\t : "$ip | tee -a $task_date.log
  ssh-copy-id -i $pubKey root@$ip
  #echo $result | tee -a $task_date.log
  rule | tee -a $task_date.log
done
rule = | tee -a $task_date.log

# show log
less $task_date.log
