#!/bin/bash


IP_LIST=ip_list
SUB_LIST=sub_list
SSH_HOSTS=list
SORTED_IP=sorted_ip

function clean_old()
{
	rm -f $IP_LIST
	rm -f $SUB_LIST
	rm -f $SORTED_IP
}


function get_ips()
{

for i in `cat $SSH_HOSTS`; do ping -c 1 $i 2>&1 > /dev/null ; if [ $? -eq 0 ]; then ssh $i ip a |grep -v docker |  grep -w inet | awk '{ print $2 }' | grep -v ^127  >> $IP_LIST ; fi; done

}

function sort_ips()
{

for line in $(cat $IP_LIST  | awk -F\. '{print $1"."$2"."$3}'|awk '!x[$0]++');do grep $line $IP_LIST |awk -F\/ '{print $1}'|awk -F\. '{print $line}'|sort -nr|tail -n 1;done > $SORTED_IP

}

function get_subnets()
{

for line in $(cat $IP_LIST  | awk -F\. '{print $1"."$2"."$3}'|awk '!x[$0]++');do grep $line $IP_LIST |awk -F\. '{print $line}'| sed -e 's/\(\([0-9]\{1,3\}\.\)\{3\}\)[0-9]\{1,3\}/\10/g' | sort -nr|tail -n 1;done > $SUB_LIST

}

function print_ip()
{

	sed -e "R $SORTED_IP" $SUB_LIST | sed 'N; s/\n/ -  /'

}


#main
clean_old
clear
get_ips
sort_ips
get_subnets
print_ip
