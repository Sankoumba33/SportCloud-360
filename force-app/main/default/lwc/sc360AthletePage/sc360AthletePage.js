import { LightningElement, api } from 'lwc';

export default class Sc360AthletePage extends LightningElement {
  @api recordId;
  activeTab = 'performance';

  get isPerformance() {
    return this.activeTab === 'performance';
  }

  get isMedical() {
    return this.activeTab === 'medical';
  }

  get isRelations() {
    return this.activeTab === 'relations';
  }

  handleTab(event) {
    const tab = event.target?.value;
    if (tab && tab !== this.activeTab) {
      this.activeTab = tab;
    }
  }
}
