import { LightningElement, api, track, wire } from 'lwc';
import getAthleteHome from '@salesforce/apex/SC360AthleteHomeController.getAthleteHome';

const READINESS_DURATION_MS = 900;

function reduceErrors(errors) {
  if (!errors) {
    return 'Erreur inconnue';
  }
  const list = Array.isArray(errors) ? errors : [errors];
  return (
    list
      .filter((e) => !!e)
      .map((e) => e.body?.message || e.message || String(e))
      .join(', ') || 'Erreur inconnue'
  );
}

export default class Sc360AthleteHome extends LightningElement {
  _recordId;
  _homeDataReady = false;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    this._homeDataReady = false;
    this.wireError = undefined;
  }

  @track activeTab = 'performance';

  @track wireError;

  @track hero = {
    athleteName: '',
    positionLabel: '',
    ageLabel: '',
    statusBadgeClass: 'status-badge',
    statusLabel: '',
    nextMatchLabel: '',
    matchTitle: '',
    matchTime: '',
    readinessTarget: 0,
    photoUrl: ''
  };

  @track readinessDisplay = 0;

  @track kpis = [];

  @track microcycleDays = [];

  @track matchStatRows = [];

  @track videoClips = [];

  @track medicalHistory = [];

  @track medicalAlert = '';

  @track aiSummaryTitle = '';

  @track aiSummaryBody = '';

  @track aiAnomalyTitle = '';

  @track aiAnomalyBody = '';

  @track aiAnomalyBorderClass = '';

  @track aiActionsTitle = '';

  @track aiActionItems = [];

  @track loadSeries = [];

  @track zoneSeries = [];

  _readinessStart = null;
  _readinessRaf = null;

  @wire(getAthleteHome, { recordId: '$resolvedRecordId' })
  wiredHome({ data, error }) {
    if (data) {
      this._homeDataReady = true;
      this.wireError = undefined;
      this.applyPayload(data);
      this.queueReadinessAnimation();
      return;
    }
    if (error) {
      this._homeDataReady = true;
      this.wireError = reduceErrors(error);
    }
  }

  get resolvedRecordId() {
    return this.recordId || undefined;
  }

  get isPreviewWithoutRecord() {
    return !this.recordId;
  }

  get showWireLoading() {
    return this.recordId && !this._homeDataReady && !this.wireError;
  }

  get readinessCircleClass() {
    return this.hero.readinessTarget < 75 ? 'readiness-score warning-glow' : 'readiness-score';
  }

  get tabDefs() {
    const active = this.activeTab;
    const tabs = [
      { id: 'performance', label: 'Performance' },
      { id: 'microcycle', label: 'Microcycle' },
      { id: 'match', label: 'Match' },
      { id: 'medical', label: 'Médical' }
    ];
    return tabs.map((t) => ({
      ...t,
      isActive: t.id === active,
      buttonClass: t.id === active ? 'tab-btn active' : 'tab-btn'
    }));
  }

  get isPerformanceTab() {
    return this.activeTab === 'performance';
  }

  get isMicrocycleTab() {
    return this.activeTab === 'microcycle';
  }

  get isMatchTab() {
    return this.activeTab === 'match';
  }

  get isMedicalTab() {
    return this.activeTab === 'medical';
  }

  get hasLoadChart() {
    return Array.isArray(this.loadSeries) && this.loadSeries.length > 0;
  }

  get hasZoneChart() {
    return Array.isArray(this.zoneSeries) && this.zoneSeries.length > 0;
  }

  get hasVideoClips() {
    return Array.isArray(this.videoClips) && this.videoClips.length > 0;
  }

  get hasAiAnomaly() {
    return !!(this.aiAnomalyBody && String(this.aiAnomalyBody).trim());
  }

  get hasAiSummary() {
    return !!(this.aiSummaryBody && String(this.aiSummaryBody).trim());
  }

  get hasMedicalContent() {
    return (
      (Array.isArray(this.medicalHistory) && this.medicalHistory.length > 0) ||
      !!(this.medicalAlert && String(this.medicalAlert).trim())
    );
  }

  get hasMicrocycleDays() {
    return Array.isArray(this.microcycleDays) && this.microcycleDays.length > 0;
  }

  get medicalPanelClass() {
    return this.medicalAlert && String(this.medicalAlert).trim()
      ? 'content-panel border-danger'
      : 'content-panel';
  }

  get hasAiActions() {
    return Array.isArray(this.aiActionItems) && this.aiActionItems.length > 0;
  }

  disconnectedCallback() {
    if (this._readinessRaf) {
      cancelAnimationFrame(this._readinessRaf);
      this._readinessRaf = null;
    }
  }

  applyPayload(payload) {
    if (!payload) {
      return;
    }
    this.hero = { ...payload.hero };
    this.kpis = payload.kpis ? [...payload.kpis] : [];
    this.microcycleDays = payload.microcycleDays ? [...payload.microcycleDays] : [];
    this.matchStatRows = payload.matchStatRows ? [...payload.matchStatRows] : [];
    this.videoClips = payload.videoClips ? [...payload.videoClips] : [];
    this.medicalHistory = payload.medicalHistory ? [...payload.medicalHistory] : [];
    this.medicalAlert = payload.medicalAlert || '';
    this.aiSummaryTitle = payload.aiSummaryTitle || '';
    this.aiSummaryBody = payload.aiSummaryBody || '';
    this.aiAnomalyTitle = payload.aiAnomalyTitle || '';
    this.aiAnomalyBody = payload.aiAnomalyBody || '';
    this.aiAnomalyBorderClass = payload.aiAnomalyBorderClass || '';
    this.aiActionsTitle = payload.aiActionsTitle || '';
    this.aiActionItems = payload.aiActionItems ? [...payload.aiActionItems] : [];
    this.loadSeries = payload.loadSeries ? [...payload.loadSeries] : [];
    this.zoneSeries = payload.zoneSeries ? [...payload.zoneSeries] : [];
    this.readinessDisplay = 0;
  }

  queueReadinessAnimation() {
    const target = this.hero.readinessTarget || 0;
    if (target <= 0) {
      this.readinessDisplay = 0;
      return;
    }
    this._readinessStart = performance.now();
    const tick = (now) => {
      const elapsed = now - this._readinessStart;
      const t = Math.min(elapsed / READINESS_DURATION_MS, 1);
      const eased = 1 - Math.pow(1 - t, 3);
      this.readinessDisplay = Math.round(target * eased);
      if (t < 1) {
        this._readinessRaf = requestAnimationFrame(tick);
      } else {
        this.readinessDisplay = target;
        this._readinessRaf = null;
      }
    };
    this._readinessRaf = requestAnimationFrame(tick);
  }

  handleTabClick(event) {
    const id = event.currentTarget?.dataset?.tabid;
    if (id && id !== this.activeTab) {
      this.activeTab = id;
    }
  }

  handleGeneratePdf() {
    // TODO: navigation / Apex / generateDocument
  }
}
