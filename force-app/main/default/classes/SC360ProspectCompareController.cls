public with sharing class SC360ProspectCompareController {
    public class ProspectCompareDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String position;
        @AuraEnabled public String status;
        @AuraEnabled public String currentClub;
        @AuraEnabled public Decimal scoutingScore;
        @AuraEnabled public Decimal potentialScore;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Decimal fitScore;
        @AuraEnabled public Decimal dataConfidence;
        @AuraEnabled public String topStrengths;
        @AuraEnabled public String topRisks;
        @AuraEnabled public String scoutingSummary;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProspectCompareDto> getProspectsCompare(List<Id> prospectIds) {
        if (prospectIds == null || prospectIds.size() < 2) {
            throw new AuraHandledException('Sélectionne au moins deux prospects.');
        }
        if (prospectIds.size() > 2) {
            throw new AuraHandledException('La comparaison est limitée à deux prospects pour le MVP.');
        }
        Set<Id> unique = new Set<Id>(prospectIds);
        if (unique.size() != prospectIds.size()) {
            throw new AuraHandledException('Les deux prospects doivent être distincts.');
        }

        Map<Id, Prospect__c> rows = new Map<Id, Prospect__c>(
            [
                SELECT
                    Id,
                    Name,
                    Position__c,
                    Status__c,
                    CurrentClub__c,
                    ScoutingScore__c,
                    PotentialScore__c,
                    RiskScore__c,
                    FitScore__c,
                    DataConfidence__c,
                    TopStrengths__c,
                    TopRisks__c,
                    ScoutingSummary__c
                FROM Prospect__c
                WHERE Id IN :prospectIds
            ]
        );

        if (rows.size() != prospectIds.size()) {
            throw new AuraHandledException('Un ou plusieurs prospects sont introuvables ou inaccessibles.');
        }

        List<ProspectCompareDto> ordered = new List<ProspectCompareDto>();
        for (Id pid : prospectIds) {
            Prospect__c p = rows.get(pid);
            ProspectCompareDto dto = new ProspectCompareDto();
            dto.id = p.Id;
            dto.name = p.Name;
            dto.position = p.Position__c;
            dto.status = p.Status__c;
            dto.currentClub = p.CurrentClub__c;
            dto.scoutingScore = p.ScoutingScore__c;
            dto.potentialScore = p.PotentialScore__c;
            dto.riskScore = p.RiskScore__c;
            dto.fitScore = p.FitScore__c;
            dto.dataConfidence = p.DataConfidence__c;
            dto.topStrengths = p.TopStrengths__c;
            dto.topRisks = p.TopRisks__c;
            dto.scoutingSummary = p.ScoutingSummary__c;
            ordered.add(dto);
        }
        return ordered;
    }
}
