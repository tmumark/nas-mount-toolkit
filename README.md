# NAS Mount Toolkit

macOS 上的 NAS 快速掛載與選單列工具組，整合 FortiClient VPN 狀態偵測、SMB 共享自動掛載、個人資料夾快速開啟。

專為 Synology / QNAP 等家用 NAS 設計（透過 VPN 連線的情境）。

## 專案內容

```
nas-mount-toolkit/
├── menubar/                   # 原生 Swift 選單列 App（arm64）
│   ├── AppDelegate.swift
│   ├── ConnectionManager.swift
│   ├── Info.plist
│   └── build.sh               # 編譯／安裝腳本
├── scripts/
│   ├── mount-nas.sh           # 互動版：首次設定、存密碼到鑰匙圈
│   └── mount-nas-silent.sh    # 靜默版：從鑰匙圈讀密碼，給 App 呼叫
├── FilterFolders.applescript  # Finder 子資料夾篩選工具
└── mount_nas_example.command  # 簡易雙擊掛載範本（舊版，已被上述取代）
```

## 功能

### 1. NAS MenuBar（主要工具）

macOS 選單列常駐 App，原生 Swift/SwiftUI，狀態每 3 秒自動刷新：

- 🟢 VPN 連線 + 三個共享全掛載
- 🟠 VPN 連線但部分未掛載
- 🔴 VPN 未連線

**選單項目：**

| 項目 | 快捷鍵 |
|---|---|
| 📂 掛載 NAS | ⌘M |
| ⏏ 卸載所有 NAS | ⌘U |
| 📁 開啟 Mark 資料夾 | ⌘O |
| 結束 | ⌘Q |

**特色：**
- 密碼從 macOS 鑰匙圈讀取，不硬寫在程式裡
- 使用 `mount_smbfs` + percent-encoding，正確處理中文共享名
- 掛載到 `~/NAS/`，避開 `/Volumes/` 權限問題
- VPN 剛連上時自動掛載

### 2. 掛載腳本（`scripts/`）

若不想用選單列 App，可直接跑 shell 腳本：

- `mount-nas.sh` — 互動版：首次用，會問帳密並存進鑰匙圈
- `mount-nas-silent.sh` — 靜默版：後續執行，從鑰匙圈自動取密碼

### 3. FilterFolders（輔助工具）

在 Finder 中依關鍵字篩選子資料夾，適合 NAS 上大量資料夾的瀏覽情境。

## 快速開始

### 前置條件

- macOS 14+（Apple Silicon）
- FortiClient VPN 已設定好，VPN 名稱為 `VPN`
- Xcode Command Line Tools：`xcode-select --install`

### 首次設定

1. **修改 NAS 連線設定**

   編輯 `menubar/ConnectionManager.swift` 與 `scripts/mount-nas-silent.sh`：
   ```
   NAS_IP   = 你的 NAS IP
   NAS_USER = 你的 NAS 帳號
   SHARES   = 要掛載的共享資料夾名稱（陣列）
   ```

2. **互動版腳本存密碼到鑰匙圈**
   ```bash
   ./scripts/mount-nas.sh
   ```
   依提示輸入帳密，最後選 `y` 存入鑰匙圈。

3. **編譯並安裝選單列 App**
   ```bash
   cd menubar
   ./build.sh install
   ```
   完成後選單列右上會出現狀態圖示。

4. **設定開機自動啟動**（可選）

   系統設定 → 一般 → 登入項目 → 加入 `/Applications/NASMenuBar.app`

## 疑難排解

| 症狀 | 解法 |
|---|---|
| 鑰匙圈找不到密碼 | 重新執行 `scripts/mount-nas.sh` 並選擇存入鑰匙圈 |
| 密碼改了掛載失敗 | `security delete-internet-password -s NAS_IP` 清舊密碼，再跑 mount-nas.sh |
| Finder 卡住「正在連接」 | 不要用 Finder Cmd+K，改用本工具的 `mount_smbfs` 方式 |
| 選單列顯示 🔴 | FortiClient VPN 未連線，或 VPN 名稱不是「VPN」 |

## License

MIT
