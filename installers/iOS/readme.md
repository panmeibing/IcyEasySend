# iOS 发版产物

CI 通过 `flutter build ios --release --no-codesign` 构建，再用本目录的 `package_ipa.sh` 打成 `.ipa`。

## 本地打包

```bash
flutter pub get
flutter build ios --release --no-codesign
bash installers/iOS/package_ipa.sh 1.5.0
```

产物：`installers/iOS/Output/IcyEasySend-ios-v1.5.0.ipa`

## 说明

- **未签名**：与 macOS DMG 类似，不能直接通过 App Store / 普通「信任证书」安装。
- 常见用法：用 AltStore / Sideloadly / 自有开发者证书重新签名后再装到设备。
- 若以后要做签名 IPA，需配置 Apple 证书与描述文件，并改 CI 为 `flutter build ipa`（导出方法 ad-hoc / app-store）。
