/**
 * Athlete 360 - Javascript
 * Gère le système d'onglets et les animations légères d'initialisation.
 */

document.addEventListener('DOMContentLoaded', () => {

    // 1. Initialisation du Tab System
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Retirer l'état actif de tous les boutons et contenus
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            // Activer le bouton cliqué et son contenu correspondant
            btn.classList.add('active');
            const targetId = btn.getAttribute('data-target');
            const targetContent = document.getElementById(targetId);
            
            if (targetContent) {
                targetContent.classList.add('active');
            }
        });
    });

    // 2. Micro-interactions KPI Cards (effet 3D léger au survol)
    const kpiCards = document.querySelectorAll('.kpi-card');
    
    kpiCards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            // Effet visuel géré par CSS, ici on pourrait ajouter des sons ou du pre-fetching
            // ex pour LWC : dispatchEvent pour un preview tooltip approfondi
        });
    });

    // 3. Animation du cercle de Readiness Score (Simulation de chargement)
    const readinessScoreContainer = document.querySelector('.circle-progress');
    const readinessValue = document.querySelector('.score-value');
    
    if (readinessScoreContainer && readinessValue) {
        // Animation simple par JS du score pour rendre l'écran "vivant"
        let startVal = 0;
        const endVal = parseInt(readinessValue.innerText, 10) || 72;
        const duration = 1000;
        const stepTime = Math.max(Math.floor(duration / endVal), 20);
        
        let timer = setInterval(() => {
            startVal += 1;
            readinessValue.innerText = startVal;
            if (startVal >= endVal) {
                clearInterval(timer);
                readinessValue.innerText = endVal; // S'assurer de la valeur finale exacte
            }
        }, stepTime);
    }
});
