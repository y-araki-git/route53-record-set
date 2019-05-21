#!/bin/bash
######################################################################
#
# [�t�@�C����]
#  a-record-set.sh(A���R�[�h�ݒ�X�N���v�g)
#
# [�T�v]
#  Route53��A���R�[�h��o�^����B
#
# [�O��]
#  �Eaws cli,cli53,jq ���g�p�\�Ȋ��Ŏ��{���邱�ƁB
#  �E�X�N���v�g���{�t�@�C���Ɠ����K�w�Ƀ]�[��ID�L�ڃt�@�C�����o�͂��邱�ƁB
#  ���]�[��ID�L�ڃt�@�C���o�̓R�}���h
#  for i in $(aws route53 list-hosted-zones|jq -r '.HostedZones[]|.Id'|awk -F"/" '{print $NF}');do
#  echo "${i} $(aws route53 get-hosted-zone --id ${i}|jq -r '.HostedZone.Name')" >> /root/r53/route53_zone_`date "+%Y%m%d"`.txt
#  done
#
# [���{���@]
#  1.�ϐ���`�ɂāA�o�^���������R�[�h������͂���B
#    DOMAIN_NAME="�ݒ肵�����h���C����"
#    PUBLIC_IP="�h���C���ɕR�t�������p�u���b�NIP"
#  2.�X�N���v�g�����s����B
#
######################################################################
# �o�[�W���� �쐬�^�X�V�� �X�V��      �ύX���e
#---------------------------------------------------------------------
# 001-01     NAME      YYYY/MM/DD     �V�K�쐬
######################################################################
######################################################################
# �ϐ���`(�X�N���v�g���s�O�ɕҏW���K�v)
######################################################################
#�h���C����
DOMAIN_NAME="test.co.jp"
#�p�u���b�NIP
PUBLIC_IP="0.0.0.0"
 
 
######################################################################
# ��Ɨp�ϐ���`(�ҏW�s�v)
######################################################################
#��Ɨp�ϐ�
# �^�C���X�^���v
NOW=`date "+%Y-%m-%d %H:%M:%S"`
# ���t
TODAY=`date "+%Y%m%d"`
# �o�b�N�A�b�v��ƃ��[�g�f�B���N�g��
WORK_DIR="$(dirname $0)/"
# �X�N���v�g���O�i�[�f�B���N�g��
LOG_DIR="${WORK_DIR}log_r53"
# �X�N���v�g���O�t�@�C��
SCRIPT_LOG="${LOG_DIR}/A_RecordSet.log"
# ���ʃt�@�C���i�[�f�B���N�g��
RESULT_DIR="${WORK_DIR}result_r53"
# ���R�[�h�o�^ ���ʃt�@�C��
RESULT_FILE="${RESULT_DIR}/${TODAY}.A_RecordSet.${DOMAIN_NAME}"
#�]�[��ID
HOSTED_ZONEID=$(grep ${DOMAIN_NAME#*.} ${WORK_DIR}route53_zone_*.txt | awk '{print $1}')
# ���R�[�h�ݒ�pjson�t�@�C��
JSON_FILE="recordset.json"
 
 
######################################################################
# �֐���`
######################################################################
#---------------------------------------------------------------------
# �X�N���v�g���O�o��
#---------------------------------------------------------------------
function fnc_output_scriptlog() {
  (echo "$NOW: $1" >>$SCRIPT_LOG) 2>/dev/null
  return $?
}
 
 
######################################################################
# �J�n����
######################################################################
#��ƃf�B���N�g���ړ�
cd $WORK_DIR
 
#��Ɨp�f�B���N�g���A�t�@�C���m�F
[ ! -e $LOG_DIR ] && mkdir -p $LOG_DIR
[ ! -e $RESULT_DIR ] && mkdir -p $RESULT_DIR
 
#�J�n���O�o��
fnc_output_scriptlog "�J�n:Route53 A���R�[�h�o�^: ${DOMAIN_NAME}"
 
######################################################################
# ���C������
######################################################################
#���R�[�h�ݒ�pjson�t�@�C���쐬
cat <<EOT > "/tmp/${JSON_FILE}"
{
  "Comment": "create A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "A",
        "TTL": 300 ,
        "ResourceRecords": [
         {
           "Value": "${PUBLIC_IP}"
         }
        ]
      }
    }
  ]
}
EOT
 
#���R�[�h�ݒ�pjson�t�@�C���m�F
if [ -f "/tmp/${JSON_FILE}" ]; then
    fnc_output_scriptlog "���R�[�h�ݒ�pjson�t�@�C���쐬�y�����z"
else
    fnc_output_scriptlog "���R�[�h�ݒ�pjson�t�@�C���쐬�y���s�z"
 
    echo "�G���[:���R�[�h�ݒ�pjson�t�@�C�����쐬�ł��܂���B"
    exit 1
fi
 
#Route53���R�[�h�o�^���s
echo "------------------- Record Set Result ${NOW} -------------------" >> $RESULT_FILE
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONEID --change-batch file:///tmp/${JSON_FILE} &>> $RESULT_FILE
 
if [ "$?" = "0" ];then
    fnc_output_scriptlog "A���R�[�h�o�^���s�y�����z"
 
    #���R�[�h�ݒ�pjson�t�@�C���폜
    rm -rf /tmp/recordset.json
  else
    fnc_output_scriptlog "A���R�[�h�o�^���s�y���s�z"
    echo "�G���[:Route53 A���R�[�h�o�^�Ɏ��s���܂����B"
    exit 1
fi
 
 
######################################################################
# �I������
######################################################################
fnc_output_scriptlog "�I��:Route53 A���R�[�h�o�^: ${DOMAIN_NAME}"
echo "����:Route53 ${DOMAIN_NAME}�̓o�^���������܂����B"
 
exit 0