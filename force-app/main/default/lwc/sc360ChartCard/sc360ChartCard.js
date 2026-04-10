import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHART_JS_LOADER from '@salesforce/resourceUrl/chartjs';

export default class Sc360ChartCard extends LightningElement {
  @api title;
  @api type = 'line';
  @api series = [];

  chart;
  _scriptLoaded = false;
  _lastSeriesSig = '';
  _loadPromise;

  connectedCallback() {
    this._loadPromise = loadScript(this, CHART_JS_LOADER)
      .then(() => this.waitForChart(0))
      .then(() => {
        this._scriptLoaded = true;
        return true;
      })
      .catch(() => {
        this._scriptLoaded = false;
      });
  }

  disconnectedCallback() {
    this.destroyChart();
  }

  renderedCallback() {
    if (!this._loadPromise) {
      return;
    }
    this._loadPromise.then(() => this.syncChart());
  }

  syncChart() {
    if (!this._scriptLoaded || !window.Chart) {
      return;
    }
    const series = this.series || [];
    const sig = JSON.stringify(
      series.map((p) => ({ label: p?.label, value: p?.value }))
    );
    if (sig === this._lastSeriesSig && this.chart) {
      return;
    }
    this._lastSeriesSig = sig;
    this.destroyChart();
    if (!series.length) {
      return;
    }
    this.buildChart();
  }

  destroyChart() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
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
    const isBar = this.type === 'bar';
    const ctx = canvas.getContext('2d');

    let backgroundColor;
    if (isBar) {
      backgroundColor = values.map((_, i) =>
        i === values.length - 1 ? 'rgba(239,68,68,0.55)' : 'rgba(106,149,255,0.5)'
      );
    } else {
      const gradient = ctx.createLinearGradient(0, 0, 0, 180);
      gradient.addColorStop(0, 'rgba(106,149,255,0.52)');
      gradient.addColorStop(1, 'rgba(106,149,255,0.06)');
      backgroundColor = gradient;
    }

    this.chart = new window.Chart(canvas, {
      type: this.type,
      data: {
        labels,
        datasets: [
          {
            data: values,
            borderColor: '#6a95ff',
            backgroundColor,
            fill: !isBar,
            borderWidth: isBar ? 0 : 2,
            tension: isBar ? 0 : 0.36
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 800
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
