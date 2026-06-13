import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    let clipboardChannel = FlutterMethodChannel(
      name: "com.icyhope.icy_easy_send/clipboard",
      binaryMessenger: controller.binaryMessenger
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
      case "getTextFromClipboard":
        result(self?.getTextFromClipboard())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getImageFromClipboard() -> [String: Any]? {
    let pasteboard = UIPasteboard.general

    if let image = pasteboard.image {
      if let imageData = image.pngData() {
        return [
          "imageData": FlutterStandardTypedData(bytes: imageData),
          "fileName": "clipboard_image.png",
          "mimeType": "image/png",
          "format": "png"
        ]
      }
    }

    return nil
  }
  
  private func getTextFromClipboard() -> String? {
    let pasteboard = UIPasteboard.general

    if pasteboard.hasImages || pasteboard.image != nil {
      return nil
    }

    if let string = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines),
       !string.isEmpty {
      return string
    }
    
    if let htmlData = pasteboard.data(forPasteboardType: "public.html"),
       let html = String(data: htmlData, encoding: .utf8)?
         .trimmingCharacters(in: .whitespacesAndNewlines),
       !html.isEmpty {
      return html
    }
    
    return nil
  }
  
  private func setImageToClipboard(imageData: Data) -> Bool {
    if let image = UIImage(data: imageData) {
      UIPasteboard.general.image = image
      return true
    }
    return false
  }
}
