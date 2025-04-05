import Foundation

// 将麦克风和语音识别权限添加到项目配置中
// 这会在Xcode自动生成的Info.plist文件中添加这些权限

let projectPath = "/Users/zhangyuanxi/Public/workspace/personal/VoiceMemo/VoiceMemo.xcodeproj/project.pbxproj"
var projectContent = try! String(contentsOfFile: projectPath)

// 添加麦克风权限
if !projectContent.contains("NSMicrophoneUsageDescription") {
    let micPermissionLine = "INFOPLIST_KEY_NSMicrophoneUsageDescription = \"我们需要访问麦克风来录制语音备忘录\";"
    // 寻找目标位置并添加权限行
    if let targetRange = projectContent.range(of: "buildSettings = {") {
        let insertPoint = projectContent.index(after: targetRange.upperBound)
        projectContent.insert(contentsOf: "\n\t\t\t\t" + micPermissionLine, at: insertPoint)
    }
}

// 添加语音识别权限
if !projectContent.contains("NSSpeechRecognitionUsageDescription") {
    let speechPermissionLine = "INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = \"我们需要使用语音识别功能将您的语音转换为文字\";"
    // 寻找目标位置并添加权限行
    if let targetRange = projectContent.range(of: "buildSettings = {") {
        let insertPoint = projectContent.index(after: targetRange.upperBound)
        projectContent.insert(contentsOf: "\n\t\t\t\t" + speechPermissionLine, at: insertPoint)
    }
}

// 保存修改后的项目文件
try! projectContent.write(toFile: projectPath, atomically: true, encoding: .utf8)

print("项目设置已更新，添加了麦克风和语音识别权限")
