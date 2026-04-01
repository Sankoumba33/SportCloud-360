// File d'attente : National (N1) + N2 + N3 -> Prospect__c (APISPORTS-*)
// sf apex run --file scripts/apex/sync_scouting_n2_import.apex

SC360ScoutingOperationResult r = SC360ScoutingProspectSyncService.startFranceProspectImport(
    SC360ScoutingProspectSyncService.DEFAULT_SEASON,
    10
);
System.debug(LoggingLevel.INFO, r.success + ' — ' + r.message);
