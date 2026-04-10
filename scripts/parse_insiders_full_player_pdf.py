"""
Insiders / ASI — extraction PDF vers JSON pour import Salesforce (FeaturesJson).

Types gérés (détection par nom de fichier ou contenu) :
  - FullPlayerStats : « Player Statistics Report » (GPS détaillé)
  - FullTeamStats : « Team Report » (table distances + table événements, lignes tokenisées pypdf)
  - Rapport Data Match : synthèse staff (minutes, m, HID, sprints, Vmax + DT collectif, moyens par poste)

Utilise pypdf pour les PDF binaires.

Usage:
  python scripts/parse_insiders_full_player_pdf.py J18VsPoitiersFullPlayerStats.pdf
  python scripts/parse_insiders_full_player_pdf.py --all -o
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def _root_dir() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_text(path: Path) -> str:
    raw = path.read_bytes()[:5]
    if raw.startswith(b"%PDF"):
        try:
            from pypdf import PdfReader
        except ImportError as e:
            raise SystemExit(
                "pypdf requis pour les PDF binaires: pip install pypdf"
            ) from e
        r = PdfReader(str(path))
        return "".join(page.extract_text() or "" for page in r.pages)
    return path.read_text(encoding="utf-8", errors="replace")


def _split_core_block(block: str) -> str:
    for sep in ("Statistics Per Speed Range", "Distances Per Zone", "Field Position Heat Map"):
        if sep in block:
            return block.split(sep)[0]
    return block


def _parse_player_name(block: str) -> str | None:
    lines = [ln.strip() for ln in block.splitlines() if ln.strip()]
    for i in range(len(lines) - 1):
        a, b = lines[i], lines[i + 1]
        if (
            len(a) > 3
            and a == b
            and not a.startswith("PLAYER")
            and not a.startswith("SENSOR")
        ):
            return a
    if "\t" in block:
        for line in block.splitlines():
            line = line.strip()
            if "\t" not in line:
                continue
            a, b = line.split("\t", 1)
            a, b = a.strip(), b.strip()
            if len(a) > 3 and a == b and not a.startswith("PLAYER"):
                return a
    return None


def _parse_block(block: str) -> dict | None:
    # Numéro maillot : "PLAYER NO. \n04" ou "PLAYER NO. 04"
    m_no = re.search(r"PLAYER NO\.\s*\n?\s*(\d+)", block)
    if not m_no:
        m_no = re.search(r"PLAYER NO\.\s*(\d+)", block)
    if not m_no:
        return None
    shirt = int(m_no.group(1))
    name = _parse_player_name(block)
    core = _split_core_block(block)

    time_m = re.search(
        r"\(minutes\)\s*\n\s*\(minutes\)\s*\n\s*(\d{1,2}:\d{2}:\d{2})",
        core,
        re.MULTILINE,
    )
    dist_m = re.search(
        r"Distance\s*\n\s*Distance\s*\n\s*\(m\)\s*\n\s*\(m\)\s*\n\s*([\d.]+)",
        core,
        re.MULTILINE,
    )
    # m/s² peut être corrompu en m/s + caractère (PDF)
    acc3 = re.search(r">3 m/s.\s*\n\s*>3 m/s.\s*\n\s*(\d+)", core)
    acc4 = re.search(r">4 m/s.\s*\n\s*>4 m/s.\s*\n\s*(\d+)", core)
    decel_sub = core
    di = core.find("# Decelerations")
    if di >= 0:
        decel_sub = core[di:]
    dec3 = re.search(r">3 m/s.\s*\n\s*>3 m/s.\s*\n\s*(\d+)", decel_sub)
    dec4 = re.search(r">4 m/s.\s*\n\s*>4 m/s.\s*\n\s*(\d+)", decel_sub)
    spr = re.search(r">25 km/h\s*\n\s*>25 km/h\s*\n\s*(\d+)", core)
    vmax = re.search(
        r"Max Speed\s*\n\s*Max Speed\s*\n\s*\(km/h\)\s*\n\s*\(km/h\)\s*\n\s*([\d.]+)",
        core,
        re.MULTILINE,
    )
    vavg = re.search(
        r"Avg\. Speed\s*\n\s*Avg\. Speed\s*\n\s*\(km/h\)\s*\n\s*\(km/h\)\s*\n\s*([\d.]+)",
        core,
        re.MULTILINE,
    )
    hid15 = re.search(
        r"\(15km/h\)\s*\n\s*\(15km/h\)\s*\n\s*([\d.]+)", core, re.MULTILINE
    )
    hid20 = re.search(
        r"\(20km/h\)\s*\n\s*\(20km/h\)\s*\n\s*([\d.]+)", core, re.MULTILINE
    )
    max_acc = re.search(
        r"Max Acceleration\s*\n\s*Max Acceleration\s*\n\s*\(m/s.\)\s*\n\s*\(m/s.\)\s*\n\s*([\d.]+)",
        core,
        re.MULTILINE,
    )

    if time_m is None and dist_m is None:
        return None

    return {
        "shirtNumber": shirt,
        "playerName": name,
        "timePlayed": time_m.group(1) if time_m else None,
        "distanceM": float(dist_m.group(1)) if dist_m else None,
        "accelerationsGt3": int(acc3.group(1)) if acc3 else None,
        "accelerationsGt4": int(acc4.group(1)) if acc4 else None,
        "decelerationsGt3": int(dec3.group(1)) if dec3 else None,
        "decelerationsGt4": int(dec4.group(1)) if dec4 else None,
        "sprintsGt25Kmh": int(spr.group(1)) if spr else None,
        "maxSpeedKmh": float(vmax.group(1)) if vmax else None,
        "avgSpeedKmh": float(vavg.group(1)) if vavg else None,
        "hidDistance15KmhM": float(hid15.group(1)) if hid15 else None,
        "hidDistance20KmhM": float(hid20.group(1)) if hid20 else None,
        "maxAccelerationMps2": float(max_acc.group(1)) if max_acc else None,
    }


def _match_meta(text: str) -> tuple[str | None, str | None]:
    m = re.search(
        r"Player Statistics Report\s*\n\s*([^\n]+)\s*\n\s*(\d{4})\s*/\s*(\d{2})\s*/\s*(\d{2})",
        text,
    )
    if not m:
        return None, None
    label = m.group(1).strip()
    d = f"{m.group(2)}-{m.group(3)}-{m.group(4)}"
    return label, d


_TIME_HHMMSS = re.compile(r"^\d{2}:\d{2}:\d{2}$")


def _team_meta(text: str) -> tuple[str | None, str | None]:
    m = re.search(
        r"Team Report\s*\n\s*([^\n]+)\s*\n\s*(\d{4})\s*/\s*(\d{2})\s*/\s*(\d{2})",
        text,
    )
    if not m:
        return None, None
    return m.group(1).strip(), f"{m.group(2)}-{m.group(3)}-{m.group(4)}"


def _try_parse_team_row(lines: list[str], i: int) -> tuple[dict | None, int]:
    if i + 11 >= len(lines):
        return None, i
    if not lines[i].isdigit():
        return None, i
    s1 = int(lines[i])
    if not lines[i + 1].isdigit() or int(lines[i + 1]) != s1:
        return None, i
    name = lines[i + 2]
    time = lines[i + 3]
    if not _TIME_HHMMSS.match(time):
        return None, i
    try:
        v1 = float(lines[i + 4].replace(",", "."))
    except ValueError:
        return None, i
    if v1 > 500:
        try:
            nums = [float(lines[i + j].replace(",", ".")) for j in range(4, 12)]
        except (ValueError, IndexError):
            return None, i
        return (
            {
                "rowType": "distance",
                "shirtNumber": s1,
                "playerName": name,
                "timePlayed": time,
                "distanceM": nums[0],
                "dist0_15KmhM": nums[1],
                "dist15_20KmhM": nums[2],
                "dist20_25KmhM": nums[3],
                "dist25_30KmhM": nums[4],
                "distGt30KmhM": nums[5],
                "hidDistance15KmhM": nums[6],
                "hidDistance20KmhM": nums[7],
            },
            i + 12,
        )
    try:
        acc3 = int(float(lines[i + 4].replace(",", ".")))
        dec3 = int(float(lines[i + 5].replace(",", ".")))
        acc4 = int(float(lines[i + 6].replace(",", ".")))
        dec4 = int(float(lines[i + 7].replace(",", ".")))
        spr = int(float(lines[i + 8].replace(",", ".")))
        vmax = float(lines[i + 9].replace(",", "."))
    except (ValueError, IndexError):
        return None, i
    return (
        {
            "rowType": "events",
            "shirtNumber": s1,
            "playerName": name,
            "timePlayed": time,
            "accelerationsGt3": acc3,
            "decelerationsGt3": dec3,
            "accelerationsGt4": acc4,
            "decelerationsGt4": dec4,
            "sprintsGt25Kmh": spr,
            "maxSpeedKmh": vmax,
        },
        i + 10,
    )


def _walk_team_segment(lines: list[str]) -> tuple[list[dict], list[dict]]:
    dist: list[dict] = []
    ev: list[dict] = []
    i = 0
    while i < len(lines) and not lines[i].isdigit():
        i += 1
    while i < len(lines):
        if lines[i] in ("Team Report", "ABFC", "Average", "Total") or lines[i].startswith(
            "Average"
        ):
            break
        if lines[i].startswith("Overall"):
            break
        row, ni = _try_parse_team_row(lines, i)
        if row:
            rt = row.pop("rowType", None)
            if rt == "distance":
                dist.append(row)
            elif rt == "events":
                ev.append(row)
            i = ni
        else:
            i += 1
    return dist, ev


def parse_team_report_pdf_text(text: str, source_file: str) -> dict:
    label, iso_date = _team_meta(text)
    dist_by: dict[int, dict] = {}
    ev_by: dict[int, dict] = {}
    for seg in text.split("Team Report"):
        if not seg.strip():
            continue
        sub = [l.strip() for l in seg.splitlines() if l.strip()]
        try:
            wi = sub.index("www.asi.swiss")
        except ValueError:
            continue
        drows, erows = _walk_team_segment(sub[wi + 1 :])
        for r in drows:
            sn = r["shirtNumber"]
            if sn not in dist_by:
                dist_by[sn] = r
        for r in erows:
            sn = r["shirtNumber"]
            if sn not in ev_by:
                ev_by[sn] = r

    shirts = sorted(set(dist_by) | set(ev_by))
    players: list[dict] = []
    for sn in shirts:
        p: dict = {"shirtNumber": sn}
        if sn in dist_by:
            p.update(dist_by[sn])
        if sn in ev_by:
            p.update(ev_by[sn])
        players.append(p)

    key = label or source_file
    safe_key = re.sub(r"[^\w\-]+", "-", key).strip("-")
    mk = f"{safe_key}-{iso_date}-team" if iso_date else f"{safe_key}-team"
    return {
        "sourceFile": source_file,
        "matchLabel": label,
        "matchDate": iso_date,
        "matchKey": mk,
        "reportType": "TeamStats",
        "players": players,
    }


def parse_rapport_data_match_text(text: str, source_file: str) -> dict:
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    head = next((l for l in lines if re.match(r"^J\d+\s+vs\s+.+", l, re.I)), None)
    match_label = head.strip() if head else None

    collective_m = None
    mc = re.search(
        r"COLLECTIVE\s*=\s*([\d\s]+)\s*m",
        text,
        re.I,
    )
    if mc:
        collective_m = int(mc.group(1).replace(" ", ""))

    score_home = score_away = None
    ms = re.search(
        r"(\d+)\s*-\s*(\d+)\s*DT\s*COLLECTIVE",
        text,
        re.I,
    )
    if ms:
        score_home, score_away = int(ms.group(1)), int(ms.group(2))

    global_notes: list[str] = []
    for pat in (r"^DT\s*=", r"^SPRINT\s*=", r"^HID\s*=", r"^VMAX\s*="):
        for ln in lines:
            if re.match(pat, ln, re.I):
                global_notes.append(ln)

    poste_moyens: dict[str, dict] = {}
    for role in ("DC", "DL", "MC", "ME", "MO", "ATT"):
        blk = re.search(
            rf"(?m)^{role}\s*:\s*\n\s*([\d.,]+)\s*km\s*\n\s*(\d+)\s*sprints\s*\n\s*(\d+)\s*m\s*HID",
            text,
            re.I,
        )
        if blk:
            poste_moyens[role] = {
                "km": float(blk.group(1).replace(",", ".")),
                "sprints": int(blk.group(2)),
                "hidM": int(blk.group(3)),
            }

    players: list[dict] = []
    skip_names = frozenset(
        {
            "STATS",
            "ATHLÉTIQUES",
            "ATHLETIQUES",
            "ENTRANTS",
            "HID",
            "SPRINT",
        }
    )
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^([A-Z][A-Z\s\-\']+?)\s+(\d{1,2})\s*$", line)
        if not m:
            i += 1
            continue
        last = m.group(1).strip()
        sh = int(m.group(2))
        if last in skip_names or len(last) < 2:
            i += 1
            continue
        if i + 5 >= len(lines):
            break
        min_raw = lines[i + 1]
        dm = re.search(r"([\d\s]+)\s*m\s*$", lines[i + 2])
        hm = re.search(r"([\d\s]+)\s*m\s*HID", lines[i + 3], re.I)
        sm = re.search(r"(\d+)\s*sprints", lines[i + 4], re.I)
        vm = re.search(r"Vmax\s*=\s*([\d.,]+)\s*km", lines[i + 5], re.I)
        if not dm or not hm or not sm or not vm:
            i += 1
            continue
        distance_m = int(dm.group(1).replace(" ", ""))
        hid_m = int(hm.group(1).replace(" ", ""))
        sprints = int(sm.group(1))
        vmax = float(vm.group(1).replace(",", "."))
        players.append(
            {
                "shirtNumber": sh,
                "playerName": last,
                "minutesRaw": min_raw,
                "distanceM": float(distance_m),
                "hidHighIntensityM": float(hid_m),
                "sprintsGt25Kmh": sprints,
                "maxSpeedKmh": vmax,
            }
        )
        i += 6

    jn = re.search(r"^(J\d+)\s+vs\s+(.+)$", head or "", re.I)
    opp = jn.group(2).strip().replace(" ", "-") if jn else "match"
    jid = jn.group(1).upper() if jn else "JX"
    match_key = f"rapport-{jid}-{opp}-staff"
    return {
        "sourceFile": source_file,
        "matchLabel": match_label,
        "matchDate": None,
        "matchKey": match_key,
        "reportType": "RapportDataMatch",
        "scoreHome": score_home,
        "scoreAway": score_away,
        "collectiveDistanceM": collective_m,
        "globalNotes": global_notes,
        "posteMoyensL1": poste_moyens,
        "players": players,
    }


def parse_full_player_pdf_text(text: str, source_file: str) -> dict:
    label, iso_date = _match_meta(text)
    parts = text.split("Player Statistics Report")
    players: list[dict] = []
    for chunk in parts[1:]:
        p = _parse_block(chunk)
        if p:
            players.append(p)
    # Dédup par maillot : garder la ligne la plus complète (sous-pages zones sans GPS core)
    by_shirt: dict[int, dict] = {}
    for p in players:
        sn = p["shirtNumber"]
        prev = by_shirt.get(sn)
        if prev is None:
            by_shirt[sn] = p
            continue

        def score(d: dict) -> int:
            return sum(1 for k, v in d.items() if k != "shirtNumber" and v is not None)

        if score(p) > score(prev):
            by_shirt[sn] = p
    players = list(by_shirt.values())
    players.sort(key=lambda x: x["shirtNumber"])
    key = label or source_file
    safe_key = re.sub(r"[^\w\-]+", "-", key).strip("-")
    match_key = f"{safe_key}-{iso_date}" if iso_date else safe_key
    return {
        "sourceFile": source_file,
        "matchLabel": label,
        "matchDate": iso_date,
        "matchKey": match_key,
        "reportType": "FullPlayerStats",
        "players": players,
    }


def parse_file(path: Path) -> dict:
    text = _load_text(path)
    n = path.name.lower()
    if "rapport" in n and "match" in n:
        return parse_rapport_data_match_text(text, path.name)
    if "fullteamstats" in n or "teamstats" in n:
        return parse_team_report_pdf_text(text, path.name)
    return parse_full_player_pdf_text(text, path.name)


DEFAULT_PDFS = [
    "J3FullPlayerStats.pdf",
    "J3FullTeamStats.pdf",
    "J4FullPlayerStats.pdf",
    "J4FullTeamStats.pdf",
    "J18VsPoitiersFullPlayerStats.pdf",
    "J18VsPoitiersFullTeamStats.pdf",
    "J22VsLorientFullPlayerStats.pdf",
    "J22VsLorientFullTeamStats.pdf",
    "Rapport Data Match J18.pdf",
    "Rapport Data Match J23.pdf",
]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf", nargs="?", help="Fichier PDF (racine projet ou chemin)")
    ap.add_argument("--all", action="store_true", help="Parser tous les PDFs listés présents")
    ap.add_argument("-o", action="store_true", help="Écrire dans data/insiders/")
    args = ap.parse_args()
    root = _root_dir()
    out_dir = root / "data" / "insiders"

    if args.all:
        bundles = []
        for name in DEFAULT_PDFS:
            p = root / name
            if not p.is_file():
                print(f"# skip (absent): {name}", file=sys.stderr)
                continue
            try:
                bundles.append(parse_file(p))
            except Exception as e:
                print(f"# erreur {name}: {e}", file=sys.stderr)
        payload = {"version": 1, "bundles": bundles}
        text = json.dumps(payload, ensure_ascii=False, indent=2)
        if args.o:
            out_dir.mkdir(parents=True, exist_ok=True)
            (out_dir / "bundle_all.json").write_text(text, encoding="utf-8")
        print(text)
        return
    if not args.pdf:
        ap.error("pdf ou --all requis")
    path = Path(args.pdf)
    if not path.is_file():
        path = root / args.pdf
    if not path.is_file():
        raise SystemExit(f"Fichier introuvable: {args.pdf}")
    data = parse_file(path)
    text = json.dumps(data, ensure_ascii=False, indent=2)
    if args.o:
        out_dir.mkdir(parents=True, exist_ok=True)
        safe = re.sub(r"[^\w\-.]+", "_", path.stem) + ".json"
        (out_dir / safe).write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
