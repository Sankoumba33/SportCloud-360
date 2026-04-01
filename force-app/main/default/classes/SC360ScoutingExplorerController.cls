public with sharing class SC360ScoutingExplorerController {
    public class FilterOptionsDto {
        @AuraEnabled public List<String> positions;
        @AuraEnabled public List<String> statuses;
        @AuraEnabled public List<String> countries;
        @AuraEnabled public List<String> nationalities;
        @AuraEnabled public List<String> championships;
        @AuraEnabled public List<LabelValueDto> dataQualityBuckets;
    }

    public class LabelValueDto {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class ExplorerRowDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String position;
        @AuraEnabled public String status;
        @AuraEnabled public String currentClub;
        @AuraEnabled public String country;
        @AuraEnabled public String nationality;
        @AuraEnabled public String championship;
        @AuraEnabled public Decimal scoutingScore;
        @AuraEnabled public Decimal dataConfidence;
        @AuraEnabled public Decimal geoLatitude;
        @AuraEnabled public Decimal geoLongitude;
        @AuraEnabled public String source;
        @AuraEnabled public String externalKey;
    }

    public class SearchResultDto {
        @AuraEnabled public List<ExplorerRowDto> rows;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Boolean dataCloudConfigured;
        @AuraEnabled public List<ExplorerRowDto> dataCloudRows;
    }

    public class ProspectDraftDto {
        @AuraEnabled public String name;
        @AuraEnabled public String position;
        @AuraEnabled public String currentClub;
        @AuraEnabled public String country;
        @AuraEnabled public String nationality;
        @AuraEnabled public String championship;
        @AuraEnabled public Decimal geoLatitude;
        @AuraEnabled public Decimal geoLongitude;
        @AuraEnabled public String status;
        @AuraEnabled public String externalKey;
    }

    @AuraEnabled(cacheable=true)
    public static FilterOptionsDto getFilterOptions() {
        FilterOptionsDto dto = new FilterOptionsDto();
        dto.positions = distinctValues('Position__c');
        dto.statuses = distinctValues('Status__c');
        dto.countries = distinctValues('Country__c');
        dto.nationalities = distinctValues('Nationality__c');
        dto.championships = distinctValues('Championship__c');
        dto.dataQualityBuckets = new List<LabelValueDto>{
            lv('Toutes données', 'all'),
            lv('Confiance >= 70%', 'high'),
            lv('Confiance < 70%', 'low'),
            lv('Confiance vide', 'empty')
        };
        return dto;
    }

    private static LabelValueDto lv(String label, String value) {
        LabelValueDto x = new LabelValueDto();
        x.label = label;
        x.value = value;
        return x;
    }

    private static List<String> distinctValues(String fieldApi) {
        List<String> out = new List<String>();
        if (!Schema.SObjectType.Prospect__c.fields.getMap().containsKey(fieldApi)) {
            return out;
        }
        String soql =
            'SELECT ' +
            fieldApi +
            ' FROM Prospect__c WHERE ' +
            fieldApi +
            ' != null GROUP BY ' +
            fieldApi +
            ' ORDER BY ' +
            fieldApi +
            ' LIMIT 200';
        for (AggregateResult ar : Database.query(soql)) {
            Object v = ar.get(fieldApi);
            if (v != null) {
                out.add(String.valueOf(v));
            }
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static SearchResultDto searchProspects(
        String searchKey,
        String position,
        String status,
        String country,
        String nationality,
        String championship,
        String dataQuality,
        Integer rowLimit
    ) {
        SearchResultDto res = new SearchResultDto();
        res.rows = new List<ExplorerRowDto>();
        res.dataCloudRows = new List<ExplorerRowDto>();
        res.dataCloudConfigured = false;
        res.totalCount = 0;

        Integer lim = rowLimit == null || rowLimit < 1 ? 50 : Math.min(rowLimit, 200);

        List<String> cond = new List<String>();
        if (!String.isBlank(searchKey)) {
            String kw = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
            cond.add(
                '(Name LIKE \'' +
                kw +
                '\' OR CurrentClub__c LIKE \'' +
                kw +
                '\' OR ExternalId__c LIKE \'' +
                kw +
                '\')'
            );
        }
        addEq(cond, 'Position__c', position);
        addEq(cond, 'Status__c', status);
        addEq(cond, 'Country__c', country);
        addEq(cond, 'Nationality__c', nationality);
        addEq(cond, 'Championship__c', championship);
        if (!String.isBlank(dataQuality) && dataQuality != 'all') {
            if (dataQuality == 'high') {
                cond.add('DataConfidence__c >= 70');
            } else if (dataQuality == 'low') {
                cond.add('DataConfidence__c < 70');
            } else if (dataQuality == 'empty') {
                cond.add('DataConfidence__c = null');
            }
        }

        String whereClause = cond.isEmpty() ? '' : ' WHERE ' + String.join(cond, ' AND ');
        String countSoql = 'SELECT COUNT() FROM Prospect__c' + whereClause;
        res.totalCount = Database.countQuery(countSoql);

        String selectFields =
            'SELECT Id, Name, Position__c, Status__c, CurrentClub__c, Country__c, Nationality__c, Championship__c, ' +
            'ScoutingScore__c, DataConfidence__c, GeoLatitude__c, GeoLongitude__c, ExternalId__c ' +
            'FROM Prospect__c' +
            whereClause +
            ' ORDER BY LastModifiedDate DESC LIMIT ' +
            String.valueOf(lim);

        for (Prospect__c p : Database.query(selectFields)) {
            res.rows.add(toRow(p, 'Core'));
        }

        return res;
    }

    private static void addEq(List<String> cond, String field, String val) {
        if (String.isBlank(val)) {
            return;
        }
        cond.add(field + ' = \'' + String.escapeSingleQuotes(val) + '\'');
    }

    private static ExplorerRowDto toRow(Prospect__c p, String source) {
        ExplorerRowDto r = new ExplorerRowDto();
        r.id = p.Id;
        r.name = p.Name;
        r.position = p.Position__c;
        r.status = p.Status__c;
        r.currentClub = p.CurrentClub__c;
        r.country = p.Country__c;
        r.nationality = p.Nationality__c;
        r.championship = p.Championship__c;
        r.scoutingScore = p.ScoutingScore__c;
        r.dataConfidence = p.DataConfidence__c;
        r.geoLatitude = p.GeoLatitude__c;
        r.geoLongitude = p.GeoLongitude__c;
        r.source = source;
        r.externalKey = p.ExternalId__c;
        return r;
    }

    @AuraEnabled
    public static void promoteToPriority(Id prospectId) {
        if (prospectId == null) {
            throw new AuraHandledException('Prospect invalide.');
        }
        Prospect__c p = new Prospect__c(Id = prospectId, Status__c = 'Priority');
        update p;
    }

    @AuraEnabled
    public static Id addProspectToPipeline(ProspectDraftDto draft) {
        if (draft == null || String.isBlank(draft.name)) {
            throw new AuraHandledException('Nom prospect obligatoire.');
        }
        Prospect__c p = new Prospect__c();
        p.Name = draft.name.trim();
        p.Position__c = draft.position;
        p.CurrentClub__c = draft.currentClub;
        p.Country__c = draft.country;
        p.Nationality__c = draft.nationality;
        p.Championship__c = draft.championship;
        p.GeoLatitude__c = draft.geoLatitude;
        p.GeoLongitude__c = draft.geoLongitude;
        if (!String.isBlank(draft.externalKey)) {
            p.ExternalId__c = draft.externalKey;
        }
        p.Status__c = String.isBlank(draft.status) ? 'Under Review' : draft.status;
        insert p;
        return p.Id;
    }
}
