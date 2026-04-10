import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRtpPhaseContext from '@salesforce/apex/SC360RelationTabsController.getRtpPhaseContext';

export default class Sc360RtpPhasePage extends NavigationMixin(LightningElement) {
  @api recordId;
  data;
  error;

  @wire(getRtpPhaseContext, { rtpPhaseId: '$recordId' })
  wiredContext({ data, error }) {
    if (data) {
      this.data = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  get hasInjury() {
    return !!this.data?.injuryId;
  }

  get hasAthlete() {
    return !!this.data?.athleteId;
  }

  get injuryLabel() {
    return this.data?.injuryName || 'Injury';
  }

  get athleteLabel() {
    return this.data?.athleteName || 'Athlete';
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  openInjury() {
    if (this.data?.injuryId) {
      this.openRecord(this.data.injuryId, 'Injury__c');
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
