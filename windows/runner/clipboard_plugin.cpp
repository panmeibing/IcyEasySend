#include "clipboard_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <objidl.h>
#include <gdiplus.h>

#include <memory>
#include <vector>

#pragma comment(lib, "gdiplus.lib")

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

class ClipboardPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  ClipboardPlugin();
  virtual ~ClipboardPlugin();

  // Disallow copy and assign.
  ClipboardPlugin(const ClipboardPlugin&) = delete;
  ClipboardPlugin& operator=(const ClipboardPlugin&) = delete;

 private:
  // Called when a method is called on the plugin channel.
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // Get image from clipboard
  EncodableValue GetImageFromClipboard();

  // Set image to clipboard
  bool SetImageToClipboard(const std::vector<uint8_t>& image_data,
                          const std::string& format);

  // GDI+ token for cleanup
  ULONG_PTR gdiplusToken_;
};

// Helper function to get PNG encoder CLSID
int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
  UINT num = 0;
  UINT size = 0;

  Gdiplus::GetImageEncodersSize(&num, &size);
  if (size == 0) return -1;

  Gdiplus::ImageCodecInfo* pImageCodecInfo =
      (Gdiplus::ImageCodecInfo*)(malloc(size));
  if (pImageCodecInfo == NULL) return -1;

  Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);

  for (UINT j = 0; j < num; ++j) {
    if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0) {
      *pClsid = pImageCodecInfo[j].Clsid;
      free(pImageCodecInfo);
      return j;
    }
  }

  free(pImageCodecInfo);
  return -1;
}

// Helper function to convert HBITMAP to PNG bytes
std::vector<uint8_t> HBitmapToPngBytes(HBITMAP hBitmap) {
  std::vector<uint8_t> result;

  Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromHBITMAP(hBitmap, NULL);
  if (!bitmap) return result;

  // Create IStream for memory
  IStream* stream = NULL;
  if (CreateStreamOnHGlobal(NULL, TRUE, &stream) != S_OK) {
    delete bitmap;
    return result;
  }

  // Get PNG encoder
  CLSID pngClsid;
  if (GetEncoderClsid(L"image/png", &pngClsid) < 0) {
    stream->Release();
    delete bitmap;
    return result;
  }

  // Save to stream
  if (bitmap->Save(stream, &pngClsid, NULL) != Gdiplus::Ok) {
    stream->Release();
    delete bitmap;
    return result;
  }

  // Get stream size
  STATSTG statstg;
  if (stream->Stat(&statstg, STATFLAG_DEFAULT) != S_OK) {
    stream->Release();
    delete bitmap;
    return result;
  }

  // Read stream data
  ULONG size = statstg.cbSize.LowPart;
  result.resize(size);

  LARGE_INTEGER li = {0};
  stream->Seek(li, STREAM_SEEK_SET, NULL);

  ULONG bytesRead;
  stream->Read(result.data(), size, &bytesRead);

  stream->Release();
  delete bitmap;

  return result;
}

// Helper function to convert PNG bytes to HBITMAP
HBITMAP PngBytesToHBitmap(const std::vector<uint8_t>& png_data) {
  // Create IStream from memory
  HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, png_data.size());
  if (!hMem) return NULL;

  void* pMem = GlobalLock(hMem);
  if (!pMem) {
    GlobalFree(hMem);
    return NULL;
  }

  memcpy(pMem, png_data.data(), png_data.size());
  GlobalUnlock(hMem);

  IStream* stream = NULL;
  if (CreateStreamOnHGlobal(hMem, TRUE, &stream) != S_OK) {
    GlobalFree(hMem);
    return NULL;
  }

  // Load bitmap from stream
  Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromStream(stream);
  stream->Release();

  if (!bitmap) return NULL;

  HBITMAP hBitmap;
  if (bitmap->GetHBITMAP(Gdiplus::Color(255, 255, 255), &hBitmap) != Gdiplus::Ok) {
    delete bitmap;
    return NULL;
  }

  delete bitmap;
  return hBitmap;
}

void ClipboardPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "com.icyhope.icy_easy_send/clipboard",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ClipboardPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ClipboardPlugin::ClipboardPlugin() : gdiplusToken_(0) {
  // Initialize GDI+
  Gdiplus::GdiplusStartupInput gdiplusStartupInput;
  Gdiplus::GdiplusStartup(&gdiplusToken_, &gdiplusStartupInput, NULL);
}

ClipboardPlugin::~ClipboardPlugin() {
  // Shutdown GDI+
  if (gdiplusToken_) {
    Gdiplus::GdiplusShutdown(gdiplusToken_);
  }
}

void ClipboardPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name() == "getImageFromClipboard") {
    EncodableValue image_data = GetImageFromClipboard();
    result->Success(image_data);
  } else if (method_call.method_name() == "setImageToClipboard") {
    const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    auto image_data_it = arguments->find(EncodableValue("imageData"));
    auto format_it = arguments->find(EncodableValue("format"));

    if (image_data_it == arguments->end() || format_it == arguments->end()) {
      result->Error("INVALID_ARGUMENT", "Missing imageData or format");
      return;
    }

    const auto* image_data = std::get_if<std::vector<uint8_t>>(&image_data_it->second);
    const auto* format = std::get_if<std::string>(&format_it->second);

    if (!image_data || !format) {
      result->Error("INVALID_ARGUMENT", "Invalid imageData or format type");
      return;
    }

    bool success = SetImageToClipboard(*image_data, *format);
    result->Success(EncodableValue(success));
  } else {
    result->NotImplemented();
  }
}

EncodableValue ClipboardPlugin::GetImageFromClipboard() {
  if (!OpenClipboard(NULL)) {
    return EncodableValue();
  }

  HANDLE hData = GetClipboardData(CF_BITMAP);
  if (!hData) {
    CloseClipboard();
    return EncodableValue();
  }

  HBITMAP hBitmap = (HBITMAP)hData;
  std::vector<uint8_t> png_data = HBitmapToPngBytes(hBitmap);

  CloseClipboard();

  if (png_data.empty()) {
    return EncodableValue();
  }

  EncodableMap result_map;
  result_map[EncodableValue("imageData")] = EncodableValue(png_data);
  result_map[EncodableValue("format")] = EncodableValue("png");

  return EncodableValue(result_map);
}

bool ClipboardPlugin::SetImageToClipboard(
    const std::vector<uint8_t>& image_data, const std::string& format) {
  HBITMAP hBitmap = PngBytesToHBitmap(image_data);
  if (!hBitmap) return false;

  if (!OpenClipboard(NULL)) {
    DeleteObject(hBitmap);
    return false;
  }

  EmptyClipboard();

  if (!SetClipboardData(CF_BITMAP, hBitmap)) {
    CloseClipboard();
    DeleteObject(hBitmap);
    return false;
  }

  CloseClipboard();
  // Don't delete hBitmap - clipboard owns it now

  return true;
}

}  // namespace

void ClipboardPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ClipboardPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
