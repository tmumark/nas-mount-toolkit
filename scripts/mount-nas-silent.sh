#!/bin/bash
# 靜默掛載公司 NAS — 從鑰匙圈讀密碼，全程無互動
# 給選單列 Shortcuts 用
set -u

NAS_IP="192.168.1.250"
NAS_USER="mark"
SHARES=("共用資料" "相片" "個人備份及公共區")
MOUNT_BASE="$HOME/NAS"

notify() {
  local title="$1" msg="$2"
  osascript -e "display notification \"$msg\" with title \"$title\""
}

# 1. 檢查 VPN
if ! ping -c 1 -t 2 "$NAS_IP" >/dev/null 2>&1; then
  notify "NAS 掛載失敗" "VPN 未連線，ping 不到 $NAS_IP"
  exit 1
fi

# 2. 從鑰匙圈取密碼
NAS_PASS=$(security find-internet-password -s "$NAS_IP" -a "$NAS_USER" -w 2>/dev/null)
if [ -z "$NAS_PASS" ]; then
  notify "NAS 掛載失敗" "鑰匙圈找不到 $NAS_USER@$NAS_IP 的密碼"
  exit 1
fi

# 3. URL 編碼
urlencode() {
  python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""),end="")' "$1"
}
ENC_USER=$(urlencode "$NAS_USER")
ENC_PASS=$(urlencode "$NAS_PASS")

# 4. 掛載（已掛載的跳過）
mkdir -p "$MOUNT_BASE"
OK=0; SKIP=0; FAIL=0; FAIL_LIST=""
for s in "${SHARES[@]}"; do
  mp="$MOUNT_BASE/$s"
  if mount | grep -q " on $mp "; then
    SKIP=$((SKIP+1))
    continue
  fi
  mkdir -p "$mp"
  ENC_SHARE=$(urlencode "$s")
  if mount_smbfs "//${ENC_USER}:${ENC_PASS}@${NAS_IP}/${ENC_SHARE}" "$mp" 2>/dev/null; then
    OK=$((OK+1))
  else
    FAIL=$((FAIL+1))
    FAIL_LIST="$FAIL_LIST $s"
  fi
done

# 5. 通知
if [ $FAIL -eq 0 ]; then
  if [ $OK -eq 0 ] && [ $SKIP -gt 0 ]; then
    notify "NAS 已掛載" "三個共享皆已在線上"
  else
    notify "NAS 掛載完成" "新掛載 $OK 個／已存在 $SKIP 個"
  fi
else
  notify "NAS 部分掛載失敗" "失敗：$FAIL_LIST"
  exit 1
fi
