public with sharing class SC360AthleteRadarController {
    private static final Decimal LOAD_CAP = 5000;
    private static final Decimal SPEED_CAP_KMH = 38;

    public class RadarDto {
        @AuraEnabled public String athleteName;
        @AuraEnabled public List<String> axisLabels;
        @AuraEnabled public List<Decimal> values;
        @AuraEnabled public String footnote;
    }

    @AuraEnabled(cacheable=true)
    public static RadarDto getRadar(Id athleteId) {
        if (athleteId == null) {
            return null;
        }
        Athlete__c a = [
            SELECT
                Name,
                ReadinessScore__c,
                InjuryRiskScore__c,
                PassAccuracy5__c,
                DuelWinPct5__c,
                MaxSpeed7d__c,
                Load7d__c
            FROM Athlete__c
            WHERE Id = :athleteId
            LIMIT 1
        ];

        RadarDto dto = new RadarDto();
        dto.athleteName = a.Name;
        dto.axisLabels = new List<String>{
            'Readiness',
            'Santé (inv. risque)',
            'Passes (5m)',
            'Duels (5m)',
            'Vitesse max',
            'Charge 7j'
        };
        dto.values = new List<Decimal>{
            nReadiness(a.ReadinessScore__c),
            nHealth(a.InjuryRiskScore__c),
            nPercent(a.PassAccuracy5__c),
            nPercent(a.DuelWinPct5__c),
            nSpeed(a.MaxSpeed7d__c),
            nLoad(a.Load7d__c)
        };
        dto.footnote =
            'Scores normalisés 0-100 (charge vs cap ' +
            LOAD_CAP.intValue() +
            ', vitesse vs ' +
            SPEED_CAP_KMH +
            ' km/h).';
        return dto;
    }

    private static Decimal nReadiness(Decimal v) {
        return clamp0to100(v == null ? 0 : v);
    }

    private static Decimal nHealth(Decimal injuryRisk) {
        if (injuryRisk == null) {
            return 50;
        }
        return clamp0to100(100 - injuryRisk);
    }

    private static Decimal nPercent(Decimal p) {
        if (p == null) {
            return 0;
        }
        return clamp0to100(p);
    }

    private static Decimal nSpeed(Decimal kmh) {
        if (kmh == null || kmh <= 0) {
            return 0;
        }
        return clamp0to100(kmh / SPEED_CAP_KMH * 100);
    }

    private static Decimal nLoad(Decimal load) {
        if (load == null || load <= 0) {
            return 0;
        }
        return clamp0to100(load / LOAD_CAP * 100);
    }

    private static Decimal clamp0to100(Decimal x) {
        if (x < 0) {
            return 0;
        }
        if (x > 100) {
            return 100;
        }
        return x.setScale(1);
    }
}
