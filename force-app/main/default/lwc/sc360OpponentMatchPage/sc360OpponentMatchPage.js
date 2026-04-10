import { LightningElement, api, wire } from 'lwc';
import getOpponentMatch from '@salesforce/apex/SC360MatchIntelligenceController.getOpponentMatch';

export default class Sc360OpponentMatchPage extends LightningElement {
  @api recordId;
  payload;
  error;

  lineupColumns = [
    { label: 'Joueur', fieldName: 'playerName' },
    { label: 'Pos', fieldName: 'position' },
    { label: 'Titulaire', fieldName: 'starter', type: 'boolean' },
    { label: 'Minutes', fieldName: 'minutes', type: 'number' },
    { label: 'Rating', fieldName: 'rating', type: 'number' },
    { label: 'Threat Tags', fieldName: 'threatTags', wrapText: true }
  ];

  @wire(getOpponentMatch, { opponentMatchId: '$recordId' })
  wiredPayload({ data, error }) {
    if (data) {
      this.payload = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.payload = undefined;
    }
  }

  get match() {
    return this.payload?.match;
  }

  get opponent() {
    return this.payload?.opponent;
  }

  get lineup() {
    return this.payload?.lineup || [];
  }

  get starters() {
    return this.lineup.filter((x) => x.starter);
  }

  get benchCount() {
    return this.lineup.filter((x) => !x.starter).length;
  }

  get threatStartersCount() {
    return this.starters.filter((x) => (x?.threatTags || '').trim().length > 0).length;
  }

  get formation() {
    return this.match?.lineupFormation || this.opponent?.preferredFormation || '4-3-3';
  }

  get rawPayload() {
    return this.payload?.rawPayload || '';
  }

  get errorMessage() {
    return this.error?.body?.message || this.error?.message || '';
  }
}
