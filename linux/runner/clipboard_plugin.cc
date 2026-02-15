#include "clipboard_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include <cstring>

struct _ClipboardPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(ClipboardPlugin, clipboard_plugin, G_TYPE_OBJECT)

// Helper function to convert GdkPixbuf to PNG bytes
static GBytes* pixbuf_to_png_bytes(GdkPixbuf* pixbuf) {
  gchar* buffer = nullptr;
  gsize buffer_size = 0;
  GError* error = nullptr;

  if (!gdk_pixbuf_save_to_buffer(pixbuf, &buffer, &buffer_size, "png", &error,
                                 nullptr)) {
    if (error) {
      g_warning("Failed to convert pixbuf to PNG: %s", error->message);
      g_error_free(error);
    }
    return nullptr;
  }

  return g_bytes_new_take(buffer, buffer_size);
}

// Helper function to convert PNG bytes to GdkPixbuf
static GdkPixbuf* png_bytes_to_pixbuf(const guint8* data, gsize size) {
  GError* error = nullptr;
  GInputStream* stream = g_memory_input_stream_new_from_data(data, size, nullptr);
  
  GdkPixbuf* pixbuf = gdk_pixbuf_new_from_stream(stream, nullptr, &error);
  g_object_unref(stream);

  if (error) {
    g_warning("Failed to create pixbuf from PNG: %s", error->message);
    g_error_free(error);
    return nullptr;
  }

  return pixbuf;
}

// Get image from clipboard
static FlValue* get_image_from_clipboard() {
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  
  GdkPixbuf* pixbuf = gtk_clipboard_wait_for_image(clipboard);
  if (!pixbuf) {
    return fl_value_new_null();
  }

  GBytes* png_bytes = pixbuf_to_png_bytes(pixbuf);
  g_object_unref(pixbuf);

  if (!png_bytes) {
    return fl_value_new_null();
  }

  gsize size;
  const guint8* data = static_cast<const guint8*>(g_bytes_get_data(png_bytes, &size));

  FlValue* result = fl_value_new_map();
  fl_value_set_string_take(result, "imageData", 
                          fl_value_new_uint8_list(data, size));
  fl_value_set_string_take(result, "format", fl_value_new_string("png"));

  g_bytes_unref(png_bytes);

  return result;
}

// Set image to clipboard
static gboolean set_image_to_clipboard(const guint8* image_data, gsize size) {
  GdkPixbuf* pixbuf = png_bytes_to_pixbuf(image_data, size);
  if (!pixbuf) {
    return FALSE;
  }

  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  gtk_clipboard_set_image(clipboard, pixbuf);
  gtk_clipboard_store(clipboard);

  g_object_unref(pixbuf);

  return TRUE;
}

// Handle method calls
static void method_call_cb(FlMethodChannel* channel,
                          FlMethodCall* method_call,
                          gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "getImageFromClipboard") == 0) {
    FlValue* result = get_image_from_clipboard();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "setImageToClipboard") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "Arguments must be a map", nullptr));
    } else {
      FlValue* image_data_value = fl_value_lookup_string(args, "imageData");
      FlValue* format_value = fl_value_lookup_string(args, "format");

      if (!image_data_value || !format_value) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENT", "Missing imageData or format", nullptr));
      } else if (fl_value_get_type(image_data_value) != FL_VALUE_TYPE_UINT8_LIST) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENT", "imageData must be Uint8List", nullptr));
      } else {
        const guint8* image_data = fl_value_get_uint8_list(image_data_value);
        size_t size = fl_value_get_length(image_data_value);

        gboolean success = set_image_to_clipboard(image_data, size);
        
        g_autoptr(FlValue) result = fl_value_new_bool(success);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      }
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

static void clipboard_plugin_dispose(GObject* object) {
  ClipboardPlugin* self = CLIPBOARD_PLUGIN(object);
  
  g_clear_object(&self->channel);

  G_OBJECT_CLASS(clipboard_plugin_parent_class)->dispose(object);
}

static void clipboard_plugin_class_init(ClipboardPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = clipboard_plugin_dispose;
}

static void clipboard_plugin_init(ClipboardPlugin* self) {}

ClipboardPlugin* clipboard_plugin_new() {
  return CLIPBOARD_PLUGIN(g_object_new(clipboard_plugin_get_type(), nullptr));
}

void clipboard_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ClipboardPlugin* plugin = clipboard_plugin_new();

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.icyhope.icy_easy_send/clipboard",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
