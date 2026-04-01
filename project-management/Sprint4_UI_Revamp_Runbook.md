# Sprint 4 - UI Revamp Athlete 360

## Scope
- UI LWC custom premium
- Theme dark pro + options light/neon
- KPI animés
- Graphes Chart.js
- Pages 360 prêtes pour App Builder
- Capture vidéo du rendu final

## Composants créés
- `sc360HeaderHero`
- `sc360KpiCard`
- `sc360ChartCard`
- `sc360Timeline`
- `sc360AiInsight`
- `sc360Kanban`
- `sc360PlayerProfile`
- `sc360DocumentCard`
- Shell: `sc360App`
- Pages: `sc360AthletePage`, `sc360ScoutingPage`, `sc360TrainingPage`, `sc360MedicalPage`, `sc360AdminPage`

## Déploiement
```bash
sf project deploy start --source-dir force-app --target-org <alias>
```

## App Builder
1. Ouvrir une Lightning Record Page de `Athlete__c`.
2. Ajouter `sc360AthletePage` (ou `sc360App`).
3. Theme: `darkPro`, `lightMinimal`, `neonSport`.

## Capture vidéo finale
```powershell
powershell -ExecutionPolicy Bypass -File scripts/video/capture_athlete360.ps1 -Output athlete360_final.mp4 -DurationSec 45
```

## Storyboard démo (45 sec)
1. Hero + profil + sync
2. KPIs animés
3. 2 charts
4. Timeline + Kanban
5. AI Insights + Documents
