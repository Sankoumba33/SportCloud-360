import { LightningElement, wire } from 'lwc';
import getOverview from '@salesforce/apex/SC360ScoutingController.getOverview';

export default class Sc360ScoutingOverview extends LightningElement {
  overview;
  error;

  @wire(getOverview)
  wiredOverview({ data, error }) {
    if (data) {
      this.overview = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.overview = undefined;
    }
  }

  get hasData() {
    return !!this.overview;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return '';
    if (this.error.body && this.error.body.message) return this.error.body.message;
    return 'Acces scouting indisponible.';
  }

  get kpis() {
    return this.overview?.kpis || [];
  }

  get statusSeries() {
    return this.overview?.statusDistribution || [];
  }

  get positionSeries() {
    return this.overview?.positionDistribution || [];
  }

  get insights() {
    return this.overview?.aiInsights || [];
  }
}
