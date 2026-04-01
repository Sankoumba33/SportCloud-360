import { LightningElement, api, wire } from 'lwc';
import getDetail from '@salesforce/apex/SC360AthleteDetailController.getDetail';

export default class Sc360AthleteDetail extends LightningElement {
  @api recordId;
  detail;
  error;

  get resolvedRecordId() {
    return this.recordId || undefined;
  }

  get isBuilderPreview() {
    return !this.recordId;
  }

  @wire(getDetail, { recordId: '$resolvedRecordId' })
  wiredDetail({ data, error }) {
    if (data) {
      this.detail = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.detail = undefined;
    }
  }

  get hasData() {
    return !!this.detail;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return '';
    if (this.error.body && this.error.body.message) return this.error.body.message;
    return 'Impossible de charger l athlete.';
  }
}
