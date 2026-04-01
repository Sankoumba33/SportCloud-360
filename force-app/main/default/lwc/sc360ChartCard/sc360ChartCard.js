import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHART_JS_LOADER from '@salesforce/resourceUrl/chartjs';

export default class Sc360ChartCard extends LightningElement {
  @api title;
  @api type = 'line';
  @api series = [];

  chart;
  hasLoaded = false;

  renderedCallback() {
    if (this.hasLoaded) {
      return;
    }
    this.hasLoaded = true;
    loadScript(this, CHART_JS_LOADER)
      .then(() => this.waitForChart(0))
      .then(() => this.buildChart())
      .catch(() => {
        this.hasLoaded = false;
      });
  }

  waitForChart(iteration) {
    return new Promise((resolve, reject) => {
      if (window.Chart) {
        resolve();
        return;
      }
      if (iteration >= 25) {
        reject(new Error('Chart.js unavailable'));
        return;
      }
      setTimeout(() => {
        this.waitForChart(iteration + 1).then(resolve).catch(reject);
      }, 120);
    });
  }

  buildChart() {
    const canvas = this.template.querySelector('canvas');
    if (!canvas || !window.Chart) {
      return;
    }

    const labels = (this.series || []).map((point) => point.label);
    const values = (this.series || []).map((point) => Number(point.value || 0));
    const gradient = canvas.getContext('2d').createLinearGradient(0, 0, 0, 180);
    gradient.addColorStop(0, 'rgba(106,149,255,0.52)');
    gradient.addColorStop(1, 'rgba(106,149,255,0.06)');

    this.chart = new window.Chart(canvas, {
      type: this.type,
      data: {
        labels,
        datasets: [
          {
            data: values,
            borderColor: '#6a95ff',
            backgroundColor: gradient,
            fill: true,
            borderWidth: 2,
            tension: 0.36
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 1000
        },
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: {
            ticks: { color: '#8fa1cf' },
            grid: { color: 'rgba(130,150,220,0.16)' }
          },
          x: {
            ticks: { color: '#8fa1cf' },
            grid: { color: 'rgba(130,150,220,0.08)' }
          }
        }
      }
    });
  }
}
