// Sync effectif Aviron Bayonnais (National 2) depuis API-Football
// Prérequis: Named Credential APISports_Football + Remote Site via NC
// sf apex run --file scripts/apex/sync_bayonne_n2_squad.apex

SC360BayonneSquadSyncService.SyncResult r = SC360BayonneSquadSyncService.syncSquad();
System.debug(LoggingLevel.INFO, r.success + ' — ' + r.message + ' (count=' + r.upsertCount + ')');
