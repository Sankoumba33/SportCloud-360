import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSquadLinks from '@salesforce/apex/SC360RelationTabsController.getSquadLinks';

export default class Sc360SquadPage extends NavigationMixin(LightningElement) {
  @api recordId;
  links;
  error;

  assignmentColumns = [
    { label: 'Athlète', fieldName: 'athleteName' },
    { label: 'Début', fieldName: 'startDate', type: 'date' },
    { label: 'Fin', fieldName: 'endDate', type: 'date' },
    { label: 'Raison', fieldName: 'reason' },
    { type: 'button', typeAttributes: { label: 'Ouvrir athlète', name: 'openAthlete', variant: 'base' } }
  ];

  planningColumns = [
    { label: 'Nom', fieldName: 'name' },
    { label: 'Type', fieldName: 'eventType' },
    { label: 'Début', fieldName: 'startDateTime', type: 'date' },
    { label: 'Fin', fieldName: 'endDateTime', type: 'date' },
    { label: 'Statut', fieldName: 'status' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'openEvent', variant: 'base' } }
  ];

  athleteColumns = [
    { label: 'Athlète', fieldName: 'name' },
    { label: 'Sport', fieldName: 'sport' },
    { label: 'Statut', fieldName: 'status' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'openAthlete', variant: 'base' } }
  ];

  @wire(getSquadLinks, { squadId: '$recordId' })
  wiredLinks({ data, error }) {
    if (data) {
      this.links = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.links = undefined;
    }
  }

  get assignments() {
    return this.links?.assignments || [];
  }

  get planningEvents() {
    return this.links?.planningEvents || [];
  }

  get athletes() {
    return this.links?.athletes || [];
  }

  get hasAssignments() {
    return this.assignments.length > 0;
  }

  get hasPlanningEvents() {
    return this.planningEvents.length > 0;
  }

  get hasAthletes() {
    return this.athletes.length > 0;
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleAssignmentAction(event) {
    const { action, row } = event.detail;
    if (action?.name === 'openAthlete' && row?.athleteId) {
      this.openRecord(row.athleteId, 'Athlete__c');
    }
  }

  handlePlanningAction(event) {
    const { action, row } = event.detail;
    if (action?.name === 'openEvent' && row?.id) {
      this.openRecord(row.id, 'PlanningEvent__c');
    }
  }

  handleAthleteAction(event) {
    const { action, row } = event.detail;
    if (action?.name === 'openAthlete' && row?.id) {
      this.openRecord(row.id, 'Athlete__c');
    }
  }

  openRecord(recordId, objectApiName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName, actionName: 'view' }
    });
  }
}
