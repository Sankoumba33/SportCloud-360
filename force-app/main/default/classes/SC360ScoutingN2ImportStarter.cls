/**
 * Flow / automation : import vivier FR (classe séparée = 1 InvocableMethod par fichier).
 */
public with sharing class SC360ScoutingN2ImportStarter {
    @InvocableMethod(
        label='Scouting: import vivier FR (National, N2, N3)'
        description='Enfile l import paginé : Championnat National, National 2, National 3 (IDs API-Football).'
    )
    public static List<SC360ScoutingOperationResult> run() {
        return new List<SC360ScoutingOperationResult>{
            SC360ScoutingProspectSyncService.startFranceProspectImport(
                SC360ScoutingProspectSyncService.DEFAULT_SEASON,
                10
            )
        };
    }
}
