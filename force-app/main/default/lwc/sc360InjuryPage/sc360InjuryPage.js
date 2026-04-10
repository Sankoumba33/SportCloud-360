import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getInjuryLinks from '@salesforce/apex/SC360RelationTabsController.getInjuryLinks';

export default class Sc360InjuryPage extends NavigationMixin(LightningElement) {
  @api recordId;

  data;
  error;

  rtpColumns = [
    { label: 'Titre', fieldName: 'title' },
    { label: 'Statut', fieldName: 'phaseStatus' },
    { label: 'Date cible', fieldName: 'targetDate', type: 'date' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getInjuryLinks, { injuryId: '$recordId' })
  wiredLinks({ data, error }) {
    if (data) {
      this.data = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  get rtpPhases() {
    return this.data?.rtpPhases || [];
  }

  get hasRtpPhases() {
    return this.rtpPhases.length > 0;
  }

  get hasAthlete() {
    return !!this.data?.athleteId;
  }

  get athleteName() {
    return this.data?.athleteName || 'Athlète';
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleRtpAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'RTPPhase__c');
    }
  }

  openAthlete() {
    if (this.data?.athleteId) {
      this.openRecord(this.data.athleteId, 'Athlete__c');
    }
  }

  openRecord(recordId, objectApiName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName, actionName: 'view' }
    });
  }
}
