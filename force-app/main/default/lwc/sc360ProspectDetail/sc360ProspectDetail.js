import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDetail from '@salesforce/apex/SC360ProspectDetailController.getDetail';
import getStepReports from '@salesforce/apex/SC360ProspectDetailController.getStepReports';
import saveStepReport from '@salesforce/apex/SC360ProspectDetailController.saveStepReport';

const STEP_OPTIONS = [
  { label: 'Video Scouting', value: 'Video Scouting' },
  { label: 'Live Scouting', value: 'Live Scouting' },
  { label: 'Data Check', value: 'Data Check' },
  { label: 'Reference Check', value: 'Reference Check' },
  { label: 'Background Check', value: 'Background Check' }
];

export default class Sc360ProspectDetail extends LightningElement {
  @api recordId;
  detail;
  reports = [];
  error;
  saving = false;

  form = {
    stepType: 'Video Scouting',
    matchSelection: '',
    summary: '',
    comparisonNotes: '',
    referenceContacts: '',
    socialNetworks: '',
    rating: null
  };

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

  @wire(getStepReports, { prospectId: '$resolvedRecordId' })
  wiredReports({ data }) {
    if (data) {
      this.reports = data;
    }
  }

  get stepOptions() {
    return STEP_OPTIONS;
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
    return 'Impossible de charger le prospect.';
  }

  get insights() {
    return this.detail?.insights || [];
  }

  get apiSeasonKpis() {
    return this.detail?.apiSeasonKpis || [];
  }

  get hasApiSeasonKpis() {
    return (this.apiSeasonKpis?.length || 0) > 0;
  }

  handleInput(event) {
    const { name, value } = event.target;
    this.form = { ...this.form, [name]: value };
  }

  async handleSaveStep() {
    if (!this.recordId || !this.form.stepType) {
      return;
    }
    this.saving = true;
    try {
      await saveStepReport({
        prospectId: this.recordId,
        stepType: this.form.stepType,
        matchSelection: this.form.matchSelection,
        summary: this.form.summary,
        comparisonNotes: this.form.comparisonNotes,
        referenceContacts: this.form.referenceContacts,
        socialNetworks: this.form.socialNetworks,
        rating: this.form.rating ? Number(this.form.rating) : null
      });
      this.dispatchEvent(new ShowToastEvent({ title: 'OK', message: 'Etape scouting enregistree.', variant: 'success' }));
      this.form = {
        stepType: this.form.stepType,
        matchSelection: '',
        summary: '',
        comparisonNotes: '',
        referenceContacts: '',
        socialNetworks: '',
        rating: null
      };
    } catch (e) {
      const message = e?.body?.message || 'Erreur enregistrement.';
      this.dispatchEvent(new ShowToastEvent({ title: 'Erreur', message, variant: 'error' }));
    } finally {
      this.saving = false;
    }
  }
}
