/**
 * IDs API-Football (ligues France) — à ajuster si la FFF / l’API renomme des groupes.
 * National = Championnat National (N1), National 2 (3 groupes), National 3 (groupes A–J + G doublon API).
 */
public with sharing class SC360ScoutingFranceLeagueIds {
    public static List<Integer> scoutingLeagueIds() {
        return new List<Integer>{
            63, // National 1 (Championnat National)
            67,
            68,
            69, // National 2 — groupes A, B, C
            461,
            462,
            463,
            464,
            465,
            466,
            467,
            468,
            469,
            1029 // National 3 — groupes (IDs API; 1029 = ex. groupe G)
        };
    }
}
