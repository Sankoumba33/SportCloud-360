public with sharing class SC360AthleteDetailController {
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
        @AuraEnabled public String location;
        @AuraEnabled public String status;
    }

    public class DetailDto {
        @AuraEnabled public String name;
        @AuraEnabled public String externalId;
        @AuraEnabled public String sport;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<PointDto> loadSeries;
        @AuraEnabled public List<PointDto> readinessSeries;
        @AuraEnabled public List<String> medicalInsights;
        @AuraEnabled public List<TimelineDto> timeline;
    }

    @AuraEnabled(cacheable=true)
    public static DetailDto getDetail(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId manquant.');
        }
        Athlete__c athlete = [
            SELECT
                Id,
                Name,
                ExternalId__c,
                Sport__c,
                Status__c,
                Load7d__c,
                Load28d__c,
                Acwr__c,
                ReadinessScore__c,
                InjuryRiskScore__c,
                TopRisks__c,
                TopStrengths__c,
                LastDataCloudSync__c,
                AthleteSummary__c
            FROM Athlete__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        DetailDto dto = new DetailDto();
        dto.name = athlete.Name;
        dto.externalId = athlete.ExternalId__c;
        dto.sport = athlete.Sport__c;
        dto.status = athlete.Status__c;
        dto.lastSync = athlete.LastDataCloudSync__c;
        dto.kpis = new List<KpiDto>{
            kpi('load7d', 'Load 7j', athlete.Load7d__c, 'AU', 'stable'),
            kpi('load28d', 'Load 28j', athlete.Load28d__c, 'AU', 'stable'),
            kpi('acwr', 'ACWR', athlete.Acwr__c, '', athlete.Acwr__c != null && (athlete.Acwr__c > 1.5 || athlete.Acwr__c < 0.8) ? 'down' : 'stable'),
            kpi('readiness', 'Readiness', athlete.ReadinessScore__c, '%', athlete.ReadinessScore__c != null && athlete.ReadinessScore__c >= 65 ? 'up' : 'down'),
            kpi('risk', 'Injury Risk', athlete.InjuryRiskScore__c, '%', athlete.InjuryRiskScore__c != null && athlete.InjuryRiskScore__c >= 60 ? 'down' : 'stable')
        };
        dto.loadSeries = buildSeries(athlete.Load7d__c, 7, 'J');
        dto.readinessSeries = buildSeries(athlete.ReadinessScore__c, 7, 'J');
        dto.medicalInsights = buildMedicalInsights(athlete);
        dto.timeline = new List<TimelineDto>();

        for (PlanningEvent__c eventRow : [
            SELECT Name, EventType__c, StartDateTime__c, Location__c, Status__c
            FROM PlanningEvent__c
            WHERE StartDateTime__c >= :System.now().addDays(-1)
            ORDER BY StartDateTime__c ASC
            LIMIT 6
        ]) {
            TimelineDto t = new TimelineDto();
            t.title = eventRow.Name;
            t.type = eventRow.EventType__c;
            t.startAt = eventRow.StartDateTime__c;
            t.location = eventRow.Location__c;
            t.status = eventRow.Status__c;
            dto.timeline.add(t);
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

    private static List<PointDto> buildSeries(Decimal baseValue, Integer count, String prefix) {
        List<PointDto> out = new List<PointDto>();
        Decimal seed = baseValue == null ? 50 : baseValue;
        for (Integer i = count - 1; i >= 0; i--) {
            PointDto p = new PointDto();
            p.label = prefix + String.valueOf(count - i);
            Decimal drift = Math.mod(i * 11, 7) - 3;
            p.value = (seed + drift).setScale(2);
            out.add(p);
        }
        return out;
    }

    private static List<String> buildMedicalInsights(Athlete__c athlete) {
        List<String> insights = new List<String>();
        if (!String.isBlank(athlete.AthleteSummary__c)) {
            insights.add(athlete.AthleteSummary__c);
        }
        if (!String.isBlank(athlete.TopRisks__c)) {
            insights.add('Risques: ' + athlete.TopRisks__c);
        }
        if (!String.isBlank(athlete.TopStrengths__c)) {
            insights.add('Forces: ' + athlete.TopStrengths__c);
        }
        if (insights.isEmpty()) {
            insights.add('Aucun insight medical disponible.');
        }
        return insights;
    }
}
