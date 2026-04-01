import { LightningElement, api } from 'lwc';

export default class Sc360Kanban extends LightningElement {
  @api items = [];

  get todo() {
    return this.items.filter((item) => item.lane === 'A faire');
  }

  get doing() {
    return this.items.filter((item) => item.lane === 'En cours' || item.lane === 'Alerte');
  }

  get done() {
    return this.items.filter((item) => item.lane === 'Done');
  }
}
