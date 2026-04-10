// Exemple Execute Anonymous : fusion d'un mini JSON (remplace par le contenu de data/insiders/bundle_all.json si < heap).
// Gros volumes : python scripts/insiders_merge_athletes_export.py + Data Loader.

String payload =
    '{"bundles":[' +
    '{"matchKey":"J18-vs-Poitiers-2026-03-18","matchLabel":"J18 vs Poitiers","matchDate":"2026-03-18","sourceFile":"J18VsPoitiersFullPlayerStats.pdf","reportType":"FullPlayerStats","players":[' +
    '{"shirtNumber":4,"distanceM":9426.3,"maxSpeedKmh":27.74}' +
    ']}]}';

SC360InsidersMatchStatsService.MergeResult r = SC360InsidersMatchStatsService.mergeFromPayloadJson(payload);
System.debug(r.message);
