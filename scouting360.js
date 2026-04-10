/**
 * Scouting 360 - Javascript
 * Gère le système d'onglets pour la fiche prospect.
 */

document.addEventListener('DOMContentLoaded', () => {

    // 1. Initialisation du Tab System
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Retirer l'état actif de tous
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            // Activer le bouton ciblé
            btn.classList.add('active');
            const targetId = btn.getAttribute('data-target');
            const targetContent = document.getElementById(targetId);
            
            if (targetContent) {
                targetContent.classList.add('active');
            }
        });
    });

    // 2. Mockup Animation: Barres de comparaison progressives
    // Pour simuler l'affichage depuis une API LWC
    const compareBarsContainer = document.getElementById('tab-compare');
    if (compareBarsContainer) {
        // Observer quand l'onglet comparaison est affiché (si IntersectionObserver ou via le click tab)
        const compareBtn = document.querySelector('[data-target="tab-compare"]');
        if (compareBtn) {
            compareBtn.addEventListener('click', () => {
                const fills = document.querySelectorAll('.cb-fill');
                fills.forEach(fill => {
                    const finalWidth = fill.style.width;
                    fill.style.width = '0%'; // Reset
                    setTimeout(() => {
                        fill.style.width = finalWidth; // Animate to final
                    }, 50);
                });
            });
        }
    }

});
