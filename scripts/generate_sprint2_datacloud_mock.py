from __future__ import annotations

import csv
import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path


def _clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _trend(v: float, up_threshold: float, down_threshold: float) -> str:
    if v >= up_threshold:
        return "up"
    if v <= down_threshold:
        return "down"
    return "stable"


def generate_athlete_rows(count: int = 10) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    now = datetime.now(timezone.utc)

    for idx in range(1, count + 1):
        athlete_external_id = f"ATH-{idx:03d}"
        training_load_7d = random.uniform(220.0, 760.0)
        training_load_28d = random.uniform(900.0, 3200.0)
        acwr = _clamp(training_load_7d / max(training_load_28d / 4.0, 1.0), 0.55, 1.95)

        readiness_score = _clamp(100.0 - (abs(acwr - 1.0) * 65.0) + random.uniform(-8, 8), 20, 98)
        injury_risk_score = _clamp((abs(acwr - 1.0) * 80.0) + random.uniform(5, 20), 5, 95)

        minutes_match_7d = random.uniform(0, 180)
        minutes_match_28d = _clamp(minutes_match_7d + random.uniform(80, 360), 0, 540)
        matches_last5 = int(_clamp(round(minutes_match_28d / 75.0), 0, 5))

        load_trend = _trend(acwr, 1.2, 0.8)
        performance_signal = random.uniform(-1, 1) + (readiness_score - injury_risk_score) / 120.0
        performance_trend = _trend(performance_signal, 0.25, -0.25)

        strengths = ["duel impact", "progressive passing", "sprint repeatability", "high availability"]
        risks = ["load spike", "hamstring exposure", "sleep debt", "travel fatigue"]

        random.shuffle(strengths)
        random.shuffle(risks)

        features_json = {
            "athlete_external_id": athlete_external_id,
            "acwr": round(acwr, 3),
            "readiness_score": round(readiness_score, 2),
            "injury_risk_score": round(injury_risk_score, 2),
            "load_trend": load_trend,
            "performance_trend": performance_trend,
            "generated_at_utc": now.isoformat(),
        }

        rows.append(
            {
                "athlete_external_id": athlete_external_id,
                "athlete_operational_status": random.choice(["Active", "Injured", "Unavailable"]),
                "primary_sport": "Football",
                "training_load_7d": f"{training_load_7d:.2f}",
                "training_load_28d": f"{training_load_28d:.2f}",
                "acwr": f"{acwr:.3f}",
                "session_duration_min_7d": f"{random.uniform(180, 620):.2f}",
                "session_count_7d": f"{int(random.randint(3, 10))}",
                "distance_total_m_7d": f"{random.uniform(18000, 68000):.2f}",
                "hid_gt15_m_7d": f"{random.uniform(1400, 12000):.2f}",
                "hid_gt20_m_7d": f"{random.uniform(400, 6200):.2f}",
                "sprints_gt25_7d": f"{int(random.randint(2, 70))}",
                "max_speed_kmh_7d": f"{random.uniform(28.0, 36.8):.2f}",
                "accel_gt3_7d": f"{int(random.randint(10, 130))}",
                "decel_gt3_7d": f"{int(random.randint(10, 130))}",
                "minutes_match_7d": f"{minutes_match_7d:.2f}",
                "minutes_match_28d": f"{minutes_match_28d:.2f}",
                "matches_last5_count": f"{matches_last5}",
                "xg_last5_sum": f"{random.uniform(0.10, 3.10):.3f}",
                "xa_last5_sum": f"{random.uniform(0.05, 2.30):.3f}",
                "shots_on_target_pct_last5": f"{random.uniform(18.0, 74.0):.2f}",
                "pass_accuracy_pct_last5": f"{random.uniform(66.0, 93.0):.2f}",
                "duel_win_pct_last5": f"{random.uniform(35.0, 68.0):.2f}",
                "progressive_passes_per90_last5": f"{random.uniform(1.2, 10.5):.3f}",
                "recoveries_per90_last5": f"{random.uniform(2.2, 12.8):.3f}",
                "readiness_score": f"{readiness_score:.2f}",
                "injury_risk_score": f"{injury_risk_score:.2f}",
                "load_trend": load_trend,
                "performance_trend": performance_trend,
                "athlete_top_strengths": "; ".join(strengths[:2]),
                "athlete_top_risks": "; ".join(risks[:2]),
                "athlete_summary": f"{athlete_external_id} readiness {readiness_score:.1f}, risk {injury_risk_score:.1f}.",
                "athlete_features_json": json.dumps(features_json, separators=(",", ":")),
                "last_training_sync_utc": (now - timedelta(minutes=random.randint(10, 160))).isoformat(),
                "last_match_sync_utc": (now - timedelta(hours=random.randint(2, 20))).isoformat(),
                "last_datacloud_sync_utc": _iso_now(),
            }
        )
    return rows


def generate_prospect_rows(count: int = 10) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    now = datetime.now(timezone.utc)

    for idx in range(1, count + 1):
        prospect_external_id = f"PROS-{idx:03d}"
        scouting_score = random.uniform(40, 92)
        potential_score = _clamp(scouting_score + random.uniform(-10, 14), 35, 96)
        fit_score = random.uniform(35, 94)
        risk_score = random.uniform(8, 78)
        data_confidence = _clamp(100 - (risk_score * 0.35) + random.uniform(-10, 8), 35, 97)

        strengths = ["first touch", "acceleration", "duel aggression", "decision speed"]
        risks = ["small sample size", "league gap", "injury history", "positional uncertainty"]
        random.shuffle(strengths)
        random.shuffle(risks)

        features_json = {
            "prospect_external_id": prospect_external_id,
            "scouting_score": round(scouting_score, 2),
            "potential_score": round(potential_score, 2),
            "fit_score": round(fit_score, 2),
            "risk_score": round(risk_score, 2),
            "data_confidence": round(data_confidence, 2),
            "generated_at_utc": now.isoformat(),
        }

        rows.append(
            {
                "prospect_external_id": prospect_external_id,
                "scouting_score": f"{scouting_score:.2f}",
                "potential_score": f"{potential_score:.2f}",
                "fit_score": f"{fit_score:.2f}",
                "risk_score": f"{risk_score:.2f}",
                "data_confidence": f"{data_confidence:.2f}",
                "activation_timestamp": _iso_now(),
                "scouting_summary": f"{prospect_external_id} fit {fit_score:.1f}, potential {potential_score:.1f}, risk {risk_score:.1f}.",
                "top_strengths": "; ".join(strengths[:2]),
                "top_risks": "; ".join(risks[:2]),
                "features_json": json.dumps(features_json, separators=(",", ":")),
            }
        )
    return rows


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    random.seed(360)
    out_dir = Path("data/sprint2")
    athlete_rows = generate_athlete_rows(10)
    prospect_rows = generate_prospect_rows(10)

    athlete_path = out_dir / "athlete_features.csv"
    prospect_path = out_dir / "prospect_features.csv"
    write_csv(athlete_path, athlete_rows)
    write_csv(prospect_path, prospect_rows)

    print(f"Generated: {athlete_path}")
    print(f"Generated: {prospect_path}")


if __name__ == "__main__":
    main()
