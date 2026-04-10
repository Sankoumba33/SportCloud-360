public with sharing class SC360DashboardController {
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

    public class DocumentDto {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Integer sizeKb;
        @AuraEnabled public Datetime lastModifiedDate;
    }

    public class ProfileDto {
        @AuraEnabled public String name;
        @AuraEnabled public String externalId;
        @AuraEnabled public String photoUrl;
        @AuraEnabled public String sport;
        @AuraEnabled public String status;
        @AuraEnabled public Integer age;
        @AuraEnabled public Datetime lastSync;
    }

    public class KanbanItemDto {
        @AuraEnabled public String title;
        @AuraEnabled public String lane;
        @AuraEnabled public String severity;
        @AuraEnabled public String helperText;
    }

    public class DashboardDto {
        @AuraEnabled public ProfileDto profile;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<PointDto> loadSeries;
        @AuraEnabled public List<PointDto> readinessSeries;
        @AuraEnabled public List<TimelineDto> timeline;
        @AuraEnabled public List<String> aiInsights;
        @AuraEnabled public List<KanbanItemDto> kanban;
        @AuraEnabled public List<DocumentDto> documents;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardDto getAthlete360(Id athleteId) {
        List<Athlete__c> athletes = athleteId == null
            ? new List<Athlete__c>([
                SELECT
                    Id,
                    Name,
                    ExternalId__c,
                    DateOfBirth__c,
                    Sport__c,
                    Status__c,
                    CurrentSquad__c,
                    Load7d__c,
                    Load28d__c,
                    Acwr__c,
                    ReadinessScore__c,
                    InjuryRiskScore__c,
                    AthleteSummary__c,
                    TopStrengths__c,
                    TopRisks__c,
                    LastDataCloudSync__c,
                    PhotoUrl__c
                FROM Athlete__c
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ])
            : new List<Athlete__c>([
                SELECT
                    Id,
                    Name,
                    ExternalId__c,
                    DateOfBirth__c,
                    Sport__c,
                    Status__c,
                    CurrentSquad__c,
                    Load7d__c,
                    Load28d__c,
                    Acwr__c,
                    ReadinessScore__c,
                    InjuryRiskScore__c,
                    AthleteSummary__c,
                    TopStrengths__c,
                    TopRisks__c,
                    LastDataCloudSync__c,
                    PhotoUrl__c
                FROM Athlete__c
                WHERE Id = :athleteId
                LIMIT 1
            ]);

        DashboardDto dto = new DashboardDto();
        if (athletes.isEmpty()) {
            dto.profile = new ProfileDto();
            dto.kpis = new List<KpiDto>();
            dto.loadSeries = new List<PointDto>();
            dto.readinessSeries = new List<PointDto>();
            dto.timeline = new List<TimelineDto>();
            dto.aiInsights = new List<String>();
            dto.kanban = new List<KanbanItemDto>();
            dto.documents = new List<DocumentDto>();
            return dto;
        }
        Athlete__c athlete = athletes[0];

        dto.profile = buildProfile(athlete);
        dto.kpis = buildKpis(athlete);
        dto.loadSeries = buildSeries(athlete.Load7d__c, 7, 'd');
        dto.readinessSeries = buildSeries(athlete.ReadinessScore__c, 7, 'd');
        dto.timeline = getTimeline(athlete.CurrentSquad__c);
        dto.aiInsights = buildAiInsights(athlete);
        dto.kanban = buildKanban(athlete);
        dto.documents = getDocuments(athlete.Id);
        return dto;
    }

    private static ProfileDto buildProfile(Athlete__c athlete) {
        ProfileDto p = new ProfileDto();
        p.name = athlete.Name;
        p.externalId = athlete.ExternalId__c;
        p.photoUrl = athlete.PhotoUrl__c;
        p.sport = athlete.Sport__c;
        p.status = athlete.Status__c;
        p.lastSync = athlete.LastDataCloudSync__c;
        if (athlete.DateOfBirth__c != null) {
            p.age = athlete.DateOfBirth__c.daysBetween(Date.today()) / 365;
        }
        return p;
    }

    private static List<KpiDto> buildKpis(Athlete__c athlete) {
        List<KpiDto> rows = new List<KpiDto>();
        rows.add(kpi('load7d', 'Load 7j', athlete.Load7d__c, 'AU', 6, trendFromDelta(6)));
        rows.add(kpi('acwr', 'ACWR', athlete.Acwr__c, '', -0.03, trendFromDelta(-0.03)));
        rows.add(kpi('readiness', 'Readiness', athlete.ReadinessScore__c, '%', 2.4, trendFromDelta(2.4)));
        rows.add(kpi('injury', 'Injury Risk', athlete.InjuryRiskScore__c, '%', -4.1, trendFromDelta(-4.1)));
        return rows;
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

    private static List<PointDto> buildSeries(Decimal baseValue, Integer count, String prefix) {
        List<PointDto> out = new List<PointDto>();
        Decimal seed = baseValue == null ? 50 : baseValue;
        for (Integer i = count - 1; i >= 0; i--) {
            PointDto p = new PointDto();
            p.label = prefix + String.valueOf(count - i);
            Decimal drift = Math.mod(i * 17, 11) - 5;
            p.value = (seed + drift).setScale(2);
            out.add(p);
        }
        return out;
    }

    private static List<TimelineDto> getTimeline(Id squadId) {
        List<TimelineDto> out = new List<TimelineDto>();
        if (squadId == null) {
            return out;
        }

        for (PlanningEvent__c eventRow : [
            SELECT Name, EventType__c, StartDateTime__c, EndDateTime__c, Location__c, Status__c
            FROM PlanningEvent__c
            WHERE Squad__c = :squadId
            AND StartDateTime__c >= :System.now().addDays(-2)
            ORDER BY StartDateTime__c ASC
            LIMIT 8
        ]) {
            TimelineDto row = new TimelineDto();
            row.title = eventRow.Name;
            row.type = eventRow.EventType__c;
            row.startAt = eventRow.StartDateTime__c;
            row.endAt = eventRow.EndDateTime__c;
            row.location = eventRow.Location__c;
            row.status = eventRow.Status__c;
            out.add(row);
        }
        return out;
    }

    private static List<String> buildAiInsights(Athlete__c athlete) {
        List<String> insights = new List<String>();
        if (!String.isBlank(athlete.AthleteSummary__c)) {
            insights.add(athlete.AthleteSummary__c);
        }
        if (!String.isBlank(athlete.TopStrengths__c)) {
            insights.add('Forces: ' + athlete.TopStrengths__c);
        }
        if (!String.isBlank(athlete.TopRisks__c)) {
            insights.add('Risques: ' + athlete.TopRisks__c);
        }
        if (insights.isEmpty()) {
            insights.add('Readiness stable, garder micro-cycle progressif et monitorer ACWR quotidiennement.');
            insights.add('Injury risk contenu, maintenir protocole prevention ischios + adducteurs.');
        }
        return insights;
    }

    private static List<KanbanItemDto> buildKanban(Athlete__c athlete) {
        List<KanbanItemDto> out = new List<KanbanItemDto>();
        out.add(kanban('Review charge du jour', athlete.Acwr__c != null && athlete.Acwr__c > 1.5 ? 'Alerte' : 'A faire', 'medium', 'Valider volume et RPE.'));
        out.add(kanban('Checkpoint medical', athlete.InjuryRiskScore__c != null && athlete.InjuryRiskScore__c >= 75 ? 'Alerte' : 'En cours', 'high', 'Verifier chaines posterieures.'));
        out.add(kanban('Synthese coach', 'Done', 'low', 'Brief pret pour staff meeting.'));
        return out;
    }

    private static KanbanItemDto kanban(String title, String lane, String severity, String helperText) {
        KanbanItemDto item = new KanbanItemDto();
        item.title = title;
        item.lane = lane;
        item.severity = severity;
        item.helperText = helperText;
        return item;
    }

    private static List<DocumentDto> getDocuments(Id athleteId) {
        List<DocumentDto> docs = new List<DocumentDto>();
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :athleteId
            LIMIT 6
        ];
        if (links.isEmpty()) {
            return docs;
        }

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink linkRow : links) {
            docIds.add(linkRow.ContentDocumentId);
        }

        for (ContentDocument d : [
            SELECT Id, Title, FileType, ContentSize, LastModifiedDate
            FROM ContentDocument
            WHERE Id IN :docIds
            ORDER BY LastModifiedDate DESC
        ]) {
            DocumentDto row = new DocumentDto();
            row.id = d.Id;
            row.title = d.Title;
            row.fileType = d.FileType;
            row.lastModifiedDate = d.LastModifiedDate;
            row.sizeKb = d.ContentSize == null ? 0 : Integer.valueOf(String.valueOf(Math.round((Decimal.valueOf(d.ContentSize) / 1024))));
            docs.add(row);
        }
        return docs;
    }

    private static String trendFromDelta(Decimal delta) {
        if (delta == null || delta == 0) {
            return 'stable';
        }
        return delta > 0 ? 'up' : 'down';
    }
}
