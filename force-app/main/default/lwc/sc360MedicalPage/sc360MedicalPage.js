import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getHighRiskAthletes from '@salesforce/apex/SC360MedicalController.getHighRiskAthletes';

export default class Sc360MedicalPage extends NavigationMixin(LightningElement) {
  @api recordId;

  @track activeTab = 'overview';

  @track riskRows = [];
  riskError;
  riskLoaded = false;

  columns = [
    { label: 'Athlète', fieldName: 'name', type: 'text' },
    {
      label: 'Risque blessure',
      fieldName: 'injuryRisk',
      type: 'number',
      typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 1 }
    },
    {
      label: 'Readiness',
      fieldName: 'readiness',
      type: 'number',
      typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 }
    },
    { label: 'Statut', fieldName: 'statusLabel', type: 'text' },
    {
      type: 'action',
      typeAttributes: {
        rowActions: [{ label: 'Ouvrir fiche', name: 'open' }],
        menuAlignment: 'right'
      }
    }
  ];

  @wire(getHighRiskAthletes, { rowLimit: 80 })
  wiredRisk({ data, error }) {
    this.riskLoaded = true;
    if (data) {
      this.riskRows = data;
      this.riskError = undefined;
    } else if (error) {
      this.riskError = error;
      this.riskRows = [];
    }
  }

  handleTabClick(event) {
    const id = event.currentTarget?.dataset?.tab;
    if (id && id !== this.activeTab) {
      this.activeTab = id;
    }
  }

  handleRiskRow(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    if (action.name === 'open' && row.athleteId) {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: row.athleteId, objectApiName: 'Athlete__c', actionName: 'view' }
      });
    }
  }

  get isOverview() {
    return this.activeTab === 'overview';
  }

  get isRisk() {
    return this.activeTab === 'risk';
  }

  get tabOverviewClass() {
    return this.isOverview ? 'sc360-tab sc360-tab--active' : 'sc360-tab';
  }

  get tabRiskClass() {
    return this.isRisk ? 'sc360-tab sc360-tab--active' : 'sc360-tab';
  }

  get riskLoading() {
    return this.isRisk && !this.riskLoaded;
  }

  get riskErrorMessage() {
    if (!this.riskError) {
      return '';
    }
    return this.riskError.body?.message || this.riskError.message || 'Liste indisponible.';
  }

  get hasRiskRows() {
    return this.riskRows && this.riskRows.length > 0;
  }
}
