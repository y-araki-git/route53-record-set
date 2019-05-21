#!/bin/bash
#------------------------------------------------------------------
#  zoneidリスト作成スクリプト
#------------------------------------------------------------------
#昨日分zoneidリスト削除
rm -f /root/r53/route53_zone_*.txt
 
#zoneidリスト作成
for i in $(aws route53 list-hosted-zones|jq -r '.HostedZones[]|.Id'|awk -F"/" '{print $NF}');do
echo "${i} $(aws route53 get-hosted-zone --id ${i}|jq -r '.HostedZone.Name')" >> /root/r53/route53_zone_`date "+%Y%m%d"`.txt
done