import 'dart:convert';

import 'package:path/path.dart' as path;

import '../models/web_share_session.dart';
import '../utils/constants.dart';
import '../utils/format_util.dart';
import 'web_share_asset_handler.dart';

/// Builds HTML pages served to guest browsers for LAN web share.
class WebSharePageBuilder {
  WebSharePageBuilder._();

  static String buildDownloadPage(
    WebShareSession session, {
    required bool preferChinese,
  }) {
    final escape = const HtmlEscape();
    final brand = AppConstants.projectName;
    final logoUrl = WebShareAssetHandler.logoRoutePath;
    final title = preferChinese ? '有人给你分享了文件' : 'Files shared with you';
    final rawDeviceName = session.deviceName?.trim();
    final deviceName = escape.convert(
      (rawDeviceName != null && rawDeviceName.isNotEmpty)
          ? rawDeviceName
          : brand,
    );
    final subtitle = preferChinese
        ? '来自 $deviceName'
        : 'From $deviceName';
    final hint = preferChinese
        ? '请保持与分享端同一 Wi‑Fi。点下方文件即可下载。'
        : 'Stay on the same Wi‑Fi as the sender. Tap a file to download.';
    final downloadAllLabel = preferChinese ? '全部下载' : 'Download all';
    final sizeLabel = preferChinese ? '总大小' : 'Total';
    final filesLabel = preferChinese ? '个文件' : 'files';
    final downloadLabel = preferChinese ? '下载' : 'Get';
    final lanNote = preferChinese ? '仅局域网传输 · 不经过云端' : 'LAN only · no cloud';

    final fileItems = StringBuffer();
    for (final file in session.files) {
      final href = '/s/${session.token}/file/${file.id}';
      final sizeText = FormatUtil.formatBytes(file.size);
      final baseName = path.basename(file.displayName);
      final safeName = escape.convert(baseName);
      final downloadAttr = escape.convert(baseName);
      final ext = path.extension(baseName).replaceFirst('.', '').toUpperCase();
      final badge = escape.convert(ext.isEmpty ? 'FILE' : ext);
      fileItems.writeln('''
        <a class="file" href="$href" download="$downloadAttr">
          <span class="badge" aria-hidden="true">$badge</span>
          <span class="info">
            <span class="name">$safeName</span>
            <span class="meta">$sizeText</span>
          </span>
          <span class="action">$downloadLabel</span>
        </a>
      ''');
    }

    final fileCount = session.files.length;
    final totalSize = FormatUtil.formatBytes(session.totalSize);

    return '''
<!DOCTYPE html>
<html lang="${preferChinese ? "zh" : "en"}">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
  <meta name="color-scheme" content="light"/>
  <meta name="theme-color" content="#2563eb"/>
  <title>$title · $brand</title>
  <style>
    :root {
      --ink: #0f172a;
      --muted: #64748b;
      --line: rgba(37, 99, 235, 0.12);
      --surface: rgba(255, 255, 255, 0.86);
      --surface-solid: #ffffff;
      --accent: #2563eb;
      --accent-deep: #1d4ed8;
      --accent-soft: rgba(37, 99, 235, 0.1);
      --sky: #60a5fa;
      --sky-soft: #dbeafe;
      --shadow: 0 18px 50px rgba(30, 64, 175, 0.12);
      --radius: 22px;
    }
    * { box-sizing: border-box; }
    html, body { min-height: 100%; }
    body {
      margin: 0;
      color: var(--ink);
      font-family: "Segoe UI", "PingFang SC", "Hiragino Sans GB",
        "Microsoft YaHei", system-ui, sans-serif;
      background:
        radial-gradient(920px 440px at 10% -10%, rgba(96, 165, 250, 0.38), transparent 58%),
        radial-gradient(720px 380px at 100% 0%, rgba(37, 99, 235, 0.16), transparent 52%),
        linear-gradient(165deg, #eff6ff 0%, #f1f5f9 48%, #f8fafc 100%);
      padding: 28px 18px 48px;
      -webkit-font-smoothing: antialiased;
    }
    .wrap {
      width: min(100%, 520px);
      margin: 0 auto;
      animation: rise 0.45s ease-out both;
    }
    @keyframes rise {
      from { opacity: 0; transform: translateY(12px); }
      to { opacity: 1; transform: none; }
    }
    .hero {
      text-align: center;
      margin-bottom: 22px;
    }
    .logo {
      width: 72px;
      height: 72px;
      margin: 0 auto 14px;
      display: block;
      border-radius: 50%;
      box-shadow:
        0 14px 30px rgba(37, 99, 235, 0.28),
        0 0 0 4px rgba(255, 255, 255, 0.75);
      background: #fff;
      object-fit: cover;
    }
    .brand {
      margin: 0;
      font-size: clamp(1.7rem, 5.5vw, 2rem);
      font-weight: 750;
      letter-spacing: -0.03em;
      line-height: 1.15;
    }
    .brand span {
      display: inline-block;
      background: linear-gradient(120deg, #1d4ed8 0%, #2563eb 48%, #3b82f6 100%);
      -webkit-background-clip: text;
      background-clip: text;
      color: transparent;
    }
    .panel {
      background: var(--surface);
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
      border: 1px solid rgba(255, 255, 255, 0.75);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 22px 18px 18px;
    }
    .headline {
      margin: 0 0 6px;
      font-size: 1.15rem;
      font-weight: 700;
      letter-spacing: -0.02em;
    }
    .sub {
      margin: 0 0 10px;
      color: var(--muted);
      font-size: 0.95rem;
      line-height: 1.45;
    }
    .hint {
      margin: 0 0 18px;
      color: var(--muted);
      font-size: 0.86rem;
      line-height: 1.5;
    }
    .stats {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      margin-bottom: 14px;
    }
    .chip {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 11px;
      border-radius: 999px;
      background: var(--accent-soft);
      color: var(--accent-deep);
      font-size: 0.82rem;
      font-weight: 600;
    }
    .files { display: grid; gap: 10px; }
    .file {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: 12px;
      align-items: center;
      text-decoration: none;
      color: inherit;
      padding: 12px;
      border-radius: 16px;
      background: var(--surface-solid);
      border: 1px solid var(--line);
      box-shadow: 0 1px 0 rgba(255, 255, 255, 0.8) inset;
      transition: transform 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
    }
    .file:hover {
      border-color: rgba(37, 99, 235, 0.3);
      box-shadow: 0 8px 20px rgba(30, 64, 175, 0.08);
    }
    .file:active { transform: scale(0.985); }
    .badge {
      min-width: 44px;
      height: 44px;
      padding: 0 6px;
      border-radius: 12px;
      display: grid;
      place-items: center;
      background: linear-gradient(160deg, #eff6ff, #dbeafe);
      color: var(--accent-deep);
      font-size: 0.62rem;
      font-weight: 800;
      letter-spacing: 0.02em;
      text-align: center;
      line-height: 1.1;
      word-break: break-all;
    }
    .info { min-width: 0; display: grid; gap: 3px; }
    .name {
      font-weight: 650;
      font-size: 0.95rem;
      line-height: 1.35;
      word-break: break-all;
    }
    .meta {
      color: var(--muted);
      font-size: 0.82rem;
    }
    .action {
      color: var(--accent-deep);
      font-size: 0.86rem;
      font-weight: 700;
      white-space: nowrap;
      padding: 8px 4px 8px 8px;
    }
    .toolbar { margin-top: 14px; }
    .primary {
      width: 100%;
      border: 0;
      border-radius: 14px;
      padding: 14px 16px;
      background: linear-gradient(135deg, #3b82f6, #2563eb 55%, #1d4ed8);
      color: #fff;
      font-size: 1rem;
      font-weight: 700;
      letter-spacing: 0.01em;
      box-shadow: 0 10px 22px rgba(37, 99, 235, 0.3);
    }
    .primary:active { transform: translateY(1px); }
    .footer {
      margin-top: 18px;
      text-align: center;
      color: var(--muted);
      font-size: 0.78rem;
      letter-spacing: 0.01em;
    }
    @media (prefers-reduced-motion: reduce) {
      .wrap { animation: none; }
      .file, .primary { transition: none; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <header class="hero">
      <img class="logo" src="$logoUrl" width="72" height="72" alt="$brand"/>
      <h1 class="brand"><span>$brand</span></h1>
    </header>

    <main class="panel">
      <h2 class="headline">$title</h2>
      <p class="sub">$subtitle</p>
      <p class="hint">$hint</p>
      <div class="stats">
        <span class="chip">$fileCount $filesLabel</span>
        <span class="chip">$sizeLabel $totalSize</span>
      </div>
      <div class="files">
        ${fileItems.toString()}
      </div>
      <div class="toolbar">
        <button type="button" class="primary" id="downloadAll">$downloadAllLabel</button>
      </div>
    </main>
    <p class="footer">$lanNote</p>
  </div>
  <script>
    (function () {
      var links = Array.prototype.slice.call(document.querySelectorAll('a.file'));
      var btn = document.getElementById('downloadAll');
      if (!btn) return;
      btn.addEventListener('click', function () {
        links.forEach(function (link, index) {
          setTimeout(function () {
            var a = document.createElement('a');
            a.href = link.href;
            var name = link.getAttribute('download');
            if (name) a.setAttribute('download', name);
            document.body.appendChild(a);
            a.click();
            a.remove();
          }, index * 400);
        });
      });
    })();
  </script>
</body>
</html>
''';
  }

  static String buildGonePage() {
    final brand = AppConstants.projectName;
    final logoUrl = WebShareAssetHandler.logoRoutePath;
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="theme-color" content="#2563eb"/>
  <title>Link expired · $brand</title>
  <style>
    :root {
      --ink: #0f172a;
      --muted: #64748b;
      --accent: #2563eb;
    }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      font-family: "Segoe UI", "PingFang SC", "Microsoft YaHei", system-ui, sans-serif;
      color: var(--ink);
      background:
        radial-gradient(720px 340px at 18% 0%, rgba(96, 165, 250, 0.35), transparent 55%),
        linear-gradient(165deg, #eff6ff, #f8fafc);
    }
    .card {
      width: min(100%, 420px);
      text-align: center;
      background: rgba(255,255,255,0.9);
      border: 1px solid rgba(37, 99, 235, 0.12);
      border-radius: 22px;
      padding: 32px 24px;
      box-shadow: 0 18px 50px rgba(30, 64, 175, 0.1);
    }
    .logo {
      width: 64px; height: 64px; margin: 0 auto 14px; display: block;
      border-radius: 50%;
      box-shadow: 0 12px 24px rgba(37, 99, 235, 0.25), 0 0 0 3px rgba(255,255,255,0.8);
      background: #fff;
      object-fit: cover;
    }
    h1 { font-size: 1.25rem; margin: 0 0 10px; }
    p { margin: 0; color: var(--muted); line-height: 1.55; font-size: 0.95rem; }
    .brand { margin-top: 18px; color: var(--accent); font-weight: 700; font-size: 0.9rem; }
  </style>
</head>
<body>
  <div class="card">
    <img class="logo" src="$logoUrl" width="64" height="64" alt="$brand"/>
    <h1>Link expired / 链接已失效</h1>
    <p>This share is no longer available. Ask the sender to create a new QR code.<br/>
    该分享已过期或已停止，请让对方重新生成二维码。</p>
    <div class="brand">$brand</div>
  </div>
</body>
</html>
''';
  }
}
