/*
* -----------------------------------------------------------------------------
* COPYRIGHT (C) 2022, FONTEVA, INC.
* ALL RIGHTS RESERVED.
*
* ALL INFORMATION CONTAINED HEREIN IS, AND REMAINS THE PROPERTY OF FONTEVA
* INCORPORATED AND ITS SUPPLIERS, IF ANY. THE INTELLECTUAL AND TECHNICAL
* CONCEPTS CONTAINED HEREIN ARE PROPRIETARY TO FONTEVA INCORPORATED AND
* ITS SUPPLIERS AND MAY BE COVERED BY U.S. AND FOREIGN PATENTS, PATENTS IN
* PROCESS, AND ARE PROTECTED BY TRADE SECRET OR COPYRIGHT LAW. DISSEMINATION
* OF THIS INFORMATION OR REPRODUCTION OF THIS MATERIAL IS STRICTLY FORBIDDEN
* UNLESS PRIOR WRITTEN PERMISSION IS OBTAINED FROM FONTEVA, INC.
* -----------------------------------------------------------------------------
*/

@isTest
public without sharing class Test_TokenMigrationBatch extends MockTestBase {
    
    @testSetup
    static void testSetup(){
        List<Contact> conLst = new List<Contact>{new Contact(LastName='Contact 1')};
        Framework.SObjectService.insertRecords(conLst);
        
        List<Account> accLst = new List<Account>{new Account(Name='Account 1', OrderApi__Primary_Contact__c=conLst[0].Id)};
        Framework.SObjectService.insertRecords(accLst);
        
        List<OrderApi__Payment_Method__c> paymentMethodLst = new List<OrderApi__Payment_Method__c>();
        paymentMethodLst.add(new OrderApi__Payment_Method__c(
            OrderApi__Payment_Method_Token__c = 'IfQpsAYp3fOD7U0yS1OeqXybHcU',
            OrderApi__Payment_Method_Type__c = 'credit_card',
            OrderApi__Is_Active__c = true,
            OrderApi__Contact__c = conLst[0].Id,
            OrderApi__Billing_Postal_Code__c = '12345',
            OrderApi__Entity__c = 'Contact'
        ));
        paymentMethodLst.add(new OrderApi__Payment_Method__c(
            OrderApi__Payment_Method_Token__c = 'IfQpsAYp3fOD7U0yS1OeqXybHcU',
            OrderApi__Payment_Method_Type__c = 'credit_card',
            OrderApi__Is_Active__c = true,
            OrderApi__Account__c = accLst[0].Id,
            OrderApi__Billing_Postal_Code__c = '12345',
            OrderApi__Entity__c = 'Account'
        ));
        Framework.SObjectService.insertRecords(paymentMethodLst);
    }
    
    @isTest
    static void testBatchWithNoArgument() {
        MultiRequestMock multiCalloutMock = new MultiRequestMock();
        multiCalloutMock.addRequestMock('https://core.spreedly.com/v1/gateways.json', SpreedlyHTTPCalloutMock.generateStripeAccessTokenSuccess());
        multiCalloutMock.addRequestMock('https://core.spreedly.com/v1/gateways/O8hP76edNVpC1tZ5pnZlgB10Th0/store.json', SpreedlyHTTPCalloutMock.generateExportTokenSuccess());
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        Test.startTest();
        
        Database.executeBatch(new TokenMigrationBatch(true));
        
        Test.stopTest();
        
        System.assertEquals(2, [SELECT count() FROM OrderApi__Payment_Method__c], 'Payment Method record is not created from batch');
    }
    
    @isTest
    static void testBatchWithArgument() {
        MultiRequestMock multiCalloutMock = new MultiRequestMock();
        multiCalloutMock.addRequestMock('https://core.spreedly.com/v1/gateways.json', SpreedlyHTTPCalloutMock.generateStripeAccessTokenSuccess());
        multiCalloutMock.addRequestMock('https://core.spreedly.com/v1/gateways/O8hP76edNVpC1tZ5pnZlgB10Th0/store.json', SpreedlyHTTPCalloutMock.generateExportTokenSuccess());
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        List<Contact> contacts = [SELECT Id FROM Contact];
        
        Test.startTest();
        
        Database.executeBatch(new TokenMigrationBatch('WHERE OrderApi__Contact__c = \'' + contacts[0].Id +'\'', true), 1);
        
        Test.stopTest();
        
        System.assertEquals(2, [SELECT count() FROM OrderApi__Payment_Method__c], 'Payment Method record is not created from batch');
    }
}