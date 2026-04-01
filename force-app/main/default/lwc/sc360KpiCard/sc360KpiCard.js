import { LightningElement, api } from 'lwc';

export default class Sc360KpiCard extends LightningElement {
  @api kpi;

  get displayValue() {
    const v = this.kpi?.value;
    if (v === undefined || v === null || v === '') {
      return '0';
    }
    const n = Number(v);
    return Number.isFinite(n) ? String(n) : String(v);
  }

  get trendClass() {
    return `delta ${this.kpi?.trend || 'stable'}`;
  }
}
