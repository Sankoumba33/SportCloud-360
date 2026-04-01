/**
 * Scouting : enrichit Prospect__c depuis API-Football (profil + stats saison).
 * ExternalId__c attendu : APISPORTS-{playerId} (aligné avec les athlètes API).
 */
public with sharing class SC360ScoutingProspectSyncService {
    public static final Integer DEFAULT_SEASON = 2025;

    @InvocableMethod(
        label='Scouting: enrichir prospects APISPORTS'
        description='Met à jour les Prospect__c dont ExternalId__c commence par APISPORTS- (1 callout / prospect en batch).'
    )
    public static List<SC360ScoutingOperationResult> invocableStartEnrichBatch() {
        SC360ScoutingOperationResult r = new SC360ScoutingOperationResult();
        try {
            Id jobId = Database.executeBatch(new SC360ScoutingProspectEnrichBatch(DEFAULT_SEASON), 1);
            r.success = true;
            r.message = 'Batch démarré: ' + jobId;
            r.processedCount = 0;
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
            r.processedCount = 0;
        }
        return new List<SC360ScoutingOperationResult>{ r };
    }

    /**
     * Enrichit un prospect (callout unique). Idéal bouton LWC / action rapide.
     */
    public static SC360ScoutingOperationResult enrichOneProspect(Id prospectId, Integer season) {
        SC360ScoutingOperationResult out = new SC360ScoutingOperationResult();
        out.processedCount = 0;
        if (prospectId == null) {
            out.success = false;
            out.message = 'prospectId requis';
            return out;
        }
        Integer y = season != null ? season : DEFAULT_SEASON;
        List<Prospect__c> rows = [
            SELECT Id, ExternalId__c
            FROM Prospect__c
            WHERE Id = :prospectId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            out.success = false;
            out.message = 'Prospect introuvable';
            return out;
        }
        try {
            enrichProspectFromRecord(rows[0], y);
            out.success = true;
            out.message = 'OK';
            out.processedCount = 1;
        } catch (Exception e) {
            out.success = false;
            out.message = e.getMessage();
        }
        return out;
    }

    /**
     * Utilisé par le batch : lecture + DML sur le même enregistrement.
     */
    public static void enrichProspectFromRecord(Prospect__c stub, Integer season) {
        Integer y = season != null ? season : DEFAULT_SEASON;
        List<Prospect__c> full = [
            SELECT
                Id,
                Name,
                ExternalId__c,
                Status__c,
                Position__c,
                CurrentClub__c,
                Country__c,
                Nationality__c,
                Championship__c,
                ScoutingFeaturesJson__c,
                ScoutingSummary__c,
                DataConfidence__c,
                LastDataCloudSync__c
            FROM Prospect__c
            WHERE Id = :stub.Id
            LIMIT 1
        ];
        if (full.isEmpty()) {
            return;
        }
        applyApiToProspect(full[0], y);
    }

    private static void applyApiToProspect(Prospect__c prospect, Integer season) {
        Integer apiPlayerId = parseApiPlayerId(prospect.ExternalId__c);
        if (apiPlayerId == null) {
            throw new CalloutException('ExternalId__c doit être APISPORTS-{id}');
        }
        HttpResponse res = ApiSportsFootballClient.get('/players?id=' + apiPlayerId + '&season=' + season);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('HTTP ' + res.getStatusCode());
        }
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (!apiErrorsEmpty(root.get('errors'))) {
            throw new CalloutException('API: ' + JSON.serialize(root.get('errors')));
        }
        List<Object> responseList = (List<Object>) root.get('response');
        if (responseList == null || responseList.isEmpty()) {
            throw new CalloutException('Joueur introuvable pour cette saison');
        }
        Map<String, Object> row = (Map<String, Object>) responseList[0];
        Map<String, Object> player = (Map<String, Object>) row.get('player');
        List<Object> statisticsList = (List<Object>) row.get('statistics');
        Map<String, Object> stat0 = null;
        if (statisticsList != null && !statisticsList.isEmpty()) {
            stat0 = (Map<String, Object>) statisticsList[0];
        }

        if (player == null) {
            throw new CalloutException('Réponse player vide');
        }

        prospect.Name = trimName((String) player.get('name'), prospect.Name);
        prospect.Nationality__c = (String) player.get('nationality');
        prospect.Country__c = 'France';
        prospect.Position__c = pickPosition(player, stat0);
        prospect.CurrentClub__c = pickClub(stat0);
        prospect.Championship__c = pickLeague(stat0);
        prospect.ScoutingFeaturesJson__c = res.getBody();
        prospect.ScoutingSummary__c = buildSummary(player, stat0, season);
        prospect.DataConfidence__c = 82;
        prospect.LastDataCloudSync__c = System.now();
        ApiFootballStatsMapper.applyToProspect(prospect, stat0, season);

        update prospect;
    }

    private static String trimName(String apiName, String fallback) {
        if (!String.isBlank(apiName) && apiName.length() <= 80) {
            return apiName;
        }
        if (!String.isBlank(apiName) && apiName.length() > 80) {
            return apiName.substring(0, 80);
        }
        return fallback;
    }

    private static String pickPosition(Map<String, Object> player, Map<String, Object> stat0) {
        if (stat0 != null) {
            Map<String, Object> games = (Map<String, Object>) stat0.get('games');
            if (games != null && games.get('position') != null) {
                return String.valueOf(games.get('position'));
            }
        }
        return player.get('position') != null ? String.valueOf(player.get('position')) : null;
    }

    private static String pickClub(Map<String, Object> stat0) {
        if (stat0 == null) {
            return null;
        }
        Map<String, Object> team = (Map<String, Object>) stat0.get('team');
        return team != null ? (String) team.get('name') : null;
    }

    private static String pickLeague(Map<String, Object> stat0) {
        if (stat0 == null) {
            return null;
        }
        Map<String, Object> league = (Map<String, Object>) stat0.get('league');
        return league != null ? (String) league.get('name') : null;
    }

    private static String buildSummary(Map<String, Object> player, Map<String, Object> stat0, Integer season) {
        String nm = (String) player.get('name');
        if (stat0 == null) {
            return 'API-Football — saison ' + season + ' — ' + nm;
        }
        Map<String, Object> games = (Map<String, Object>) stat0.get('games');
        Object apps = games != null ? games.get('appearences') : null;
        if (apps == null && games != null) {
            apps = games.get('appearances');
        }
        Map<String, Object> goals = (Map<String, Object>) stat0.get('goals');
        Object totalGoals = goals != null ? goals.get('total') : null;
        String club = pickClub(stat0);
        return 'Saison '
            + season
            + ' — '
            + (club != null ? club : 'club N/A')
            + ' — '
            + (apps != null ? String.valueOf(apps) + ' apparitions' : 'stats partielles')
            + (totalGoals != null ? ' — buts: ' + String.valueOf(totalGoals) : '');
    }

    private static Integer parseApiPlayerId(String externalId) {
        if (String.isBlank(externalId) || !externalId.startsWith('APISPORTS-')) {
            return null;
        }
        String tail = externalId.substring('APISPORTS-'.length());
        try {
            return Integer.valueOf(tail);
        } catch (Exception e) {
            return null;
        }
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

    /**
     * Démarre l’import paginé : National (N1), National 2 (×3), National 3 (groupes API).
     * maxPages = nombre de pages max par ligue (pagination API-Football).
     */
    public static SC360ScoutingOperationResult startNational2ProspectImport(Integer season, Integer maxPages) {
        return startFranceProspectImport(season, maxPages);
    }

    public static SC360ScoutingOperationResult startFranceProspectImport(Integer season, Integer maxPages) {
        SC360ScoutingOperationResult r = new SC360ScoutingOperationResult();
        Integer y = season != null ? season : DEFAULT_SEASON;
        Integer maxP = maxPages != null && maxPages > 0 ? Math.min(maxPages, 50) : 10;
        try {
            System.enqueueJob(
                new SC360ScoutingLeagueImportQueueable(SC360ScoutingFranceLeagueIds.scoutingLeagueIds(), 0, 1, y, maxP)
            );
            r.success = true;
            r.message =
                'Import FR (National + N2 + N3) en file — saison ' +
                y +
                ', max ' +
                maxP +
                ' pages/ligue';
            r.processedCount = 0;
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
        }
        return r;
    }
}
