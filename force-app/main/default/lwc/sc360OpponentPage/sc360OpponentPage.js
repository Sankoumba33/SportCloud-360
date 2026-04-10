import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpponentHub from '@salesforce/apex/SC360MatchIntelligenceController.getOpponentHub';

export default class Sc360OpponentPage extends NavigationMixin(LightningElement) {
  @api recordId;
  hub;
  error;

  matchColumns = [
    { label: 'Date', fieldName: 'matchDate', type: 'date' },
    { label: 'Compétition', fieldName: 'competition' },
    { label: 'H/A', fieldName: 'homeAway' },
    { label: 'Résultat', fieldName: 'result' },
    { label: 'Score', fieldName: 'scoreLabel' },
    { label: 'xG', fieldName: 'xgLabel' },
    { label: 'PPDA', fieldName: 'ppda', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  patternColumns = [
    { label: 'Pattern', fieldName: 'patternType' },
    { label: 'Fréquence %', fieldName: 'frequency', type: 'percent' },
    { label: 'Confiance %', fieldName: 'confidence', type: 'percent' },
    { label: 'Evidence', fieldName: 'evidenceMatchIds', wrapText: true }
  ];

  reportColumns = [
    { label: 'Match', fieldName: 'planningEventName' },
    { label: 'Risque', fieldName: 'riskLevel' },
    { label: 'Statut', fieldName: 'status' },
    { label: 'Confiance %', fieldName: 'confidenceScore', type: 'percent' },
    { label: 'Généré le', fieldName: 'generatedAt', type: 'date' },
    { type: 'button', typeAttributes: { label: 'Ouvrir', name: 'open', variant: 'base' } }
  ];

  @wire(getOpponentHub, { opponentId: '$recordId' })
  wiredHub({ data, error }) {
    if (data) {
      this.hub = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.hub = undefined;
    }
  }

  get header() {
    return this.hub?.header;
  }

  get matches() {
    return (this.hub?.recentMatches || []).map((m) => ({
      ...m,
      scoreLabel: `${m.goalsFor ?? '-'}-${m.goalsAgainst ?? '-'}`,
      xgLabel: `${m.xgFor ?? '-'} / ${m.xgAgainst ?? '-'}`
    }));
  }

  get patterns() {
    return this.hub?.tacticalPatterns || [];
  }

  get reports() {
    return this.hub?.prepReports || [];
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }

  handleMatchAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'OpponentMatch__c');
    }
  }

  handleReportAction(event) {
    const row = event.detail.row;
    if (event.detail.action?.name === 'open' && row?.id) {
      this.openRecord(row.id, 'MatchPrepReport__c');
    }
  }

  openRecord(recordId, objectApiName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName, actionName: 'view' }
    });
  }
}
