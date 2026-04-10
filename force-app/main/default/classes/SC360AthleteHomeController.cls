/**
 * Home Athlete 360 — données réelles uniquement (pas de séries simulées).
 * Graphiques Performance :
 * - Courbe charge : FeaturesJson__c.loadSeries ou charts.loadDynamic → [{label,value},...]
 * - Barres zones : zoneBars ou charts.zones dans JSON ; sinon champs Distance7d, Hid15_7d, Hid20_7d, Sprints25_7d, Accel3_7d (valeurs non nulles).
 */
public with sharing class SC360AthleteHomeController {
  public class HeroDto {
    @AuraEnabled public String athleteName;
    @AuraEnabled public String positionLabel;
    @AuraEnabled public String ageLabel;
    @AuraEnabled public String statusBadgeClass;
    @AuraEnabled public String statusLabel;
    @AuraEnabled public String nextMatchLabel;
    @AuraEnabled public String matchTitle;
    @AuraEnabled public String matchTime;
    @AuraEnabled public Integer readinessTarget;
    @AuraEnabled public String photoUrl;
  }

  public class HomeKpiDto {
    @AuraEnabled public String id;
    @AuraEnabled public String iconName;
    @AuraEnabled public String valueMain;
    @AuraEnabled public String valueUnit;
    @AuraEnabled public String title;
    @AuraEnabled public String valClass;
    @AuraEnabled public String cardClass;
  }

  public class MicrocycleRowDto {
    @AuraEnabled public String id;
    @AuraEnabled public String dayClass;
    @AuraEnabled public String label;
    @AuraEnabled public Boolean circleKindIcon;
    @AuraEnabled public Boolean circleKindOff;
    @AuraEnabled public Boolean circleKindPulse;
    @AuraEnabled public Boolean circleKindEmpty;
    @AuraEnabled public String iconName;
    @AuraEnabled public String offText;
    @AuraEnabled public String focus;
    @AuraEnabled public String focusWrapClass;
    @AuraEnabled public String focusClass;
  }

  public class MatchStatRowDto {
    @AuraEnabled public String id;
    @AuraEnabled public String label;
    @AuraEnabled public String value;
    @AuraEnabled public String rowClass;
  }

  public class VideoClipDto {
    @AuraEnabled public String id;
    @AuraEnabled public String label;
  }

  public class MedicalHistoryDto {
    @AuraEnabled public String id;
    @AuraEnabled public String dateLabel;
    @AuraEnabled public String title;
    @AuraEnabled public String body;
  }

  public class AiActionDto {
    @AuraEnabled public String id;
    @AuraEnabled public String itemClass;
    @AuraEnabled public String iconName;
    @AuraEnabled public String label;
  }

  /** Point pour graphiques (série depuis FeaturesJson__c.loadSeries / zoneBars ou champs scalaires). */
  public class ChartPointDto {
    @AuraEnabled public String label;
    @AuraEnabled public Decimal value;
  }

  public class HomePayloadDto {
    @AuraEnabled public HeroDto hero;
    @AuraEnabled public List<HomeKpiDto> kpis;
    @AuraEnabled public List<MicrocycleRowDto> microcycleDays;
    @AuraEnabled public List<MatchStatRowDto> matchStatRows;
    @AuraEnabled public List<VideoClipDto> videoClips;
    @AuraEnabled public List<MedicalHistoryDto> medicalHistory;
    @AuraEnabled public String medicalAlert;
    @AuraEnabled public String aiSummaryTitle;
    @AuraEnabled public String aiSummaryBody;
    @AuraEnabled public String aiAnomalyTitle;
    @AuraEnabled public String aiAnomalyBody;
    @AuraEnabled public String aiAnomalyBorderClass;
    @AuraEnabled public String aiActionsTitle;
    @AuraEnabled public List<AiActionDto> aiActionItems;
    @AuraEnabled public List<ChartPointDto> loadSeries;
    @AuraEnabled public List<ChartPointDto> zoneSeries;
  }

  @AuraEnabled(cacheable=true)
  public static HomePayloadDto getAthleteHome(Id recordId) {
    if (recordId == null) {
      throw new AuraHandledException('recordId manquant.');
    }

    Athlete__c a = [
      SELECT
        Name,
        Sport__c,
        Status__c,
        DateOfBirth__c,
        ReadinessScore__c,
        InjuryRiskScore__c,
        Acwr__c,
        Load7d__c,
        MinutesMatch7d__c,
        Distance7d__c,
        Hid20_7d__c,
        Sprints25_7d__c,
        MaxSpeed7d__c,
        MinutesMatch28d__c,
        AthleteSummary__c,
        TopRisks__c,
        TopStrengths__c,
        PerformanceTrend__c,
        FeaturesJson__c,
        Hid15_7d__c,
        Accel3_7d__c,
        CurrentSquad__c,
        CurrentSquad__r.Name
      FROM Athlete__c
      WHERE Id = :recordId
      LIMIT 1
    ];

    HomePayloadDto out = new HomePayloadDto();
    out.hero = buildHero(a);
    out.kpis = buildKpis(a);
    out.microcycleDays = buildMicrocycle(a.Id);
    out.matchStatRows = buildMatchRows(a);
    out.videoClips = new List<VideoClipDto>();
    out.medicalHistory = buildMedicalHistory(a);
    out.medicalAlert = buildMedicalAlert(a);
    out.aiSummaryTitle = String.isBlank(a.AthleteSummary__c) ? '' : 'Résumé';
    out.aiSummaryBody = String.isBlank(a.AthleteSummary__c) ? '' : a.AthleteSummary__c.left(800);
    out.aiAnomalyTitle = String.isBlank(a.TopRisks__c) ? '' : 'Points de vigilance';
    out.aiAnomalyBody = String.isBlank(a.TopRisks__c) ? '' : a.TopRisks__c.left(800);
    out.aiAnomalyBorderClass = String.isBlank(a.TopRisks__c) ? '' : 'ai-box anomalie border-warning';
    out.aiActionsTitle = 'Recommandations';
    out.aiActionItems = buildAiActions(a);
    out.loadSeries = chartLoadSeriesFromFeaturesJson(a.FeaturesJson__c);
    out.zoneSeries = chartZoneSeries(a);
    return out;
  }

  private static HeroDto buildHero(Athlete__c a) {
    HeroDto h = new HeroDto();
    h.athleteName = a.Name;
    String squad = a.CurrentSquad__r != null ? a.CurrentSquad__r.Name : '';
    h.positionLabel = String.isBlank(a.Sport__c) ? squad : (a.Sport__c + (String.isBlank(squad) ? '' : ' · ' + squad));
    h.ageLabel = formatAge(a.DateOfBirth__c);
    Boolean warn = a.InjuryRiskScore__c != null && a.InjuryRiskScore__c >= 50;
    h.statusBadgeClass = warn ? 'status-badge warning' : 'status-badge';
    h.statusLabel = String.isBlank(a.Status__c) ? (warn ? 'À surveiller' : 'OK') : a.Status__c;
    h.photoUrl = '';

    PlanningEvent__c nextEv = nextMatchForSquad(a.CurrentSquad__c);
    if (nextEv != null) {
      h.nextMatchLabel = 'Prochain événement';
      h.matchTitle = nextEv.Name;
      h.matchTime =
        nextEv.StartDateTime__c != null ? nextEv.StartDateTime__c.format('dd/MM/yyyy HH:mm') : '';
    } else {
      h.nextMatchLabel = 'Planning';
      h.matchTitle = '—';
      h.matchTime = '';
    }

    Integer r = a.ReadinessScore__c == null ? 0 : Integer.valueOf(a.ReadinessScore__c.round());
    if (r > 100) {
      r = 100;
    }
    if (r < 0) {
      r = 0;
    }
    h.readinessTarget = r;
    return h;
  }

  private static PlanningEvent__c nextMatchForSquad(Id squadId) {
    if (squadId == null) {
      return null;
    }
    List<PlanningEvent__c> evs = [
      SELECT Name, StartDateTime__c, EventType__c
      FROM PlanningEvent__c
      WHERE Squad__c = :squadId AND StartDateTime__c >= :System.now()
      ORDER BY StartDateTime__c ASC
      LIMIT 1
    ];
    return evs.isEmpty() ? null : evs[0];
  }

  private static String formatAge(Date dob) {
    if (dob == null) {
      return '';
    }
    Integer y = dob.year();
    Integer m = dob.month();
    Integer d = dob.day();
    Date today = Date.today();
    Integer age = today.year() - y;
    if (today.month() < m || (today.month() == m && today.day() < d)) {
      age--;
    }
    return String.valueOf(age) + ' ans';
  }

  private static List<HomeKpiDto> buildKpis(Athlete__c a) {
    List<HomeKpiDto> rows = new List<HomeKpiDto>();
    rows.add(kpi('k1', 'utility:clock', fmtInt(a.MinutesMatch7d__c), 'm', 'Minutes (7j)', 'neutral', false));
    rows.add(kpi('k2', 'utility:metrics', fmtLoadK(a.Load7d__c), 'k', 'Charge hebdo', 'neutral', false));
    Boolean hidWarn = a.Hid20_7d__c != null && a.Hid20_7d__c > 800;
    rows.add(
      kpi(
        'k3',
        'utility:sparkles',
        fmtInt(a.Hid20_7d__c),
        'm',
        'HID (>19.8km/h)',
        hidWarn ? 'danger' : 'neutral',
        false
      )
    );
    rows.add(kpi('k4', 'utility:lightning', fmtInt(a.Sprints25_7d__c), '', 'Sprints (>25km/h)', 'neutral', false));
    rows.add(
      kpi(
        'k5',
        'utility:trending',
        fmtDec(a.MaxSpeed7d__c, 1),
        'km/h',
        'Vitesse max (7j)',
        'neutral',
        false
      )
    );
    Boolean acwrWarn = a.Acwr__c != null && a.Acwr__c > 1.1;
    rows.add(
      kpi(
        'k6',
        'utility:macros',
        fmtDec(a.Acwr__c, 2),
        '',
        'Ratio ACWR',
        acwrWarn ? 'warning' : 'neutral',
        true
      )
    );
    return rows;
  }

  private static HomeKpiDto kpi(
    String id,
    String icon,
    String main,
    String unit,
    String title,
    String tone,
    Boolean ratioCard
  ) {
    HomeKpiDto k = new HomeKpiDto();
    k.id = id;
    k.iconName = icon;
    k.valueMain = main;
    k.valueUnit = unit;
    k.title = title;
    if (tone == 'danger') {
      k.valClass = 'kpi-val danger-text';
    } else if (tone == 'warning') {
      k.valClass = 'kpi-val warning-text';
    } else {
      k.valClass = 'kpi-val';
    }
    k.cardClass = ratioCard ? 'kpi-card ratio-card' : 'kpi-card';
    return k;
  }

  private static String fmtInt(Decimal v) {
    if (v == null) {
      return '—';
    }
    return String.valueOf(v.setScale(0, System.RoundingMode.HALF_UP).intValue());
  }

  private static String fmtDec(Decimal v, Integer scale) {
    if (v == null) {
      return '—';
    }
    return String.valueOf(v.setScale(scale, System.RoundingMode.HALF_UP));
  }

  private static String fmtLoadK(Decimal load) {
    if (load == null) {
      return '—';
    }
    Decimal k = load / 1000.0;
    return String.valueOf(k.setScale(1, System.RoundingMode.HALF_UP));
  }

  private static List<MicrocycleRowDto> buildMicrocycle(Id athleteId) {
    List<MicrocycleRowDto> out = new List<MicrocycleRowDto>();
    Integer idx = 0;
    for (AthleteMicrocycleDay__c row : [
      SELECT
        Id,
        PlannedLoad__c,
        ActualLoad__c,
        LoadComment__c,
        MicrocycleDay__r.DayDate__c,
        MicrocycleDay__r.PhysicalFocus__c,
        MicrocycleDay__r.Phase__c
      FROM AthleteMicrocycleDay__c
      WHERE Athlete__c = :athleteId
      ORDER BY MicrocycleDay__r.DayDate__c ASC
      LIMIT 6
    ]) {
      idx++;
      MicrocycleRowDto m = new MicrocycleRowDto();
      m.id = 'mc' + String.valueOf(idx);
      m.label = row.MicrocycleDay__r.DayDate__c != null ? String.valueOf(row.MicrocycleDay__r.DayDate__c) : 'J' + String.valueOf(idx);
      m.focus = String.isBlank(row.MicrocycleDay__r.PhysicalFocus__c)
        ? (String.isBlank(row.LoadComment__c) ? '—' : row.LoadComment__c)
        : row.MicrocycleDay__r.PhysicalFocus__c;
      m.focusWrapClass = 'mc-focus';
      m.focusClass = '';
      m.offText = '';
      m.iconName = 'utility:check';
      m.circleKindIcon = true;
      m.circleKindOff = false;
      m.circleKindPulse = false;
      m.circleKindEmpty = false;
      m.dayClass = 'mc-day past complete';
      out.add(m);
    }
    return out;
  }

  private static List<MatchStatRowDto> buildMatchRows(Athlete__c a) {
    List<MatchStatRowDto> rows = new List<MatchStatRowDto>();
    rows.add(
      row(
        'm1',
        'Minutes (fenêtre)',
        fmtInt(a.MinutesMatch28d__c) + ' min',
        'ms-row'
      )
    );
    rows.add(row('m2', 'Distance (7j)', fmtDec(a.Distance7d__c, 1) + ' km', 'ms-row'));
    rows.add(row('m3', 'Sprints (7j)', fmtInt(a.Sprints25_7d__c), 'ms-row'));
    return rows;
  }

  private static MatchStatRowDto row(String id, String label, String value, String cls) {
    MatchStatRowDto r = new MatchStatRowDto();
    r.id = id;
    r.label = label;
    r.value = value;
    r.rowClass = cls;
    return r;
  }

  private static List<MedicalHistoryDto> buildMedicalHistory(Athlete__c a) {
    List<MedicalHistoryDto> hist = new List<MedicalHistoryDto>();
    if (!String.isBlank(a.TopRisks__c)) {
      MedicalHistoryDto h = new MedicalHistoryDto();
      h.id = 'h1';
      h.dateLabel = 'Synthèse';
      h.title = 'Risques identifiés';
      h.body = a.TopRisks__c.left(2000);
      hist.add(h);
    }
    return hist;
  }

  private static String buildMedicalAlert(Athlete__c a) {
    if (!String.isBlank(a.TopRisks__c)) {
      return a.TopRisks__c.left(500);
    }
    if (a.InjuryRiskScore__c != null && a.InjuryRiskScore__c >= 40) {
      return 'Score risque blessure élevé — adapter charge et suivi.';
    }
    return '';
  }

  private static List<AiActionDto> buildAiActions(Athlete__c a) {
    List<AiActionDto> actions = new List<AiActionDto>();
    Integer n = 1;
    if (a.Acwr__c != null && a.Acwr__c > 1.1) {
      actions.add(act('a' + n, 'action-item decrease', 'utility:arrowdown', 'Réduire charge relative (ACWR)'));
      n++;
    }
    if (a.InjuryRiskScore__c != null && a.InjuryRiskScore__c >= 45) {
      actions.add(act('a' + n, 'action-item observe', 'utility:preview', 'Surveillance blessure / staff médical'));
      n++;
    }
    return actions;
  }

  /** Courbe charge : uniquement si FeaturesJson__c contient loadSeries ou charts.loadDynamic (tableau {label,value}). */
  private static List<ChartPointDto> chartLoadSeriesFromFeaturesJson(String featuresJson) {
    Map<String, Object> root = parseFeaturesRoot(featuresJson);
    if (root == null) {
      return new List<ChartPointDto>();
    }
    List<ChartPointDto> pts = parsePointArray(root.get('loadSeries'));
    if (!pts.isEmpty()) {
      return pts;
    }
    Object charts = root.get('charts');
    if (charts instanceof Map<String, Object>) {
      return parsePointArray(((Map<String, Object>) charts).get('loadDynamic'));
    }
    return new List<ChartPointDto>();
  }

  private static List<ChartPointDto> chartZoneSeries(Athlete__c a) {
    Map<String, Object> root = parseFeaturesRoot(a.FeaturesJson__c);
    if (root != null) {
      List<ChartPointDto> fromJson = parsePointArray(root.get('zoneBars'));
      if (!fromJson.isEmpty()) {
        return fromJson;
      }
      Object charts = root.get('charts');
      if (charts instanceof Map<String, Object>) {
        fromJson = parsePointArray(((Map<String, Object>) charts).get('zones'));
        if (!fromJson.isEmpty()) {
          return fromJson;
        }
      }
    }
    return zoneSeriesFromAthleteScalars(a);
  }

  /**
   * Barres intensité : champs Athlete__c (km / m / unités brutes). Vide si tout est null.
   */
  private static List<ChartPointDto> zoneSeriesFromAthleteScalars(Athlete__c a) {
    List<ChartPointDto> out = new List<ChartPointDto>();
    addScalarPoint(out, 'Dist. 7j (km)', a.Distance7d__c);
    addScalarPoint(out, 'HID >15 (m)', a.Hid15_7d__c);
    addScalarPoint(out, 'HID >20 (m)', a.Hid20_7d__c);
    addScalarPoint(out, 'Sprints', a.Sprints25_7d__c);
    addScalarPoint(out, 'Accél. (7j)', a.Accel3_7d__c);
    return out;
  }

  private static void addScalarPoint(List<ChartPointDto> out, String label, Decimal v) {
    if (v == null) {
      return;
    }
    ChartPointDto p = new ChartPointDto();
    p.label = label;
    p.value = v;
    out.add(p);
  }

  private static Map<String, Object> parseFeaturesRoot(String featuresJson) {
    if (String.isBlank(featuresJson)) {
      return null;
    }
    try {
      Object o = JSON.deserializeUntyped(featuresJson);
      return o instanceof Map<String, Object> ? (Map<String, Object>) o : null;
    } catch (Exception e) {
      return null;
    }
  }

  private static List<ChartPointDto> parsePointArray(Object node) {
    List<ChartPointDto> out = new List<ChartPointDto>();
    if (node == null || !(node instanceof List<Object>)) {
      return out;
    }
    for (Object o : (List<Object>) node) {
      if (!(o instanceof Map<String, Object>)) {
        continue;
      }
      Map<String, Object> m = (Map<String, Object>) o;
      Object v = m.get('value');
      if (v == null) {
        continue;
      }
      Decimal d = toDecimal(v);
      if (d == null) {
        continue;
      }
      ChartPointDto p = new ChartPointDto();
      Object l = m.get('label');
      p.label = l != null ? String.valueOf(l) : '';
      p.value = d;
      out.add(p);
    }
    return out;
  }

  private static Decimal toDecimal(Object v) {
    if (v == null) {
      return null;
    }
    if (v instanceof Decimal) {
      return (Decimal) v;
    }
    if (v instanceof Double) {
      return Decimal.valueOf((Double) v);
    }
    if (v instanceof Long) {
      return Decimal.valueOf((Long) v);
    }
    if (v instanceof Integer) {
      return Decimal.valueOf((Integer) v);
    }
    try {
      return Decimal.valueOf(String.valueOf(v));
    } catch (Exception e) {
      return null;
    }
  }

  private static AiActionDto act(String id, String cls, String icon, String label) {
    AiActionDto dto = new AiActionDto();
    dto.id = id;
    dto.itemClass = cls;
    dto.iconName = icon;
    dto.label = label;
    return dto;
  }
}
