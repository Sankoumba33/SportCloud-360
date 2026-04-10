@IsTest
private class SC360RelationTabsControllerTest {
  @IsTest
  static void testRelationsEndpoints() {
    Athlete__c athlete = new Athlete__c(Name = 'Ath Test', Status__c = 'Active');
    insert athlete;

    Injury__c injury = new Injury__c(
      Athlete__c = athlete.Id,
      BodyZone__c = 'Ischio',
      Status__c = 'Active',
      InjuryDate__c = Date.today().addDays(-7),
      ExpectedReturnDate__c = Date.today().addDays(14)
    );
    insert injury;

    RTPPhase__c phase = new RTPPhase__c(
      Injury__c = injury.Id,
      Title__c = 'Phase 1',
      PhaseStatus__c = 'Current',
      SortOrder__c = 1
    );
    insert phase;

    Microcycle__c micro = new Microcycle__c(Name = 'Week 1', Status__c = 'Draft');
    insert micro;

    MicrocycleDay__c day = new MicrocycleDay__c(
      Name = 'D1',
      Microcycle__c = micro.Id,
      DayDate__c = Date.today(),
      Phase__c = 'MD_Minus_2'
    );
    insert day;

    AthleteMicrocycleDay__c link = new AthleteMicrocycleDay__c(
      Athlete__c = athlete.Id,
      MicrocycleDay__c = day.Id,
      PlannedLoad__c = 3000,
      ActualLoad__c = 2800
    );
    insert link;

    Prospect__c prospect = new Prospect__c(Name = 'Prospect Test', Status__c = 'New');
    insert prospect;

    ScoutingReport__c report = new ScoutingReport__c(
      Prospect__c = prospect.Id,
      StepType__c = 'Video Scouting',
      ReportDate__c = Date.today(),
      Summary__c = 'Summary'
    );
    insert report;

    ScoutingSnapshot__c snapshot = new ScoutingSnapshot__c(
      Prospect__c = prospect.Id,
      SnapshotDateTime__c = System.now(),
      ScoutingScore__c = 70,
      PotentialScore__c = 75,
      FitScore__c = 68,
      RiskScore__c = 35
    );
    insert snapshot;

    Squad__c squad = new Squad__c(Name = 'N2 Test');
    insert squad;

    athlete.CurrentSquad__c = squad.Id;
    update athlete;

    SquadAssignment__c assignment = new SquadAssignment__c(
      Athlete__c = athlete.Id,
      Squad__c = squad.Id,
      StartDate__c = Date.today().addDays(-30),
      Reason__c = 'Test'
    );
    insert assignment;

    PlanningEvent__c pe = new PlanningEvent__c(
      Name = 'Session Test',
      Squad__c = squad.Id,
      EventType__c = 'Training',
      StartDateTime__c = System.now().addDays(1),
      EndDateTime__c = System.now().addDays(1).addHours(2),
      Status__c = 'Planned'
    );
    insert pe;

    Test.startTest();
    SC360RelationTabsController.AthleteLinksDto athleteLinks = SC360RelationTabsController.getAthleteLinks(athlete.Id);
    SC360RelationTabsController.InjuryLinksDto injuryLinks = SC360RelationTabsController.getInjuryLinks(injury.Id);
    SC360RelationTabsController.ProspectLinksDto prospectLinks = SC360RelationTabsController.getProspectLinks(prospect.Id);
    SC360RelationTabsController.MicrocycleLinksDto microLinks = SC360RelationTabsController.getMicrocycleLinks(micro.Id);
    SC360RelationTabsController.MicrocycleDayLinksDto dayLinks = SC360RelationTabsController.getMicrocycleDayLinks(day.Id);
    SC360RelationTabsController.RtpPhaseContextDto phaseContext = SC360RelationTabsController.getRtpPhaseContext(phase.Id);
    SC360RelationTabsController.SquadLinksDto squadLinks = SC360RelationTabsController.getSquadLinks(squad.Id);
    Test.stopTest();

    System.assertEquals(1, athleteLinks.injuries.size());
    System.assertEquals(1, athleteLinks.microcycleLinks.size());
    System.assertEquals(athlete.Id, injuryLinks.athleteId);
    System.assertEquals(1, injuryLinks.rtpPhases.size());
    System.assertEquals(1, prospectLinks.reports.size());
    System.assertEquals(1, prospectLinks.snapshots.size());
    System.assertEquals(1, microLinks.days.size());
    System.assertEquals(1, dayLinks.athleteLinks.size());
    System.assertEquals(injury.Id, phaseContext.injuryId);
    System.assertEquals(1, squadLinks.assignments.size());
    System.assertEquals(1, squadLinks.planningEvents.size());
    System.assertEquals(1, squadLinks.athletes.size());
  }
}
