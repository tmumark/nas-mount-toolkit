#!/bin/bash

# ============================
# NAS SMB 快速掛載工具
# ============================
# 第一次使用請複製 nas_config.example 為 nas_config
#   cp nas_config.example nas_config
# 並填入你的 NAS 連線資訊

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/nas_config"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "找不到設定檔：nas_config"
  echo "請先執行：cp nas_config.example nas_config"
  echo "並填入你的 NAS 連線資訊"
  read -p "按 Enter 關閉..."
  exit 1
fi

source "$CONFIG_FILE"

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

FAIL_COUNT=0
for SHARE in "${SHARES[@]}"; do
  mount_share "$SHARE" || ((FAIL_COUNT++))
done

# 連接成功後自動開啟常用子資料夾
if [ -n "$AUTO_OPEN_PATH" ] && [ -d "$AUTO_OPEN_PATH" ]; then
  echo ""
  echo "開啟常用資料夾：${AUTO_OPEN_PATH}"
  open "$AUTO_OPEN_PATH"
fi

echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "全部連接完成！"
else
  echo "有 ${FAIL_COUNT} 個共享連接失敗，請檢查網路或 NAS 狀態。"
fi
