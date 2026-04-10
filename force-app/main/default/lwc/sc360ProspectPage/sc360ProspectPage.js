import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProspectLinks from '@salesforce/apex/SC360RelationTabsController.getProspectLinks';

export default class Sc360ProspectPage extends NavigationMixin(LightningElement) {
  @api recordId;
  links;
  error;

  reportColumns = [
    { label: 'Étape', fieldName: 'stepType' },
    { label: 'Date', fieldName: 'reportDate', type: 'date' },
    { label: 'Rating', fieldName: 'rating', type: 'number' },
    { label: 'Synthèse', fieldName: 'summary', wrapText: true },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  snapshotColumns = [
    { label: 'Snapshot', fieldName: 'snapshotDateTime', type: 'date' },
    { label: 'Scouting', fieldName: 'scoutingScore', type: 'number' },
    { label: 'Potential', fieldName: 'potentialScore', type: 'number' },
    { label: 'Fit', fieldName: 'fitScore', type: 'number' },
    { label: 'Risk', fieldName: 'riskScore', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getProspectLinks, { prospectId: '$recordId' })
  wiredLinks({ data, error }) {
    if (data) {
      this.links = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.links = undefined;
    }
  }

  get reports() {
    return this.links?.reports || [];
  }

  get snapshots() {
    return this.links?.snapshots || [];
  }

  get hasReports() {
    return this.reports.length > 0;
  }

  get hasSnapshots() {
    return this.snapshots.length > 0;
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleReportAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'ScoutingReport__c');
    }
  }

  handleSnapshotAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'ScoutingSnapshot__c');
    }
  }

  openRecord(recordId, objectApiName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName, actionName: 'view' }
    });
  }
}
