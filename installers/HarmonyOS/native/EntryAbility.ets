import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import {
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import {
  abilityAccessCtrl,
  bundleManager,
  common,
  Permissions,
} from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { Environment, fileUri, fileIo as fs, picker } from '@kit.CoreFileKit';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const OHOS_FS_CHANNEL = 'com.icyhope.icy_easy_send/ohos_fs';
const CLIPBOARD_CHANNEL = 'com.icyhope.icy_easy_send/clipboard';
const READ_PASTEBOARD: Permissions = 'ohos.permission.READ_PASTEBOARD';

/**
 * Resolves a user-visible Downloads directory for received files.
 * Phones cannot use Environment.getUserDownloadDir (syscap FolderObtain);
 * DocumentViewPicker DOWNLOAD mode creates Download/<bundleName>/ instead.
 *
 * Also exposes pasteboard helpers: ensure READ_PASTEBOARD (user_grant) then
 * silent text read. Dart falls back to paste-to-share when this fails.
 */
export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    this.registerPublicDownloadsChannel(flutterEngine);
    this.registerClipboardChannel(flutterEngine);
  }

  private registerPublicDownloadsChannel(flutterEngine: FlutterEngine): void {
    const channel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      OHOS_FS_CHANNEL,
    );
    const ability = this;
    channel.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult): void {
        if (call.method === 'getPublicDownloadsPath') {
          ability.resolvePublicDownloadsPath(result);
        } else {
          result.notImplemented();
        }
      },
    } as MethodCallHandler);
  }

  private registerClipboardChannel(flutterEngine: FlutterEngine): void {
    const channel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      CLIPBOARD_CHANNEL,
    );
    const ability = this;
    channel.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult): void {
        if (call.method === 'ensureReadPasteboardPermission') {
          ability.ensureReadPasteboardPermission(result);
        } else if (call.method === 'getTextFromClipboard') {
          ability.readPasteboardText(result);
        } else {
          result.notImplemented();
        }
      },
    } as MethodCallHandler);
  }

  private async ensureReadPasteboardPermission(result: MethodResult): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;
      const status = atManager.checkAccessTokenSync(tokenId, READ_PASTEBOARD);
      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        result.success(true);
        return;
      }

      const context = this.context as common.UIAbilityContext;
      const requestResult = await atManager.requestPermissionsFromUser(
        context,
        [READ_PASTEBOARD],
      );
      const granted =
        requestResult.authResults !== undefined &&
        requestResult.authResults.length > 0 &&
        requestResult.authResults[0] === 0;
      result.success(granted);
    } catch (err) {
      const e = err as BusinessError;
      console.info(
        `ensureReadPasteboardPermission failed (code=${e?.code}): ${e?.message ?? err}`,
      );
      // Not granted / unsupported device — Dart will use paste dialog.
      result.success(false);
    }
  }

  private readPasteboardText(result: MethodResult): void {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard
        .getData()
        .then((data: pasteboard.PasteData) => {
          try {
            const text = data.getPrimaryText();
            if (text === undefined || text === null || text.trim().length === 0) {
              result.success(null);
              return;
            }
            result.success(text);
          } catch (parseErr) {
            result.error('PARSE', `${parseErr}`, null);
          }
        })
        .catch((err: BusinessError) => {
          result.error(
            'READ_FAIL',
            `code=${err?.code} message=${err?.message ?? err}`,
            null,
          );
        });
    } catch (err) {
      result.error('SETUP', `${err}`, null);
    }
  }

  private resolvePublicDownloadsPath(result: MethodResult): void {
    try {
      const dir = Environment.getUserDownloadDir();
      if (dir !== undefined && dir !== null && dir.length > 0) {
        try {
          if (!fs.accessSync(dir)) {
            fs.mkdirSync(dir, true);
          }
        } catch (_mkdirErr) {
          // Directory may already exist or be pre-authorized.
        }
        result.success(dir);
        return;
      }
    } catch (err) {
      const e = err as BusinessError;
      console.info(
        `getUserDownloadDir unavailable (code=${e?.code}): ${e?.message ?? err}`,
      );
    }

    this.resolveViaDownloadPicker(result);
  }

  private resolveViaDownloadPicker(result: MethodResult): void {
    try {
      const context = this.context as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSaveOptions();
      options.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
      documentViewPicker
        .save(options)
        .then((uris: Array<string>) => {
          if (uris === undefined || uris === null || uris.length === 0) {
            result.error('NO_URI', 'DocumentViewPicker DOWNLOAD returned empty', null);
            return;
          }
          try {
            const path = new fileUri.FileUri(uris[0]).path;
            if (path === undefined || path === null || path.length === 0) {
              result.error('EMPTY_PATH', `Cannot resolve path from uri=${uris[0]}`, null);
              return;
            }
            try {
              if (!fs.accessSync(path)) {
                fs.mkdirSync(path, true);
              }
            } catch (_mkdirErr) {
              // Ignore; write probe on Dart side will validate.
            }
            result.success(path);
          } catch (pathErr) {
            result.error('URI_PATH', `${pathErr}`, null);
          }
        })
        .catch((err: BusinessError) => {
          result.error(
            'PICKER_FAIL',
            `code=${err?.code} message=${err?.message ?? err}`,
            null,
          );
        });
    } catch (err) {
      result.error('PICKER_SETUP', `${err}`, null);
    }
  }
}
