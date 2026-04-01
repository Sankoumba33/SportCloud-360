import { LightningElement, api } from 'lwc';

export default class Sc360Timeline extends LightningElement {
  @api items = [];

  get hasItems() {
    return this.items && this.items.length > 0;
  }
}
