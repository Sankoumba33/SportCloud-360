import { LightningElement, wire } from 'lwc';
import getOverview from '@salesforce/apex/SC360ScoutingController.getOverview';
import getPipelineKanban from '@salesforce/apex/SC360ScoutingEnhancedController.getPipelineKanban';

export default class Sc360ScoutingOverview extends LightningElement {
  overview;
  error;
  kanbanData;

  @wire(getOverview)
  wiredOverview({ data, error }) {
    if (data) {
      this.overview = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.overview = undefined;
    }
  }

  @wire(getPipelineKanban)
  wiredKanban({ data, error }) {
    if (data) {
      // Transform incoming Apex grouping into the format accepted by c-sc360-kanban
      // Assuming c-sc360-kanban takes an array of items with a 'status' or 'lane' property.
      let flattenedItems = [];
      data.forEach(lane => {
          if (lane.items) {
              lane.items.forEach(item => {
                  flattenedItems.push({
                      id: item.id,
                      title: item.title,
                      subtitle: item.position || '',
                      status: lane.status, // Link to lane via status value
                      variant: 'info'
                  });
              });
          }
      });
      this.kanbanData = flattenedItems;
    }
  }

  get hasData() {
    return !!this.overview;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return '';
    if (this.error.body && this.error.body.message) return this.error.body.message;
    return 'Acces scouting indisponible.';
  }

  get kpis() {
    return this.overview?.kpis || [];
  }

  get statusSeries() {
    return this.overview?.statusDistribution || [];
  }

  get positionSeries() {
    return this.overview?.positionDistribution || [];
  }

  get insights() {
    return this.overview?.aiInsights || [];
  }
}
