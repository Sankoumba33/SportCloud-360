/**
 * Fusionne les stats PDF insiders (JSON produit par scripts/parse_insiders_full_player_pdf.py)
 * dans Athlete__c.FeaturesJson__c sous insidersLive.matchStats[matchKey].
 * Rattachement par numéro de maillot = champ JSON `number` (sync API Bayonne).
 */
public with sharing class SC360InsidersMatchStatsService {
    public class MergeResult {
        public Integer updated;
        public Integer skippedNoShirt;
        public String message;
    }

    /**
     * @param payloadJson soit { "bundles": [ { matchKey, players: [...] }, ... ] } soit un seul bundle racine
     */
    public static MergeResult mergeFromPayloadJson(String payloadJson) {
        MergeResult res = new MergeResult();
        res.updated = 0;
        res.skippedNoShirt = 0;
        if (String.isBlank(payloadJson)) {
            res.message = 'JSON vide';
            return res;
        }
        Object parsed = JSON.deserializeUntyped(payloadJson);
        List<Map<String, Object>> bundles = new List<Map<String, Object>>();
        if (parsed instanceof Map<String, Object>) {
            Map<String, Object> root = (Map<String, Object>) parsed;
            if (root.containsKey('bundles')) {
                for (Object o : (List<Object>) root.get('bundles')) {
                    bundles.add((Map<String, Object>) o);
                }
            } else {
                bundles.add(root);
            }
        }
        if (bundles.isEmpty()) {
            res.message = 'Aucun bundle';
            return res;
        }

        List<Athlete__c> athletes = [
            SELECT Id, ExternalId__c, FeaturesJson__c
            FROM Athlete__c
            WHERE ExternalId__c LIKE 'APISPORTS-%'
        ];
        List<Athlete__c> toUpdate = new List<Athlete__c>();

        for (Athlete__c a : athletes) {
            Integer shirt = shirtFromFeaturesJson(a.FeaturesJson__c);
            if (shirt == null) {
                res.skippedNoShirt++;
                continue;
            }
            Map<String, Object> root = parseRoot(a.FeaturesJson__c);
            Boolean touched = false;

            for (Map<String, Object> bundle : bundles) {
                List<Object> players = (List<Object>) bundle.get('players');
                if (players == null || players.isEmpty()) {
                    continue;
                }
                String matchKey = (String) bundle.get('matchKey');
                if (String.isBlank(matchKey)) {
                    continue;
                }
                Map<String, Object> playerRow = findPlayer(players, shirt);
                if (playerRow == null) {
                    continue;
                }
                Map<String, Object> meta = enrichBundleMeta(bundle);
                mergeOneMatch(root, matchKey, playerRow, meta);
                touched = true;
            }

            if (touched) {
                a.FeaturesJson__c = JSON.serialize(root);
                toUpdate.add(a);
                res.updated++;
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        res.message = 'OK — MAJ ' + res.updated + ', sans numéro JSON ' + res.skippedNoShirt;
        return res;
    }

    private static Map<String, Object> enrichBundleMeta(Map<String, Object> bundle) {
        Map<String, Object> meta = new Map<String, Object>{
            'matchLabel' => bundle.get('matchLabel'),
            'matchDate' => bundle.get('matchDate'),
            'sourceFile' => bundle.get('sourceFile'),
            'reportType' => bundle.get('reportType')
        };
        for (String k : new List<String>{
            'collectiveDistanceM',
            'scoreHome',
            'scoreAway',
            'globalNotes',
            'posteMoyensL1'
        }) {
            if (bundle.containsKey(k)) {
                meta.put(k, bundle.get(k));
            }
        }
        return meta;
    }

    private static Map<String, Object> findPlayer(List<Object> players, Integer shirt) {
        for (Object o : players) {
            Map<String, Object> p = (Map<String, Object>) o;
            Object sn = p.get('shirtNumber');
            if (sn != null && Decimal.valueOf(String.valueOf(sn)).intValue() == shirt) {
                return p;
            }
        }
        return null;
    }

    private static void mergeOneMatch(
        Map<String, Object> root,
        String matchKey,
        Map<String, Object> playerStats,
        Map<String, Object> meta
    ) {
        Map<String, Object> insiders = (Map<String, Object>) root.get('insidersLive');
        if (insiders == null) {
            insiders = new Map<String, Object>();
        }
        Map<String, Object> matchStats = (Map<String, Object>) insiders.get('matchStats');
        if (matchStats == null) {
            matchStats = new Map<String, Object>();
        }
        Map<String, Object> entry = new Map<String, Object>();
        for (String k : playerStats.keySet()) {
            entry.put(k, playerStats.get(k));
        }
        entry.put('_meta', meta);
        matchStats.put(matchKey, entry);
        insiders.put('matchStats', matchStats);
        root.put('insidersLive', insiders);
    }

    private static Map<String, Object> parseRoot(String fj) {
        if (String.isBlank(fj)) {
            return new Map<String, Object>();
        }
        try {
            Object o = JSON.deserializeUntyped(fj);
            if (o instanceof Map<String, Object>) {
                return (Map<String, Object>) o;
            }
        } catch (Exception e) {
        }
        return new Map<String, Object>{ 'legacyFeaturesJson' => fj };
    }

    private static Integer shirtFromFeaturesJson(String fj) {
        if (String.isBlank(fj)) {
            return null;
        }
        try {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(fj);
            Object n = m.get('number');
            if (n == null) {
                return null;
            }
            return Integer.valueOf(String.valueOf(n).trim());
        } catch (Exception e) {
            return null;
        }
    }
}
