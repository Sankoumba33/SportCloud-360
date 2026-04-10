@IsTest
private class SC360AthleteMedicalControllerTest {
  @IsTest
  static void testGetMedicalAthlete_withInjuryAndRtp() {
    Athlete__c a = new Athlete__c(
      Name = 'Med Full',
      Status__c = 'Injured',
      InjuryRiskScore__c = 50,
      ReadinessScore__c = 70,
      Acwr__c = 1.0,
      Load7d__c = 3000,
      MaxSpeed7d__c = 31,
      TopRisks__c = 'Risque test',
      TopStrengths__c = 'Force test'
    );
    insert a;

    Injury__c inj = new Injury__c(
      Athlete__c = a.Id,
      BodyZone__c = 'Genou droit (LCA)',
      InjuryDate__c = Date.today().addDays(-30),
      ExpectedReturnDate__c = Date.today().addDays(14),
      Status__c = 'Active',
      ClinicalSummary__c = 'Résumé clinique test.'
    );
    insert inj;

    insert new List<RTPPhase__c>{
      new RTPPhase__c(
        Injury__c = inj.Id,
        Title__c = 'Phase 1 : soins',
        Subtitle__c = 'OK staff',
        PhaseStatus__c = 'Completed',
        SortOrder__c = 1
      ),
      new RTPPhase__c(
        Injury__c = inj.Id,
        Title__c = 'Phase 2 : terrain',
        Subtitle__c = 'En cours',
        PhaseStatus__c = 'Current',
        SortOrder__c = 2
      )
    };

    Test.startTest();
    SC360AthleteMedicalController.MedicalPayloadDto dto = SC360AthleteMedicalController.getMedicalAthlete(a.Id);
    Test.stopTest();

    System.assertEquals('Med Full', dto.hero.athleteName);
    System.assertEquals(2, dto.rtpSteps.size());
    System.assertEquals('Genou droit (LCA)', dto.hero.zoneLabel);
    System.assert(dto.historyRows.size() >= 1);
  }

  @IsTest
  static void testGetMedicalAthlete_noInjury() {
    Athlete__c a = new Athlete__c(Name = 'Med Solo', Status__c = 'Active', InjuryRiskScore__c = 20);
    insert a;

    Test.startTest();
    SC360AthleteMedicalController.MedicalPayloadDto dto = SC360AthleteMedicalController.getMedicalAthlete(a.Id);
    Test.stopTest();

    System.assertEquals(4, dto.rtpSteps.size());
  }
}
