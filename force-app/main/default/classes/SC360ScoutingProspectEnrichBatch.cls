/**
 * Batch 1-by-1 : 1 prospect APISPORTS-* = 1 callout (limite Salesforce).
 */
public class SC360ScoutingProspectEnrichBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private final Integer seasonYear;

    public SC360ScoutingProspectEnrichBatch(Integer seasonYear) {
        this.seasonYear = seasonYear != null ? seasonYear : SC360ScoutingProspectSyncService.DEFAULT_SEASON;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Id, ExternalId__c FROM Prospect__c WHERE ExternalId__c LIKE 'APISPORTS-%']
        );
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        for (sObject row : scope) {
            try {
                SC360ScoutingProspectSyncService.enrichProspectFromRecord((Prospect__c) row, seasonYear);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Scouting enrich ' + row.Id + ' : ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
