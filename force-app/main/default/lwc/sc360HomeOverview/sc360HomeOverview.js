import { LightningElement, wire } from 'lwc';
import getOverview from '@salesforce/apex/SC360HomeController.getOverview';

export default class Sc360HomeOverview extends LightningElement {
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

  get kpis() {
    return this.overview?.kpis || [];
  }

  get statusSeries() {
    return this.overview?.statusDistribution || [];
  }

  get squadSeries() {
    return this.overview?.squadDistribution || [];
  }

  get timelineItems() {
    return this.overview?.upcomingEvents || [];
  }

  get insights() {
    return this.overview?.aiInsights || [];
  }

  get qualityRows() {
    if (!this.overview?.dataQuality) {
      return [];
    }
    const q = this.overview.dataQuality;
    return [
      { key: 'ext', label: 'Athletes sans External ID', value: q.athletesWithoutExternalId },
      { key: 'sync', label: 'Sync > 24h', value: q.staleSyncOver24h },
      { key: 'ready', label: 'Readiness manquant', value: q.missingReadiness }
    ];
  }
}
