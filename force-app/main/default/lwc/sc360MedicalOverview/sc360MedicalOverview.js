import { LightningElement, wire } from 'lwc';
import getOverview from '@salesforce/apex/SC360MedicalController.getOverview';

export default class Sc360MedicalOverview extends LightningElement {
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
    return 'Acces medical indisponible.';
  }

  get kpis() {
    return this.overview?.kpis || [];
  }

  get statusSeries() {
    return this.overview?.statusDistribution || [];
  }

  get riskSeries() {
    return this.overview?.riskBands || [];
  }

  get timelineItems() {
    return this.overview?.upcomingEvents || [];
  }

  get insights() {
    return this.overview?.aiInsights || [];
  }
}
