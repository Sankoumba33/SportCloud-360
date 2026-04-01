/**
 * Import paginé multi-ligues : GET /players?league={id}&season=&page=
 * Enchaîne National (63), National 2 (67–69), National 3 (461+…), puis pages suivantes.
 */
public class SC360ScoutingLeagueImportQueueable implements Queueable, Database.AllowsCallouts {
    private final List<Integer> leagueIds;
    private final Integer leagueIndex;
    private final Integer page;
    private final Integer season;
    private final Integer maxPagesPerLeague;

    public SC360ScoutingLeagueImportQueueable(
        List<Integer> leagueIds,
        Integer leagueIndex,
        Integer page,
        Integer season,
        Integer maxPagesPerLeague
    ) {
        this.leagueIds = leagueIds != null && !leagueIds.isEmpty()
            ? leagueIds
            : SC360ScoutingFranceLeagueIds.scoutingLeagueIds();
        this.leagueIndex = leagueIndex != null && leagueIndex >= 0 ? leagueIndex : 0;
        this.page = page != null && page > 0 ? page : 1;
        this.season = season != null ? season : SC360ScoutingProspectSyncService.DEFAULT_SEASON;
        this.maxPagesPerLeague = maxPagesPerLeague != null && maxPagesPerLeague > 0 ? maxPagesPerLeague : 10;
    }

    public void execute(QueueableContext ctx) {
        if (leagueIds.isEmpty() || leagueIndex >= leagueIds.size()) {
            return;
        }
        if (page > maxPagesPerLeague) {
            chainNextLeague(leagueIndex + 1, 1);
            return;
        }

        Integer leagueId = leagueIds[leagueIndex];
        HttpResponse res = ApiSportsFootballClient.get(
            '/players?league=' + leagueId + '&season=' + season + '&page=' + page
        );
        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.WARN, 'Import league ' + leagueId + ' HTTP ' + res.getStatusCode());
            chainNextLeague(leagueIndex + 1, 1);
            return;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (!errorsEmpty(root.get('errors'))) {
            System.debug(LoggingLevel.WARN, 'Import league ' + leagueId + ' API ' + JSON.serialize(root.get('errors')));
            chainNextLeague(leagueIndex + 1, 1);
            return;
        }

        List<Object> responseList = (List<Object>) root.get('response');
        if (responseList == null || responseList.isEmpty()) {
            chainNextLeague(leagueIndex + 1, 1);
            return;
        }

        List<Prospect__c> rows = new List<Prospect__c>();
        for (Object o : responseList) {
            Map<String, Object> row = (Map<String, Object>) o;
            Map<String, Object> player = (Map<String, Object>) row.get('player');
            if (player == null) {
                continue;
            }
            Object pid = player.get('id');
            if (pid == null) {
                continue;
            }
            List<Object> statsList = (List<Object>) row.get('statistics');
            Map<String, Object> stat0 = statsList != null && !statsList.isEmpty()
                ? (Map<String, Object>) statsList[0]
                : null;

            String nm = (String) player.get('name');
            if (String.isBlank(nm)) {
                nm = 'Player ' + String.valueOf(pid);
            }
            if (nm.length() > 80) {
                nm = nm.substring(0, 80);
            }

            Prospect__c p = new Prospect__c(
                ExternalId__c = 'APISPORTS-' + String.valueOf(pid),
                Name = nm,
                Status__c = 'New',
                Nationality__c = (String) player.get('nationality'),
                Country__c = 'France',
                Position__c = positionFrom(player, stat0),
                CurrentClub__c = clubFrom(stat0),
                Championship__c = leagueFrom(stat0),
                ScoutingFeaturesJson__c = JSON.serialize(row),
                ScoutingSummary__c = shortSummary(player, stat0, season, leagueId),
                DataConfidence__c = 72
            );
            ApiFootballStatsMapper.applyToProspect(p, stat0, season);
            rows.add(p);
        }
        if (!rows.isEmpty()) {
            upsert rows ExternalId__c;
        }

        Map<String, Object> paging = (Map<String, Object>) root.get('paging');
        Integer current = intVal(paging != null ? paging.get('current') : null);
        Integer totalPages = intVal(paging != null ? paging.get('total') : null);
        if (current == null) {
            current = page;
        }

        if (totalPages != null && current < totalPages && page < maxPagesPerLeague) {
            System.enqueueJob(
                new SC360ScoutingLeagueImportQueueable(leagueIds, leagueIndex, page + 1, season, maxPagesPerLeague)
            );
        } else {
            chainNextLeague(leagueIndex + 1, 1);
        }
    }

    private void chainNextLeague(Integer nextIndex, Integer nextPage) {
        if (nextIndex >= leagueIds.size()) {
            return;
        }
        System.enqueueJob(new SC360ScoutingLeagueImportQueueable(leagueIds, nextIndex, nextPage, season, maxPagesPerLeague));
    }

    private static String shortSummary(
        Map<String, Object> player,
        Map<String, Object> stat0,
        Integer season,
        Integer leagueApiId
    ) {
        String club = clubFrom(stat0);
        String lg = leagueFrom(stat0);
        return 'Import FR — ligue API '
            + leagueApiId
            + (lg != null ? ' (' + lg + ')' : '')
            + ' — saison '
            + season
            + ' — '
            + (club != null ? club : 'club N/A')
            + ' — '
            + (String) player.get('name');
    }

    private static String positionFrom(Map<String, Object> player, Map<String, Object> stat0) {
        if (stat0 != null) {
            Map<String, Object> games = (Map<String, Object>) stat0.get('games');
            if (games != null && games.get('position') != null) {
                return String.valueOf(games.get('position'));
            }
        }
        return player.get('position') != null ? String.valueOf(player.get('position')) : null;
    }

    private static String clubFrom(Map<String, Object> stat0) {
        if (stat0 == null) {
            return null;
        }
        Map<String, Object> team = (Map<String, Object>) stat0.get('team');
        return team != null ? (String) team.get('name') : null;
    }

    private static String leagueFrom(Map<String, Object> stat0) {
        if (stat0 == null) {
            return null;
        }
        Map<String, Object> league = (Map<String, Object>) stat0.get('league');
        return league != null ? (String) league.get('name') : null;
    }

    private static Integer intVal(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof Integer) {
            return (Integer) o;
        }
        if (o instanceof Decimal) {
            return ((Decimal) o).intValue();
        }
        if (o instanceof Long) {
            return ((Long) o).intValue();
        }
        if (o instanceof Double) {
            return ((Double) o).intValue();
        }
        try {
            return Integer.valueOf(String.valueOf(o));
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean errorsEmpty(Object errorsNode) {
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
