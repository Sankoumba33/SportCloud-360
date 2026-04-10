document.addEventListener('DOMContentLoaded', () => {
    
    // 1. Gestion des Onglets (Tabs)
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Retirer l'état actif de tous les boutons et contenus
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            // Ajouter l'état actif au bouton cliqué et au contenu correspondant
            btn.classList.add('active');
            const targetId = btn.getAttribute('data-target');
            document.getElementById(targetId).classList.add('active');
        });
    });

    // 2. Animation des cercles de progression
    const circleProgressBars = document.querySelectorAll('.circle-progress');
    
    // On simule une animation de remplissage en CSS via background conic-gradient
    circleProgressBars.forEach(circle => {
        // Ex: on récupère la valeur dans le span.score-value
        const valueSpan = circle.querySelector('.score-value');
        if (valueSpan) {
            let valText = valueSpan.textContent.replace('%', '');
            let percentage = parseInt(valText);
            
            if (!isNaN(percentage)) {
                // Animation de 0 à la valeur
                let current = 0;
                let color = "var(--color-primary)";
                
                // Si la barre a une contrainte de couleur selon la valeur
                // Ici pour l'IA on reste sur du primary
                
                let interval = setInterval(() => {
                    if(current >= percentage) {
                        clearInterval(interval);
                    } else {
                        current += 2;
                        if(current > percentage) current = percentage;
                        
                        circle.style.background = `conic-gradient(${color} ${current * 3.6}deg, rgba(255,255,255,0.05) 0deg)`;
                        // valueSpan.innerHTML = current + '<small>%</small>'; // Décommenter si on veut l'effet compteur
                    }
                }, 20);
                
                // Set initial state
                circle.style.background = `conic-gradient(${color} ${percentage * 3.6}deg, rgba(255,255,255,0.05) 0deg)`;
            }
        }
    });

    // 3. Hover Effects Tactiques
    // Optionnel : Ajouter de l'interactivité sur les points du terrain
    const playerDots = document.querySelectorAll('.player-dot');
    playerDots.forEach(dot => {
        dot.addEventListener('mouseenter', () => {
            dot.style.transform = 'translate(-50%, -50%) scale(1.2)';
            dot.style.boxShadow = '0 0 10px var(--color-danger)';
        });
        dot.addEventListener('mouseleave', () => {
            dot.style.transform = 'translate(-50%, -50%) scale(1)';
            dot.style.boxShadow = 'none';
        });
    });
});
