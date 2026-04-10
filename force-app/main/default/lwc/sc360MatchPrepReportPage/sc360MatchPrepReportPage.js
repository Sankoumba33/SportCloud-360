import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMatchPrepReport from '@salesforce/apex/SC360MatchIntelligenceController.getMatchPrepReport';

export default class Sc360MatchPrepReportPage extends NavigationMixin(LightningElement) {
  @api recordId;
  report;
  error;

  recentMatchColumns = [
    { label: 'Date', fieldName: 'matchDate', type: 'date' },
    { label: 'Compétition', fieldName: 'competition' },
    { label: 'Résultat', fieldName: 'result' },
    { label: 'Score', fieldName: 'scoreLabel' },
    { label: 'xG', fieldName: 'xgLabel' }
  ];

  @wire(getMatchPrepReport, { reportId: '$recordId' })
  wiredReport({ data, error }) {
    if (data) {
      this.report = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.report = undefined;
    }
  }

  get headerClass() {
    const level = (this.report?.riskLevel || '').toLowerCase();
    return `hero ${level}`;
  }

  get recentMatches() {
    return (this.report?.recentOpponentMatches || []).map((m) => ({
      ...m,
      scoreLabel: `${m.goalsFor ?? '-'}-${m.goalsAgainst ?? '-'}`,
      xgLabel: `${m.xgFor ?? '-'} / ${m.xgAgainst ?? '-'}`
    }));
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  openPlanningEvent() {
    if (!this.report?.planningEventId) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: this.report.planningEventId, objectApiName: 'PlanningEvent__c', actionName: 'view' }
    });
  }

  openOpponent() {
    if (!this.report?.opponent?.id) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: this.report.opponent.id, objectApiName: 'Opponent__c', actionName: 'view' }
    });
  }
}
