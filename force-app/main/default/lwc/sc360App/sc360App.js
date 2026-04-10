import { LightningElement, api, wire } from 'lwc';
import getAthlete360 from '@salesforce/apex/SC360DashboardController.getAthlete360';

export default class Sc360App extends LightningElement {
  @api recordId;
  @api pageType = 'athlete';
  @api theme = 'avironBayonnais';

  dashboard;
  error;

  @wire(getAthlete360, { athleteId: '$recordId' })
  wiredDashboard({ data, error }) {
    if (data) {
      this.dashboard = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.dashboard = undefined;
    }
  }

  get shellClass() {
    return `sc360-shell ${this.themeClass}`;
  }

  get themeClass() {
    if (this.theme === 'avironBayonnais') {
      return 'theme-aviron';
    }
    if (this.theme === 'lightMinimal') {
      return 'theme-light';
    }
    if (this.theme === 'neonSport') {
      return 'theme-neon';
    }
    if (this.theme === 'darkPro') {
      return 'theme-dark';
    }
    if (this.theme === 'reset') {
      return 'theme-reset';
    }
    return 'theme-aviron';
  }

  get pageLabel() {
    const map = {
      athlete: 'Athlete 360',
      scouting: 'Scouting 360',
      training: 'Training 360',
      medical: 'Medical 360',
      admin: 'Admin 360'
    };
    return map[this.pageType] || 'Athlete 360';
  }

  get hasData() {
    return !!this.dashboard;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) {
      return '';
    }
    if (this.error.body && this.error.body.message) {
      return this.error.body.message;
    }
    return 'Impossible de charger le dashboard.';
  }

  get emptyDocuments() {
    return this.hasData && (!this.dashboard.documents || this.dashboard.documents.length === 0);
  }
}
