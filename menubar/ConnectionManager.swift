import Foundation
import AppKit

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()

    @Published var vpnConnected = false
    @Published var mountedShares: Set<String> = []

    let nasIP = "192.168.1.250"
    let nasUser = "mark"
    let shares = ["相片", "共用資料", "個人備份及公共區", "管理文件及網站", "acc", "進案請款專區"]

    // 掛載基底目錄：避開 /Volumes/ 的權限問題
    var mountBase: String { NSHomeDirectory() + "/NAS" }
    var markFolder: String { mountBase + "/個人備份及公共區/個人備份區/Mark" }

    private var timer: Timer?
    private var wasVPNConnected = false

    init() {
        // 確保掛載目錄存在
        try? FileManager.default.createDirectory(atPath: mountBase, withIntermediateDirectories: true)
        startPolling()
    }

    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
        refreshStatus()
    }

    func refreshStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let vpn = self.checkVPN()
            var mounted: Set<String> = []
            // 檢查實際掛載狀態（用 mount 指令輸出判斷才準確）
            let mountOutput = self.shell("/sbin/mount")
            for share in self.shares {
                let path = "\(self.mountBase)/\(share)"
                if mountOutput.contains(" on \(path) ") {
                    mounted.insert(share)
                }
            }
            let shouldAutoMount = vpn && !self.wasVPNConnected && mounted.isEmpty
            self.wasVPNConnected = vpn

            DispatchQueue.main.async {
                self.vpnConnected = vpn
                self.mountedShares = mounted
            }

            if shouldAutoMount {
                self.mountAllShares()
                Thread.sleep(forTimeInterval: 3)
                DispatchQueue.main.async { self.refreshStatus() }
            }
        }
    }

    private func checkVPN() -> Bool {
        // 直接 embed scutil 呼叫，不再依賴外部腳本
        let output = shell("/usr/sbin/scutil --nc status \"VPN\" 2>/dev/null | head -1")
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "Connected"
    }

    func mountNAS() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.mountAllShares()
            Thread.sleep(forTimeInterval: 2)
            DispatchQueue.main.async { self?.refreshStatus() }
        }
    }

    func unmountNAS() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.unmountAllShares()
            Thread.sleep(forTimeInterval: 1)
            DispatchQueue.main.async { self.refreshStatus() }
        }
    }

    // MARK: - 掛載邏輯

    private func mountAllShares() {
        guard let password = fetchPasswordFromKeychain() else {
            notify("NAS 掛載失敗", "鑰匙圈找不到 \(nasUser)@\(nasIP) 的密碼")
            return
        }
        let encUser = urlEncode(nasUser)
        let encPass = urlEncode(password)

        var okCount = 0
        var failList: [String] = []

        for share in shares {
            let mountPoint = "\(mountBase)/\(share)"
            // 已掛載就跳過
            let mountOutput = shell("/sbin/mount")
            if mountOutput.contains(" on \(mountPoint) ") { continue }

            // 建立掛載點
            try? FileManager.default.createDirectory(atPath: mountPoint, withIntermediateDirectories: true)

            // URL 編碼共享名（中文字必要）
            let encShare = urlEncode(share)
            let url = "//\(encUser):\(encPass)@\(nasIP)/\(encShare)"

            // 用 mount_smbfs 掛載
            let escapedMount = mountPoint.replacingOccurrences(of: "\"", with: "\\\"")
            let result = shell("/sbin/mount_smbfs \"\(url)\" \"\(escapedMount)\" 2>&1")

            let nowMounted = shell("/sbin/mount").contains(" on \(mountPoint) ")
            if nowMounted {
                okCount += 1
            } else {
                failList.append(share)
                NSLog("Mount failed for \(share): \(result)")
            }
        }

        if failList.isEmpty && okCount > 0 {
            notify("NAS 掛載完成", "已掛載 \(okCount) 個共享")
        } else if !failList.isEmpty {
            notify("NAS 部分掛載失敗", "失敗：\(failList.joined(separator: "、"))")
        }
    }

    private func unmountAllShares() {
        for share in shares {
            let mountPoint = "\(mountBase)/\(share)"
            let mountOutput = shell("/sbin/mount")
            if mountOutput.contains(" on \(mountPoint) ") {
                _ = shell("/usr/sbin/diskutil unmount force \"\(mountPoint)\"")
            }
        }
        notify("NAS 已卸載", "所有共享已斷開")
    }

    func openMarkFolder() {
        let url = URL(fileURLWithPath: markFolder)
        NSWorkspace.shared.open(url)
    }

    // MARK: - 工具函式

    /// 從鑰匙圈讀密碼（之前 mount-nas.sh 存過）
    private func fetchPasswordFromKeychain() -> String? {
        let output = shell("/usr/bin/security find-internet-password -s \(nasIP) -a \(nasUser) -w 2>/dev/null")
        let pw = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return pw.isEmpty ? nil : pw
    }

    /// URL 百分比編碼（正確處理 UTF-8 中文字）
    private func urlEncode(_ str: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return str.addingPercentEncoding(withAllowedCharacters: allowed) ?? str
    }

    /// 顯示系統通知
    private func notify(_ title: String, _ body: String) {
        let escTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        _ = shell("/usr/bin/osascript -e 'display notification \"\(escBody)\" with title \"\(escTitle)\"'")
    }

    @discardableResult
    private func shell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    var overallStatus: String {
        if vpnConnected && mountedShares.count == shares.count { return "connected" }
        if vpnConnected { return "partial" }
        return "disconnected"
    }
}
