#!/bin/bash


SSH_HOSTS=${1}
RESULT=sorted_ip
IP_LIST=ip_list

if [ -z "$1" ]
then
  echo "Script usage: `basename $0` [Your IP's list]"
  exit 1
fi

function get_ips()
{

	for ssh_hosts in `cat $SSH_HOSTS` 
	do ping -c 1 $ssh_hosts 2>&1 > /dev/null 
		if [ $? -eq 0 ]; then 
			ssh $ssh_hosts  ip a |grep -v docker |  grep -w inet | awk '{ print $2 }' | grep -v ^127  >> $IP_LIST 
		fi
	done

}

function sort_list()
{
	if [ ! -f $IP_LIST ]
	then
		echo "No active IP's" 
		exit 1
	else
	touch $RESULT
        for active_ip in `cat ${IP_LIST}`
        do
	# nd states for network data detemined for a particular IP by usin sipcalc,
	# e.g. 168098573, 10.4.224.0/19, 10.4.251.13/19
	nd=($(sipcalc -i ${active_ip} | tr -d " " | egrep -w "Hostaddress\(decimal\)|Networkaddress|Networkmask\(bits\)" | awk -F "-" '{print $2}'))
	nv=($(sipcalc -i ${active_ip} | tr -d " " | egrep -w "Hostaddress" | awk -F "-" '{print $2}'))
	if [ $(grep ${nd[1]} $RESULT | wc -l) -eq 0 ]; then
	    printf "%s,%s/%s,%s\n" ${nd[0]} ${nd[1]} ${nd[2]} ${nv[0]} >> $RESULT
	else
	    existing_ip_decimal=$(grep ${nd[1]} $RESULT | awk -F "," '{print $1}')
	    if ((${existing_ip_decimal} > ${nd[0]}));then
		cat $RESULT | grep -v ${existing_ip_decimal} > temp_list
		mv temp_list $RESULT
		printf "%s,%s/%s,%s\n" ${nd[0]} ${nd[1]} ${nd[2]} ${nv[0]}  >> $RESULT
	    fi
	fi
        done
        fi
}

function print_result() {
    cat $RESULT | awk -F \, '{print $2 " - " $3}'
    rm $RESULT 2>&1 > /dev/null
}
get_ips
sort_list
print_result
