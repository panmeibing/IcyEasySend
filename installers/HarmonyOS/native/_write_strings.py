# -*- coding: utf-8 -*-
"""Upsert HarmonyOS string resources without wiping unrelated keys."""
from pathlib import Path
import json

repo = Path(__file__).resolve().parents[3]
base = repo / "ohos" / "entry" / "src" / "main" / "resources"

ENTRIES = {
    "base/element/string.json": {
        "module_desc": "module description",
        "EntryAbility_desc": "description",
        "EntryAbility_label": "IcyEasySend",
        "perm_reason_download": "用于将接收到的文件保存到系统下载目录，便于在文件管理中查看",
        "perm_reason_pasteboard": (
            "用于在本机授权后读取剪切板，以便与局域网/中转对端同步文本内容"
        ),
    },
    "zh_CN/element/string.json": {
        "module_desc": "模块描述",
        "EntryAbility_desc": "Ability描述",
        "EntryAbility_label": "IcyEasySend",
        "perm_reason_download": "用于将接收到的文件保存到系统下载目录，便于在文件管理中查看",
        "perm_reason_pasteboard": (
            "用于在本机授权后读取剪切板，以便与局域网/中转对端同步文本内容"
        ),
    },
    "en_US/element/string.json": {
        "module_desc": "module description",
        "EntryAbility_desc": "description",
        "EntryAbility_label": "IcyEasySend",
        "perm_reason_download": (
            "Used to save received files to the system Downloads folder "
            "so they appear in Files"
        ),
        "perm_reason_pasteboard": (
            "Used to read the clipboard after user grant so text can be "
            "synced with LAN or relay peers"
        ),
    },
}


def upsert(path: Path, desired: dict[str, str]) -> None:
    if path.exists():
        data = json.loads(path.read_text(encoding="utf-8"))
    else:
        data = {"string": []}
        path.parent.mkdir(parents=True, exist_ok=True)

    by_name = {item["name"]: item for item in data.get("string", [])}
    for name, value in desired.items():
        by_name[name] = {"name": name, "value": value}

    data["string"] = list(by_name.values())
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(path.relative_to(repo), "OK")


def main() -> None:
    for rel, desired in ENTRIES.items():
        upsert(base / rel, desired)


if __name__ == "__main__":
    main()
