import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let clipboardChannel = FlutterMethodChannel(
      name: "com.icyhope.icy_easy_send/clipboard",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    clipboardChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getImageFromClipboard":
        if let imageData = self?.getImageFromClipboard() {
          result(imageData)
        } else {
          result(nil)
        }
      case "setImageToClipboard":
        if let args = call.arguments as? [String: Any],
           let imageData = args["imageData"] as? FlutterStandardTypedData {
          let success = self?.setImageToClipboard(imageData: imageData.data) ?? false
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func getImageFromClipboard() -> [String: Any]? {
    let pasteboard = NSPasteboard.general
    
    if let image = NSImage(pasteboard: pasteboard) {
      if let tiffData = image.tiffRepresentation,
         let bitmapImage = NSBitmapImageRep(data: tiffData),
         let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        return [
          "imageData": FlutterStandardTypedData(bytes: pngData),
          "format": "png"
        ]
      }
    }
    
    return nil
  }
  
  private func setImageToClipboard(imageData: Data) -> Bool {
    if let image = NSImage(data: imageData) {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.writeObjects([image])
      return true
    }
    return false
  }
}
