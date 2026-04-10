public with sharing class SC360MatchIntelligenceController {
  public class OpponentHeaderDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String league;
    @AuraEnabled public String coach;
    @AuraEnabled public String preferredFormation;
    @AuraEnabled public String pressingStyle;
    @AuraEnabled public String buildUpStyle;
    @AuraEnabled public String setPieceThreat;
  }

  public class OpponentMatchRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Date matchDate;
    @AuraEnabled public String homeAway;
    @AuraEnabled public String competition;
    @AuraEnabled public String result;
    @AuraEnabled public Decimal goalsFor;
    @AuraEnabled public Decimal goalsAgainst;
    @AuraEnabled public Decimal xgFor;
    @AuraEnabled public Decimal xgAgainst;
    @AuraEnabled public Decimal possession;
    @AuraEnabled public Decimal ppda;
    @AuraEnabled public String lineupFormation;
  }

  public class TacticalPatternDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String patternType;
    @AuraEnabled public Decimal frequency;
    @AuraEnabled public Decimal confidence;
    @AuraEnabled public String evidenceMatchIds;
  }

  public class MatchPrepReportRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Id planningEventId;
    @AuraEnabled public String planningEventName;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public Datetime generatedAt;
    @AuraEnabled public String status;
    @AuraEnabled public Decimal confidenceScore;
    @AuraEnabled public String summary;
  }

  public class OpponentLineupRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String playerName;
    @AuraEnabled public String position;
    @AuraEnabled public Boolean starter;
    @AuraEnabled public Decimal minutes;
    @AuraEnabled public Decimal rating;
    @AuraEnabled public String threatTags;
  }

  public class OpponentHubDto {
    @AuraEnabled public OpponentHeaderDto header;
    @AuraEnabled public List<OpponentMatchRowDto> recentMatches;
    @AuraEnabled public List<TacticalPatternDto> tacticalPatterns;
    @AuraEnabled public List<MatchPrepReportRowDto> prepReports;
  }

  public class OpponentMatchDto {
    @AuraEnabled public OpponentMatchRowDto match;
    @AuraEnabled public OpponentHeaderDto opponent;
    @AuraEnabled public List<OpponentLineupRowDto> lineup;
    @AuraEnabled public String rawPayload;
  }

  public class MatchPrepReportDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String summary;
    @AuraEnabled public String strengths;
    @AuraEnabled public String weaknesses;
    @AuraEnabled public String keyPlayers;
    @AuraEnabled public String last5Form;
    @AuraEnabled public String recommendedPlan;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public Datetime generatedAt;
    @AuraEnabled public String status;
    @AuraEnabled public Boolean generatedByAI;
    @AuraEnabled public Decimal confidenceScore;
    @AuraEnabled public Id planningEventId;
    @AuraEnabled public String planningEventName;
    @AuraEnabled public OpponentHeaderDto opponent;
    @AuraEnabled public List<OpponentMatchRowDto> recentOpponentMatches;
  }

  @AuraEnabled(cacheable=true)
  public static OpponentHubDto getOpponentHub(Id opponentId) {
    if (opponentId == null) {
      throw new AuraHandledException('recordId opponent manquant.');
    }
    Opponent__c o = [
      SELECT
        Id,
        Name,
        League__c,
        Coach__c,
        PreferredFormation__c,
        PressingStyle__c,
        BuildUpStyle__c,
        SetPieceThreat__c
      FROM Opponent__c
      WHERE Id = :opponentId
      LIMIT 1
    ];

    OpponentHubDto out = new OpponentHubDto();
    out.header = toHeader(o);
    out.recentMatches = new List<OpponentMatchRowDto>();
    out.tacticalPatterns = new List<TacticalPatternDto>();
    out.prepReports = new List<MatchPrepReportRowDto>();

    for (OpponentMatch__c row : [
      SELECT
        Id,
        MatchDate__c,
        HomeAway__c,
        Competition__c,
        Result__c,
        GoalsFor__c,
        GoalsAgainst__c,
        xGFor__c,
        xGAgainst__c,
        Possession__c,
        PPDA__c,
        LineupFormation__c
      FROM OpponentMatch__c
      WHERE Opponent__c = :opponentId
      ORDER BY MatchDate__c DESC NULLS LAST
      LIMIT 10
    ]) {
      out.recentMatches.add(toMatchRow(row));
    }

    for (OpponentTacticalPattern__c row : [
      SELECT Id, PatternType__c, Frequency__c, Confidence__c, EvidenceMatchIds__c
      FROM OpponentTacticalPattern__c
      WHERE Opponent__c = :opponentId
      ORDER BY Confidence__c DESC NULLS LAST, Frequency__c DESC NULLS LAST
      LIMIT 12
    ]) {
      TacticalPatternDto dto = new TacticalPatternDto();
      dto.id = row.Id;
      dto.patternType = row.PatternType__c;
      dto.frequency = row.Frequency__c;
      dto.confidence = row.Confidence__c;
      dto.evidenceMatchIds = row.EvidenceMatchIds__c;
      out.tacticalPatterns.add(dto);
    }

    for (MatchPrepReport__c row : [
      SELECT
        Id,
        PlanningEvent__c,
        PlanningEvent__r.Name,
        RiskLevel__c,
        GeneratedAt__c,
        Status__c,
        ConfidenceScore__c,
        Summary__c
      FROM MatchPrepReport__c
      WHERE Opponent__c = :opponentId
      ORDER BY GeneratedAt__c DESC NULLS LAST, CreatedDate DESC
      LIMIT 10
    ]) {
      MatchPrepReportRowDto dto = new MatchPrepReportRowDto();
      dto.id = row.Id;
      dto.planningEventId = row.PlanningEvent__c;
      dto.planningEventName = row.PlanningEvent__r != null ? row.PlanningEvent__r.Name : null;
      dto.riskLevel = row.RiskLevel__c;
      dto.generatedAt = row.GeneratedAt__c;
      dto.status = row.Status__c;
      dto.confidenceScore = row.ConfidenceScore__c;
      dto.summary = row.Summary__c;
      out.prepReports.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static OpponentMatchDto getOpponentMatch(Id opponentMatchId) {
    if (opponentMatchId == null) {
      throw new AuraHandledException('recordId opponent match manquant.');
    }
    OpponentMatch__c m = [
      SELECT
        Id,
        Opponent__c,
        Opponent__r.Id,
        Opponent__r.Name,
        Opponent__r.League__c,
        Opponent__r.Coach__c,
        Opponent__r.PreferredFormation__c,
        Opponent__r.PressingStyle__c,
        Opponent__r.BuildUpStyle__c,
        Opponent__r.SetPieceThreat__c,
        MatchDate__c,
        HomeAway__c,
        Competition__c,
        Result__c,
        GoalsFor__c,
        GoalsAgainst__c,
        xGFor__c,
        xGAgainst__c,
        Possession__c,
        PPDA__c,
        LineupFormation__c,
        RawPayload__c
      FROM OpponentMatch__c
      WHERE Id = :opponentMatchId
      LIMIT 1
    ];

    OpponentMatchDto out = new OpponentMatchDto();
    out.match = toMatchRow(m);
    out.opponent = toHeader(m.Opponent__r);
    out.rawPayload = m.RawPayload__c;
    out.lineup = new List<OpponentLineupRowDto>();
    for (OpponentLineup__c row : [
      SELECT Id, PlayerName__c, Position__c, Starter__c, Minutes__c, Rating__c, ThreatTags__c
      FROM OpponentLineup__c
      WHERE OpponentMatch__c = :opponentMatchId
      ORDER BY Starter__c DESC, Minutes__c DESC NULLS LAST, Rating__c DESC NULLS LAST
    ]) {
      OpponentLineupRowDto dto = new OpponentLineupRowDto();
      dto.id = row.Id;
      dto.playerName = row.PlayerName__c;
      dto.position = row.Position__c;
      dto.starter = row.Starter__c;
      dto.minutes = row.Minutes__c;
      dto.rating = row.Rating__c;
      dto.threatTags = row.ThreatTags__c;
      out.lineup.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static MatchPrepReportDto getMatchPrepReport(Id reportId) {
    if (reportId == null) {
      throw new AuraHandledException('recordId match prep report manquant.');
    }
    MatchPrepReport__c r = [
      SELECT
        Id,
        PlanningEvent__c,
        PlanningEvent__r.Name,
        Opponent__c,
        Opponent__r.Id,
        Opponent__r.Name,
        Opponent__r.League__c,
        Opponent__r.Coach__c,
        Opponent__r.PreferredFormation__c,
        Opponent__r.PressingStyle__c,
        Opponent__r.BuildUpStyle__c,
        Opponent__r.SetPieceThreat__c,
        Summary__c,
        Strengths__c,
        Weaknesses__c,
        KeyPlayers__c,
        Last5Form__c,
        RecommendedPlan__c,
        RiskLevel__c,
        GeneratedAt__c,
        Status__c,
        GeneratedByAI__c,
        ConfidenceScore__c
      FROM MatchPrepReport__c
      WHERE Id = :reportId
      LIMIT 1
    ];

    MatchPrepReportDto out = new MatchPrepReportDto();
    out.id = r.Id;
    out.summary = r.Summary__c;
    out.strengths = r.Strengths__c;
    out.weaknesses = r.Weaknesses__c;
    out.keyPlayers = r.KeyPlayers__c;
    out.last5Form = r.Last5Form__c;
    out.recommendedPlan = r.RecommendedPlan__c;
    out.riskLevel = r.RiskLevel__c;
    out.generatedAt = r.GeneratedAt__c;
    out.status = r.Status__c;
    out.generatedByAI = r.GeneratedByAI__c;
    out.confidenceScore = r.ConfidenceScore__c;
    out.planningEventId = r.PlanningEvent__c;
    out.planningEventName = r.PlanningEvent__r != null ? r.PlanningEvent__r.Name : null;
    out.opponent = toHeader(r.Opponent__r);
    out.recentOpponentMatches = new List<OpponentMatchRowDto>();

    if (r.Opponent__c != null) {
      for (OpponentMatch__c m : [
        SELECT
          Id,
          MatchDate__c,
          HomeAway__c,
          Competition__c,
          Result__c,
          GoalsFor__c,
          GoalsAgainst__c,
          xGFor__c,
          xGAgainst__c,
          Possession__c,
          PPDA__c,
          LineupFormation__c
        FROM OpponentMatch__c
        WHERE Opponent__c = :r.Opponent__c
        ORDER BY MatchDate__c DESC NULLS LAST
        LIMIT 5
      ]) {
        out.recentOpponentMatches.add(toMatchRow(m));
      }
    }
    return out;
  }

  private static OpponentHeaderDto toHeader(Opponent__c o) {
    OpponentHeaderDto dto = new OpponentHeaderDto();
    dto.id = o != null ? o.Id : null;
    dto.name = o != null ? o.Name : null;
    dto.league = o != null ? o.League__c : null;
    dto.coach = o != null ? o.Coach__c : null;
    dto.preferredFormation = o != null ? o.PreferredFormation__c : null;
    dto.pressingStyle = o != null ? o.PressingStyle__c : null;
    dto.buildUpStyle = o != null ? o.BuildUpStyle__c : null;
    dto.setPieceThreat = o != null ? o.SetPieceThreat__c : null;
    return dto;
  }

  private static OpponentMatchRowDto toMatchRow(OpponentMatch__c m) {
    OpponentMatchRowDto dto = new OpponentMatchRowDto();
    dto.id = m.Id;
    dto.matchDate = m.MatchDate__c;
    dto.homeAway = m.HomeAway__c;
    dto.competition = m.Competition__c;
    dto.result = m.Result__c;
    dto.goalsFor = m.GoalsFor__c;
    dto.goalsAgainst = m.GoalsAgainst__c;
    dto.xgFor = m.xGFor__c;
    dto.xgAgainst = m.xGAgainst__c;
    dto.possession = m.Possession__c;
    dto.ppda = m.PPDA__c;
    dto.lineupFormation = m.LineupFormation__c;
    return dto;
  }
}
