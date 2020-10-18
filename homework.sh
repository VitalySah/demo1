#!/bin/bash


SSH_HOSTS=list
RESULT=sorted_ip
IP_LIST=ip_list


function get_ips()
{

for i in `cat $SSH_HOSTS`; do ping -c 1 $i 2>&1 > /dev/null ; if [ $? -eq 0 ]; then ssh $i ip a |grep -v docker |  grep -w inet | awk '{ print $2 }' | grep -v ^127  >> $IP_LIST ; fi; done

}

function sort_list()
{
	rm $RESULT
	touch $RESULT
        for active_ip in `cat ${1}`
        do
	# nd states for network data detemined for a particular IP by usin sipcalc,
	# e.g. 168098573, 10.4.224.0/19, 10.4.251.13/19
	nd=($(sipcalc -i ${active_ip} | tr -d " " | egrep -w "Hostaddress\(decimal\)|Networkaddress|Networkmask\(bits\)" | cut -f2 -d"-"))
	if [ $(grep ${nd[1]} $RESULT | wc -l) -eq 0 ]; then
	    printf "%s,%s/%s,%s\n" ${nd[0]} ${nd[1]} ${nd[2]} $active_ip >> $RESULT
	else
	    existing_ip_decimal=$(grep ${nd[1]} $RESULT | cut -f1 -d",")
	    if ((${existing_ip_decimal} > ${nd[0]}));then
		cat $RESULT | grep -v ${existing_ip_decimal} > temp_list
		mv temp_list $RESULT
		printf "%s,%s/%s,%s\n" ${nd[0]} ${nd[1]} ${nd[2]} $active_ip >> $RESULT
	    fi
	fi
    done
}

function print_result() {
    cat $RESULT | awk -F \, '{print $2 " - " $3}'
}
get_ips
sort_list $IP_LIST
print_result
