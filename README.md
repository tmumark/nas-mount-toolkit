# NAS Mount Toolkit

macOS 上的 NAS 快速掛載與資料夾管理工具組，專為 Synology / QNAP 等家用 NAS 設計。

## 功能

### 1. NAS 快速掛載 (`mount_nas.command`)

雙擊即可一鍵掛載多個 SMB 共享資料夾，並自動開啟常用路徑。

- 支援多個共享資料夾同時掛載
- 每個掛載最多等待 15 秒，超時自動跳過
- 掛載完成後自動開啟指定資料夾
- 密碼與設定分離，不怕誤傳

### 2. 資料夾篩選工具 (`FilterFolders.applescript`)

在 Finder 中快速篩選子資料夾，只顯示你需要的。適合 NAS 上有大量資料夾的情境。

- 自動偵測當前 Finder 視窗路徑
- 輸入關鍵字清單，隱藏不符合的資料夾
- 支援模糊比對（資料夾名稱包含關鍵字即匹配）
- 一鍵還原所有隱藏的資料夾
- 可編譯為 .app 放在 Finder 工具列

### 3. NAS MenuBar (`NASMenuBar.app`)

macOS 選單列常駐工具（Swift/SwiftUI 開發，原始碼已遺失）。

- 僅支援 Apple Silicon (arm64)

## 快速開始

### 安裝

```bash
git clone https://github.com/YOUR_USERNAME/nas-mount-toolkit.git
cd nas-mount-toolkit
```

### 設定 NAS 連線

```bash
# 複製設定範本
cp nas_config.example nas_config

# 編輯設定檔，填入你的 NAS IP、帳號、密碼
nano nas_config
```

### 掛載 NAS

```bash
# 方法一：雙擊 mount_nas.command
# 方法二：終端機執行
chmod +x mount_nas.command
./mount_nas.command
```

### 使用資料夾篩選

1. 用 Script Editor 打開 `FilterFolders.applescript`
2. 選擇 File > Export > Application 匯出為 .app
3. 將 .app 拖到 Finder 工具列
4. 在 NAS 資料夾中點擊即可篩選

## 檔案結構

```
.
├── mount_nas.command          # NAS 掛載腳本
├── nas_config.example         # 連線設定範本
├── FilterFolders.applescript  # 資料夾篩選工具原始碼
├── NASMenuBar.app/            # 選單列工具（arm64 binary）
└── README.md
```

## 安全注意事項

- `nas_config` 包含你的 NAS 密碼，已加入 `.gitignore`，不會被上傳
- 請勿將密碼直接寫在腳本中

## 系統需求

- macOS 12+ (Monterey 或更新)
- NASMenuBar.app 僅支援 Apple Silicon

## License

MIT
