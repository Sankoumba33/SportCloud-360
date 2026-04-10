public with sharing class SC360AthleteMedicalController {
  public class HeroDto {
    @AuraEnabled public String athleteName;
    @AuraEnabled public String statusLine;
    @AuraEnabled public String statusLineClass;
    @AuraEnabled public Integer riskGaugeValue;
    @AuraEnabled public String riskGaugeClass;
    @AuraEnabled public String zoneLabel;
    @AuraEnabled public String injuryDateLabel;
    @AuraEnabled public String returnCompetitionLabel;
  }

  public class StripKpiDto {
    @AuraEnabled public String id;
    @AuraEnabled public String valueMain;
    @AuraEnabled public String valueUnit;
    @AuraEnabled public String title;
    @AuraEnabled public String valClass;
    @AuraEnabled public String cardClass;
  }

  public class RtpStepDto {
    @AuraEnabled public String id;
    @AuraEnabled public String title;
    @AuraEnabled public String subtitle;
    @AuraEnabled public String stateKey;
  }

  public class TaskRowDto {
    @AuraEnabled public String id;
    @AuraEnabled public String taskName;
    @AuraEnabled public String badgeLabel;
    @AuraEnabled public String badgeClass;
  }

  public class LoadBarDto {
    @AuraEnabled public String id;
    @AuraEnabled public String weekLabel;
    @AuraEnabled public Integer heightPct;
    @AuraEnabled public Boolean warning;
  }

  public class StaffNoteDto {
    @AuraEnabled public String id;
    @AuraEnabled public String channel;
    @AuraEnabled public String author;
    @AuraEnabled public String dateLabel;
    @AuraEnabled public String body;
  }

  public class HistoryRowDto {
    @AuraEnabled public String id;
    @AuraEnabled public String eventPeriod;
    @AuraEnabled public String injuryLabel;
    @AuraEnabled public String durationLabel;
    @AuraEnabled public String recurrenceLabel;
    @AuraEnabled public Boolean activeRow;
  }

  public class AiRecDto {
    @AuraEnabled public String id;
    @AuraEnabled public String tone;
    @AuraEnabled public String title;
    @AuraEnabled public String body;
  }

  public class PredictionLineDto {
    @AuraEnabled public String id;
    @AuraEnabled public String lineHtml;
  }

  public class MedicalPayloadDto {
    @AuraEnabled public HeroDto hero;
    @AuraEnabled public List<StripKpiDto> stripKpis;
    @AuraEnabled public List<RtpStepDto> rtpSteps;
    @AuraEnabled public List<TaskRowDto> tasks;
    @AuraEnabled public List<LoadBarDto> loadBars;
    @AuraEnabled public List<StaffNoteDto> staffNotes;
    @AuraEnabled public List<HistoryRowDto> historyRows;
    @AuraEnabled public List<AiRecDto> aiRecommendations;
    @AuraEnabled public List<PredictionLineDto> predictions;
  }

  @AuraEnabled(cacheable=true)
  public static MedicalPayloadDto getMedicalAthlete(Id recordId) {
    if (recordId == null) {
      throw new AuraHandledException('recordId manquant.');
    }

    Athlete__c a = [
      SELECT
        Name,
        Status__c,
        InjuryRiskScore__c,
        ReadinessScore__c,
        Acwr__c,
        Load7d__c,
        MaxSpeed7d__c,
        TopRisks__c,
        TopStrengths__c,
        AthleteSummary__c,
        LastInjuryAlertAt__c,
        LastDataCloudSync__c
      FROM Athlete__c
      WHERE Id = :recordId
      LIMIT 1
    ];

    List<Injury__c> injuries = [
      SELECT
        Id,
        BodyZone__c,
        InjuryDate__c,
        ExpectedReturnDate__c,
        ActualReturnDate__c,
        Status__c,
        RecurrenceNote__c,
        ClinicalSummary__c
      FROM Injury__c
      WHERE Athlete__c = :recordId
      ORDER BY InjuryDate__c DESC NULLS LAST, CreatedDate DESC
    ];

    Injury__c heroInjury = pickHeroInjury(injuries);

    List<RTPPhase__c> rtpPhases = new List<RTPPhase__c>();
    if (heroInjury != null) {
      rtpPhases = [
        SELECT Id, Title__c, Subtitle__c, PhaseStatus__c, SortOrder__c, TargetDate__c, Notes__c
        FROM RTPPhase__c
        WHERE Injury__c = :heroInjury.Id
        ORDER BY SortOrder__c ASC NULLS LAST, CreatedDate ASC
      ];
    }

    MedicalPayloadDto out = new MedicalPayloadDto();
    out.hero = buildHero(a, heroInjury);
    out.stripKpis = buildStrip(a);
    out.rtpSteps = buildRtp(a, rtpPhases);
    out.tasks = buildTasks(a);
    out.loadBars = buildLoadBars(a);
    out.staffNotes = buildStaffNotes(a, heroInjury);
    out.historyRows = buildHistory(injuries, a);
    out.aiRecommendations = buildAiRecs(a);
    out.predictions = buildPredictions(a, heroInjury);
    return out;
  }

  private static Injury__c pickHeroInjury(List<Injury__c> injuries) {
    if (injuries == null || injuries.isEmpty()) {
      return null;
    }
    for (Injury__c inj : injuries) {
      if (inj.Status__c == 'Active') {
        return inj;
      }
    }
    return injuries[0];
  }

  private static HeroDto buildHero(Athlete__c a, Injury__c inj) {
    HeroDto h = new HeroDto();
    h.athleteName = a.Name;
    if (a.Status__c == 'Injured') {
      h.statusLine = 'En phase de reprise';
      h.statusLineClass = 'status-medical warning-mode';
    } else if (a.Status__c == 'Unavailable') {
      h.statusLine = 'Indisponible';
      h.statusLineClass = 'status-medical warning-mode';
    } else {
      h.statusLine = 'Disponible';
      h.statusLineClass = 'status-medical ok-mode';
    }
    Integer risk = a.InjuryRiskScore__c == null ? 0 : Integer.valueOf(a.InjuryRiskScore__c.round());
    if (risk > 100) {
      risk = 100;
    }
    if (risk < 0) {
      risk = 0;
    }
    h.riskGaugeValue = risk;
    if (risk >= 70) {
      h.riskGaugeClass = 'risk-gauge danger-glow';
    } else if (risk >= 45) {
      h.riskGaugeClass = 'risk-gauge warning-glow';
    } else {
      h.riskGaugeClass = 'risk-gauge success-glow';
    }

    if (inj != null && !String.isBlank(inj.BodyZone__c)) {
      h.zoneLabel = inj.BodyZone__c;
    } else {
      h.zoneLabel = String.isBlank(a.TopRisks__c) ? '— (renseigner blessure ou Top Risks)' : a.TopRisks__c.left(120);
    }

    if (inj != null && inj.InjuryDate__c != null) {
      h.injuryDateLabel = inj.InjuryDate__c.format();
    } else {
      h.injuryDateLabel = a.LastInjuryAlertAt__c != null ? a.LastInjuryAlertAt__c.format('dd/MM/yyyy') : '—';
    }

    if (inj != null && inj.ExpectedReturnDate__c != null) {
      h.returnCompetitionLabel = 'Prévu: ' + inj.ExpectedReturnDate__c.format();
    } else if (inj != null && inj.ActualReturnDate__c != null) {
      h.returnCompetitionLabel = 'Effectif: ' + inj.ActualReturnDate__c.format();
    } else {
      h.returnCompetitionLabel = a.Status__c == 'Injured' ? 'À planifier (staff médical)' : 'N/A';
    }
    return h;
  }

  private static List<StripKpiDto> buildStrip(Athlete__c a) {
    List<StripKpiDto> rows = new List<StripKpiDto>();
    rows.add(
      strip(
        'sk1',
        a.ReadinessScore__c != null ? String.valueOf(a.ReadinessScore__c.setScale(0)) : '—',
        '',
        'Readiness',
        'text-pure',
        ''
      )
    );
    rows.add(
      strip(
        'sk2',
        fmtAcwr(a.Acwr__c),
        '',
        'Ratio ACWR',
        acwrClass(a.Acwr__c),
        ''
      )
    );
    rows.add(
      strip(
        'sk3',
        fmtLoadK(a.Load7d__c),
        'k',
        'Charge 7j',
        'text-pure',
        ''
      )
    );
    rows.add(
      strip(
        'sk4',
        a.MaxSpeed7d__c != null ? String.valueOf(a.MaxSpeed7d__c.setScale(1)) : '—',
        'km/h',
        'Vitesse max récente',
        'text-warning',
        ''
      )
    );
    String riskWord = riskWord(a.InjuryRiskScore__c);
    rows.add(
      strip(
        'sk5',
        riskWord,
        '',
        'Niveau risque global',
        riskWordClass(a.InjuryRiskScore__c),
        'border-warning'
      )
    );
    return rows;
  }

  private static String fmtAcwr(Decimal v) {
    if (v == null) {
      return '—';
    }
    return String.valueOf(v.setScale(2));
  }

  private static String fmtLoadK(Decimal load) {
    if (load == null) {
      return '—';
    }
    return String.valueOf((load / 1000.0).setScale(1, System.RoundingMode.HALF_UP));
  }

  private static String acwrClass(Decimal v) {
    if (v == null) {
      return 'text-pure';
    }
    if (v > 1.15) {
      return 'text-warning';
    }
    return 'text-success';
  }

  private static String riskWord(Decimal r) {
    if (r == null) {
      return '—';
    }
    if (r >= 70) {
      return 'Élevé';
    }
    if (r >= 45) {
      return 'Modéré';
    }
    return 'Faible';
  }

  private static String riskWordClass(Decimal r) {
    if (r == null) {
      return 'text-pure';
    }
    if (r >= 70) {
      return 'text-danger';
    }
    if (r >= 45) {
      return 'text-warning';
    }
    return 'text-success';
  }

  private static StripKpiDto strip(
    String id,
    String main,
    String unit,
    String title,
    String valCls,
    String cardCls
  ) {
    StripKpiDto s = new StripKpiDto();
    s.id = id;
    s.valueMain = main;
    s.valueUnit = unit;
    s.title = title;
    s.valClass = valCls;
    s.cardClass = String.isBlank(cardCls) ? 'kpi-card' : 'kpi-card ' + cardCls;
    return s;
  }

  private static List<RtpStepDto> buildRtp(Athlete__c a, List<RTPPhase__c> phases) {
    if (phases != null && !phases.isEmpty()) {
      List<RtpStepDto> steps = new List<RtpStepDto>();
      for (RTPPhase__c p : phases) {
        steps.add(rtpFromPhase(p));
      }
      return steps;
    }
    return buildRtpFallback(a);
  }

  private static RtpStepDto rtpFromPhase(RTPPhase__c p) {
    RtpStepDto r = new RtpStepDto();
    r.id = String.valueOf(p.Id);
    r.title = p.Title__c;
    r.subtitle = buildPhaseSubtitle(p);
    r.stateKey = mapPhaseStatus(p.PhaseStatus__c);
    return r;
  }

  private static String buildPhaseSubtitle(RTPPhase__c p) {
    List<String> parts = new List<String>();
    if (p.TargetDate__c != null) {
      parts.add('Cible ' + p.TargetDate__c.format());
    }
    if (!String.isBlank(p.Subtitle__c)) {
      parts.add(p.Subtitle__c);
    }
    if (String.isBlank(p.Notes__c) == false) {
      parts.add(p.Notes__c.left(80));
    }
    return parts.isEmpty() ? '—' : String.join(parts, ' · ');
  }

  private static String mapPhaseStatus(String phaseStatus) {
    if (phaseStatus == 'Completed') {
      return 'completed';
    }
    if (phaseStatus == 'Current') {
      return 'current';
    }
    return 'future';
  }

  private static List<RtpStepDto> buildRtpFallback(Athlete__c a) {
    List<RtpStepDto> steps = new List<RtpStepDto>();
    Boolean injured = a.Status__c == 'Injured' || a.Status__c == 'Unavailable';
    steps.add(rtp('r1', 'Phase 1 : soins & mobilité', 'Validation staff médical', 'completed'));
    steps.add(rtp('r2', 'Phase 2 : renforcement', 'Prépa physique', injured ? 'completed' : 'completed'));
    steps.add(
      rtp(
        'r3',
        'Phase 3 : retour terrain',
        injured ? 'En cours (Core)' : 'Validé',
        injured ? 'current' : 'completed'
      )
    );
    steps.add(
      rtp(
        'r4',
        'Phase 4 : intégration groupe',
        injured ? 'Prévu RTP' : '—',
        injured ? 'future' : 'completed'
      )
    );
    return steps;
  }

  private static RtpStepDto rtp(String id, String title, String subtitle, String stateKey) {
    RtpStepDto r = new RtpStepDto();
    r.id = id;
    r.title = title;
    r.subtitle = subtitle;
    r.stateKey = stateKey;
    return r;
  }

  private static List<TaskRowDto> buildTasks(Athlete__c a) {
    List<TaskRowDto> tasks = new List<TaskRowDto>();
    Decimal risk = a.InjuryRiskScore__c;
    tasks.add(
      taskRow(
        't1',
        'Course linéaire contrôlée',
        risk != null && risk < 50 ? 'Toléré' : 'Surveillance',
        risk != null && risk < 50 ? 'badge success' : 'badge warning'
      )
    );
    tasks.add(
      taskRow(
        't2',
        'Changements de direction progressifs',
        risk != null && risk < 60 ? 'Tolérance 70%' : 'Réduit',
        risk != null && risk < 60 ? 'badge warning' : 'badge danger'
      )
    );
    tasks.add(
      taskRow(
        't3',
        'Frappes / sollicitations maximales',
        risk != null && risk >= 55 ? 'Reporter si douleur' : 'OK sous contrôle',
        risk != null && risk >= 55 ? 'badge danger' : 'badge success'
      )
    );
    tasks.add(taskRow('t4', 'Proprioception / stabilité', 'Suivi staff', 'badge success'));
    return tasks;
  }

  private static TaskRowDto taskRow(String id, String name, String badge, String bcls) {
    TaskRowDto t = new TaskRowDto();
    t.id = id;
    t.taskName = name;
    t.badgeLabel = badge;
    t.badgeClass = bcls;
    return t;
  }

  private static List<LoadBarDto> buildLoadBars(Athlete__c a) {
    Decimal base = a.Load7d__c == null ? 40 : a.Load7d__c;
    List<LoadBarDto> bars = new List<LoadBarDto>();
    Integer idx = 1;
    for (Integer pct : new List<Integer>{ 15, 28, 42, 58, 72 }) {
      LoadBarDto b = new LoadBarDto();
      b.id = 'lb' + String.valueOf(idx);
      b.weekLabel = 'S' + String.valueOf(idx);
      b.heightPct = pct;
      b.warning = idx == 5 && base > 3500;
      idx++;
    }
    return bars;
  }

  private static List<StaffNoteDto> buildStaffNotes(Athlete__c a, Injury__c inj) {
    List<StaffNoteDto> notes = new List<StaffNoteDto>();
    StaffNoteDto m = new StaffNoteDto();
    m.id = 'n1';
    m.channel = 'medical';
    m.author = inj != null ? 'Dossier blessure (Injury__c)' : 'Synthèse IA / Core';
    m.dateLabel = a.LastDataCloudSync__c != null ? a.LastDataCloudSync__c.format('dd/MM/yyyy') : '—';
    if (inj != null && !String.isBlank(inj.ClinicalSummary__c)) {
      m.body = inj.ClinicalSummary__c.left(400);
    } else if (!String.isBlank(a.TopRisks__c)) {
      m.body = a.TopRisks__c.left(400);
    } else {
      m.body = 'Aucune note clinique — compléter Clinical Summary sur la blessure active ou Top Risks.';
    }
    notes.add(m);
    StaffNoteDto p = new StaffNoteDto();
    p.id = 'n2';
    p.channel = 'performance';
    p.author = 'Performance (données charge)';
    p.dateLabel = 'Live';
    p.body = String.isBlank(a.AthleteSummary__c)
      ? 'Résumé athlète vide — alimenté par Data Cloud / import.'
      : a.AthleteSummary__c.left(400);
    notes.add(p);
    return notes;
  }

  private static List<HistoryRowDto> buildHistory(List<Injury__c> injuries, Athlete__c a) {
    List<HistoryRowDto> rows = new List<HistoryRowDto>();
    if (injuries != null && !injuries.isEmpty()) {
      for (Injury__c inj : injuries) {
        HistoryRowDto row = new HistoryRowDto();
        row.id = String.valueOf(inj.Id);
        row.eventPeriod = inj.InjuryDate__c != null ? inj.InjuryDate__c.format() : '—';
        row.injuryLabel = String.isBlank(inj.BodyZone__c) ? 'Blessure' : inj.BodyZone__c;
        row.durationLabel = formatInjuryDuration(inj);
        row.recurrenceLabel = String.isBlank(inj.RecurrenceNote__c) ? '—' : inj.RecurrenceNote__c;
        row.activeRow = inj.Status__c == 'Active';
        rows.add(row);
      }
      return rows;
    }
    HistoryRowDto cur = new HistoryRowDto();
    cur.id = 'h0';
    cur.eventPeriod = a.LastInjuryAlertAt__c != null ? a.LastInjuryAlertAt__c.format('MMM yyyy') : '—';
    cur.injuryLabel = a.Status__c == 'Injured' ? 'Suivi (sans ligne Injury__c)' : 'Aucune blessure enregistrée';
    cur.durationLabel = a.Status__c == 'Injured' ? 'En cours' : '—';
    cur.recurrenceLabel = '—';
    cur.activeRow = a.Status__c == 'Injured';
    rows.add(cur);
    return rows;
  }

  private static String formatInjuryDuration(Injury__c inj) {
    if (inj.Status__c == 'Active') {
      return 'En cours';
    }
    if (inj.InjuryDate__c != null && inj.ActualReturnDate__c != null) {
      Integer days = inj.InjuryDate__c.daysBetween(inj.ActualReturnDate__c);
      if (days < 0) {
        days = -days;
      }
      return String.valueOf(days) + ' j.';
    }
    if (inj.Status__c == 'Resolved') {
      return 'Clôturé';
    }
    return '—';
  }

  private static List<AiRecDto> buildAiRecs(Athlete__c a) {
    List<AiRecDto> recs = new List<AiRecDto>();
    AiRecDto w = new AiRecDto();
    w.id = 'ai1';
    w.tone = 'warning';
    w.title = 'Surveillance charge & risque';
    w.body = String.isBlank(a.TopRisks__c)
      ? 'Renseigner les risques identifiés pour affiner les recommandations.'
      : a.TopRisks__c.left(500);
    recs.add(w);
    AiRecDto s = new AiRecDto();
    s.id = 'ai2';
    s.tone = 'success';
    s.title = 'Points positifs';
    s.body = String.isBlank(a.TopStrengths__c)
      ? 'Aucune force saisie — compléter Top Strengths.'
      : a.TopStrengths__c.left(500);
    recs.add(s);
    return recs;
  }

  private static List<PredictionLineDto> buildPredictions(Athlete__c a, Injury__c inj) {
    List<PredictionLineDto> lines = new List<PredictionLineDto>();
    lines.add(line('p1', 'Retour entraînement collectif (sans contact) : selon staff médical & RTP.'));
    if (inj != null && inj.ExpectedReturnDate__c != null) {
      lines.add(
        line(
          'p2',
          'Retour compétition cible (Injury) : ' + inj.ExpectedReturnDate__c.format() + '.'
        )
      );
    } else {
      lines.add(line('p2', 'Réintégration pleine : pilotée par readiness & ACWR.'));
    }
    lines.add(
      line(
        'p3',
        'Risque blessure actuel (Core) : ' +
        (a.InjuryRiskScore__c == null ? '—' : String.valueOf(a.InjuryRiskScore__c.setScale(0))) +
        ' %.'
      )
    );
    return lines;
  }

  private static PredictionLineDto line(String id, String txt) {
    PredictionLineDto p = new PredictionLineDto();
    p.id = id;
    p.lineHtml = txt;
    return p;
  }
}
