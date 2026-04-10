@IsTest
private class SC360AthleteHomeControllerTest {
  @IsTest
  static void testGetAthleteHome_returnsPayload() {
    String fj =
      '{"loadSeries":[{"label":"J1","value":100},{"label":"J2","value":120}],' +
      '"zoneBars":[{"label":"Z1","value":10},{"label":"Z2","value":20}]}';
    Athlete__c a = new Athlete__c(
      Name = 'Home Test',
      Sport__c = 'Football',
      Status__c = 'Active',
      ReadinessScore__c = 72,
      InjuryRiskScore__c = 30,
      Acwr__c = 1.05,
      Load7d__c = 4200,
      MinutesMatch7d__c = 180,
      MinutesMatch28d__c = 400,
      Distance7d__c = 10.5,
      Hid15_7d__c = 500,
      Hid20_7d__c = 700,
      Sprints25_7d__c = 32,
      MaxSpeed7d__c = 34.1,
      Accel3_7d__c = 40,
      AthleteSummary__c = 'Résumé test',
      TopRisks__c = 'Risque test',
      FeaturesJson__c = fj
    );
    insert a;

    Test.startTest();
    SC360AthleteHomeController.HomePayloadDto dto = SC360AthleteHomeController.getAthleteHome(a.Id);
    Test.stopTest();

    System.assertNotEquals(null, dto);
    System.assertEquals('Home Test', dto.hero.athleteName);
    System.assertEquals(72, dto.hero.readinessTarget);
    System.assertEquals(6, dto.kpis.size());
    System.assertEquals(0, dto.microcycleDays.size());
    System.assertEquals(3, dto.matchStatRows.size());
    System.assertEquals(0, dto.videoClips.size());
    System.assertEquals(2, dto.loadSeries.size());
    System.assertEquals(2, dto.zoneSeries.size());
  }

  @IsTest
  static void testGetAthleteHome_zoneSeries_fromScalarsWhenNoJsonZones() {
    Athlete__c a = new Athlete__c(
      Name = 'Zones Scalar',
      Sport__c = 'Football',
      Status__c = 'Active',
      Distance7d__c = 8.5,
      Hid20_7d__c = 600,
      FeaturesJson__c = '{"loadSeries":[{"label":"J1","value":100}]}'
    );
    insert a;

    Test.startTest();
    SC360AthleteHomeController.HomePayloadDto dto = SC360AthleteHomeController.getAthleteHome(a.Id);
    Test.stopTest();

    System.assertEquals(1, dto.loadSeries.size());
    System.assert(dto.zoneSeries.size() >= 1);
  }

  @IsTest
  static void testGetAthleteHome_nullId_throws() {
    Boolean threw = false;
    try {
      SC360AthleteHomeController.getAthleteHome(null);
    } catch (AuraHandledException e) {
      threw = true;
    }
    System.assert(threw, 'AuraHandledException attendue');
  }
}
