@IsTest
private class SC360AthleteRadarControllerTest {
    @IsTest
    static void testRadar() {
        Athlete__c ath = new Athlete__c(
            Name = 'Radar Test',
            ReadinessScore__c = 80,
            InjuryRiskScore__c = 20,
            PassAccuracy5__c = 85,
            DuelWinPct5__c = 60,
            MaxSpeed7d__c = 34,
            Load7d__c = 2500
        );
        insert ath;

        Test.startTest();
        SC360AthleteRadarController.RadarDto dto = SC360AthleteRadarController.getRadar(ath.Id);
        Test.stopTest();

        System.assertEquals('Radar Test', dto.athleteName);
        System.assertEquals(6, dto.axisLabels.size());
        System.assertEquals(6, dto.values.size());
        System.assertEquals(80, dto.values[0]);
        System.assertEquals(80, dto.values[1]);
        System.assertEquals(85, dto.values[2]);
        System.assertEquals(60, dto.values[3]);
    }

    @IsTest
    static void testRadar_nullId() {
        System.assertEquals(null, SC360AthleteRadarController.getRadar(null));
    }
}
