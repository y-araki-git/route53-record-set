#!/bin/bash
#------------------------------------------------------------------
#  zoneid���X�g�쐬�X�N���v�g
#------------------------------------------------------------------
#�����zoneid���X�g�폜
rm -f /root/r53/route53_zone_*.txt
 
#zoneid���X�g�쐬
for i in $(aws route53 list-hosted-zones|jq -r '.HostedZones[]|.Id'|awk -F"/" '{print $NF}');do
echo "${i} $(aws route53 get-hosted-zone --id ${i}|jq -r '.HostedZone.Name')" >> /root/r53/route53_zone_`date "+%Y%m%d"`.txt
done