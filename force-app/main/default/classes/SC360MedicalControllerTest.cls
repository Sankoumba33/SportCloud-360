@IsTest
private class SC360MedicalControllerTest {
  @IsTest
  static void testGetOverview() {
    Athlete__c a = new Athlete__c(
      Name = 'Med Test',
      Status__c = 'Active',
      ReadinessScore__c = 70,
      InjuryRiskScore__c = 40
    );
    insert a;

    Test.startTest();
    SC360MedicalController.OverviewDto dto = SC360MedicalController.getOverview();
    Test.stopTest();

    System.assertNotEquals(null, dto);
    System.assert(dto.kpis.size() > 0);
  }

  @IsTest
  static void testGetHighRiskAthletes() {
    insert new Athlete__c(
      Name = 'High Risk',
      Status__c = 'Active',
      InjuryRiskScore__c = 80,
      ReadinessScore__c = 55
    );

    Test.startTest();
    List<SC360MedicalController.AthleteRiskRowDto> rows = SC360MedicalController.getHighRiskAthletes(10);
    Test.stopTest();

    System.assertEquals(1, rows.size());
    System.assertEquals('High Risk', rows[0].name);
    System.assertEquals(80, rows[0].injuryRisk);
  }
}
