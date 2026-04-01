// clipboard-normalizer.swift
// 监听终端应用激活事件，按需将剪贴板图片转换为 PNG
// 零轮询，仅在切换到终端时触发一次检查
//
// 编译: swiftc clipboard-normalizer.swift -o clipboard-normalizer

import AppKit
import Foundation

// 常见终端的 Bundle ID，按需补充
let TERMINAL_BUNDLE_IDS: Set<String> = [
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "com.github.wez.wezterm",
    "io.alacritty",
    "com.mitchellh.ghostty",
    "net.kovidgoyal.kitty",
    "co.zeit.hyper",
]

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss +0800"
    f.timeZone = TimeZone(identifier: "Asia/Shanghai")
    return f
}()

func ts() -> String { dateFormatter.string(from: Date()) }

let pb = NSPasteboard.general
let fileURLType = NSPasteboard.PasteboardType("public.file-url")
let tmpImagePath = "/tmp/clipboard-normalizer-image.png"

func tryConvertToPNG() {
    let types = pb.types ?? []

    // 已有文件 URL（如从 Finder 复制文件），CLI 直接读磁盘文件，无需处理
    if types.contains(fileURLType) { return }

    // NSImage(pasteboard:) 能处理 TIFF/JPEG/BMP 等所有 AppKit 支持的格式
    guard
        let image = NSImage(pasteboard: pb),
        image.isValid,
        let tiffData = image.tiffRepresentation,
        let bitmapRep = NSBitmapImageRep(data: tiffData),
        let pngData = bitmapRep.representation(using: .png, properties: [:])
    else {
        return
    }

    // 存到固定临时文件（每次覆盖，不会堆积）
    // Claude Code CLI 通过 public.file-url 读取磁盘文件，而非裸图片数据
    let tmpURL = URL(fileURLWithPath: tmpImagePath)
    guard (try? pngData.write(to: tmpURL)) != nil else { return }

    pb.clearContents()
    // writeObjects 写入 public.file-url、NSFilenamesPboardType 等 URL 关联类型
    pb.writeObjects([tmpURL as NSURL])
    // Terminal.app 粘贴文件时读取 public.utf8-plain-text（文件路径文本），
    // 发给 Claude Code CLI，CLI 凭路径读取图片文件
    pb.addTypes([.string, .tiff, .png], owner: nil)
    pb.setString(tmpURL.path, forType: .string)
    pb.setData(tiffData, forType: .tiff)
    pb.setData(pngData, forType: .png)
    fputs("[\(ts())] saved to \(tmpImagePath) (\(pngData.count) bytes)\n", stderr)
}

// 监听全局应用激活事件
// 仅在用户切换到终端时触发，其余时间进程完全静默
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { notification in
    guard
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication,
        let bundleID = app.bundleIdentifier,
        TERMINAL_BUNDLE_IDS.contains(bundleID)
    else { return }

    tryConvertToPNG()
}

fputs("[\(ts())] clipboard-normalizer started (PID: \(ProcessInfo.processInfo.processIdentifier))\n", stderr)
fputs("[\(ts())] watching: \(TERMINAL_BUNDLE_IDS.sorted().joined(separator: ", "))\n", stderr)

// 事件驱动，RunLoop 阻塞等待系统通知
RunLoop.main.run()
