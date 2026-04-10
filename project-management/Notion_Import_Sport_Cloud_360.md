# Sport Cloud 360 — Structure Notion (Epics, Sprints, tâches de config)

**Usage** : copier les sections dans Notion (pages ou base de données). Chaque ligne `- [ ]` est une tâche à cocher dans Notion ou à importer en CSV.

**Références repo** : `Sprint1_Execution_Checklist.md` … `Sprint4_UI_Revamp_Runbook.md`, `Sprint3_PromptPack.md`, `DataCloud_Activation_Mapping_*.csv`.

---

## Propriétés suggérées (base de données Notion « Tâches »)

| Propriété | Type | Valeurs / notes |
|-----------|------|------------------|
| **Nom** | Title | |
| **Epic** | Select ou relation | E1 … E7 (voir ci-dessous) |
| **Sprint** | Select | S1, S2, S3, S4 |
| **Type** | Multi-select | `Champ` · `Page layout` · `Onglet` · `App Lightning` · `Flexipage` · `Permission Set` · `FLS` · `Flow` · `Data Cloud` · `Event plateforme` · `Prompt IA` · `Données` · `QA` · `Doc` |
| **Environnement** | Select | Sandbox · UAT · Prod |
| **Priorité** | Select | P0 · P1 · P2 |
| **Doc** | URL | Lien vers fichier GitHub / `project-management/` |
| **Statut** | Select | À faire · En cours · Bloqué · Fait |

---

## Epics (vue d’ensemble)

| ID | Epic | Description |
|----|------|-------------|
| **E1** | Fondations Core & UX | Objets, champs, onglets, apps, layouts, pages Lightning. |
| **E2** | Sécurité & accès | Permission sets, FLS, tests par persona. |
| **E3** | Planning & calendrier | `PlanningEvent__c` ↔ `Event`. |
| **E4** | Data Cloud & activation | Ingest, features, mappings, Data Actions, timestamps. |
| **E5** | Automatisation & événements | Flows alertes, platform events / handlers déjà en repo. |
| **E6** | IA Agentforce | Prompts Athlete / Scouting, paramètres. |
| **E7** | Qualité, ops & démo | UAT, monitoring, runbooks. |

---

# Sprint 1 — MVP navigation, données de base, droits

**Objectif** : org navigable, seed minimal, permission sets, layouts, sync planning.

**Réf.** : `Sprint1_Execution_Checklist.md`

## Données (E1, E7 · Type: Données)

- [ ] Créer / vérifier **6** enregistrements `Squad__c`
- [ ] Créer / vérifier **10** enregistrements `Athlete__c`
- [ ] Créer / vérifier **10** enregistrements `Prospect__c`
- [ ] Créer / vérifier **15** enregistrements `SquadAssignment__c`

## UI — Layouts & pages (E1 · Type: Page layout, Flexipage)

- [ ] **Page layout** `Athlete__c` : sections, champs obligatoires, ordre logique
- [ ] **Page layout** `Prospect__c` : idem
- [ ] **Related lists** visibles (affectations, données externes, rapports scouting selon besoin)
- [ ] **Lightning Record Pages** : vérifier fiche détail / mobile si utilisé

## Onglets & applications (E1 · Type: Onglet, App Lightning)

- [ ] **Tabs** : objets exposés (`Athlete__c`, `Prospect__c`, etc.) dans les apps concernées
- [ ] **Apps Lightning** : `Athlete_360`, `Scouting_360`, `Medical_360`, `Club_360` — visibles pour les utilisateurs de test
- [ ] **Navigation** : ordre des onglets cohérent par app

## Permission sets (E2 · Type: Permission Set)

- [ ] Déployer / assigner **`SportCloud_Admin`**
- [ ] Déployer / assigner **`Coach_Read`**
- [ ] Déployer / assigner **`Scout_Editor`**
- [ ] Déployer / assigner **`Recruiter_Editor`**
- [ ] Déployer / assigner **`Planning_Editor`**
- [ ] **FLS** : vérifier lecture/édition sur champs critiques par PS (pas seulement l’objet)

## Planning calendrier (E3 · Type: Flow / Apex — config métier)

- [ ] Création `PlanningEvent__c` → **`Event`** Salesforce créé
- [ ] Mise à jour `PlanningEvent__c` → **`Event`** mis à jour
- [ ] Suppression `PlanningEvent__c` → **`Event`** supprimé

## Automatisation métier (E5)

- [ ] **Conversion Prospect → Athlete** opérationnelle (process / action / bouton selon implémentation)
- [ ] **Règles de validation** dates opérationnelles
- [ ] **Anti-chevauchement** affectation (si implémenté)

## QA Sprint 1 (E7 · Type: QA)

- [ ] Tests par rôle **Coach** OK
- [ ] Tests par rôle **Scout** OK
- [ ] Tests par rôle **Recruiter** OK
- [ ] **UAT** : script démo 8 étapes
- [ ] Démo **&lt; 7 min** — pas de blocker ouvert

---

# Sprint 2 — Data Cloud, features, activation Core

**Objectif** : ingest Data Cloud, features calculées, activation vers `Athlete__c` / `Prospect__c`.

**Réf.** : `Sprint2_Execution_Checklist.md`, `Sprint2_DataCloud_Runbook.md`, `DataCloud_Activation_Mapping_Athlete.csv`, `DataCloud_Activation_Mapping_Scouting.csv`

## Data Cloud — entrées (E4 · Type: Data Cloud)

- [ ] **Source de données** (ex. API / fichiers) : paramètres, token, quotas
- [ ] **Fichiers mock** : `data/sprint2/athlete_features.csv`, `prospect_features.csv` alignés schéma
- [ ] **External IDs** alignés avec `Athlete__c.ExternalId__c` et `Prospect__c.ExternalId__c`
- [ ] **Plan de refresh** documenté (intraday training, daily scouting)

## Feature engineering (E4)

- [ ] Features **athlète** : readiness, injury risk, ACWR, trends (côté lake / calcul)
- [ ] Features **scouting** : scores + `data_confidence`
- [ ] **JSON snapshot** (`FeaturesJson__c` / `ScoutingFeaturesJson__c`) pour audit si prévu

## Activation Core (E4 · Type: Data Cloud, Champ, FLS)

- [ ] Valider **mapping Athlete** ligne à ligne vs CSV repo
- [ ] Valider **mapping Scouting** ligne à ligne vs CSV repo
- [ ] **Data Action** ou équivalent : upsert `Athlete__c` sans doublons
- [ ] Idem **upsert** `Prospect__c`
- [ ] Champs **timestamps** : `LastTrainingSync__c`, `LastMatchSync__c`, `LastDataCloudSync__c` renseignés après activation

## IA & automation Sprint 2 (E5, E6)

- [ ] Prompts brouillon **AthleteAgent** (summary, risk) — peut être raffiné Sprint 3
- [ ] Prompt brouillon **ScoutingAgent** (recommendation)
- [ ] **Flow** alerte risque blessure élevé (si pas reporté S3)
- [ ] **Flow** alerte charge ACWR hors plage (si pas reporté S3)

## QA Sprint 2 (E7)

- [ ] **5 athlètes** : cohérence features → record Core
- [ ] **5 prospects** : cohérence scores → record Core
- [ ] **Alertes** : cas positif + négatif
- [ ] Démo **&lt; 10 min** ; **24h** sans échec sync ; KPI Data Cloud (latence, couverture)

---

# Sprint 3 — Fiabilité activation, alertes, prompts IA, monitoring

**Objectif** : identité stable, flows production, pack prompts Agentforce, ops.

**Réf.** : `Sprint3_Execution_Checklist.md`, `Sprint3_PromptPack.md`, `Sprint3_AI_Automation_Runbook.md`

## Identité & activation (E4, E7)

- [ ] **`ExternalId__c`** : 100% renseigné sur athlètes cibles
- [ ] **`ExternalId__c`** : 100% renseigné sur prospects cibles
- [ ] **Zéro doublon** sur `ExternalId__c` (athlète + prospect)
- [ ] **Data Action Athlete** : pas d’erreur sur fenêtre 24h
- [ ] **Data Action Prospect** : pas d’erreur sur fenêtre 24h

## Flows & notifications (E5 · Type: Flow)

- [ ] **Flow injury** actif : `InjuryRiskScore__c >= 75`
- [ ] **Flow ACWR** actif : `Acwr__c > 1.5` OU `< 0.8`
- [ ] **Notifications** : destinataires (rôle Coach / Medical / Recruiter ou groupes)
- [ ] **Dédoublonnage** alertes (ex. pas 2× la même alerte 24h / même athlète)

## Prompts Agentforce (E6 · Type: Prompt IA)

- [ ] Prompt **Athlete Summary** — texte + merge fields `Sprint3_PromptPack.md`
- [ ] Prompt **Risk Alert** — idem
- [ ] Prompt **Scouting Recommendation** — idem
- [ ] **Paramètres** : température 0.2–0.4, max tokens ~220, grounding champs Core uniquement
- [ ] **Inputs / outputs** documentés (champs obligatoires, fallback si données manquantes)

## Monitoring (E7 · Type: Doc, Rapport)

- [ ] **Dashboard** : latence sync, échecs, couverture
- [ ] **KPI** `LastDataCloudSync__c` exploitable athlète + prospect
- [ ] **Procédure incident** : replay event, ré-ingestion
- [ ] **Runbook** testé par un **autre** membre d’équipe

## QA Sprint 3 (E7)

- [ ] **5 cas athlète** : scores, trend, alertes
- [ ] **5 cas prospect** : scores, summary, confidence
- [ ] **Cas négatif** : external id absent → pas de MAJ
- [ ] **Cas limites** : nulls, bornes extrêmes
- [ ] Démo **&lt; 10 min** ; **0** blocker P1/P2 ; storyline Data Cloud → Event → Core → IA → Action

---

# Sprint 4 — UI revamp LWC (optionnel / polish)

**Objectif** : record pages premium, thèmes, démo visuelle.

**Réf.** : `Sprint4_UI_Revamp_Runbook.md`

## Déploiement & App Builder (E1)

- [ ] Déployer **force-app** vers l’org cible (`sf project deploy start --source-dir force-app`)
- [ ] **Lightning Record Page** `Athlete__c` : ajouter composant **`sc360AthletePage`** ou **`sc360App`**
- [ ] **Thème** : `darkPro`, `lightMinimal`, ou `neonSport` selon cible
- [ ] Vérifier LWC : `sc360HeaderHero`, `sc360KpiCard`, `sc360ChartCard`, `sc360Timeline`, `sc360AiInsight`, `sc360Kanban`, `sc360PlayerProfile`, `sc360DocumentCard`, pages `sc360TrainingPage`, `sc360MedicalPage`, `sc360ScoutingPage`, `sc360AdminPage` si utilisées

## QA Sprint 4 (E7)

- [ ] Storyboard démo **~45 s** (hero, KPIs, charts, timeline, AI, documents)
- [ ] Capture vidéo finale (script PowerShell du runbook si utilisé)

---

## Légende types de configuration (tags Notion)

| Tag | Exemples concrets |
|-----|-------------------|
| **Champ** | Création / modification champ custom, type, aide, validation |
| **Page layout** | Mise en page classique, sections, related lists |
| **Onglet** | Tab Lightning pour objet dans une app |
| **App Lightning** | Athlete_360, Scouting_360, Medical_360, Club_360 |
| **Flexipage** | Lightning App Builder, home, record page |
| **Permission Set** | SportCloud_Admin, Coach_Read, Scout_Editor, … |
| **FLS** | Field-Level Security par profil ou PS |
| **Flow** | Record-triggered ou scheduled, critères injury / ACWR |
| **Data Cloud** | Stream, DMO, mapping, Data Action, calendrier |
| **Event plateforme** | Publication / abonnement `AthleteFeatureUpdate__e`, etc. |
| **Prompt IA** | Prompt Builder / Agent, variables `{!Athlete__c...}` |
| **Données** | Seed, External ID, dédoublonnage |
| **QA** | UAT, jeux de test |
| **Doc** | Runbook, procédure incident |

---

## Import rapide dans Notion

1. **Page unique** : coller ce fichier dans une page Notion ; transformer les listes en **to-do**.
2. **Base de données** : créer une table avec colonnes Epic, Sprint, Type ; copier chaque **tâche** comme une ligne (ou importer CSV exporté depuis ce MD après conversion manuelle).
3. **Lier le repo** : propriété **Doc** = `https://github.com/Sankoumba33/SportCloud-360/tree/main/project-management`

---

*Dernière mise à jour : alignée sur les checklists Sprint 1–4 du dépôt Sport Cloud 360.*
