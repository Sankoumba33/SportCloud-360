import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMicrocycleDayLinks from '@salesforce/apex/SC360RelationTabsController.getMicrocycleDayLinks';

export default class Sc360MicrocycleDayPage extends NavigationMixin(LightningElement) {
  @api recordId;
  data;
  error;

  athleteColumns = [
    { label: 'Athlète', fieldName: 'athleteName' },
    { label: 'Charge planifiée', fieldName: 'plannedLoad', type: 'number' },
    { label: 'Charge réelle', fieldName: 'actualLoad', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getMicrocycleDayLinks, { microcycleDayId: '$recordId' })
  wiredData({ data, error }) {
    if (data) {
      this.data = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  get athleteLinks() {
    return this.data?.athleteLinks || [];
  }

  get hasAthleteLinks() {
    return this.athleteLinks.length > 0;
  }

  get hasPlanningEvent() {
    return !!this.data?.planningEventId;
  }

  get planningEventName() {
    return this.data?.planningEventName || 'Planning Event';
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  openPlanningEvent() {
    if (!this.data?.planningEventId) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: this.data.planningEventId, objectApiName: 'PlanningEvent__c', actionName: 'view' }
    });
  }

  handleAthleteAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.athleteId) {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: row.athleteId, objectApiName: 'Athlete__c', actionName: 'view' }
      });
    }
  }
}
