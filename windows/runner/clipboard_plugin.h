#ifndef RUNNER_CLIPBOARD_PLUGIN_H_
#define RUNNER_CLIPBOARD_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef __cplusplus
extern "C" {
#endif

void ClipboardPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // RUNNER_CLIPBOARD_PLUGIN_H_
