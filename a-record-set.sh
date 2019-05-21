#!/bin/bash
######################################################################
#
# [ファイル名]
#  a-record-set.sh(Aレコード設定スクリプト)
#
# [概要]
#  Route53にAレコードを登録する。
#
# [前提]
#  ・aws cli,cli53,jq が使用可能な環境で実施すること。
#  ・スクリプト実施ファイルと同じ階層にゾーンID記載ファイルを出力すること。
#  ※ゾーンID記載ファイル出力コマンド
#  for i in $(aws route53 list-hosted-zones|jq -r '.HostedZones[]|.Id'|awk -F"/" '{print $NF}');do
#  echo "${i} $(aws route53 get-hosted-zone --id ${i}|jq -r '.HostedZone.Name')" >> /root/r53/route53_zone_`date "+%Y%m%d"`.txt
#  done
#
# [実施方法]
#  1.変数定義にて、登録したいレコード情報を入力する。
#    DOMAIN_NAME="設定したいドメイン名"
#    PUBLIC_IP="ドメインに紐付けたいパブリックIP"
#  2.スクリプトを実行する。
#
######################################################################
# バージョン 作成／更新者 更新日      変更内容
#---------------------------------------------------------------------
# 001-01     NAME      YYYY/MM/DD     新規作成
######################################################################
######################################################################
# 変数定義(スクリプト実行前に編集が必要)
######################################################################
#ドメイン名
DOMAIN_NAME="test.co.jp"
#パブリックIP
PUBLIC_IP="0.0.0.0"
 
 
######################################################################
# 作業用変数定義(編集不要)
######################################################################
#作業用変数
# タイムスタンプ
NOW=`date "+%Y-%m-%d %H:%M:%S"`
# 日付
TODAY=`date "+%Y%m%d"`
# バックアップ作業ルートディレクトリ
WORK_DIR="$(dirname $0)/"
# スクリプトログ格納ディレクトリ
LOG_DIR="${WORK_DIR}log_r53"
# スクリプトログファイル
SCRIPT_LOG="${LOG_DIR}/A_RecordSet.log"
# 結果ファイル格納ディレクトリ
RESULT_DIR="${WORK_DIR}result_r53"
# レコード登録 結果ファイル
RESULT_FILE="${RESULT_DIR}/${TODAY}.A_RecordSet.${DOMAIN_NAME}"
#ゾーンID
HOSTED_ZONEID=$(grep ${DOMAIN_NAME#*.} ${WORK_DIR}route53_zone_*.txt | awk '{print $1}')
# レコード設定用jsonファイル
JSON_FILE="recordset.json"
 
 
######################################################################
# 関数定義
######################################################################
#---------------------------------------------------------------------
# スクリプトログ出力
#---------------------------------------------------------------------
function fnc_output_scriptlog() {
  (echo "$NOW: $1" >>$SCRIPT_LOG) 2>/dev/null
  return $?
}
 
 
######################################################################
# 開始処理
######################################################################
#作業ディレクトリ移動
cd $WORK_DIR
 
#作業用ディレクトリ、ファイル確認
[ ! -e $LOG_DIR ] && mkdir -p $LOG_DIR
[ ! -e $RESULT_DIR ] && mkdir -p $RESULT_DIR
 
#開始ログ出力
fnc_output_scriptlog "開始:Route53 Aレコード登録: ${DOMAIN_NAME}"
 
######################################################################
# メイン処理
######################################################################
#レコード設定用jsonファイル作成
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
 
#レコード設定用jsonファイル確認
if [ -f "/tmp/${JSON_FILE}" ]; then
    fnc_output_scriptlog "レコード設定用jsonファイル作成【成功】"
else
    fnc_output_scriptlog "レコード設定用jsonファイル作成【失敗】"
 
    echo "エラー:レコード設定用jsonファイルを作成できません。"
    exit 1
fi
 
#Route53レコード登録実行
echo "------------------- Record Set Result ${NOW} -------------------" >> $RESULT_FILE
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONEID --change-batch file:///tmp/${JSON_FILE} &>> $RESULT_FILE
 
if [ "$?" = "0" ];then
    fnc_output_scriptlog "Aレコード登録実行【成功】"
 
    #レコード設定用jsonファイル削除
    rm -rf /tmp/recordset.json
  else
    fnc_output_scriptlog "Aレコード登録実行【失敗】"
    echo "エラー:Route53 Aレコード登録に失敗しました。"
    exit 1
fi
 
 
######################################################################
# 終了処理
######################################################################
fnc_output_scriptlog "終了:Route53 Aレコード登録: ${DOMAIN_NAME}"
echo "完了:Route53 ${DOMAIN_NAME}の登録が成功しました。"
 
exit 0