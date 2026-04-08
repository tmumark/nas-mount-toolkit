#!/bin/bash

SMB_SERVER="YOUR_NAS_IP"
SMB_USER="YOUR_USERNAME"
SMB_PASS='YOUR_PASSWORD'

mount_share() {
  local SHARE="$1"
  echo "連接：${SHARE} ..."
  open "smb://${SMB_USER}:${SMB_PASS}@${SMB_SERVER}/${SHARE}"
  for i in {1..15}; do
    if [ -d "/Volumes/${SHARE}" ]; then
      echo "  已連接：${SHARE}"
      return 0
    fi
    sleep 1
  done
  echo "  連接失敗：${SHARE}（逾時 15 秒）"
  return 1
}

echo "=============================="
echo "  開始連接 NAS ($SMB_SERVER)"
echo "=============================="

SHARES=(
  "相片"
  "共用資料"
  "個人備份及公共區"
)

FAIL_COUNT=0
for SHARE in "${SHARES[@]}"; do
  mount_share "$SHARE" || ((FAIL_COUNT++))
done

# 開啟常用子資料夾
MAIN_SHARE="個人備份及公共區"
SUB_PATH="個人備份區/Mark"
if [ -d "/Volumes/${MAIN_SHARE}/${SUB_PATH}" ]; then
  echo ""
  echo "開啟常用資料夾：${SUB_PATH}"
  open "/Volumes/${MAIN_SHARE}/${SUB_PATH}"
fi

echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "全部連接完成！"
else
  echo "有 ${FAIL_COUNT} 個共享連接失敗，請檢查網路或 NAS 狀態。"
fi
