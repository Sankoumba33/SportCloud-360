public with sharing class SC360MedicalController {
    public class KpiDto {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Decimal value;
        @AuraEnabled public String unit;
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

    public class OverviewDto {
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<PointDto> statusDistribution;
        @AuraEnabled public List<PointDto> riskBands;
        @AuraEnabled public List<TimelineDto> upcomingEvents;
        @AuraEnabled public List<String> aiInsights;
    }

    @AuraEnabled(cacheable=true)
    public static OverviewDto getOverview() {
        OverviewDto dto = new OverviewDto();
        dto.kpis = new List<KpiDto>();
        dto.statusDistribution = new List<PointDto>();
        dto.riskBands = new List<PointDto>();
        dto.upcomingEvents = new List<TimelineDto>();
        dto.aiInsights = new List<String>();

        AggregateResult[] metricsRows = [
            SELECT
                COUNT(Id) totalAthletes,
                AVG(ReadinessScore__c) avgReadiness,
                AVG(InjuryRiskScore__c) avgInjuryRisk,
                MAX(LastDataCloudSync__c) maxSync
            FROM Athlete__c
        ];
        AggregateResult metrics = metricsRows.isEmpty() ? null : metricsRows[0];
        Decimal totalAthletes = decimalOrZero(metrics, 'totalAthletes');
        Decimal avgReadiness = decimalOrZero(metrics, 'avgReadiness');
        Decimal avgInjuryRisk = decimalOrZero(metrics, 'avgInjuryRisk');

        Integer injuredCount = [SELECT COUNT() FROM Athlete__c WHERE Status__c = 'Injured'];
        Integer highRiskCount = [SELECT COUNT() FROM Athlete__c WHERE InjuryRiskScore__c >= 75];

        if (metrics != null && metrics.get('maxSync') != null) {
            dto.lastSync = (Datetime) metrics.get('maxSync');
        }

        dto.kpis.add(kpi('athletes', 'Athletes', totalAthletes, '', 'stable'));
        dto.kpis.add(kpi('injured', 'Blesses', Decimal.valueOf(String.valueOf(injuredCount)), '', injuredCount > 0 ? 'down' : 'stable'));
        dto.kpis.add(kpi('highRisk', 'High Risk', Decimal.valueOf(String.valueOf(highRiskCount)), '', highRiskCount > 0 ? 'down' : 'stable'));
        dto.kpis.add(kpi('readiness', 'Readiness Moy.', avgReadiness, '%', avgReadiness >= 65 ? 'up' : 'down'));
        dto.kpis.add(kpi('injuryRisk', 'Injury Risk Moy.', avgInjuryRisk, '%', avgInjuryRisk >= 60 ? 'down' : 'stable'));

        for (AggregateResult row : [
            SELECT Status__c statusLabel, COUNT(Id) total
            FROM Athlete__c
            GROUP BY Status__c
            ORDER BY COUNT(Id) DESC
        ]) {
            dto.statusDistribution.add(point(
                String.valueOf(row.get('statusLabel')),
                decimalOrZero(row, 'total')
            ));
        }

        dto.riskBands.add(point('Low (<35)', Decimal.valueOf(String.valueOf([SELECT COUNT() FROM Athlete__c WHERE InjuryRiskScore__c != null AND InjuryRiskScore__c < 35]))));
        dto.riskBands.add(point('Moderate (35-59)', Decimal.valueOf(String.valueOf([SELECT COUNT() FROM Athlete__c WHERE InjuryRiskScore__c >= 35 AND InjuryRiskScore__c < 60]))));
        dto.riskBands.add(point('High (60-74)', Decimal.valueOf(String.valueOf([SELECT COUNT() FROM Athlete__c WHERE InjuryRiskScore__c >= 60 AND InjuryRiskScore__c < 75]))));
        dto.riskBands.add(point('Critical (>=75)', Decimal.valueOf(String.valueOf([SELECT COUNT() FROM Athlete__c WHERE InjuryRiskScore__c >= 75]))));

        for (PlanningEvent__c eventRow : [
            SELECT Name, EventType__c, StartDateTime__c, EndDateTime__c, Location__c, Status__c
            FROM PlanningEvent__c
            WHERE StartDateTime__c >= :System.now()
            ORDER BY StartDateTime__c ASC
            LIMIT 6
        ]) {
            TimelineDto row = new TimelineDto();
            row.title = eventRow.Name;
            row.type = eventRow.EventType__c;
            row.startAt = eventRow.StartDateTime__c;
            row.endAt = eventRow.EndDateTime__c;
            row.location = eventRow.Location__c;
            row.status = eventRow.Status__c;
            dto.upcomingEvents.add(row);
        }

        dto.aiInsights.add('Risque blessure moyen: ' + String.valueOf(avgInjuryRisk.setScale(1)) + '%.');
        dto.aiInsights.add('Athletes blesses: ' + String.valueOf(injuredCount) + '. Prioriser les retours progressifs individualises.');
        dto.aiInsights.add('High risk >=75: ' + String.valueOf(highRiskCount) + '. Revue staff medical recommandee aujourd hui.');
        return dto;
    }

    private static KpiDto kpi(String key, String label, Decimal value, String unit, String trend) {
        KpiDto row = new KpiDto();
        row.key = key;
        row.label = label;
        row.value = value == null ? 0 : value.setScale(2);
        row.unit = unit;
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
        return Decimal.valueOf(String.valueOf(row.get(key)));
    }

}
