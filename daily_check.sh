#!/bin/bash 

###################################################################
#Script Name : daily_check.sh          
#Description : daily system check, resource, disk usage, message log
#Args : [server ip list] [password]
#Author : Kim Jinhyeok
#Email : snare909@gmail.com
###################################################################
# util funciton
## Print a horizontal rule
rule () {
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}
###################################################################

# read file and turn into array
readarray -t servers < $1

for ip in ${servers[@]}; do
  rule
  echo "HOSTNAME:"$host_name
  echo "IP:"$ip
  echo "OS:"$os_name
  echo "COMMAND:"$3
  rule
  sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip $3
done

for ip in ${servers[@]}; do
  echo $ip
  host_name=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip hostname)
  os_name=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip cat /etc/*release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
  cpu_usage=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip mpstat | tail -1 | awk '{print 100-$NF}')
  mem_usage=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip free -m | grep 'Mem' | awk '{ print "usage: " 100-$7/$2*100 "%" }')
  disk_usage=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip df | sed 's/%//g' | awk '{ if ($5 > 90 && $1 != "/dev/sr0" ) print $1 "\t" $5 "%\t" $6}')
  #disk_usage=$(sshpass -p$2 ssh -o StrictHostKeyChecking=no root@$ip 'df -h'


  echo $host_name
  echo $cpu_usage
  echo $mem_usage
  # double quote!!!
  echo "$disk_usage" 
done

#while read p; do
  #echo "$p"
  #echo $hname
#done < $1

# resource
#echo "###################################################################"
#
#mem=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
#cpu=$(mpstat | tail -1 | awk '{print 100-$NF}')
#
#echo memory usage : $mem %
#echo cpu usage : $cpu %
#
#echo "###################################################################"
## disk usage
#ALERT=90 # if percentage of ALERT over, notify
#df | awk '{ print $1 "\t" $5 }' | sed 's/%//g' | awk -v alert="$ALERT" '{ if ($2 > alert) print $0 "%" }'
