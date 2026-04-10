/**
 * Medical 360 - Javascript
 * Gère le système d'onglets et l'animation des graphes pour la fiche clinique.
 */

document.addEventListener('DOMContentLoaded', () => {

    // 1. Navigation par onglets fluide
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Nettoyage des états actifs
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            // Activation
            btn.classList.add('active');
            const targetId = btn.getAttribute('data-target');
            const targetContent = document.getElementById(targetId);
            
            if (targetContent) {
                targetContent.classList.add('active');
                
                // Si on ouvre l'onglet Charge & Risque, on déclenche l'animation des barres
                if (targetId === 'tab-load') {
                    animateLoadChart();
                }
            }
        });
    });

    // 2. Fonction d'animation du Mockup Chart (Délai interactif)
    function animateLoadChart() {
        const fills = document.querySelectorAll('.t-bar .fill');
        fills.forEach(fill => {
            const originalHeight = fill.style.height;
            // On le réinitialise brièvement
            fill.style.transition = 'none';
            fill.style.height = '0%';
            
            // Puis on déclenche l'animation
            setTimeout(() => {
                fill.style.transition = 'height 1s cubic-bezier(0.4,0,0.2,1)';
                fill.style.height = originalHeight;
            }, 50);
        });
    }

});
