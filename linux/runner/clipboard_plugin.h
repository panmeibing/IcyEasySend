#ifndef FLUTTER_CLIPBOARD_PLUGIN_H_
#define FLUTTER_CLIPBOARD_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#define CLIPBOARD_PLUGIN_TYPE (clipboard_plugin_get_type())

G_DECLARE_FINAL_TYPE(ClipboardPlugin,
                     clipboard_plugin,
                     CLIPBOARD,
                     PLUGIN,
                     GObject)

/**
 * clipboard_plugin_new:
 *
 * Creates a new clipboard plugin.
 *
 * Returns: a new #ClipboardPlugin.
 */
ClipboardPlugin* clipboard_plugin_new();

/**
 * clipboard_plugin_register_with_registrar:
 * @registrar: an #FlPluginRegistrar
 *
 * Registers the clipboard plugin with the Flutter engine.
 */
void clipboard_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_CLIPBOARD_PLUGIN_H_
