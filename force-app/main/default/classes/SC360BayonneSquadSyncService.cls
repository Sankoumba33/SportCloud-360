/**
 * Synchronise l'effectif National 2 (Aviron Bayonnais FC) depuis API-Football vers Athlete__c.
 * Références: équipe Bayonne id 10166, National 2 groupe A ligue id 67 (API-Football).
 * Saison demandée 2025/2026: les endpoints "squad" reflètent l'effectif courant; les stats par saison
 * peuvent exiger un plan payant pour 2025 (plan gratuit: saisons 2022–2024 selon API).
 */
public with sharing class SC360BayonneSquadSyncService {
    public static final Integer TEAM_ID_BAYONNE = 10166;
    public static final Integer LEAGUE_NATIONAL_2_GROUP_A = 67;
    public static final String SEASON_LABEL = '2025/2026';
    public static final String SQUAD_NAME_N2 = 'Effectif N2';
    public static final String SQUAD_CODE_N2 = 'N2';

    public class SyncResult {
        @InvocableVariable(label='Succès') public Boolean success;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Nombre upsert') public Integer upsertCount;
    }

    @InvocableMethod(
        label='Sync effectif Bayonne N2 (API-Football)'
        description='Importe l effectif API-Football vers Athlete__c (External ID APISPORTS-{playerId}).'
    )
    public static List<SyncResult> syncInvocable() {
        return new List<SyncResult>{ syncSquad() };
    }

    public static SyncResult syncSquad() {
        SyncResult out = new SyncResult();
        out.success = false;
        out.upsertCount = 0;

        HttpResponse res;
        try {
            res = ApiSportsFootballClient.get('/players/squads?team=' + TEAM_ID_BAYONNE);
        } catch (Exception e) {
            out.message = 'Callout: ' + e.getMessage();
            return out;
        }

        if (res.getStatusCode() != 200) {
            out.message = 'HTTP ' + res.getStatusCode() + ' ' + res.getStatus();
            return out;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (!apiErrorsEmpty(root.get('errors'))) {
            out.message = 'API: ' + JSON.serialize(root.get('errors'));
            return out;
        }

        List<Object> responseList = (List<Object>) root.get('response');
        if (responseList == null || responseList.isEmpty()) {
            out.message = 'Réponse vide (response)';
            return out;
        }

        Map<String, Object> first = (Map<String, Object>) responseList[0];
        Map<String, Object> teamMap = (Map<String, Object>) first.get('team');
        List<Object> players = (List<Object>) first.get('players');
        if (players == null || players.isEmpty()) {
            out.message = 'Aucun joueur dans l effectif';
            return out;
        }

        Id squadId = resolveEffectifN2SquadId();

        String teamName = teamMap != null ? (String) teamMap.get('name') : 'Bayonne';
        List<Athlete__c> rows = new List<Athlete__c>();
        for (Object p : players) {
            Map<String, Object> pl = (Map<String, Object>) p;
            Object pid = pl.get('id');
            if (pid == null) {
                continue;
            }
            String extId = 'APISPORTS-' + String.valueOf(pid);
            Map<String, Object> featurePayload = new Map<String, Object>{
                'apiSource' => 'api-football',
                'teamId' => TEAM_ID_BAYONNE,
                'teamName' => teamName,
                'leagueNational2GroupAId' => LEAGUE_NATIONAL_2_GROUP_A,
                'seasonLabel' => SEASON_LABEL,
                'playerApiId' => pid,
                'number' => pl.get('number'),
                'position' => pl.get('position'),
                'photo' => pl.get('photo'),
                'age' => pl.get('age')
            };

            Athlete__c a = new Athlete__c(
                Name = (String) pl.get('name'),
                ExternalId__c = extId,
                Sport__c = 'Football',
                Status__c = 'Active',
                FeaturesJson__c = JSON.serialize(featurePayload)
            );
            if (squadId != null) {
                a.CurrentSquad__c = squadId;
            }
            rows.add(a);
        }

        try {
            upsert rows ExternalId__c;
        } catch (DmlException e) {
            out.message = 'DML: ' + e.getMessage();
            return out;
        }

        out.success = true;
        out.upsertCount = rows.size();
        out.message = 'OK — ' + rows.size() + ' athlètes (Bayonne / ' + SEASON_LABEL + ')';
        return out;
    }

    private static Id resolveEffectifN2SquadId() {
        List<Squad__c> existing = [SELECT Id FROM Squad__c WHERE Name = :SQUAD_NAME_N2 LIMIT 1];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        insert new Squad__c(Name = SQUAD_NAME_N2, Code__c = SQUAD_CODE_N2, IsActive__c = true);
        return [SELECT Id FROM Squad__c WHERE Name = :SQUAD_NAME_N2 LIMIT 1].Id;
    }

    private static Boolean apiErrorsEmpty(Object errorsNode) {
        if (errorsNode == null) {
            return true;
        }
        if (errorsNode instanceof List<Object>) {
            return ((List<Object>) errorsNode).isEmpty();
        }
        if (errorsNode instanceof Map<String, Object>) {
            return ((Map<String, Object>) errorsNode).isEmpty();
        }
        return false;
    }
}
