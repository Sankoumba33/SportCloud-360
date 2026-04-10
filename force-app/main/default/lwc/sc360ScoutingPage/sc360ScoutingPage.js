import { LightningElement, api, track } from 'lwc';

export default class Sc360ScoutingPage extends LightningElement {
  @api recordId;

  @track activeTab = 'overview';

  handleTabClick(event) {
    const id = event.currentTarget?.dataset?.tab;
    if (id && id !== this.activeTab) {
      this.activeTab = id;
    }
  }

  get isOverview() {
    return this.activeTab === 'overview';
  }

  get isExplorer() {
    return this.activeTab === 'explorer';
  }

  get tabOverviewClass() {
    return this.isOverview ? 'sc360-tab sc360-tab--active' : 'sc360-tab';
  }

  get tabExplorerClass() {
    return this.isExplorer ? 'sc360-tab sc360-tab--active' : 'sc360-tab';
  }
}
