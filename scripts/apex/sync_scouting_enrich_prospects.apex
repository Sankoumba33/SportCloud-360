// Batch : enrichit tous les Prospect__c avec ExternalId__c APISPORTS-* (stats saison DEFAULT_SEASON)
// sf apex run --file scripts/apex/sync_scouting_enrich_prospects.apex

Id jobId = Database.executeBatch(new SC360ScoutingProspectEnrichBatch(SC360ScoutingProspectSyncService.DEFAULT_SEASON), 1);
System.debug(LoggingLevel.INFO, 'Batch scouting enrich: ' + jobId);
