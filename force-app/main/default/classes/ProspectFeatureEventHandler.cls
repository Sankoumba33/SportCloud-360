public with sharing class ProspectFeatureEventHandler {
    public static void handleAfterInsert(List<ProspectFeatureUpdate__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        Map<String, ProspectFeatureUpdate__e> latestByExternalId = new Map<String, ProspectFeatureUpdate__e>();
        for (ProspectFeatureUpdate__e evt : events) {
            if (String.isBlank(evt.ProspectExternalId__c)) {
                continue;
            }
            latestByExternalId.put(evt.ProspectExternalId__c.trim(), evt);
        }

        if (latestByExternalId.isEmpty()) {
            return;
        }

        Map<String, Prospect__c> prospectsByExternalId = new Map<String, Prospect__c>();
        for (Prospect__c prospect : [
            SELECT
                Id,
                ExternalId__c,
                ScoutingScore__c,
                PotentialScore__c,
                FitScore__c,
                RiskScore__c,
                DataConfidence__c,
                ScoutingSummary__c,
                TopStrengths__c,
                TopRisks__c,
                ScoutingFeaturesJson__c,
                LastDataCloudSync__c
            FROM Prospect__c
            WHERE ExternalId__c IN :latestByExternalId.keySet()
        ]) {
            prospectsByExternalId.put(prospect.ExternalId__c, prospect);
        }

        List<Prospect__c> toUpdate = new List<Prospect__c>();
        for (String externalId : latestByExternalId.keySet()) {
            Prospect__c prospect = prospectsByExternalId.get(externalId);
            if (prospect == null) {
                continue;
            }

            ProspectFeatureUpdate__e evt = latestByExternalId.get(externalId);
            prospect.ScoutingScore__c = evt.ScoutingScore__c;
            prospect.PotentialScore__c = evt.PotentialScore__c;
            prospect.FitScore__c = evt.FitScore__c;
            prospect.RiskScore__c = evt.RiskScore__c;
            prospect.DataConfidence__c = evt.DataConfidence__c;
            prospect.ScoutingSummary__c = evt.ScoutingSummary__c;
            prospect.TopStrengths__c = evt.TopStrengths__c;
            prospect.TopRisks__c = evt.TopRisks__c;
            prospect.ScoutingFeaturesJson__c = evt.ScoutingFeaturesJson__c;
            prospect.LastDataCloudSync__c = evt.EventTimestamp__c == null ? System.now() : evt.EventTimestamp__c;
            toUpdate.add(prospect);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
