@isTest
private class OpportunityServiceTest {
    
    @testSetup
    static void setupTestData() {
        
        List<User> users = [SELECT Id FROM User LIMIT 2];
        
        List<Opportunity> opps = new List<Opportunity>();
        Date interval = Date.today().addDays(-31);
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Opportunity ' + i,
            StageName = Math.mod(i, 2) == 0 ? 'Prospecting' : 'Closed Won',
            CloseDate = interval.addDays(-i),
            Amount = 1000 + i * 100,
            OwnerId = users[Math.mod(i, 2)].Id
                ));
        }
        
        opps.add(new Opportunity(
            Name = 'Old Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(-200),
        Amount = 5000
            ));
        
        insert opps;
    }
    
    @isTest
    static void testGetAllRecentOpportunities() {
        Test.startTest();
        List<Opportunity> result = OpportunityService.getRecentOpportunitiesFiltered('', null, null);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Deveria retornar as opps recentes');
    }
    
    @isTest
    static void testFilterByStage() {
        Test.startTest();
        List<Opportunity> result = OpportunityService.getRecentOpportunitiesFiltered('Prospecting', null, null);
        Test.stopTest();
        for (Opportunity opp : result) {
            System.assertEquals('Prospecting', opp.StageName, 'A oportunidade deve estar no stage - Prospecting');
        }
    }
    
    @isTest
    static void testFilterByDateRange() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();
        Test.startTest();
        List<Opportunity> result = OpportunityService.getRecentOpportunitiesFiltered('', startDate, endDate);
        Test.stopTest();
        for (Opportunity opp : result) {
            System.assert(opp.CloseDate >= startDate && opp.CloseDate <= endDate, 'A oportunidade deve estar dentro do intervalo de datas');
        }
    }
    
    @isTest
    static void testFilterByStageAndDate() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();
        Test.startTest();
        List<Opportunity> result = OpportunityService.getRecentOpportunitiesFiltered('Closed Won', startDate, endDate);
        Test.stopTest();
        for (Opportunity opp : result) {
            System.assertEquals('Closed Won', opp.StageName, 'A oportunidade deve estar no stage - Closed Won');
            System.assert(opp.CloseDate >= startDate && opp.CloseDate <= endDate, 'A oportunidade deve estar dentro do intervalo de datas');
        }
    }
    
    @isTest static void testDefaultDaysNullInput() {
        Test.startTest();
        List<AggregateResult> results = OpportunityService.getOpportunitiesGroupedByStage(null);
        Test.stopTest();
        System.assert(results.size() > 0, 'Deve retornar opps com default 90 dias');
    }
    
    @isTest static void testValidInput30Days() {
        Test.startTest();
        List<AggregateResult> results = OpportunityService.getOpportunitiesGroupedByStage(30);
        Test.stopTest();
        System.assert(results.isEmpty(), 'Não deve retornar opps com 30 dias');
    }
    
    @isTest static void testValidInput60Days() {
        Test.startTest();
        List<AggregateResult> results = OpportunityService.getOpportunitiesGroupedByStage(60);
        Test.stopTest();
        System.debug(results);
        System.assertNotEquals(null, results, 'Resultados não devem ser nulos para 60 dias');
        System.assertEquals(2, results.size(), 'Deve retornar 5 resultados para 60 dias');
        System.assertEquals(3, results[0].get('total'), 'Deve retornar 3 opps com fase - Prospecting');
    }
    
    @isTest static void testValidInput90Days() {
        Test.startTest();
        List<AggregateResult> results = OpportunityService.getOpportunitiesGroupedByStage(90);
        Test.stopTest();
        System.assertNotEquals(null, results, 'Resultados não devem ser nulos para 90 dias');
        System.assertEquals(2, results.size(), 'Deve retornar 5 resultados para 90 dias');
        System.assertEquals(2, results[1].get('total'), 'Deve retornar 3 opps com fase - Closed Won');
    }
    
    @isTest
    static void testGetKpiSummaryDefault90Days() {
        Test.startTest();
        KpiSummary summary = OpportunityService.getKpiSummary(null);
        Test.stopTest();
        
        System.assertEquals(5, summary.totalOpps, 'Deve contar todas as oportunidades em 90 dias');
        System.assertEquals(2, summary.uniqueOwners, 'Deve identificar dois donos distintos');
        System.assert(summary.totalAmount > 0, 'TotalAmount deve somar valores corretamente');
    }
    
    @isTest
    static void testGetKpiSummaryCustomRange() {
        Integer lastDays = 60;
        Test.startTest();
        KpiSummary summary = OpportunityService.getKpiSummary(lastDays);
        Test.stopTest();
        
        System.assertEquals(5, summary.totalOpps, 'Deve retornar apenas as oportunidades nos últimos ' + lastDays + ' dias');
        System.assert(summary.totalAmount > 0, 'Soma deve refletir corretamente as oportunidades válidas');
    }
    
    @isTest
    static void testGetKpiSummaryNoResults() {
        Integer lastDays = 30;
        Test.startTest();
        KpiSummary summary = OpportunityService.getKpiSummary(lastDays);
        Test.stopTest();
        
        System.assertEquals(0, summary.totalOpps, 'Não deve retornar nenhuma oportunidade');
        System.assertEquals(0, summary.totalAmount, 'Soma deve ser zero');
        System.assertEquals(0, summary.uniqueOwners, 'Nenhum dono único encontrado');
    }
}