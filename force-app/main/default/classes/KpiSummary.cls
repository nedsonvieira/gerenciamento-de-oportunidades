public class KpiSummary {
    
    @AuraEnabled public Integer totalOpps;
    @AuraEnabled public Decimal totalAmount;
    @AuraEnabled public Integer uniqueOwners;
    
    public KpiSummary(Integer totalOpps, Decimal totalAmount, Integer uniqueOwners) {
        this.totalOpps = totalOpps;
        this.totalAmount = totalAmount;
        this.uniqueOwners = uniqueOwners;
    }
}