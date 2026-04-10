import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAthleteLinks from '@salesforce/apex/SC360RelationTabsController.getAthleteLinks';

export default class Sc360AthleteRelations extends NavigationMixin(LightningElement) {
  @api recordId;

  data;
  error;

  injuryColumns = [
    { label: 'Zone', fieldName: 'bodyZone' },
    { label: 'Statut', fieldName: 'status' },
    { label: 'Date blessure', fieldName: 'injuryDate', type: 'date' },
    { label: 'Retour prévu', fieldName: 'expectedReturnDate', type: 'date' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  microColumns = [
    { label: 'Jour', fieldName: 'dayLabel' },
    { label: 'Phase', fieldName: 'phase' },
    { label: 'Charge planifiée', fieldName: 'plannedLoad', type: 'number' },
    { label: 'Charge réelle', fieldName: 'actualLoad', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getAthleteLinks, { athleteId: '$recordId' })
  wiredData({ data, error }) {
    if (data) {
      this.data = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  get injuries() {
    return this.data?.injuries || [];
  }

  get microcycleLinks() {
    return this.data?.microcycleLinks || [];
  }

  get hasInjuries() {
    return this.injuries.length > 0;
  }

  get hasMicrocycleLinks() {
    return this.microcycleLinks.length > 0;
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleInjuryRowAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'Injury__c');
    }
  }

  handleMicroRowAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'AthleteMicrocycleDay__c');
    }
  }

  openRecord(recordId, objectApiName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName, actionName: 'view' }
    });
  }
}
