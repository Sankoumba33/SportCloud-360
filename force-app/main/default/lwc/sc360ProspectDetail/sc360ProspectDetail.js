import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDetail from '@salesforce/apex/SC360ProspectDetailController.getDetail';
import getStepReports from '@salesforce/apex/SC360ProspectDetailController.getStepReports';
import saveStepReport from '@salesforce/apex/SC360ProspectDetailController.saveStepReport';
import promoteToPriority from '@salesforce/apex/SC360ScoutingExplorerController.promoteToPriority';
import getFinancialData from '@salesforce/apex/SC360ScoutingEnhancedController.getFinancialData';
import getVideoEvents from '@salesforce/apex/SC360ScoutingEnhancedController.getVideoEvents';
import getHeatmapCoordinates from '@salesforce/apex/SC360ScoutingEnhancedController.getHeatmapCoordinates';
import generateAIScoutingSummary from '@salesforce/apex/SC360ScoutingEnhancedController.generateAIScoutingSummary';

const STEP_OPTIONS = [
  { label: 'Video Scouting', value: 'Video Scouting' },
  { label: 'Live Scouting', value: 'Live Scouting' },
  { label: 'Data Check', value: 'Data Check' },
  { label: 'Reference Check', value: 'Reference Check' },
  { label: 'Background Check', value: 'Background Check' }
];

const POTENTIAL_MS = 800;

export default class Sc360ProspectDetail extends NavigationMixin(LightningElement) {
  @api recordId;

  @track activeTab = 'profile';

  detail;
  reports = [];
  error;
  saving = false;

  potentialDisplay = 0;
  _potRaf = null;
  _potStart = null;

  form = {
    stepType: 'Video Scouting',
    matchSelection: '',
    summary: '',
    comparisonNotes: '',
    referenceContacts: '',
    socialNetworks: '',
    rating: null
  };

  get resolvedRecordId() {
    return this.recordId || undefined;
  }

  get isBuilderPreview() {
    return !this.recordId;
  }

  @wire(getDetail, { recordId: '$resolvedRecordId' })
  wiredDetail({ data, error }) {
    if (data) {
      this.detail = data;
      this.error = undefined;
      this.queuePotentialAnimation();
    } else if (error) {
      this.error = error;
      this.detail = undefined;
    }
  }

  @wire(getStepReports, { prospectId: '$resolvedRecordId' })
  wiredReports({ data }) {
    if (data) {
      this.reports = data;
    }
  }

  // --- NOUVELLES OPTIONS (SANS FAUSSES DONNEES) ---
  financeData;
  videoEvents = [];
  heatmapData = [];
  aiSummaryResult = '';
  isGeneratingAI = false;

  @wire(getFinancialData, { prospectId: '$resolvedRecordId' })
  wiredFinance({ data }) {
      if (data) this.financeData = data;
  }

  @wire(getVideoEvents, { prospectId: '$resolvedRecordId' })
  wiredVideo({ data }) {
      if (data) this.videoEvents = data;
  }

  @wire(getHeatmapCoordinates, { prospectId: '$resolvedRecordId' })
  wiredHeatmap({ data }) {
      if (data) this.heatmapData = data;
  }

  get hasVideoEvents() {
      return this.videoEvents && this.videoEvents.length > 0;
  }

  get hasHeatmapData() {
      return this.heatmapData && this.heatmapData.length > 0;
  }

  async handleGenerateAI() {
      if (!this.recordId) return;
      this.isGeneratingAI = true;
      try {
          this.aiSummaryResult = await generateAIScoutingSummary({ prospectId: this.recordId });
          this.toast('Génération terminée', 'La synthèse exécutive a été générée.', 'success');
      } catch (error) {
          this.toast('Erreur IA', error.body ? error.body.message : error.message, 'error');
      } finally {
          this.isGeneratingAI = false;
      }
  }
  // ------------------------------------------------

  disconnectedCallback() {
    if (this._potRaf) {
      cancelAnimationFrame(this._potRaf);
      this._potRaf = null;
    }
  }

  queuePotentialAnimation() {
    const target = this.detail?.potentialDisplay || 0;
    if (target <= 0) {
      this.potentialDisplay = 0;
      return;
    }
    this._potStart = performance.now();
    const tick = (now) => {
      const elapsed = now - this._potStart;
      const t = Math.min(elapsed / POTENTIAL_MS, 1);
      const eased = 1 - Math.pow(1 - t, 3);
      this.potentialDisplay = Math.round(target * eased);
      if (t < 1) {
        this._potRaf = requestAnimationFrame(tick);
      } else {
        this.potentialDisplay = target;
        this._potRaf = null;
      }
    };
    this._potRaf = requestAnimationFrame(tick);
  }

  get stepOptions() {
    return STEP_OPTIONS;
  }

  get hasData() {
    return !!this.detail;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return '';
    if (this.error.body && this.error.body.message) return this.error.body.message;
    return 'Impossible de charger le prospect.';
  }

  get insights() {
    return this.detail?.insights || [];
  }

  get insightLines() {
    return (this.insights || []).map((text, i) => ({ id: `ins${i}`, text }));
  }

  get reportsFormatted() {
    return (this.reports || []).map((r) => ({
      ...r,
      reportDateStr: r.reportDate != null ? String(r.reportDate) : ''
    }));
  }

  get tabDefs() {
    const t = this.activeTab;
    const tabs = [
      { id: 'profile', label: 'Profil & Perf' },
      { id: 'match', label: 'Matchs & Vidéos' },
      { id: 'compare', label: 'Comparaison' },
      { id: 'reports', label: 'Rapports scouts' },
      { id: 'ai', label: 'Projection & IA' },
      { id: 'process', label: 'Saisie process' }
    ];
    return tabs.map((x) => ({
      ...x,
      buttonClass: x.id === t ? 'tab-btn active' : 'tab-btn'
    }));
  }

  get isProfileTab() {
    return this.activeTab === 'profile';
  }
  get isMatchTab() {
    return this.activeTab === 'match';
  }
  get isCompareTab() {
    return this.activeTab === 'compare';
  }
  get isReportsTab() {
    return this.activeTab === 'reports';
  }
  get isAiTab() {
    return this.activeTab === 'ai';
  }
  get isProcessTab() {
    return this.activeTab === 'process';
  }

  get stripKpis() {
    const d = this.detail;
    if (!d) return [];
    const api = d.apiSeasonKpis || [];
    const find = (key) => api.find((k) => k.key === key);
    const val = (key) => {
      const x = find(key);
      if (!x || x.value == null) return '—';
      return String(x.value);
    };
    const kpiLine = (key) => d.kpis?.find((x) => x.key === key);
    const scout = kpiLine('scouting');
    return [
      {
        id: 'sk1',
        iconName: 'utility:clock',
        valueMain: val('api_minutes'),
        valueUnit: 'min',
        title: 'Minutes (saison)',
        cardClass: 'kpi-card'
      },
      {
        id: 'sk2',
        iconName: 'utility:metrics',
        valueMain: val('api_key_passes'),
        valueUnit: '',
        title: 'Passes clés',
        cardClass: 'kpi-card'
      },
      {
        id: 'sk3',
        iconName: 'utility:flash',
        valueMain: val('api_tackles'),
        valueUnit: '',
        title: 'Tacles',
        cardClass: 'kpi-card'
      },
      {
        id: 'sk4',
        iconName: 'utility:touchdown',
        valueMain: val('api_duels'),
        valueUnit: '',
        title: 'Duels gagnés',
        cardClass: 'kpi-card'
      },
      {
        id: 'sk5',
        iconName: 'utility:ribbon',
        valueMain: val('api_goals'),
        valueUnit: '',
        title: 'Buts (saison)',
        cardClass: 'kpi-card'
      },
      {
        id: 'sk6',
        iconName: 'utility:preview',
        valueMain: scout ? String(scout.value) : '—',
        valueUnit: '%',
        title: 'Score scouting',
        cardClass: 'kpi-card kpi-card--scouting'
      }
    ];
  }

  get keyStatsRows() {
    return (this.detail?.keyStats || []).map((r, i) => ({
      id: `ks${i}`,
      metricLabel: r.metricLabel,
      displayValue: r.displayValue,
      badgeClass:
        r.badgeTone === 'danger' ? 'badge danger' : r.badgeTone === 'warning' ? 'badge warning' : 'badge success'
    }));
  }

  get compareRows() {
    const pairs = this.detail?.comparePairs || [];
    return pairs.map((p, idx) => {
      const lv = Number(p.leftValue != null ? p.leftValue : 0);
      const rv = Number(p.rightValue != null ? p.rightValue : 0);
      const max = Math.max(lv, rv, 1);
      const leftPct = Math.min(100, (lv / max) * 100);
      const rightPct = Math.min(100, (rv / max) * 100);
      return {
        rowKey: `cp${idx}`,
        metricLabel: p.metricLabel,
        leftCaption: p.leftCaption,
        rightCaption: p.rightCaption,
        leftFmt: p.leftValue != null ? String(Number(p.leftValue).toFixed(1)) : '—',
        rightFmt: p.rightValue != null ? String(Number(p.rightValue).toFixed(1)) : '—',
        leftStyle: `width:${leftPct}%;`,
        rightStyle: `width:${rightPct}%;`
      };
    });
  }

  get matchRows() {
    return (this.reports || []).slice(0, 5).map((r, i) => ({
      id: r.id || `mr${i}`,
      dateLabel: r.reportDate || '',
      line: r.matchSelection ? String(r.matchSelection).substring(0, 120) : r.summary ? String(r.summary).substring(0, 120) : '—',
      grade: r.rating != null ? String(r.rating) : '—'
    }));
  }

  get potentialCircleClass() {
    const t = this.detail?.potentialDisplay || 0;
    return t >= 70 ? 'potential-score success-glow' : 'potential-score';
  }

  get statusBadgeClass() {
    return this.detail?.isPriority ? 'status-badge priority' : 'status-badge';
  }

  get statusBadgeLabel() {
    if (this.detail?.isPriority) return 'Cible prioritaire';
    return this.detail?.status || '—';
  }

  handleTabClick(event) {
    const id = event.currentTarget?.dataset?.tabid;
    if (id && id !== this.activeTab) {
      this.activeTab = id;
    }
  }

  handleInput(event) {
    const { name, value } = event.target;
    this.form = { ...this.form, [name]: value };
  }

  async handleShortlist() {
    if (!this.recordId) return;
    try {
      await promoteToPriority({ prospectId: this.recordId });
      this.toast('Shortlist', 'Prospect passé en Priority.', 'success');
    } catch (e) {
      this.toast('Erreur', e?.body?.message || e?.message || 'Erreur', 'error');
    }
  }

  handleOpenCompare() {
    this.toast(
      'Comparer',
      'Ouvre la page App « Comparaison prospects » ou ajoute un second prospect depuis le pipeline.',
      'info'
    );
  }

  handleOpenReport() {
    this.activeTab = 'process';
    this.toast('Rapport', 'Renseigne l’étape dans l’onglet Saisie process.', 'info');
  }

  async handleSaveStep() {
    if (!this.recordId || !this.form.stepType) {
      return;
    }
    this.saving = true;
    try {
      await saveStepReport({
        prospectId: this.recordId,
        stepType: this.form.stepType,
        matchSelection: this.form.matchSelection,
        summary: this.form.summary,
        comparisonNotes: this.form.comparisonNotes,
        referenceContacts: this.form.referenceContacts,
        socialNetworks: this.form.socialNetworks,
        rating: this.form.rating ? Number(this.form.rating) : null
      });
      this.toast('OK', 'Étape scouting enregistrée.', 'success');
      this.form = {
        stepType: this.form.stepType,
        matchSelection: '',
        summary: '',
        comparisonNotes: '',
        referenceContacts: '',
        socialNetworks: '',
        rating: null
      };
    } catch (e) {
      const message = e?.body?.message || 'Erreur enregistrement.';
      this.toast('Erreur', message, 'error');
    } finally {
      this.saving = false;
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
