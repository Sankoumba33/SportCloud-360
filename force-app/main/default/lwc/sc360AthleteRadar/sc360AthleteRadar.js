import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHART_JS from '@salesforce/resourceUrl/chartjs';
import getRadar from '@salesforce/apex/SC360AthleteRadarController.getRadar';

export default class Sc360AthleteRadar extends LightningElement {
    @api recordId;

    radarPayload;
    error;
    chart;
    scriptLoaded = false;

    @wire(getRadar, { athleteId: '$recordId' })
    wiredRadar({ data, error }) {
        if (data) {
            this.radarPayload = data;
            this.error = undefined;
            this.destroyChart();
            this.scheduleBuild();
        } else if (error) {
            this.error = error;
            this.radarPayload = undefined;
            this.destroyChart();
        } else {
            this.radarPayload = undefined;
            this.error = undefined;
            this.destroyChart();
        }
    }

    scheduleBuild() {
        Promise.resolve().then(() => {
            requestAnimationFrame(() => {
                this.ensureScript()
                    .then(() => this.buildRadar())
                    .catch(() => {});
            });
        });
    }

    disconnectedCallback() {
        this.destroyChart();
    }

    ensureScript() {
        if (this.scriptLoaded && window.Chart) {
            return Promise.resolve();
        }
        return loadScript(this, CHART_JS)
            .then(() => this.waitForChart(0))
            .then(() => {
                this.scriptLoaded = true;
            });
    }

    waitForChart(iteration) {
        return new Promise((resolve, reject) => {
            if (window.Chart) {
                resolve();
                return;
            }
            if (iteration >= 30) {
                reject(new Error('Chart.js indisponible'));
                return;
            }
            setTimeout(() => {
                this.waitForChart(iteration + 1).then(resolve).catch(reject);
            }, 100);
        });
    }

    buildRadar() {
        const canvas = this.template.querySelector('canvas.radar-canvas');
        if (!canvas || !window.Chart || !this.radarPayload) {
            return;
        }

        this.destroyChart();

        const labels = this.radarPayload.axisLabels || [];
        const values = (this.radarPayload.values || []).map((v) => Number(v || 0));

        this.chart = new window.Chart(canvas, {
            type: 'radar',
            data: {
                labels,
                datasets: [
                    {
                        label: this.radarPayload.athleteName || 'Profil',
                        data: values,
                        borderColor: 'rgba(4, 120, 87, 0.95)',
                        backgroundColor: 'rgba(4, 120, 87, 0.22)',
                        borderWidth: 2,
                        pointBackgroundColor: 'rgba(4, 120, 87, 1)',
                        pointBorderColor: '#fff',
                        pointHoverBackgroundColor: '#fff',
                        pointHoverBorderColor: 'rgba(4, 120, 87, 1)'
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: { duration: 900, easing: 'easeOutQuart' },
                plugins: {
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { color: '#3e3e3c', font: { size: 11 } }
                    },
                    tooltip: {
                        callbacks: {
                            label(ctx) {
                                const v = ctx.parsed.r != null ? ctx.parsed.r : ctx.raw;
                                return ` ${v.toFixed(1)} / 100`;
                            }
                        }
                    }
                },
                scales: {
                    r: {
                        angleLines: { color: 'rgba(0,0,0,0.08)' },
                        grid: { color: 'rgba(0,0,0,0.08)' },
                        pointLabels: {
                            color: '#444',
                            font: { size: 10 }
                        },
                        suggestedMin: 0,
                        suggestedMax: 100,
                        ticks: {
                            stepSize: 20,
                            showLabelBackdrop: false,
                            color: '#706e6b'
                        }
                    }
                }
            }
        });
    }

    destroyChart() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = undefined;
        }
    }

    get hasRadar() {
        return this.radarPayload && (this.radarPayload.values || []).length > 0;
    }

    get footnote() {
        return this.radarPayload?.footnote || '';
    }

    get errorMessage() {
        if (!this.error) {
            return '';
        }
        if (this.error.body && this.error.body.message) {
            return this.error.body.message;
        }
        return 'Radar indisponible.';
    }
}
