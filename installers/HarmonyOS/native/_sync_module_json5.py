# -*- coding: utf-8 -*-
"""Sync tracked module.json5 into local ohos/ (includes ACL permissions)."""
from pathlib import Path

repo = Path(__file__).resolve().parents[3]
module_src = Path(__file__).resolve().parent / "module.json5"
module_dst = repo / "ohos" / "entry" / "src" / "main" / "module.json5"

module_dst.write_text(module_src.read_text(encoding="utf-8"), encoding="utf-8")
print("module.json5 synced (with download + pasteboard ACL permissions)")
