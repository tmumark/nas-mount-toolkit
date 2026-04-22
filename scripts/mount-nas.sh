#!/bin/bash
# 掛載公司 NAS (192.168.1.250) 的共享資料夾
# 使用前請先確認 FortiClient VPN 已連線
# 掛載點：~/NAS/<共享名稱>
set -u

NAS_IP="192.168.1.250"
SHARES=("共用資料" "相片" "個人備份及公共區" "管理文件及網站" "acc" "進案請款專區")
MOUNT_BASE="$HOME/NAS"

G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;36m'; N='\033[0m'

echo -e "${Y}▶ 檢查 VPN 連線...${N}"
if ! ping -c 1 -t 2 "$NAS_IP" >/dev/null 2>&1; then
  echo -e "${R}✗ 無法 ping 到 $NAS_IP，請先連上 FortiClient VPN${N}"
  exit 1
fi
echo -e "${G}✓ NAS 連線正常${N}"

# 卸除已掛載的舊連線（如果有）
for s in "${SHARES[@]}"; do
  mp="$MOUNT_BASE/$s"
  if mount | grep -q " on $mp "; then
    umount "$mp" 2>/dev/null && echo -e "${B}  卸除舊掛載：$s${N}"
  fi
done

# 建立掛載點
mkdir -p "$MOUNT_BASE"
for s in "${SHARES[@]}"; do
  mkdir -p "$MOUNT_BASE/$s"
done

# 詢問帳密（只問一次，所有共享共用）
echo ""
read -rp "NAS 帳號： " NAS_USER
read -rsp "NAS 密碼： " NAS_PASS
echo ""
echo ""

# URL 編碼（用 python3 處理 UTF-8 才不會炸）
urlencode() {
  python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""),end="")' "$1"
}
ENC_USER=$(urlencode "$NAS_USER")
ENC_PASS=$(urlencode "$NAS_PASS")

echo -e "${Y}▶ 開始掛載...${N}"
OK=0; FAIL=0
for s in "${SHARES[@]}"; do
  mp="$MOUNT_BASE/$s"
  ENC_SHARE=$(urlencode "$s")
  if mount_smbfs "//${ENC_USER}:${ENC_PASS}@${NAS_IP}/${ENC_SHARE}" "$mp" 2>/tmp/smb-err.log; then
    echo -e "${G}✓ 掛載成功：$s → $mp${N}"
    OK=$((OK+1))
  else
    echo -e "${R}✗ 掛載失敗：$s${N}"
    sed 's/^/    /' /tmp/smb-err.log
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo -e "${Y}▶ 最終結果：成功 ${G}$OK${Y}／失敗 ${R}$FAIL${N}"
mount | grep smbfs | sed 's/^/  /'

# 詢問是否存鑰匙圈
if [ $OK -gt 0 ]; then
  echo ""
  read -rp "要把密碼存進鑰匙圈方便下次自動登入嗎？[y/N] " YN
  if [[ "$YN" =~ ^[Yy]$ ]]; then
    security add-internet-password -s "$NAS_IP" -a "$NAS_USER" -w "$NAS_PASS" -r "smb " -U
    echo -e "${G}✓ 已存入鑰匙圈${N}"
  fi
fi
