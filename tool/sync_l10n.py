#!/usr/bin/env python3
"""Merge translation fragments into the ARB files and regenerate localizations.

The i18n migration runs several agents in parallel; each one writes its keys
to ``l10n_fragments/<feature>.json`` instead of touching the ARB files. This
script folds every fragment into ``lib/l10n/app_nl.arb`` (template) and
``lib/l10n/app_en.arb``, then runs ``flutter gen-l10n`` — all under an
exclusive lock so concurrent runs cannot tear the files.

Fragment format::

    {
      "loginTitle": {"nl": "Welkom terug", "en": "Welcome back"},
      "loginSubtitle": {"nl": "...", "en": "...", "description": "..."},
      "lessonCount": {
        "nl": "{count} lessen",
        "en": "{count} lessons",
        "placeholders": {"count": {"type": "int"}}
      }
    }

Rules:
  * existing ARB entries are never overwritten (the ARB files win);
  * every key must exist in both languages;
  * keys must be valid Dart identifiers;
  * conflicts between fragments are reported and the first one wins.

Usage: ``python3 tool/sync_l10n.py [--no-gen]``
"""

from __future__ import annotations

import argparse
import fcntl
import json
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"
TEMPLATE = ARB_DIR / "app_nl.arb"
TRANSLATIONS = ARB_DIR / "app_en.arb"
FRAGMENTS = ROOT / "l10n_fragments"
LOCK = ROOT / ".l10n.lock"

IDENT = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def load(path: Path) -> OrderedDict:
    if not path.exists():
        return OrderedDict()
    with path.open(encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=OrderedDict)


def dump(path: Path, data: OrderedDict) -> None:
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


def strip_metadata(entries: OrderedDict) -> OrderedDict:
    return OrderedDict((k, v) for k, v in entries.items() if not k.startswith("@"))


def metadata_key(key: str) -> str:
    return "@" + key


def value_of(entry) -> str:
    """ARB entry value → the message string (objects may carry `message`)."""
    if isinstance(entry, str):
        return entry
    if isinstance(entry, dict) and isinstance(entry.get("message"), str):
        return entry["message"]
    raise ValueError(f"unsupported ARB value for entry: {entry!r}")


def collect_fragments() -> tuple[OrderedDict, list[str]]:
    """Returns (merged fragment data, warnings)."""
    merged: OrderedDict = OrderedDict()
    warnings: list[str] = []
    if not FRAGMENTS.exists():
        return merged, warnings

    for path in sorted(FRAGMENTS.glob("*.json")):
        try:
            data = load(path)
        except json.JSONDecodeError as exc:
            warnings.append(f"{path.name}: invalid JSON ({exc})")
            continue
        if not isinstance(data, dict):
            warnings.append(f"{path.name}: top level value must be an object")
            continue
        for key, spec in data.items():
            if key.startswith("//"):
                continue
            if not IDENT.match(key):
                warnings.append(f"{path.name}: '{key}' is not a valid Dart identifier")
                continue
            if not isinstance(spec, dict) or "nl" not in spec or "en" not in spec:
                warnings.append(f"{path.name}: '{key}' needs both 'nl' and 'en'")
                continue
            if key in merged and merged[key]["nl"] != spec["nl"]:
                warnings.append(
                    f"{path.name}: '{key}' already defined elsewhere "
                    f"(keeping the first definition)"
                )
                continue
            merged[key] = spec
    return merged, warnings


def merge() -> int:
    nl_all = load(TEMPLATE)
    en_all = load(TRANSLATIONS)

    nl = strip_metadata(nl_all)
    en = strip_metadata(en_all)
    nl_meta = OrderedDict(
        (k, v) for k, v in nl_all.items() if k.startswith("@") and k[1:] in nl
    )

    fragments, warnings = collect_fragments()
    added = 0

    for key, spec in fragments.items():
        if key in nl:
            if value_of(nl[key]) != spec["nl"] or value_of(en.get(key, "")) != spec["en"]:
                warnings.append(f"'{key}' already exists in the ARB files (kept existing)")
            continue
        nl[key] = spec["nl"]
        en[key] = spec["en"]
        if spec.get("placeholders") or spec.get("description"):
            meta = OrderedDict()
            if spec.get("description"):
                meta["description"] = spec["description"]
            if spec.get("placeholders"):
                meta["placeholders"] = spec["placeholders"]
            nl_meta[metadata_key(key)] = meta
        added += 1

    missing_en = [k for k in nl if k not in en]
    missing_nl = [k for k in en if k not in nl]
    if missing_en:
        print(f"ERROR: missing English translations: {', '.join(missing_en)}", file=sys.stderr)
        return 1
    if missing_nl:
        print(f"ERROR: keys missing from the Dutch template: {', '.join(missing_nl)}", file=sys.stderr)
        return 1

    # Template: messages first (in order), then their @metadata.
    template_out: OrderedDict = OrderedDict()
    for key, value in nl.items():
        template_out[key] = value
        if metadata_key(key) in nl_meta:
            template_out[metadata_key(key)] = nl_meta[metadata_key(key)]

    dump(TEMPLATE, template_out)
    dump(TRANSLATIONS, en)

    for warning in warnings:
        print(f"warning: {warning}")
    print(f"synced {added} new key(s); {len(nl)} key(s) total")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-gen", action="store_true", help="skip flutter gen-l10n")
    args = parser.parse_args()

    with LOCK.open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        status = merge()
        if status:
            return status
        if not args.no_gen:
            proc = subprocess.run(
                ["flutter", "gen-l10n"], cwd=ROOT, capture_output=True, text=True
            )
            out = (proc.stdout + proc.stderr).strip()
            # The "l10n.yaml exists" banner is noise; everything else matters.
            noise = ("Because l10n.yaml exists", "To use the command line arguments")
            lines = [
                ln
                for ln in out.splitlines()
                if ln and not any(n in ln for n in noise)
            ]
            if proc.returncode != 0 or lines:
                print("\n".join(lines), file=sys.stderr if proc.returncode else sys.stdout)
            if proc.returncode != 0:
                return proc.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
