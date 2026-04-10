import { LightningElement, api } from 'lwc';

const FORMATION_MAP = {
  '4-3-3': ['GK', 'RB', 'RCB', 'LCB', 'LB', 'DM', 'CM', 'AM', 'RW', 'ST', 'LW'],
  '4-2-3-1': ['GK', 'RB', 'RCB', 'LCB', 'LB', 'DM', 'CM', 'RW', 'AM', 'LW', 'ST'],
  '4-4-2': ['GK', 'RB', 'RCB', 'LCB', 'LB', 'RM', 'CM', 'CM', 'LM', 'ST', 'ST'],
  '3-5-2': ['GK', 'RCB', 'CB', 'LCB', 'RWB', 'CM', 'DM', 'AM', 'LWB', 'ST', 'ST'],
  '3-4-3': ['GK', 'RCB', 'CB', 'LCB', 'RM', 'CM', 'CM', 'LM', 'RW', 'ST', 'LW']
};

const COORDS = [
  { x: 50, y: 90 },
  { x: 84, y: 73 },
  { x: 63, y: 74 },
  { x: 37, y: 74 },
  { x: 16, y: 73 },
  { x: 67, y: 55 },
  { x: 50, y: 55 },
  { x: 33, y: 55 },
  { x: 78, y: 35 },
  { x: 50, y: 28 },
  { x: 22, y: 35 }
];

export default class Sc360LineupPitch extends LightningElement {
  @api formation = '4-3-3';
  @api players = [];
  @api showBench;

  showNames = true;
  showRatings = true;
  highlightThreat = true;

  get benchPlayers() {
    return (this.players || []).filter((p) => !(p?.starter === true || p?.starter === 'true'));
  }

  get hasBench() {
    return this.showBenchEnabled && this.benchPlayers.length > 0;
  }

  get showBenchEnabled() {
    return this.showBench !== false && this.showBench !== 'false';
  }

  get startersCount() {
    return (this.players || []).filter((p) => p?.starter === true || p?.starter === 'true').length;
  }

  get threatCount() {
    return (this.players || []).filter((p) => (p?.threatTags || '').trim().length > 0).length;
  }

  get compactFormationLabel() {
    return this.formation || 'N/A';
  }

  get nodes() {
    const starters = (this.players || []).filter((p) => p?.starter === true || p?.starter === 'true');
    const remaining = [...starters];
    const slots = FORMATION_MAP[this.formation] || FORMATION_MAP['4-3-3'];
    return slots.map((slot, index) => {
      const foundIndex = remaining.findIndex((p) => (p.position || '').toUpperCase() === slot.toUpperCase());
      const player = foundIndex >= 0 ? remaining.splice(foundIndex, 1)[0] : remaining.shift();
      const rating = Number(player?.rating);
      const threatTags = player?.threatTags || '';
      const hasThreat = threatTags.trim().length > 0;
      const coord = COORDS[index] || { x: 50, y: 50 };
      return {
        key: `n-${index}`,
        leftStyle: `left:${coord.x}%; top:${coord.y}%;`,
        cssClass: this.computeNodeClass({ rating, hasThreat }),
        name: player?.playerName || '—',
        pos: player?.position || slot,
        rating: Number.isFinite(rating) ? rating.toFixed(1) : null,
        minutes: player?.minutes,
        threatTags,
        hasThreat
      };
    });
  }

  get benchRows() {
    return this.benchPlayers.map((p, i) => ({
      key: `b-${i}`,
      name: p?.playerName || '—',
      position: p?.position || 'N/A',
      rating: p?.rating,
      minutes: p?.minutes,
      threatTags: p?.threatTags || ''
    }));
  }

  get showToggles() {
    return true;
  }

  handleToggleNames(event) {
    this.showNames = event.target.checked;
  }

  handleToggleRatings(event) {
    this.showRatings = event.target.checked;
  }

  handleToggleThreat(event) {
    this.highlightThreat = event.target.checked;
  }

  computeNodeClass({ rating, hasThreat }) {
    const classes = ['player'];
    if (Number.isFinite(rating) && rating >= 7.5) classes.push('rating-hot');
    else if (Number.isFinite(rating) && rating >= 6.5) classes.push('rating-mid');
    else if (Number.isFinite(rating)) classes.push('rating-low');
    if (this.highlightThreat && hasThreat) classes.push('threat');
    return classes.join(' ');
  }
}
