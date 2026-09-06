#!/usr/bin/env python3
"""Extract System B provider messages into app_*.arb files.

Adds only keys that are not already present in app_en.arb.
Parameterized messages: Dart $param / ${param} -> ICU {param}.
@key placeholder metadata is written only into the template (app_en.arb).
Missing locale strings fall back to English.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
UTILS = ROOT / "lib" / "utils"

LOCALES = [
    "en",
    "zh",
    "zh_HK",
    "de",
    "es",
    "fr",
    "it",
    "ja",
    "ko",
    "nl",
    "pt",
    "ru",
]

# Locale key in providers -> arb filename suffix
LOCALE_TO_ARB = {
    "en": "app_en.arb",
    "zh": "app_zh.arb",
    "zh_HK": "app_zh_HK.arb",
    "de": "app_de.arb",
    "es": "app_es.arb",
    "fr": "app_fr.arb",
    "it": "app_it.arb",
    "ja": "app_ja.arb",
    "ko": "app_ko.arb",
    "nl": "app_nl.arb",
    "pt": "app_pt.arb",
    "ru": "app_ru.arb",
}

TYPE_MAP = {
    "String": "String",
    "int": "int",
    "double": "double",
    "num": "num",
}


@dataclass
class Message:
    key: str
    translations: dict[str, str]  # locale -> text (ICU)
    placeholders: dict[str, str] = field(default_factory=dict)  # name -> type
    source: str = ""
    fallback_locales: list[str] = field(default_factory=list)


def unescape_dart_string(s: str) -> str:
    """Unescape a Dart single/double-quoted string body."""
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            mapping = {
                "n": "\n",
                "r": "\r",
                "t": "\t",
                "'": "'",
                '"': '"',
                "\\": "\\",
                "$": "$",
            }
            out.append(mapping.get(nxt, nxt))
            i += 2
            continue
        out.append(s[i])
        i += 1
    return "".join(out)


def dart_interp_to_icu(text: str, param_alias: dict[str, str] | None = None) -> str:
    """Convert Dart string interpolations to ICU placeholders."""
    alias = param_alias or {}

    def repl_braced(m: re.Match[str]) -> str:
        expr = m.group(1).strip()
        # Only simple identifiers — complex expressions cannot be extracted cleanly.
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", expr):
            name = alias.get(expr, expr)
            return "{" + name + "}"
        return m.group(0)  # leave as-is; caller may flag

    def repl_simple(m: re.Match[str]) -> str:
        name = m.group(1)
        name = alias.get(name, name)
        return "{" + name + "}"

    text = re.sub(r"\$\{([^}]+)\}", repl_braced, text)
    text = re.sub(r"\$([A-Za-z_][A-Za-z0-9_]*)", repl_simple, text)
    return text


def has_unconverted_dart_interp(text: str) -> bool:
    # After conversion, leftover ${...} with expressions, or $ident that wasn't a placeholder
    if re.search(r"\$\{[^}]+\}", text):
        return True
    if re.search(r"\$[A-Za-z_]", text):
        return True
    return False


def extract_string_literal(src: str, start: int) -> tuple[str, int] | None:
    """Extract a Dart string starting at start (must be ' or \"). Returns (body, end_index)."""
    if start >= len(src) or src[start] not in "'\"":
        return None
    quote = src[start]
    i = start + 1
    raw: list[str] = []
    while i < len(src):
        ch = src[i]
        if ch == "\\" and i + 1 < len(src):
            raw.append(src[i : i + 2])
            i += 2
            continue
        if ch == quote:
            return ("".join(raw), i + 1)
        raw.append(ch)
        i += 1
    return None


def skip_ws_and_comments(src: str, i: int) -> int:
    n = len(src)
    while i < n:
        if src[i] in " \t\r\n":
            i += 1
            continue
        if src.startswith("//", i):
            nl = src.find("\n", i)
            i = n if nl < 0 else nl + 1
            continue
        if src.startswith("/*", i):
            end = src.find("*/", i + 2)
            i = n if end < 0 else end + 2
            continue
        break
    return i


def find_matching(src: str, open_idx: int, open_ch: str, close_ch: str) -> int:
    """Return index of matching close_ch for open at open_idx. Handles strings."""
    depth = 0
    i = open_idx
    n = len(src)
    while i < n:
        ch = src[i]
        if ch in "'\"":
            lit = extract_string_literal(src, i)
            if lit is None:
                return -1
            i = lit[1]
            continue
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def parse_map_entries(map_body: str) -> dict[str, str]:
    """Parse locale -> string entries from a map body (without outer braces).

    Supports both plain strings and single-expression lambdas that return a string.
    Concatenated adjacent string literals are joined.
    """
    entries: dict[str, str] = {}
    i = 0
    n = len(map_body)
    while i < n:
        i = skip_ws_and_comments(map_body, i)
        if i >= n:
            break
        if map_body[i] == ",":
            i += 1
            continue

        # Key: 'locale'
        key_lit = extract_string_literal(map_body, i)
        if key_lit is None:
            break
        locale = unescape_dart_string(key_lit[0])
        i = skip_ws_and_comments(map_body, key_lit[1])
        if i >= n or map_body[i] != ":":
            break
        i = skip_ws_and_comments(map_body, i + 1)

        # Value: either string(s), or (params) => string(s)
        if map_body[i] == "(":
            # lambda — skip param list, then =>, then string expression
            close_paren = find_matching(map_body, i, "(", ")")
            if close_paren < 0:
                break
            i = skip_ws_and_comments(map_body, close_paren + 1)
            if not map_body.startswith("=>", i):
                break
            i = skip_ws_and_comments(map_body, i + 2)

        # Collect one or more adjacent string literals (possibly with +)
        parts: list[str] = []
        while i < n:
            i = skip_ws_and_comments(map_body, i)
            if i < n and map_body[i] in "'\"":
                lit = extract_string_literal(map_body, i)
                if lit is None:
                    break
                parts.append(unescape_dart_string(lit[0]))
                i = skip_ws_and_comments(map_body, lit[1])
                # optional +
                if i < n and map_body[i] == "+":
                    i += 1
                    continue
                break
            break

        if not parts:
            # Could not extract — skip this entry
            # Advance to next top-level comma roughly
            while i < n and map_body[i] not in ",":
                if map_body[i] in "'\"":
                    lit = extract_string_literal(map_body, i)
                    i = lit[1] if lit else i + 1
                else:
                    i += 1
            continue

        entries[locale] = "".join(parts)
        # consume until comma or end
        i = skip_ws_and_comments(map_body, i)
        if i < n and map_body[i] == ",":
            i += 1

    return entries


METHOD_RE = re.compile(
    r"""
    (?:String|Future<\s*String\s*>)\s+
    (?:get\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)
    (?:\s*\((?P<params>[^)]*)\))?
    \s*(?:=>|{)
    """,
    re.VERBOSE,
)

PARAM_RE = re.compile(
    r"(?P<type>String|int|double|num)\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
)


def parse_formal_params(params: str | None) -> list[tuple[str, str]]:
    if not params or not params.strip():
        return []
    return [(m.group("name"), m.group("type")) for m in PARAM_RE.finditer(params)]


def find_message_map_after(src: str, method_start: int) -> tuple[str, int] | None:
    """Find the first map-literal argument to getMessage* after method_start."""
    # Look for getMessage / getMessageWith* within a reasonable window
    window = src[method_start : method_start + 8000]
    m = re.search(
        r"getMessage(?:With(?:1Param|2Params|3Params|MapParam))?\s*(?:<\s*[^>]+>)?\s*\(",
        window,
    )
    if not m:
        # Also handle: final messages = <String, ...>{ ... }; return getMessage
        m2 = re.search(
            r"(?:final|const|var)\s+\w+\s*=\s*(?:<[^>]+>)?\s*\{",
            window,
        )
        if not m2:
            return None
        brace = method_start + m2.end() - 1
        close = find_matching(src, brace, "{", "}")
        if close < 0:
            return None
        return src[brace + 1 : close], close + 1

    call_open = method_start + m.end() - 1  # '('
    # Find the map `{` after the call paren (skip generics already handled)
    i = skip_ws_and_comments(src, call_open + 1)
    # Optional type args already consumed; expect `{` or `<...>{`
    if src.startswith("<", i):
        gt = src.find(">", i)
        if gt < 0:
            return None
        i = skip_ws_and_comments(src, gt + 1)
    if i >= len(src) or src[i] != "{":
        return None
    close = find_matching(src, i, "{", "}")
    if close < 0:
        return None
    return src[i + 1 : close], close + 1


def build_param_alias(
    formals: list[tuple[str, str]], map_body: str
) -> dict[str, str]:
    """Map lambda param names used in bodies to formal names when they differ.

    Heuristic: for getMessageWith2Params style, lambdas often rename the last
    param (e.g. maxAttempts -> max). Detect `(a, b) =>` patterns and zip with formals.
    """
    alias: dict[str, str] = {}
    if not formals:
        return alias
    # Find first lambda param list in the map
    m = re.search(r"\(\s*([^)]*?)\s*\)\s*=>", map_body)
    if not m:
        return alias
    raw = m.group(1).strip()
    if not raw:
        return alias
    lambda_params = [p.strip() for p in raw.split(",") if p.strip()]
    # Strip types if present
    cleaned = []
    for p in lambda_params:
        parts = p.split()
        cleaned.append(parts[-1])
    for lp, (fp, _) in zip(cleaned, formals):
        if lp != fp:
            alias[lp] = fp
    return alias


def extract_from_provider(
    path: Path,
    *,
    only_keys: set[str] | None = None,
    skip_keys: set[str] | None = None,
) -> tuple[list[Message], list[str]]:
    """Return (messages, unclean_keys)."""
    src = path.read_text(encoding="utf-8")
    unclean: list[str] = []
    messages: list[Message] = []
    seen: set[str] = set()

    for m in METHOD_RE.finditer(src):
        name = m.group("name")
        if name in seen:
            continue
        if only_keys is not None and name not in only_keys:
            continue
        if skip_keys is not None and name in skip_keys:
            continue

        formals = parse_formal_params(m.group("params"))
        found = find_message_map_after(src, m.start())
        if not found:
            # getters that use AppConstants interpolation etc. may still have maps
            unclean.append(f"{name} (no message map found)")
            continue

        map_body, _ = found
        raw_entries = parse_map_entries(map_body)
        if not raw_entries:
            unclean.append(f"{name} (empty/unparsed map)")
            continue

        alias = build_param_alias(formals, map_body)
        translations: dict[str, str] = {}
        bad = False
        for locale, text in raw_entries.items():
            icu = dart_interp_to_icu(text, alias)
            if has_unconverted_dart_interp(icu):
                unclean.append(f"{name}@{locale} (complex interpolation)")
                bad = True
                break
            # Skip maps that still contain AppConstants / other non-string embeds
            if "${" in text or "AppConstants" in text:
                unclean.append(f"{name}@{locale} (non-literal embed)")
                bad = True
                break
            translations[locale] = icu

        if bad:
            continue

        # Fill English fallback for missing locales
        en = translations.get("en")
        if en is None:
            unclean.append(f"{name} (missing en)")
            continue

        fallback_locales: list[str] = []
        for loc in LOCALES:
            if loc not in translations:
                translations[loc] = en
                fallback_locales.append(loc)

        placeholders = {pname: TYPE_MAP[ptype] for pname, ptype in formals}
        # Verify placeholders mentioned in English exist
        used = set(re.findall(r"\{([A-Za-z_][A-Za-z0-9_]*)\}", translations["en"]))
        # Drop unused formals from metadata; add missing as String
        for u in used:
            if u not in placeholders:
                placeholders[u] = "String"
        placeholders = {k: v for k, v in placeholders.items() if k in used}

        seen.add(name)
        messages.append(
            Message(
                key=name,
                translations=translations,
                placeholders=placeholders,
                source=path.name,
                fallback_locales=fallback_locales,
            )
        )

    return messages, unclean


def load_arb(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_arb(path: Path, data: dict) -> None:
    # Preserve trailing newline; indent like existing files (2 spaces).
    text = json.dumps(data, ensure_ascii=False, indent=2)
    path.write_text(text + "\n", encoding="utf-8")


def main() -> int:
    en_path = L10N / "app_en.arb"
    existing = load_arb(en_path)
    existing_keys = {k for k in existing if not k.startswith("@")}

    plans: list[tuple[Path, set[str] | None]] = [
        (
            UTILS / "error_message_provider.dart",
            {"foregroundServiceChannelName", "foregroundServiceChannelDescription"},
        ),
        (UTILS / "pairing_message_provider.dart", None),
        (UTILS / "relay_message_provider.dart", None),
        (UTILS / "transfer_status_provider.dart", None),
    ]

    all_messages: list[Message] = []
    all_unclean: list[str] = []
    skipped_existing: list[str] = []
    skipped_collision: list[str] = []

    collected_keys: set[str] = set(existing_keys)

    for path, only in plans:
        msgs, unclean = extract_from_provider(path, only_keys=only)
        all_unclean.extend(f"{path.name}: {u}" for u in unclean)
        for msg in msgs:
            if msg.key in collected_keys:
                # Already in ARB or already collected from an earlier provider
                if msg.key in existing_keys:
                    skipped_existing.append(f"{msg.key} ({path.name})")
                else:
                    skipped_collision.append(
                        f"{msg.key} ({path.name}) — already taken by earlier provider"
                    )
                continue
            collected_keys.add(msg.key)
            all_messages.append(msg)

    if not all_messages:
        print("No new keys to add.")
        return 0

    # Append to every locale ARB
    arbs: dict[str, dict] = {}
    for loc, fname in LOCALE_TO_ARB.items():
        arbs[loc] = load_arb(L10N / fname)

    fallback_report: dict[str, list[str]] = {}

    for msg in all_messages:
        for loc in LOCALES:
            arb = arbs[loc]
            text = msg.translations[loc]
            arb[msg.key] = text
            if loc == "en" and msg.placeholders:
                arb[f"@{msg.key}"] = {
                    "placeholders": {
                        name: {"type": typ} for name, typ in msg.placeholders.items()
                    }
                }
        if msg.fallback_locales:
            # locales that fell back excluding zh which had content? report non-zh
            # User asked: keys that used English fallback for non-zh locales
            # Typically zh+en only keys → fallback for zh_HK, de, es, ...
            fb = [l for l in msg.fallback_locales if l != "zh"]
            # Also include zh if it fell back (shouldn't)
            if "zh" in msg.fallback_locales:
                fb = msg.fallback_locales[:]
            if fb:
                fallback_report[msg.key] = fb

    for loc, fname in LOCALE_TO_ARB.items():
        write_arb(L10N / fname, arbs[loc])

    print(f"Added {len(all_messages)} keys to {len(LOCALES)} ARB files.")
    print("\nKeys added:")
    for msg in all_messages:
        ph = f" placeholders={list(msg.placeholders)}" if msg.placeholders else ""
        print(f"  - {msg.key} ({msg.source}){ph}")

    print("\nEnglish fallback for non-zh locales:")
    if not fallback_report:
        print("  (none)")
    else:
        for k, locs in fallback_report.items():
            print(f"  - {k}: {', '.join(locs)}")

    print("\nSkipped (already in ARB):")
    for s in skipped_existing:
        print(f"  - {s}")

    print("\nSkipped (name collision with earlier provider):")
    for s in skipped_collision:
        print(f"  - {s}")

    print("\nCould not extract cleanly:")
    if not all_unclean:
        print("  (none)")
    else:
        for u in all_unclean:
            print(f"  - {u}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
