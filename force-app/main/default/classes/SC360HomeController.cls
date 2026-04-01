public with sharing class SC360HomeController {
    public class KpiDto {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Decimal value;
        @AuraEnabled public String unit;
        @AuraEnabled public Decimal delta;
        @AuraEnabled public String trend;
    }

    public class PointDto {
        @AuraEnabled public String label;
        @AuraEnabled public Decimal value;
    }

    public class TimelineDto {
        @AuraEnabled public String title;
        @AuraEnabled public String type;
        @AuraEnabled public Datetime startAt;
        @AuraEnabled public Datetime endAt;
        @AuraEnabled public String location;
        @AuraEnabled public String status;
    }

    public class DataQualityDto {
        @AuraEnabled public Integer athletesWithoutExternalId;
        @AuraEnabled public Integer staleSyncOver24h;
        @AuraEnabled public Integer missingReadiness;
    }

    public class HomeDto {
        @AuraEnabled public String clubName;
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<PointDto> statusDistribution;
        @AuraEnabled public List<PointDto> squadDistribution;
        @AuraEnabled public List<TimelineDto> upcomingEvents;
        @AuraEnabled public List<String> aiInsights;
        @AuraEnabled public DataQualityDto dataQuality;
    }

    @AuraEnabled(cacheable=true)
    public static HomeDto getOverview() {
        HomeDto dto = new HomeDto();
        dto.clubName = 'Sports Intelligence Cloud';
        dto.kpis = new List<KpiDto>();
        dto.statusDistribution = new List<PointDto>();
        dto.squadDistribution = new List<PointDto>();
        dto.upcomingEvents = new List<TimelineDto>();
        dto.aiInsights = new List<String>();
        dto.dataQuality = new DataQualityDto();

        AggregateResult[] metricRows = [
            SELECT
                COUNT(Id) totalAthletes,
                AVG(ReadinessScore__c) avgReadiness,
                AVG(InjuryRiskScore__c) avgInjuryRisk,
                AVG(Load7d__c) avgLoad7d,
                MAX(LastDataCloudSync__c) maxSync
            FROM Athlete__c
        ];
        AggregateResult metrics = metricRows.isEmpty() ? null : metricRows[0];

        Decimal totalAthletes = decimalOrZero(metrics, 'totalAthletes');
        Integer totalActiveCount = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE Status__c = 'Active'
        ];
        Integer totalInjuredCount = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE Status__c = 'Injured'
        ];
        Decimal totalActive = Decimal.valueOf(String.valueOf(totalActiveCount));
        Decimal totalInjured = Decimal.valueOf(String.valueOf(totalInjuredCount));
        Decimal avgReadiness = decimalOrZero(metrics, 'avgReadiness');
        Decimal avgInjuryRisk = decimalOrZero(metrics, 'avgInjuryRisk');
        Decimal avgLoad7d = decimalOrZero(metrics, 'avgLoad7d');

        if (metrics != null && metrics.get('maxSync') != null) {
            dto.lastSync = (Datetime) metrics.get('maxSync');
        }

        Integer alertsCount = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE InjuryRiskScore__c >= 75
            OR (Acwr__c > 1.5 OR Acwr__c < 0.8)
        ];

        dto.kpis.add(kpi('total', 'Athletes', totalAthletes, '', 0, 'stable'));
        dto.kpis.add(kpi('active', 'Actifs', totalActive, '', 0, 'stable'));
        dto.kpis.add(kpi('injured', 'Blesses', totalInjured, '', 0, totalInjured > 0 ? 'down' : 'stable'));
        dto.kpis.add(kpi('readiness', 'Readiness Moy.', avgReadiness, '%', 1.2, 'up'));
        dto.kpis.add(kpi('injuryRisk', 'Injury Risk Moy.', avgInjuryRisk, '%', -1.7, 'down'));
        dto.kpis.add(kpi('alerts', 'Alertes', Decimal.valueOf(String.valueOf(alertsCount)), '', 0, alertsCount > 0 ? 'down' : 'stable'));

        for (AggregateResult row : [
            SELECT Status__c status, COUNT(Id) total
            FROM Athlete__c
            GROUP BY Status__c
            ORDER BY COUNT(Id) DESC
        ]) {
            dto.statusDistribution.add(point(
                String.valueOf(row.get('status')),
                decimalOrZero(row, 'total')
            ));
        }

        Map<Id, Integer> squadCountById = new Map<Id, Integer>();
        for (AggregateResult row : [
            SELECT CurrentSquad__c squadId, COUNT(Id) total
            FROM Athlete__c
            WHERE CurrentSquad__c != null
            GROUP BY CurrentSquad__c
            ORDER BY COUNT(Id) DESC
            LIMIT 8
        ]) {
            squadCountById.put((Id) row.get('squadId'), Integer.valueOf(String.valueOf(row.get('total'))));
        }
        if (!squadCountById.isEmpty()) {
            for (Squad__c squadRow : [
                SELECT Id, Name
                FROM Squad__c
                WHERE Id IN :squadCountById.keySet()
            ]) {
                dto.squadDistribution.add(point(
                    squadRow.Name,
                    Decimal.valueOf(squadCountById.get(squadRow.Id))
                ));
            }
        }

        for (PlanningEvent__c eventRow : [
            SELECT Name, EventType__c, StartDateTime__c, EndDateTime__c, Location__c, Status__c
            FROM PlanningEvent__c
            WHERE StartDateTime__c >= :System.now()
            AND StartDateTime__c <= :System.now().addDays(7)
            ORDER BY StartDateTime__c ASC
            LIMIT 10
        ]) {
            TimelineDto t = new TimelineDto();
            t.title = eventRow.Name;
            t.type = eventRow.EventType__c;
            t.startAt = eventRow.StartDateTime__c;
            t.endAt = eventRow.EndDateTime__c;
            t.location = eventRow.Location__c;
            t.status = eventRow.Status__c;
            dto.upcomingEvents.add(t);
        }

        dto.dataQuality.athletesWithoutExternalId = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE ExternalId__c = null
        ];
        dto.dataQuality.staleSyncOver24h = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE LastDataCloudSync__c = null
            OR LastDataCloudSync__c < :System.now().addHours(-24)
        ];
        dto.dataQuality.missingReadiness = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE ReadinessScore__c = null
        ];

        dto.aiInsights.add('Readiness collectif a ' + String.valueOf(avgReadiness.setScale(1)) + '%. Prioriser la recuperation active pour les profils a haut volume.');
        dto.aiInsights.add('Risque blessure moyen a ' + String.valueOf(avgInjuryRisk.setScale(1)) + '%. Renforcer le bloc prevention ischios/adducteurs cette semaine.');
        dto.aiInsights.add('Alertes actives: ' + String.valueOf(alertsCount) + '. Revue staff recommandee avant le prochain micro-cycle.');

        return dto;
    }

    private static KpiDto kpi(String key, String label, Decimal value, String unit, Decimal delta, String trend) {
        KpiDto row = new KpiDto();
        row.key = key;
        row.label = label;
        row.value = value == null ? 0 : value.setScale(2);
        row.unit = unit;
        row.delta = delta;
        row.trend = trend;
        return row;
    }

    private static PointDto point(String label, Decimal value) {
        PointDto row = new PointDto();
        row.label = String.isBlank(label) ? 'Non renseigne' : label;
        row.value = value == null ? 0 : value;
        return row;
    }

    private static Decimal decimalOrZero(AggregateResult row, String key) {
        if (row == null || row.get(key) == null) {
            return 0;
        }
        Object raw = row.get(key);
        if (raw instanceof Decimal) {
            return (Decimal) raw;
        }
        if (raw instanceof Integer) {
            return Decimal.valueOf(String.valueOf(raw));
        }
        if (raw instanceof Long) {
            return Decimal.valueOf(String.valueOf(raw));
        }
        return Decimal.valueOf(String.valueOf(raw));
    }
}
