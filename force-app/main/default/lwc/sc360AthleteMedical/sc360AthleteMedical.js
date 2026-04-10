import { LightningElement, api, track, wire } from 'lwc';
import getMedicalAthlete from '@salesforce/apex/SC360AthleteMedicalController.getMedicalAthlete';

const GAUGE_MS = 700;

export default class Sc360AthleteMedical extends LightningElement {
  @api recordId;

  @track activeTab = 'reath';

  payload;
  error;
  gaugeDisplay = 0;
  _gaugeRaf = null;
  _gaugeStart = null;

  get resolvedRecordId() {
    return this.recordId || undefined;
  }

  get isBuilderPreview() {
    return !this.recordId;
  }

  @wire(getMedicalAthlete, { recordId: '$resolvedRecordId' })
  wiredMedical({ data, error }) {
    if (data) {
      this.payload = data;
      this.error = undefined;
      this.queueGaugeAnimation();
    } else if (error) {
      this.error = error;
      this.payload = undefined;
    }
  }

  disconnectedCallback() {
    if (this._gaugeRaf) {
      cancelAnimationFrame(this._gaugeRaf);
      this._gaugeRaf = null;
    }
  }

  queueGaugeAnimation() {
    const target = this.payload?.hero?.riskGaugeValue || 0;
    if (target <= 0) {
      this.gaugeDisplay = 0;
      return;
    }
    this._gaugeStart = performance.now();
    const tick = (now) => {
      const t = Math.min((now - this._gaugeStart) / GAUGE_MS, 1);
      const eased = 1 - Math.pow(1 - t, 3);
      this.gaugeDisplay = Math.round(target * eased);
      if (t < 1) {
        this._gaugeRaf = requestAnimationFrame(tick);
      } else {
        this.gaugeDisplay = target;
        this._gaugeRaf = null;
      }
    };
    this._gaugeRaf = requestAnimationFrame(tick);
  }

  get hasData() {
    return !!this.payload;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return '';
    return this.error.body?.message || this.error.message || 'Erreur chargement Medical 360.';
  }

  get tabDefs() {
    const t = this.activeTab;
    const tabs = [
      { id: 'reath', label: 'Réathlétisation' },
      { id: 'load', label: 'Charge & risque' },
      { id: 'collab', label: 'Collaboration staff' },
      { id: 'history', label: 'Historique médical' },
      { id: 'ai', label: 'IA médicale' }
    ];
    return tabs.map((x) => ({
      ...x,
      buttonClass: x.id === t ? 'm360-tab active' : 'm360-tab'
    }));
  }

  get isReath() {
    return this.activeTab === 'reath';
  }
  get isLoad() {
    return this.activeTab === 'load';
  }
  get isCollab() {
    return this.activeTab === 'collab';
  }
  get isHistory() {
    return this.activeTab === 'history';
  }
  get isAi() {
    return this.activeTab === 'ai';
  }

  get rtpStepsView() {
    return (this.payload?.rtpSteps || []).map((s) => ({
      ...s,
      rowClass:
        s.stateKey === 'completed'
          ? 'rtp-step completed'
          : s.stateKey === 'current'
            ? 'rtp-step current'
            : 'rtp-step future',
      iconName:
        s.stateKey === 'completed'
          ? 'utility:success'
          : s.stateKey === 'current'
            ? 'utility:jump_to_right'
            : ''
    }));
  }

  get noteMedical() {
    return (this.payload?.staffNotes || []).find((n) => n.channel === 'medical');
  }

  get notePerformance() {
    return (this.payload?.staffNotes || []).find((n) => n.channel === 'performance');
  }

  get aiRecsView() {
    return (this.payload?.aiRecommendations || []).map((r, i) => ({
      ...r,
      rowKey: `ai${i}`,
      rowClass: r.tone === 'success' ? 'rec-item success' : 'rec-item warning',
      toneIcon: r.tone === 'success' ? 'utility:success' : 'utility:warning'
    }));
  }

  get historyRowsView() {
    return (this.payload?.historyRows || []).map((r) => ({
      ...r,
      rowClass: r.activeRow ? 'active-injury' : ''
    }));
  }

  get loadBarsView() {
    return (this.payload?.loadBars || []).map((b) => ({
      ...b,
      fillStyleObj: { height: `${b.heightPct}%` },
      fillClassName: b.warning ? 'fill warning-bg' : 'fill'
    }));
  }

  handleTabClick(e) {
    const id = e.currentTarget?.dataset?.tabid;
    if (id && id !== this.activeTab) {
      this.activeTab = id;
    }
  }
}
