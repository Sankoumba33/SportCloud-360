# Sprint 1 - UAT Demo Script

## Objectif
Montrer en moins de 7 minutes un parcours complet Athlete 360 + Scouting 360 + Planning.

## Preconditions
- Donnees seedees:
  - 6 squads
  - 10 athletes
  - 10 prospects
  - 15 squad assignments
- Permissions sets affectes:
  - Coach_Read
  - Scout_Editor
  - Recruiter_Editor
  - Planning_Editor

## Etapes demo

1. Ouvrir un prospect dans `Prospect__c`.
   - Resultat attendu: statut visible, position, club actuel, related list scouting reports.

2. Ajouter un `ScoutingReport__c`.
   - Resultat attendu: report date, rating, summary sauvegardes.

3. Lancer conversion prospect -> athlete (flow/action).
   - Resultat attendu: nouvel `Athlete__c` cree, `ConvertedAthlete__c` renseigne, statut prospect = Converted.

4. Ouvrir la fiche athlete converti.
   - Resultat attendu: current squad visible, historique effectif accessible.

5. Creer un `PlanningEvent__c` (Training).
   - Resultat attendu: validation des dates OK, event sauvegarde.

6. Verifier le calendrier standard Salesforce (`Event`).
   - Resultat attendu: event synchronise present avec sujet, date, lieu, sportcloud fields.

7. Modifier puis supprimer le `PlanningEvent__c`.
   - Resultat attendu: Event sync update puis delete sans doublons.

8. Verifier acces role-based.
   - Resultat attendu:
     - Coach lit athlete/planning
     - Scout cree prospect/report
     - Recruiter convertit prospect
     - Medical data sensible non editable par roles non medicaux

## Critere Go/No-Go
- 8/8 etapes passent
- Aucun blocage permission
- Aucune incoherence de synchro planning/calendrier
