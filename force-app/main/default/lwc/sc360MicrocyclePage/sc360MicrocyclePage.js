import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMicrocycleLinks from '@salesforce/apex/SC360RelationTabsController.getMicrocycleLinks';

export default class Sc360MicrocyclePage extends NavigationMixin(LightningElement) {
  @api recordId;
  data;
  error;

  dayColumns = [
    { label: 'Date', fieldName: 'dayDate', type: 'date' },
    { label: 'Phase', fieldName: 'phase' },
    { label: 'Focus', fieldName: 'physicalFocus' },
    { label: 'Intensité', fieldName: 'targetIntensity' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getMicrocycleLinks, { microcycleId: '$recordId' })
  wiredData({ data, error }) {
    if (data) {
      this.data = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  get days() {
    return this.data?.days || [];
  }

  get hasDays() {
    return this.days.length > 0;
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleDayAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: row.id, objectApiName: 'MicrocycleDay__c', actionName: 'view' }
      });
    }
  }
}
