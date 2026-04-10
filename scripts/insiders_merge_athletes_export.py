"""
Fusionne bundle JSON (parse_insiders_full_player_pdf.py --all -o) dans un export
Data Loader Athlete__c (Id, ExternalId__c, FeaturesJson__c).

Usage:
  sf data query -q "SELECT Id, ExternalId__c, FeaturesJson__c FROM Athlete__c WHERE ExternalId__c LIKE 'APISPORTS-%'" -r csv -o data/insiders/athletes_export.csv
  python scripts/insiders_merge_athletes_export.py data/insiders/athletes_export.csv data/insiders/bundle_all.json -o data/insiders/athletes_update.csv

Puis Data Loader : Update sur Athlete__c, champs Id + FeaturesJson__c.
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def _norm_shirt(val) -> int | None:
    if val is None or val == "":
        return None
    s = str(val).strip()
    if not s:
        return None
    try:
        return int(s)
    except ValueError:
        return None


def _shirt_from_features(fj: str | None) -> int | None:
    if not fj:
        return None
    try:
        m = json.loads(fj)
    except json.JSONDecodeError:
        return None
    return _norm_shirt(m.get("number"))


def _bundle_meta_extra(bundle: dict) -> dict:
    extra: dict = {}
    for k in (
        "collectiveDistanceM",
        "scoreHome",
        "scoreAway",
        "globalNotes",
        "posteMoyensL1",
    ):
        if k in bundle and bundle[k] is not None:
            extra[k] = bundle[k]
    return extra


def _merge_root(existing: dict, match_key: str, stats: dict, meta: dict) -> dict:
    root = dict(existing) if isinstance(existing, dict) else {}
    il = dict(root.get("insidersLive") or {})
    ms = dict(il.get("matchStats") or {})
    entry = dict(stats)
    entry["_meta"] = meta
    ms[match_key] = entry
    il["matchStats"] = ms
    root["insidersLive"] = il
    return root


def merge_export(athlete_rows: list[dict], bundles: list[dict]) -> list[dict]:
    """Retourne lignes avec Id, FeaturesJson__c mis à jour."""
    out_rows = []
    for row in athlete_rows:
        fid = row.get("Id")
        fj = row.get("FeaturesJson__c") or ""
        try:
            root = json.loads(fj) if fj.strip() else {}
        except json.JSONDecodeError:
            root = {"legacyFeaturesJson": fj}

        sid = _shirt_from_features(row.get("FeaturesJson__c"))
        if sid is not None:
            for bundle in bundles:
                if not bundle.get("players"):
                    continue
                mk = bundle["matchKey"]
                meta = {
                    "matchLabel": bundle.get("matchLabel"),
                    "matchDate": bundle.get("matchDate"),
                    "sourceFile": bundle.get("sourceFile"),
                    "reportType": bundle.get("reportType"),
                    **_bundle_meta_extra(bundle),
                }
                for p in bundle["players"]:
                    if p.get("shirtNumber") != sid:
                        continue
                    stats = {k: v for k, v in p.items() if not k.startswith("_")}
                    root = _merge_root(root, mk, stats, meta)
        out_rows.append({"Id": fid, "FeaturesJson__c": json.dumps(root, ensure_ascii=False)})
    return out_rows


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("athletes_csv", help="Export SF Id, ExternalId__c, FeaturesJson__c")
    ap.add_argument("bundle_json", help="bundle_all.json")
    ap.add_argument("-o", "--output", required=True, help="athletes_update.csv")
    args = ap.parse_args()

    bundle_path = Path(args.bundle_json)
    data = json.loads(bundle_path.read_text(encoding="utf-8"))
    bundles = data.get("bundles") or [data]
    bundles = [b for b in bundles if b.get("players")]

    rows = []
    with open(args.athletes_csv, encoding="utf-8-sig", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            rows.append(row)

    merged = merge_export(rows, bundles)
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["Id", "FeaturesJson__c"],
            quoting=csv.QUOTE_NONNUMERIC,
        )
        w.writeheader()
        for row in merged:
            w.writerow(row)
    print(f"OK {len(merged)} lignes -> {out_path}")


if __name__ == "__main__":
    main()
