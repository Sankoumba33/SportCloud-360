public with sharing class SC360RelationTabsController {
  public class InjuryRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String bodyZone;
    @AuraEnabled public String status;
    @AuraEnabled public Date injuryDate;
    @AuraEnabled public Date expectedReturnDate;
  }

  public class AthleteMicrocycleLinkRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String dayLabel;
    @AuraEnabled public String phase;
    @AuraEnabled public Decimal plannedLoad;
    @AuraEnabled public Decimal actualLoad;
  }

  public class AthleteLinksDto {
    @AuraEnabled public List<InjuryRowDto> injuries;
    @AuraEnabled public List<AthleteMicrocycleLinkRowDto> microcycleLinks;
  }

  public class RtpPhaseRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String title;
    @AuraEnabled public String phaseStatus;
    @AuraEnabled public Date targetDate;
  }

  public class InjuryLinksDto {
    @AuraEnabled public Id athleteId;
    @AuraEnabled public String athleteName;
    @AuraEnabled public List<RtpPhaseRowDto> rtpPhases;
  }

  public class ScoutingReportRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String stepType;
    @AuraEnabled public Date reportDate;
    @AuraEnabled public Decimal rating;
    @AuraEnabled public String summary;
  }

  public class ScoutingSnapshotRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Datetime snapshotDateTime;
    @AuraEnabled public Decimal scoutingScore;
    @AuraEnabled public Decimal potentialScore;
    @AuraEnabled public Decimal fitScore;
    @AuraEnabled public Decimal riskScore;
  }

  public class ProspectLinksDto {
    @AuraEnabled public List<ScoutingReportRowDto> reports;
    @AuraEnabled public List<ScoutingSnapshotRowDto> snapshots;
  }

  public class MicrocycleDayRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Date dayDate;
    @AuraEnabled public String phase;
    @AuraEnabled public String physicalFocus;
    @AuraEnabled public String targetIntensity;
  }

  public class MicrocycleLinksDto {
    @AuraEnabled public List<MicrocycleDayRowDto> days;
  }

  public class MicrocycleDayAthleteRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Id athleteId;
    @AuraEnabled public String athleteName;
    @AuraEnabled public Decimal plannedLoad;
    @AuraEnabled public Decimal actualLoad;
  }

  public class MicrocycleDayLinksDto {
    @AuraEnabled public Id planningEventId;
    @AuraEnabled public String planningEventName;
    @AuraEnabled public List<MicrocycleDayAthleteRowDto> athleteLinks;
  }

  public class RtpPhaseContextDto {
    @AuraEnabled public Id injuryId;
    @AuraEnabled public String injuryName;
    @AuraEnabled public Id athleteId;
    @AuraEnabled public String athleteName;
  }

  public class SquadAssignmentRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public Id athleteId;
    @AuraEnabled public String athleteName;
    @AuraEnabled public Date startDate;
    @AuraEnabled public Date endDate;
    @AuraEnabled public String reason;
  }

  public class SquadPlanningEventRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String eventType;
    @AuraEnabled public Datetime startDateTime;
    @AuraEnabled public Datetime endDateTime;
    @AuraEnabled public String status;
  }

  public class SquadAthleteRowDto {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String status;
    @AuraEnabled public String sport;
  }

  public class SquadLinksDto {
    @AuraEnabled public List<SquadAssignmentRowDto> assignments;
    @AuraEnabled public List<SquadPlanningEventRowDto> planningEvents;
    @AuraEnabled public List<SquadAthleteRowDto> athletes;
  }

  @AuraEnabled(cacheable=true)
  public static AthleteLinksDto getAthleteLinks(Id athleteId) {
    if (athleteId == null) {
      throw new AuraHandledException('recordId athlete manquant.');
    }
    AthleteLinksDto out = new AthleteLinksDto();
    out.injuries = new List<InjuryRowDto>();
    out.microcycleLinks = new List<AthleteMicrocycleLinkRowDto>();

    for (Injury__c row : [
      SELECT Id, BodyZone__c, Status__c, InjuryDate__c, ExpectedReturnDate__c
      FROM Injury__c
      WHERE Athlete__c = :athleteId
      ORDER BY InjuryDate__c DESC NULLS LAST, CreatedDate DESC
    ]) {
      InjuryRowDto dto = new InjuryRowDto();
      dto.id = row.Id;
      dto.bodyZone = row.BodyZone__c;
      dto.status = row.Status__c;
      dto.injuryDate = row.InjuryDate__c;
      dto.expectedReturnDate = row.ExpectedReturnDate__c;
      out.injuries.add(dto);
    }

    for (AthleteMicrocycleDay__c row : [
      SELECT
        Id,
        PlannedLoad__c,
        ActualLoad__c,
        MicrocycleDay__r.DayDate__c,
        MicrocycleDay__r.Phase__c
      FROM AthleteMicrocycleDay__c
      WHERE Athlete__c = :athleteId
      ORDER BY MicrocycleDay__r.DayDate__c DESC NULLS LAST, CreatedDate DESC
      LIMIT 120
    ]) {
      AthleteMicrocycleLinkRowDto dto = new AthleteMicrocycleLinkRowDto();
      dto.id = row.Id;
      dto.dayLabel = row.MicrocycleDay__r != null && row.MicrocycleDay__r.DayDate__c != null
        ? row.MicrocycleDay__r.DayDate__c.format()
        : '—';
      dto.phase = row.MicrocycleDay__r != null ? row.MicrocycleDay__r.Phase__c : null;
      dto.plannedLoad = row.PlannedLoad__c;
      dto.actualLoad = row.ActualLoad__c;
      out.microcycleLinks.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static InjuryLinksDto getInjuryLinks(Id injuryId) {
    if (injuryId == null) {
      throw new AuraHandledException('recordId injury manquant.');
    }
    Injury__c injury = [
      SELECT Id, Athlete__c, Athlete__r.Name
      FROM Injury__c
      WHERE Id = :injuryId
      LIMIT 1
    ];
    InjuryLinksDto out = new InjuryLinksDto();
    out.athleteId = injury.Athlete__c;
    out.athleteName = injury.Athlete__r != null ? injury.Athlete__r.Name : null;
    out.rtpPhases = new List<RtpPhaseRowDto>();
    for (RTPPhase__c row : [
      SELECT Id, Title__c, PhaseStatus__c, TargetDate__c
      FROM RTPPhase__c
      WHERE Injury__c = :injuryId
      ORDER BY SortOrder__c ASC NULLS LAST, CreatedDate ASC
    ]) {
      RtpPhaseRowDto dto = new RtpPhaseRowDto();
      dto.id = row.Id;
      dto.title = row.Title__c;
      dto.phaseStatus = row.PhaseStatus__c;
      dto.targetDate = row.TargetDate__c;
      out.rtpPhases.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static ProspectLinksDto getProspectLinks(Id prospectId) {
    if (prospectId == null) {
      throw new AuraHandledException('recordId prospect manquant.');
    }
    ProspectLinksDto out = new ProspectLinksDto();
    out.reports = new List<ScoutingReportRowDto>();
    out.snapshots = new List<ScoutingSnapshotRowDto>();

    for (ScoutingReport__c row : [
      SELECT Id, StepType__c, ReportDate__c, Rating__c, Summary__c
      FROM ScoutingReport__c
      WHERE Prospect__c = :prospectId
      ORDER BY ReportDate__c DESC NULLS LAST, LastModifiedDate DESC
    ]) {
      ScoutingReportRowDto dto = new ScoutingReportRowDto();
      dto.id = row.Id;
      dto.stepType = row.StepType__c;
      dto.reportDate = row.ReportDate__c;
      dto.rating = row.Rating__c;
      dto.summary = row.Summary__c;
      out.reports.add(dto);
    }

    for (ScoutingSnapshot__c row : [
      SELECT
        Id,
        SnapshotDateTime__c,
        ScoutingScore__c,
        PotentialScore__c,
        FitScore__c,
        RiskScore__c
      FROM ScoutingSnapshot__c
      WHERE Prospect__c = :prospectId
      ORDER BY SnapshotDateTime__c DESC
    ]) {
      ScoutingSnapshotRowDto dto = new ScoutingSnapshotRowDto();
      dto.id = row.Id;
      dto.snapshotDateTime = row.SnapshotDateTime__c;
      dto.scoutingScore = row.ScoutingScore__c;
      dto.potentialScore = row.PotentialScore__c;
      dto.fitScore = row.FitScore__c;
      dto.riskScore = row.RiskScore__c;
      out.snapshots.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static MicrocycleLinksDto getMicrocycleLinks(Id microcycleId) {
    if (microcycleId == null) {
      throw new AuraHandledException('recordId microcycle manquant.');
    }
    MicrocycleLinksDto out = new MicrocycleLinksDto();
    out.days = new List<MicrocycleDayRowDto>();
    for (MicrocycleDay__c row : [
      SELECT Id, DayDate__c, Phase__c, PhysicalFocus__c, TargetIntensity__c
      FROM MicrocycleDay__c
      WHERE Microcycle__c = :microcycleId
      ORDER BY DayDate__c ASC NULLS LAST, SortOrder__c ASC NULLS LAST
    ]) {
      MicrocycleDayRowDto dto = new MicrocycleDayRowDto();
      dto.id = row.Id;
      dto.dayDate = row.DayDate__c;
      dto.phase = row.Phase__c;
      dto.physicalFocus = row.PhysicalFocus__c;
      dto.targetIntensity = row.TargetIntensity__c;
      out.days.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static MicrocycleDayLinksDto getMicrocycleDayLinks(Id microcycleDayId) {
    if (microcycleDayId == null) {
      throw new AuraHandledException('recordId microcycle day manquant.');
    }
    MicrocycleDay__c day = [
      SELECT Id, PlanningEvent__c, PlanningEvent__r.Name
      FROM MicrocycleDay__c
      WHERE Id = :microcycleDayId
      LIMIT 1
    ];
    MicrocycleDayLinksDto out = new MicrocycleDayLinksDto();
    out.planningEventId = day.PlanningEvent__c;
    out.planningEventName = day.PlanningEvent__r != null ? day.PlanningEvent__r.Name : null;
    out.athleteLinks = new List<MicrocycleDayAthleteRowDto>();
    for (AthleteMicrocycleDay__c row : [
      SELECT Id, Athlete__c, Athlete__r.Name, PlannedLoad__c, ActualLoad__c
      FROM AthleteMicrocycleDay__c
      WHERE MicrocycleDay__c = :microcycleDayId
      ORDER BY Athlete__r.Name ASC NULLS LAST, CreatedDate DESC
    ]) {
      MicrocycleDayAthleteRowDto dto = new MicrocycleDayAthleteRowDto();
      dto.id = row.Id;
      dto.athleteId = row.Athlete__c;
      dto.athleteName = row.Athlete__r != null ? row.Athlete__r.Name : null;
      dto.plannedLoad = row.PlannedLoad__c;
      dto.actualLoad = row.ActualLoad__c;
      out.athleteLinks.add(dto);
    }
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static RtpPhaseContextDto getRtpPhaseContext(Id rtpPhaseId) {
    if (rtpPhaseId == null) {
      throw new AuraHandledException('recordId RTP phase manquant.');
    }
    RTPPhase__c phase = [
      SELECT Id, Injury__c, Injury__r.Name, Injury__r.Athlete__c, Injury__r.Athlete__r.Name
      FROM RTPPhase__c
      WHERE Id = :rtpPhaseId
      LIMIT 1
    ];
    RtpPhaseContextDto out = new RtpPhaseContextDto();
    out.injuryId = phase.Injury__c;
    out.injuryName = phase.Injury__r != null ? phase.Injury__r.Name : null;
    out.athleteId = phase.Injury__r != null ? phase.Injury__r.Athlete__c : null;
    out.athleteName = phase.Injury__r != null && phase.Injury__r.Athlete__r != null
      ? phase.Injury__r.Athlete__r.Name
      : null;
    return out;
  }

  @AuraEnabled(cacheable=true)
  public static SquadLinksDto getSquadLinks(Id squadId) {
    if (squadId == null) {
      throw new AuraHandledException('recordId squad manquant.');
    }

    SquadLinksDto out = new SquadLinksDto();
    out.assignments = new List<SquadAssignmentRowDto>();
    out.planningEvents = new List<SquadPlanningEventRowDto>();
    out.athletes = new List<SquadAthleteRowDto>();

    for (SquadAssignment__c row : [
      SELECT Id, Athlete__c, Athlete__r.Name, StartDate__c, EndDate__c, Reason__c
      FROM SquadAssignment__c
      WHERE Squad__c = :squadId
      ORDER BY StartDate__c DESC NULLS LAST, CreatedDate DESC
    ]) {
      SquadAssignmentRowDto dto = new SquadAssignmentRowDto();
      dto.id = row.Id;
      dto.athleteId = row.Athlete__c;
      dto.athleteName = row.Athlete__r != null ? row.Athlete__r.Name : null;
      dto.startDate = row.StartDate__c;
      dto.endDate = row.EndDate__c;
      dto.reason = row.Reason__c;
      out.assignments.add(dto);
    }

    for (PlanningEvent__c row : [
      SELECT Id, Name, EventType__c, StartDateTime__c, EndDateTime__c, Status__c
      FROM PlanningEvent__c
      WHERE Squad__c = :squadId
      ORDER BY StartDateTime__c DESC NULLS LAST, CreatedDate DESC
    ]) {
      SquadPlanningEventRowDto dto = new SquadPlanningEventRowDto();
      dto.id = row.Id;
      dto.name = row.Name;
      dto.eventType = row.EventType__c;
      dto.startDateTime = row.StartDateTime__c;
      dto.endDateTime = row.EndDateTime__c;
      dto.status = row.Status__c;
      out.planningEvents.add(dto);
    }

    for (Athlete__c row : [
      SELECT Id, Name, Status__c, Sport__c
      FROM Athlete__c
      WHERE CurrentSquad__c = :squadId
      ORDER BY Name ASC
    ]) {
      SquadAthleteRowDto dto = new SquadAthleteRowDto();
      dto.id = row.Id;
      dto.name = row.Name;
      dto.status = row.Status__c;
      dto.sport = row.Sport__c;
      out.athletes.add(dto);
    }

    return out;
  }
}
