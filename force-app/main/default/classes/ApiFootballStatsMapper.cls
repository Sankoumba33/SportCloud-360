/**
 * Extrait statistics[0] API-Football (v3) vers champs Prospect__c.
 * Réf. champs typiques : games, goals, cards, shots, passes, tackles, duels.
 */
public with sharing class ApiFootballStatsMapper {
    public static void applyToProspect(Prospect__c p, Map<String, Object> stat0, Integer season) {
        p.ApiStatsSeason__c = season;
        if (stat0 == null) {
            clearStats(p);
            return;
        }
        p.ApiStatisticsJson__c = JSON.serialize(stat0);

        Map<String, Object> games = (Map<String, Object>) stat0.get('games');
        if (games != null) {
            p.ApiAppearances__c = firstDecimal(games.get('appearences'), games.get('appearances'));
            p.ApiLineups__c = toDecimal(games.get('lineups'));
            p.ApiMinutes__c = toDecimal(games.get('minutes'));
        } else {
            p.ApiAppearances__c = null;
            p.ApiLineups__c = null;
            p.ApiMinutes__c = null;
        }

        Map<String, Object> goals = (Map<String, Object>) stat0.get('goals');
        if (goals != null) {
            p.ApiGoals__c = toDecimal(goals.get('total'));
            p.ApiAssists__c = toDecimal(goals.get('assists'));
        } else {
            p.ApiGoals__c = null;
            p.ApiAssists__c = null;
        }

        Map<String, Object> cards = (Map<String, Object>) stat0.get('cards');
        if (cards != null) {
            p.ApiYellowCards__c = toDecimal(cards.get('yellow'));
            p.ApiRedCards__c = toDecimal(cards.get('red'));
        } else {
            p.ApiYellowCards__c = null;
            p.ApiRedCards__c = null;
        }

        Map<String, Object> shots = (Map<String, Object>) stat0.get('shots');
        if (shots != null) {
            p.ApiShotsTotal__c = toDecimal(shots.get('total'));
            p.ApiShotsOnTarget__c = toDecimal(shots.get('on'));
        } else {
            p.ApiShotsTotal__c = null;
            p.ApiShotsOnTarget__c = null;
        }

        Map<String, Object> passes = (Map<String, Object>) stat0.get('passes');
        if (passes != null) {
            p.ApiPassesTotal__c = toDecimal(passes.get('total'));
            p.ApiPassesKey__c = toDecimal(passes.get('key'));
            p.ApiPassesAccuracyPct__c = toDecimal(passes.get('accuracy'));
        } else {
            p.ApiPassesTotal__c = null;
            p.ApiPassesKey__c = null;
            p.ApiPassesAccuracyPct__c = null;
        }

        Map<String, Object> tackles = (Map<String, Object>) stat0.get('tackles');
        if (tackles != null) {
            p.ApiTacklesTotal__c = toDecimal(tackles.get('total'));
        } else {
            p.ApiTacklesTotal__c = null;
        }

        Map<String, Object> duels = (Map<String, Object>) stat0.get('duels');
        if (duels != null) {
            p.ApiDuelsWon__c = toDecimal(duels.get('won'));
        } else {
            p.ApiDuelsWon__c = null;
        }
    }

    private static void clearStats(Prospect__c p) {
        p.ApiStatisticsJson__c = null;
        p.ApiAppearances__c = null;
        p.ApiLineups__c = null;
        p.ApiMinutes__c = null;
        p.ApiGoals__c = null;
        p.ApiAssists__c = null;
        p.ApiYellowCards__c = null;
        p.ApiRedCards__c = null;
        p.ApiShotsTotal__c = null;
        p.ApiShotsOnTarget__c = null;
        p.ApiPassesTotal__c = null;
        p.ApiPassesKey__c = null;
        p.ApiPassesAccuracyPct__c = null;
        p.ApiTacklesTotal__c = null;
        p.ApiDuelsWon__c = null;
    }

    private static Decimal firstDecimal(Object a, Object b) {
        Decimal d = toDecimal(a);
        if (d != null) {
            return d;
        }
        return toDecimal(b);
    }

    private static Decimal toDecimal(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof Decimal) {
            return (Decimal) o;
        }
        if (o instanceof Integer) {
            return Decimal.valueOf((Integer) o);
        }
        if (o instanceof Long) {
            return Decimal.valueOf((Long) o);
        }
        if (o instanceof Double) {
            return Decimal.valueOf((Double) o);
        }
        if (o instanceof String) {
            String s = ((String) o).trim();
            if (String.isBlank(s)) {
                return null;
            }
            try {
                return Decimal.valueOf(s);
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
}
