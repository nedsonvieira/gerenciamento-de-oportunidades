public with sharing class OpportunityService {
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getRecentOpportunitiesFiltered(String stageFilter, Date startDate, Date endDate) {
        String baseQuery = 'SELECT Id, Name, StageName, Amount, CloseDate, Owner.Name FROM Opportunity WHERE LastModifiedDate = LAST_N_DAYS:180';
        
        if (stageFilter != '') {
            baseQuery += ' AND StageName = :stageFilter';
        }
        if (startDate != null) {
            baseQuery += ' AND CloseDate >= :startDate';
        }
        if (endDate != null) {
            baseQuery += ' AND CloseDate <= :endDate';
        }
        
        baseQuery += ' ORDER BY LastModifiedDate DESC LIMIT 20';
        
        return Database.query(baseQuery);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getOpportunitiesGroupedByStage(Integer lastDays) {
        Integer days = (lastDays != null) ? lastDays : 90;
        Date startDate = Date.today().addDays(-days);
        
        return [
        SELECT StageName stage, COUNT(Id) total, SUM(Amount) totalAmount
        FROM Opportunity
        WHERE CloseDate >= :startDate WITH SECURITY_ENFORCED
        GROUP BY StageName
        ORDER BY StageName
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static KpiSummary getKpiSummary(Integer lastDays) {
        Integer days = (lastDays != null) ? lastDays : 90;
        Date startDate = Date.today().addDays(-days);
        
        AggregateResult[] totalAgg = [
        SELECT COUNT(Id) totalOpps, SUM(Amount) totalAmount
        FROM Opportunity
        WHERE CloseDate >= : startDate WITH SECURITY_ENFORCED
    ];
        
        List<Id> uniqueOwners = new List<Id>();
        
        for (AggregateResult ar : [SELECT OwnerId FROM Opportunity
                                    WHERE CloseDate >= :startDate WITH SECURITY_ENFORCED
                                    GROUP BY OwnerId]) {
            uniqueOwners.add((Id) ar.get('OwnerId'));
        }
        
        AggregateResult res = totalAgg[0];
        return new KpiSummary(
            (Integer) res.get('totalOpps'),
        (Decimal) res.get('totalAmount'),
        uniqueOwners.size()
            );
    }
}