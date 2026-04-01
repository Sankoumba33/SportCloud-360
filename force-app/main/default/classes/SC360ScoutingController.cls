public with sharing class SC360ScoutingController {
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

    public class OverviewDto {
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<PointDto> statusDistribution;
        @AuraEnabled public List<PointDto> positionDistribution;
        @AuraEnabled public List<String> aiInsights;
    }

    @AuraEnabled(cacheable=true)
    public static OverviewDto getOverview() {
        OverviewDto dto = new OverviewDto();
        dto.kpis = new List<KpiDto>();
        dto.statusDistribution = new List<PointDto>();
        dto.positionDistribution = new List<PointDto>();
        dto.aiInsights = new List<String>();

        AggregateResult[] metricsRows = [
            SELECT
                COUNT(Id) totalProspects,
                AVG(ScoutingScore__c) avgScouting,
                AVG(PotentialScore__c) avgPotential,
                AVG(RiskScore__c) avgRisk,
                MAX(LastDataCloudSync__c) maxSync
            FROM Prospect__c
        ];
        AggregateResult metrics = metricsRows.isEmpty() ? null : metricsRows[0];

        Decimal totalProspects = decimalOrZero(metrics, 'totalProspects');
        Decimal avgScouting = decimalOrZero(metrics, 'avgScouting');
        Decimal avgPotential = decimalOrZero(metrics, 'avgPotential');
        Decimal avgRisk = decimalOrZero(metrics, 'avgRisk');
        Integer priorityCount = [
            SELECT COUNT()
            FROM Prospect__c
            WHERE Status__c = 'Priority'
        ];

        if (metrics != null && metrics.get('maxSync') != null) {
            dto.lastSync = (Datetime) metrics.get('maxSync');
        }

        dto.kpis.add(kpi('prospects', 'Prospects', totalProspects, '', 'stable'));
        dto.kpis.add(kpi('priority', 'Priority', Decimal.valueOf(String.valueOf(priorityCount)), '', priorityCount > 0 ? 'down' : 'stable'));
        dto.kpis.add(kpi('scouting', 'Scouting Score', avgScouting, '%', 'up'));
        dto.kpis.add(kpi('potential', 'Potential', avgPotential, '%', 'up'));
        dto.kpis.add(kpi('risk', 'Risk Score', avgRisk, '%', avgRisk >= 60 ? 'down' : 'stable'));

        for (AggregateResult row : [
            SELECT Status__c statusLabel, COUNT(Id) total
            FROM Prospect__c
            GROUP BY Status__c
            ORDER BY COUNT(Id) DESC
        ]) {
            dto.statusDistribution.add(point(
                String.valueOf(row.get('statusLabel')),
                decimalOrZero(row, 'total')
            ));
        }

        for (AggregateResult row : [
            SELECT Position__c positionLabel, COUNT(Id) total
            FROM Prospect__c
            GROUP BY Position__c
            ORDER BY COUNT(Id) DESC
            LIMIT 8
        ]) {
            dto.positionDistribution.add(point(
                String.valueOf(row.get('positionLabel')),
                decimalOrZero(row, 'total')
            ));
        }

        for (Prospect__c p : [
            SELECT Name, ScoutingScore__c, RiskScore__c, TopStrengths__c, TopRisks__c
            FROM Prospect__c
            ORDER BY LastModifiedDate DESC
            LIMIT 3
        ]) {
            String scoreLabel = p.ScoutingScore__c == null ? 'n/a' : String.valueOf(p.ScoutingScore__c.setScale(0));
            String riskLabel = p.RiskScore__c == null ? 'n/a' : String.valueOf(p.RiskScore__c.setScale(0));
            dto.aiInsights.add(p.Name + ': score ' + scoreLabel + ', risk ' + riskLabel + '.');
            if (!String.isBlank(p.TopStrengths__c)) {
                dto.aiInsights.add('Forces ' + p.Name + ': ' + p.TopStrengths__c);
            }
            if (!String.isBlank(p.TopRisks__c)) {
                dto.aiInsights.add('Risques ' + p.Name + ': ' + p.TopRisks__c);
            }
        }

        if (dto.aiInsights.isEmpty()) {
            dto.aiInsights.add('Aucun insight scouting disponible pour le moment.');
        }
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
