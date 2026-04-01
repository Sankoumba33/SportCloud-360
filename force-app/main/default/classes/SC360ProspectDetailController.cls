public with sharing class SC360ProspectDetailController {
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

    public class ProspectDto {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String externalId;
        @AuraEnabled public String position;
        @AuraEnabled public String status;
        @AuraEnabled public String currentClub;
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public List<KpiDto> kpis;
        @AuraEnabled public List<KpiDto> apiSeasonKpis;
        @AuraEnabled public List<String> insights;
        @AuraEnabled public List<PointDto> benchmark;
    }

    public class StepReportDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String stepType;
        @AuraEnabled public Date reportDate;
        @AuraEnabled public Decimal rating;
        @AuraEnabled public String summary;
        @AuraEnabled public String matchSelection;
        @AuraEnabled public String referenceContacts;
        @AuraEnabled public String socialNetworks;
        @AuraEnabled public String comparisonNotes;
        @AuraEnabled public String autoInsights;
    }

    @AuraEnabled(cacheable=true)
    public static ProspectDto getDetail(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId manquant.');
        }
        Prospect__c prospect = [
            SELECT
                Id,
                Name,
                ExternalId__c,
                Position__c,
                Status__c,
                CurrentClub__c,
                ScoutingScore__c,
                PotentialScore__c,
                FitScore__c,
                RiskScore__c,
                DataConfidence__c,
                TopStrengths__c,
                TopRisks__c,
                ScoutingSummary__c,
                LastDataCloudSync__c,
                ApiStatsSeason__c,
                ApiAppearances__c,
                ApiLineups__c,
                ApiMinutes__c,
                ApiGoals__c,
                ApiAssists__c,
                ApiYellowCards__c,
                ApiRedCards__c,
                ApiShotsTotal__c,
                ApiShotsOnTarget__c,
                ApiPassesTotal__c,
                ApiPassesKey__c,
                ApiPassesAccuracyPct__c,
                ApiTacklesTotal__c,
                ApiDuelsWon__c
            FROM Prospect__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        ProspectDto dto = new ProspectDto();
        dto.id = prospect.Id;
        dto.name = prospect.Name;
        dto.externalId = prospect.ExternalId__c;
        dto.position = prospect.Position__c;
        dto.status = prospect.Status__c;
        dto.currentClub = prospect.CurrentClub__c;
        dto.lastSync = prospect.LastDataCloudSync__c;
        dto.kpis = new List<KpiDto>{
            kpi('scouting', 'Scouting Score', prospect.ScoutingScore__c, '%', 'up'),
            kpi('potential', 'Potential', prospect.PotentialScore__c, '%', 'up'),
            kpi('fit', 'Fit', prospect.FitScore__c, '%', 'stable'),
            kpi('risk', 'Risk', prospect.RiskScore__c, '%', prospect.RiskScore__c != null && prospect.RiskScore__c >= 60 ? 'down' : 'stable'),
            kpi('confidence', 'Data Confidence', prospect.DataConfidence__c, '%', 'stable')
        };
        dto.apiSeasonKpis = buildApiSeasonKpis(prospect);
        dto.insights = new List<String>();
        if (!String.isBlank(prospect.ScoutingSummary__c)) {
            dto.insights.add(prospect.ScoutingSummary__c);
        }
        if (!String.isBlank(prospect.TopStrengths__c)) {
            dto.insights.add('Forces: ' + prospect.TopStrengths__c);
        }
        if (!String.isBlank(prospect.TopRisks__c)) {
            dto.insights.add('Risques: ' + prospect.TopRisks__c);
        }
        if (dto.insights.isEmpty()) {
            dto.insights.add('Aucun insight scouting disponible.');
        }
        dto.benchmark = buildBenchmark(prospect);
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static List<StepReportDto> getStepReports(Id prospectId) {
        List<StepReportDto> out = new List<StepReportDto>();
        for (ScoutingReport__c row : [
            SELECT
                Id,
                StepType__c,
                ReportDate__c,
                Rating__c,
                Summary__c,
                MatchSelection__c,
                ReferenceContacts__c,
                SocialNetworks__c,
                ComparisonNotes__c,
                AutoInsights__c
            FROM ScoutingReport__c
            WHERE Prospect__c = :prospectId
            ORDER BY ReportDate__c DESC, LastModifiedDate DESC
        ]) {
            StepReportDto dto = new StepReportDto();
            dto.id = row.Id;
            dto.stepType = row.StepType__c;
            dto.reportDate = row.ReportDate__c;
            dto.rating = row.Rating__c;
            dto.summary = row.Summary__c;
            dto.matchSelection = row.MatchSelection__c;
            dto.referenceContacts = row.ReferenceContacts__c;
            dto.socialNetworks = row.SocialNetworks__c;
            dto.comparisonNotes = row.ComparisonNotes__c;
            dto.autoInsights = row.AutoInsights__c;
            out.add(dto);
        }
        return out;
    }

    @AuraEnabled
    public static Id saveStepReport(
        Id prospectId,
        String stepType,
        String matchSelection,
        String summary,
        String comparisonNotes,
        String referenceContacts,
        String socialNetworks,
        Decimal rating
    ) {
        if (prospectId == null || String.isBlank(stepType)) {
            throw new AuraHandledException('Prospect et etape obligatoires.');
        }
        ScoutingReport__c report = new ScoutingReport__c();
        report.Prospect__c = prospectId;
        report.StepType__c = stepType;
        report.ReportDate__c = Date.today();
        report.Rating__c = rating;
        report.MatchSelection__c = matchSelection;
        report.Summary__c = summary;
        report.ComparisonNotes__c = comparisonNotes;
        report.ReferenceContacts__c = referenceContacts;
        report.SocialNetworks__c = socialNetworks;
        report.AutoInsights__c = buildAutoInsight(stepType, rating, summary, comparisonNotes);
        insert report;
        return report.Id;
    }

    private static List<KpiDto> buildApiSeasonKpis(Prospect__c p) {
        List<KpiDto> rows = new List<KpiDto>();
        if (p.ApiStatsSeason__c != null) {
            rows.add(kpi('api_season', 'Saison API', p.ApiStatsSeason__c, '', 'stable'));
        }
        addKpiIfNotNull(rows, 'api_apps', 'Matchs joués (API)', p.ApiAppearances__c, '');
        addKpiIfNotNull(rows, 'api_lineups', 'Titularisations (API)', p.ApiLineups__c, '');
        addKpiIfNotNull(rows, 'api_minutes', 'Minutes (API)', p.ApiMinutes__c, 'min');
        addKpiIfNotNull(rows, 'api_goals', 'Buts (API)', p.ApiGoals__c, '');
        addKpiIfNotNull(rows, 'api_assists', 'Passes D. (API)', p.ApiAssists__c, '');
        addKpiIfNotNull(rows, 'api_yellow', 'Jaunes (API)', p.ApiYellowCards__c, '');
        addKpiIfNotNull(rows, 'api_red', 'Rouges (API)', p.ApiRedCards__c, '');
        addKpiIfNotNull(rows, 'api_shots', 'Tirs (API)', p.ApiShotsTotal__c, '');
        addKpiIfNotNull(rows, 'api_shots_on', 'Tirs cadrés (API)', p.ApiShotsOnTarget__c, '');
        addKpiIfNotNull(rows, 'api_passes', 'Passes (API)', p.ApiPassesTotal__c, '');
        addKpiIfNotNull(rows, 'api_key_passes', 'Passes clés (API)', p.ApiPassesKey__c, '');
        addKpiIfNotNull(rows, 'api_pass_acc', 'Précision passes % (API)', p.ApiPassesAccuracyPct__c, '%');
        addKpiIfNotNull(rows, 'api_tackles', 'Tacles (API)', p.ApiTacklesTotal__c, '');
        addKpiIfNotNull(rows, 'api_duels', 'Duels gagnés (API)', p.ApiDuelsWon__c, '');
        return rows;
    }

    private static void addKpiIfNotNull(List<KpiDto> rows, String key, String label, Decimal val, String unit) {
        if (val == null) {
            return;
        }
        rows.add(kpi(key, label, val, unit, 'stable'));
    }

    private static List<PointDto> buildBenchmark(Prospect__c prospect) {
        AggregateResult[] aggRows = [
            SELECT AVG(ScoutingScore__c) avgScouting, AVG(PotentialScore__c) avgPotential, AVG(RiskScore__c) avgRisk
            FROM Prospect__c
            WHERE Position__c = :prospect.Position__c
        ];
        AggregateResult agg = aggRows.isEmpty() ? null : aggRows[0];
        List<PointDto> rows = new List<PointDto>();
        rows.add(point('Scout Score (prospect)', prospect.ScoutingScore__c));
        rows.add(point('Scout Score (poste)', decimalOrZero(agg, 'avgScouting')));
        rows.add(point('Potential (prospect)', prospect.PotentialScore__c));
        rows.add(point('Potential (poste)', decimalOrZero(agg, 'avgPotential')));
        rows.add(point('Risk (prospect)', prospect.RiskScore__c));
        rows.add(point('Risk (poste)', decimalOrZero(agg, 'avgRisk')));
        return rows;
    }

    private static String buildAutoInsight(String stepType, Decimal rating, String summary, String comparisonNotes) {
        List<String> lines = new List<String>();
        lines.add('Etape: ' + stepType);
        if (rating != null) {
            lines.add('Rating: ' + String.valueOf(rating.setScale(1)) + '/10');
        }
        if (!String.isBlank(comparisonNotes)) {
            lines.add('Comparaison: ' + comparisonNotes.left(180));
        }
        if (!String.isBlank(summary)) {
            lines.add('Synthese: ' + summary.left(180));
        }
        if (rating != null && rating >= 8) {
            lines.add('Recommendation: avancer vers shortlist prioritaire.');
        } else if (rating != null && rating <= 5) {
            lines.add('Recommendation: monitorer, informations complementaires necessaires.');
        } else {
            lines.add('Recommendation: poursuivre le scouting avec data check approfondi.');
        }
        return String.join(lines, '\n');
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
        row.label = label;
        row.value = value == null ? 0 : value.setScale(2);
        return row;
    }

    private static Decimal decimalOrZero(AggregateResult row, String key) {
        if (row == null || row.get(key) == null) {
            return 0;
        }
        return Decimal.valueOf(String.valueOf(row.get(key)));
    }
}
