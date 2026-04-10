/**
 * SIC Cockpit - JavaScript
 * Gestion des micro-animations et interactions UI (Préparation à la conversion LWC)
 */

document.addEventListener('DOMContentLoaded', () => {
    
    // 1. Animation d'entrée "Premium" (Stagger effect)
    // Donne l'impression que le dashboard s'allume et se charge de façon fluide et hiérarchisée
    const elementsToAnimate = document.querySelectorAll('.alert-card, .microcycle-card, .chart-card, .app-card');
    
    // État initial
    elementsToAnimate.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(15px)';
        el.style.transition = 'opacity 0.4s ease-out, transform 0.4s ease-out';
    });

    // Cascade d'apparition
    setTimeout(() => {
        elementsToAnimate.forEach((el, index) => {
            setTimeout(() => {
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
                
                // On retire les transitions inline après pour préserver les effets :hover du CSS
                setTimeout(() => {
                    el.style.transition = ''; 
                }, 400);

            }, index * 40); // 40ms est un bon rythme pour ne pas paraître lent
        });
    }, 100);

    // 2. Interaction Sélecteur d'Équipe (Context Switching)
    const teamSelector = document.querySelector('.team-selector select');
    if (teamSelector) {
        teamSelector.addEventListener('change', (e) => {
            // Dans Salesforce LWC, on propagerait un Evènement (CustomEvent / LMS)
            // pour recharger les données des enfants. Ici on fait juste remonter l'UX.
            const selectedTeam = e.target.value;
            console.log(`[Context] Équipe modifiée : ${selectedTeam}`);
            
            // Petit feedback visuel simulant un rechargement
            const mainContent = document.querySelector('.sic-main');
            mainContent.style.opacity = '0.5';
            setTimeout(() => {
                mainContent.style.opacity = '1';
            }, 300);
        });
    }

    // 3. Info bulles dynamiques (Mock) sur la Timeline du Microcycle
    const timelineDays = document.querySelectorAll('.day.past, .day.today');
    
    timelineDays.forEach(day => {
        day.addEventListener('mouseenter', () => {
            day.style.transform = 'scale(1.05)';
            day.style.zIndex = '10';
        });
        
        day.addEventListener('mouseleave', () => {
            day.style.transform = '';
            day.style.zIndex = '';
        });
    });
});
