public with sharing class OpportunityTriggerHandler {
    
    public static void handleBefore(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            // Validação de valor negativo
            if (opp.Amount != null && opp.Amount < 0) {
                opp.addError('O valor da oportunidade não pode ser negativo.');
            }
        }
    }
    
    public static void handleAfterInsert(List<Opportunity> newOpps) {
        List<Opportunity> highValueOpps = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            if (opp.Amount != null && opp.Amount >= 50000) {
                highValueOpps.add(opp);
            }
        }
        
        if (!highValueOpps.isEmpty()) {
            // Simulação de notificação
            System.debug('Oportunidades de alto valor criadas: ' + highValueOpps);
        }
    }
}