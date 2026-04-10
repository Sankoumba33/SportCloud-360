@IsTest
private class SC360MatchIntelligenceControllerTest {
  @IsTest
  static void testEndpoints() {
    Opponent__c opp = new Opponent__c(
      Name = 'US Test Opponent',
      League__c = 'National 2',
      Coach__c = 'Coach Test',
      PreferredFormation__c = '4-3-3',
      PressingStyle__c = 'Mid Block',
      BuildUpStyle__c = 'Mixed',
      SetPieceThreat__c = 'High'
    );
    insert opp;

    OpponentMatch__c om = new OpponentMatch__c(
      Opponent__c = opp.Id,
      MatchDate__c = Date.today().addDays(-3),
      HomeAway__c = 'Away',
      Competition__c = 'League',
      Result__c = 'Win',
      GoalsFor__c = 2,
      GoalsAgainst__c = 1,
      xGFor__c = 1.8,
      xGAgainst__c = 1.1,
      Possession__c = 54,
      PPDA__c = 8.7,
      LineupFormation__c = '4-3-3',
      RawPayload__c = '{"source":"test"}'
    );
    insert om;

    insert new OpponentLineup__c(
      OpponentMatch__c = om.Id,
      PlayerName__c = 'N. 9',
      Position__c = 'ST',
      Starter__c = true,
      Minutes__c = 90,
      Rating__c = 7.8,
      ThreatTags__c = 'set-piece,depth-run'
    );

    insert new OpponentTacticalPattern__c(
      Opponent__c = opp.Id,
      PatternType__c = 'Press',
      Frequency__c = 62,
      Confidence__c = 80,
      EvidenceMatchIds__c = String.valueOf(om.Id)
    );

    Squad__c sq = new Squad__c(Name = 'Test Squad');
    insert sq;
    PlanningEvent__c pe = new PlanningEvent__c(
      Name = 'Matchday Test',
      EventType__c = 'Match',
      StartDateTime__c = System.now().addDays(2),
      EndDateTime__c = System.now().addDays(2).addHours(2),
      Status__c = 'Planned',
      Squad__c = sq.Id
    );
    insert pe;

    MatchPrepReport__c report = new MatchPrepReport__c(
      PlanningEvent__c = pe.Id,
      Opponent__c = opp.Id,
      Summary__c = 'Summary',
      Strengths__c = 'Strengths',
      Weaknesses__c = 'Weaknesses',
      KeyPlayers__c = 'Key players',
      Last5Form__c = 'W-D-W-L-W',
      RecommendedPlan__c = 'Plan',
      RiskLevel__c = 'Medium',
      GeneratedAt__c = System.now(),
      Status__c = 'Draft',
      GeneratedByAI__c = true,
      ConfidenceScore__c = 76
    );
    insert report;

    Test.startTest();
    SC360MatchIntelligenceController.OpponentHubDto hub = SC360MatchIntelligenceController.getOpponentHub(opp.Id);
    SC360MatchIntelligenceController.OpponentMatchDto matchDto = SC360MatchIntelligenceController.getOpponentMatch(om.Id);
    SC360MatchIntelligenceController.MatchPrepReportDto prepDto = SC360MatchIntelligenceController.getMatchPrepReport(report.Id);
    Test.stopTest();

    System.assertEquals(opp.Id, hub.header.id);
    System.assertEquals(1, hub.recentMatches.size());
    System.assertEquals(1, hub.tacticalPatterns.size());
    System.assertEquals(1, hub.prepReports.size());

    System.assertEquals(om.Id, matchDto.match.id);
    System.assertEquals(1, matchDto.lineup.size());

    System.assertEquals(report.Id, prepDto.id);
    System.assertEquals(opp.Id, prepDto.opponent.id);
    System.assertEquals(1, prepDto.recentOpponentMatches.size());
  }
}
