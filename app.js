/* =============================================
   Athlete 360 — SVG gradient defs injected
   ============================================= */
(function () {
  // Inject SVG defs for gradients used by ring
  const svgNS = 'http://www.w3.org/2000/svg';
  const defs = document.createElementNS(svgNS, 'svg');
  defs.setAttribute('width', '0');
  defs.setAttribute('height', '0');
  defs.style.position = 'absolute';
  defs.innerHTML = `
    <defs>
      <linearGradient id="scoreGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#6366f1"/>
        <stop offset="100%" stop-color="#38bdf8"/>
      </linearGradient>
    </defs>`;
  document.body.prepend(defs);
})();

/* =============================================
   NAVBAR — scroll shadow
   ============================================= */
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 10);
}, { passive: true });

/* =============================================
   TOAST HELPER
   ============================================= */
const toast = document.getElementById('toast');
let toastTimer;
function showToast(msg) {
  clearTimeout(toastTimer);
  toast.textContent = msg;
  toast.classList.add('show');
  toastTimer = setTimeout(() => toast.classList.remove('show'), 3000);
}

/* =============================================
   NAV TABS
   ============================================= */
document.querySelectorAll('.nav-tab').forEach(tab => {
  tab.addEventListener('click', function () {
    document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
    this.classList.add('active');
    showToast(`Vue : ${this.textContent}`);
  });
});

/* =============================================
   NOTIFICATION BUTTON
   ============================================= */
document.getElementById('btn-notif').addEventListener('click', () => {
  showToast('🔔 3 nouvelles alertes de performance');
});

/* =============================================
   SCORE RING ANIMATION ON LOAD
   ============================================= */
function animateScoreRing() {
  const ring = document.getElementById('score-ring-fill');
  const score = 87;
  const circumference = 2 * Math.PI * 52; // r=52
  const offset = circumference * (1 - score / 100);
  // Start from full offset (empty) then transition
  ring.style.strokeDashoffset = circumference;
  requestAnimationFrame(() => {
    setTimeout(() => {
      ring.style.strokeDashoffset = offset;
    }, 200);
  });
}
animateScoreRing();

/* =============================================
   KPI CARDS — click interaction
   ============================================= */
const kpiMessages = {
  charge:    '⚡ Charge cumulée : 742 UA sur 7 jours',
  vitesse:   '🏃 Vitesse max atteinte : 34.2 km/h (PR saison)',
  intensite: '🔥 Intensité moyenne à 78% FC max',
  blessure:  '🛡️ Risque faible — Surveillance standard maintenue',
};
document.querySelectorAll('.kpi-card').forEach(card => {
  card.addEventListener('click', function () {
    const key = this.dataset.kpi;
    if (kpiMessages[key]) showToast(kpiMessages[key]);
  });
});

/* =============================================
   CHART.JS — Performance Trend
   ============================================= */
const ctx = document.getElementById('performanceChart').getContext('2d');

const labels7d  = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const labels30d = ['S1','S2','S3','S4'];
const labels90d = ['Jan','Fév','Mar'];

const datasets7d = {
  charge:     [620, 710, 680, 760, 742, 690, 720],
  intensite:  [72,  80,  75,  85,  78,  70,  76],
  recup:      [85,  78,  82,  74,  80,  88,  83],
};
const datasets30d = {
  charge:     [650, 700, 742, 690],
  intensite:  [74,  77,  80,  76],
  recup:      [82,  80,  78,  84],
};
const datasets90d = {
  charge:     [680, 710, 742],
  intensite:  [73,  76,  78],
  recup:      [85,  81,  80],
};

function makeGradient(ctx, color) {
  const grad = ctx.createLinearGradient(0, 0, 0, 240);
  grad.addColorStop(0, color.replace(')', ', 0.35)').replace('rgb', 'rgba'));
  grad.addColorStop(1, color.replace(')', ', 0.0)').replace('rgb', 'rgba'));
  return grad;
}

const chart = new Chart(ctx, {
  type: 'line',
  data: {
    labels: labels7d,
    datasets: [
      {
        label: 'Charge',
        data: datasets7d.charge,
        borderColor: '#38bdf8',
        backgroundColor: 'rgba(56,189,248,0.08)',
        borderWidth: 2.5,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: '#38bdf8',
        tension: 0.45,
        fill: true,
        yAxisID: 'y',
      },
      {
        label: 'Intensité',
        data: datasets7d.intensite,
        borderColor: '#f97316',
        backgroundColor: 'rgba(249,115,22,0.07)',
        borderWidth: 2.5,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: '#f97316',
        tension: 0.45,
        fill: true,
        yAxisID: 'y1',
      },
      {
        label: 'Récupération',
        data: datasets7d.recup,
        borderColor: '#22c55e',
        backgroundColor: 'rgba(34,197,94,0.07)',
        borderWidth: 2.5,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: '#22c55e',
        tension: 0.45,
        fill: true,
        yAxisID: 'y1',
        borderDash: [5, 3],
      },
    ],
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    animation: { duration: 800, easing: 'easeInOutQuart' },
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1a2236',
        titleColor: '#f1f5f9',
        bodyColor: '#7f8ea3',
        borderColor: 'rgba(255,255,255,0.1)',
        borderWidth: 1,
        padding: 12,
        cornerRadius: 10,
        callbacks: {
          label: ctx => {
            const unit = ctx.datasetIndex === 0 ? ' UA' : '%';
            return ` ${ctx.dataset.label}: ${ctx.parsed.y}${unit}`;
          },
        },
      },
    },
    scales: {
      x: {
        grid: { color: 'rgba(255,255,255,0.04)' },
        ticks: { color: '#4b5563', font: { size: 11, family: 'Inter' } },
        border: { color: 'rgba(255,255,255,0.07)' },
      },
      y: {
        position: 'left',
        grid: { color: 'rgba(255,255,255,0.04)' },
        ticks: { color: '#4b5563', font: { size: 11, family: 'Inter' } },
        border: { color: 'rgba(255,255,255,0.07)' },
        title: { display: true, text: 'Charge (UA)', color: '#4b5563', font: { size: 10 } },
      },
      y1: {
        position: 'right',
        grid: { drawOnChartArea: false },
        ticks: {
          color: '#4b5563',
          font: { size: 11, family: 'Inter' },
          callback: v => v + '%',
        },
        border: { color: 'rgba(255,255,255,0.07)' },
      },
    },
  },
});

/* Chart period chips */
const chipData = {
  '7d':  { labels: labels7d,  data: datasets7d },
  '30d': { labels: labels30d, data: datasets30d },
  '90d': { labels: labels90d, data: datasets90d },
};

['7d', '30d', '90d'].forEach(period => {
  document.getElementById(`chip-${period}`).addEventListener('click', function () {
    document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    this.classList.add('active');

    const d = chipData[period];
    chart.data.labels = d.labels;
    chart.data.datasets[0].data = d.data.charge;
    chart.data.datasets[1].data = d.data.intensite;
    chart.data.datasets[2].data = d.data.recup;
    chart.update();
  });
});

/* =============================================
   AI INSIGHTS — REFRESH BUTTON
   ============================================= */
const aiRefresh = document.getElementById('btn-refresh-ai');
aiRefresh.addEventListener('click', function () {
  this.textContent = '⌛ Analyse…';
  this.disabled = true;
  setTimeout(() => {
    this.textContent = '↻ Actualiser';
    this.disabled = false;
    showToast('🤖 Insights IA mis à jour avec succès');
  }, 1800);
});

/* =============================================
   ADD EVENT button
   ============================================= */
document.getElementById('btn-add-event').addEventListener('click', () => {
  showToast('➕ Fonctionnalité d\'ajout d\'événement à venir');
});

/* =============================================
   INSIGHT CARDS — Confidence bars animation
   ============================================= */
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.querySelectorAll('.conf-fill').forEach(bar => {
        bar.style.width = bar.style.width; // trigger reflow
      });
    }
  });
}, { threshold: 0.2 });

document.querySelectorAll('.insight-card').forEach(card => observer.observe(card));

/* =============================================
   KPI BAR ANIMATIONS ON LOAD
   ============================================= */
function animateKPIs() {
  document.querySelectorAll('.kpi-bar-fill').forEach(bar => {
    const target = bar.style.width;
    bar.style.width = '0%';
    setTimeout(() => { bar.style.width = target; }, 400);
  });
}
window.addEventListener('load', animateKPIs);
