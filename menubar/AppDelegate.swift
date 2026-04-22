import SwiftUI
import AppKit

@main
struct NASMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let manager = ConnectionManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        let menu = NSMenu()
        menu.delegate = self
        rebuildMenu(menu)
        statusItem.menu = menu
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }
    
    func updateIcon() {
        let icon: String
        switch manager.overallStatus {
        case "connected": icon = "🟢"
        case "partial": icon = "🟠"
        default: icon = "🔴"
        }
        statusItem.button?.title = icon
    }
    
    func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        let vpnLabel = manager.vpnConnected ? "VPN: 已連線 ✅" : "VPN: 未連線 ❌"
        addDisabledItem(menu, vpnLabel)
        menu.addItem(NSMenuItem.separator())
        
        for share in manager.shares {
            let ok = manager.mountedShares.contains(share)
            addDisabledItem(menu, "\(share): \(ok ? "✅" : "❌")")
        }
        menu.addItem(NSMenuItem.separator())
        
        if manager.vpnConnected {
            if manager.mountedShares.count < manager.shares.count {
                addActionItem(menu, "📂 掛載 NAS", #selector(mountNAS), "m")
            }
            if !manager.mountedShares.isEmpty {
                addActionItem(menu, "⏏ 卸載所有 NAS", #selector(unmountNAS), "u")
            }
            if manager.mountedShares.contains("個人備份及公共區") {
                addActionItem(menu, "📁 開啟 Mark 資料夾", #selector(openFolder), "o")
            }
        } else {
            addDisabledItem(menu, "請先用 FortiClient 連線 VPN")
        }
        
        menu.addItem(NSMenuItem.separator())
        addActionItem(menu, "結束", #selector(quitApp), "q")
    }
    
    private func addDisabledItem(_ menu: NSMenu, _ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }
    
    private func addActionItem(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = .command
        item.target = self
        menu.addItem(item)
    }
    
    @objc func mountNAS() { manager.mountNAS() }
    @objc func unmountNAS() { manager.unmountNAS() }
    @objc func openFolder() { manager.openMarkFolder() }
    @objc func quitApp() { NSApplication.shared.terminate(nil) }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        manager.refreshStatus()
        updateIcon()
        rebuildMenu(menu)
    }
}
