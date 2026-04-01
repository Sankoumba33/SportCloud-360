/** Résultat partagé pour actions scouting (Flow / invocables). */
public class SC360ScoutingOperationResult {
    @InvocableVariable(label='Succès')
    public Boolean success;
    @InvocableVariable(label='Message')
    public String message;
    @InvocableVariable(label='Traité')
    public Integer processedCount;
}
