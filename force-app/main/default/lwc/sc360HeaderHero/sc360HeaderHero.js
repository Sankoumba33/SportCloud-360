import { LightningElement, api } from 'lwc';

export default class Sc360HeaderHero extends LightningElement {
  @api pageLabel;
  @api athleteName;
  @api externalId;
  @api syncAt;
}
