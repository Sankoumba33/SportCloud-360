# Sprint 3 - Execution Checklist

## 1) Activation Reliability (T1)
- [ ] `Athlete__c.ExternalId__c` rempli pour 100% des athletes cibles
- [ ] `Prospect__c.ExternalId__c` rempli pour 100% des prospects cibles
- [ ] Zero doublon sur `ExternalId__c` (athlete + prospect)
- [ ] Data Action Athlete publie sans erreur (24h)
- [ ] Data Action Prospect publie sans erreur (24h)

## 2) Automation Alertes (T2)
- [ ] Flow alerte injury risk actif (`InjuryRiskScore__c >= 75`)
- [ ] Flow alerte ACWR actif (`Acwr__c > 1.5` ou `< 0.8`)
- [ ] Notification envoyee au role cible (Coach/Medical/Recruiter)
- [ ] Dedoublonnage alerte en place (pas de spam)

## 3) Prompt Pack Agentforce (T3)
- [ ] Prompt `Athlete Summary` valide (resume exploitable staff)
- [ ] Prompt `Risk Alert` valide (risques + action court terme)
- [ ] Prompt `Scouting Recommendation` valide (go / monitor / no-go)
- [ ] Inputs/outputs documentes (champs obligatoires + fallback)

## 4) Monitoring Ops (T4)
- [ ] Dashboard de suivi sync disponible (latence, echec, couverture)
- [ ] KPI `LastDataCloudSync__c` monitorable (athlete + prospect)
- [ ] Procedure incident documentee (replay event, re-ingestion)
- [ ] Checklist runbook executee par 1 autre membre de l equipe

## 5) QA et UAT (T5)
- [ ] 5 cas athlete verifies (scores + trend + alertes)
- [ ] 5 cas prospect verifies (scores + summary + confidence)
- [ ] Cas negatif valide (external id absent => pas de MAJ)
- [ ] Cas limite valide (values nulles / bornes extremes)

## 6) Demo Ready
- [ ] Demo Sprint 3 executee en < 10 min
- [ ] Zero blocker P1/P2
- [ ] Storyline claire: Data Cloud -> Event -> Core -> IA -> Action
