public with sharing class AthleteFeatureEventHandler {
    public static void handleAfterInsert(List<AthleteFeatureUpdate__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        Map<String, AthleteFeatureUpdate__e> latestByExternalId = new Map<String, AthleteFeatureUpdate__e>();
        for (AthleteFeatureUpdate__e evt : events) {
            if (String.isBlank(evt.AthleteExternalId__c)) {
                continue;
            }
            latestByExternalId.put(evt.AthleteExternalId__c.trim(), evt);
        }

        if (latestByExternalId.isEmpty()) {
            return;
        }

        Map<String, Athlete__c> athletesByExternalId = new Map<String, Athlete__c>();
        for (Athlete__c athlete : [
            SELECT
                Id,
                ExternalId__c,
                Load7d__c,
                Load28d__c,
                Acwr__c,
                ReadinessScore__c,
                InjuryRiskScore__c,
                LoadTrend__c,
                PerformanceTrend__c,
                FeaturesJson__c,
                LastDataCloudSync__c
            FROM Athlete__c
            WHERE ExternalId__c IN :latestByExternalId.keySet()
        ]) {
            athletesByExternalId.put(athlete.ExternalId__c, athlete);
        }

        List<Athlete__c> toUpdate = new List<Athlete__c>();
        for (String externalId : latestByExternalId.keySet()) {
            Athlete__c athlete = athletesByExternalId.get(externalId);
            if (athlete == null) {
                continue;
            }

            AthleteFeatureUpdate__e evt = latestByExternalId.get(externalId);
            athlete.Load7d__c = evt.Load7d__c;
            athlete.Load28d__c = evt.Load28d__c;
            athlete.Acwr__c = evt.Acwr__c;
            athlete.ReadinessScore__c = evt.ReadinessScore__c;
            athlete.InjuryRiskScore__c = evt.InjuryRiskScore__c;
            athlete.LoadTrend__c = normalizeTrend(evt.LoadTrend__c);
            athlete.PerformanceTrend__c = normalizeTrend(evt.PerformanceTrend__c);
            athlete.FeaturesJson__c = evt.FeaturesJson__c;
            athlete.LastDataCloudSync__c = evt.EventTimestamp__c == null ? System.now() : evt.EventTimestamp__c;
            toUpdate.add(athlete);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static String normalizeTrend(String trendRaw) {
        if (String.isBlank(trendRaw)) {
            return null;
        }
        String normalized = trendRaw.trim().toLowerCase();
        if (normalized == 'up') {
            return 'Up';
        }
        if (normalized == 'down') {
            return 'Down';
        }
        if (normalized == 'stable') {
            return 'Stable';
        }
        return null;
    }
}
