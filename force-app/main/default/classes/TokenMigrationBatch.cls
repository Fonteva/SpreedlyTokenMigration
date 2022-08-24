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

/**
 * @name TokenMigrationBatch
 * @description Batch class for token migration from Spreedly to Stripe
 */
global with sharing class TokenMigrationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    private String query;
    private String stipeGatewayToken;
    private Map<Id, Contact> contactsToUpdate;
    private Boolean isTestMode;

    global TokenMigrationBatch(Boolean isTestMode) {
        generateQuery('');
        this.isTestMode = isTestMode;
    }
    
    global TokenMigrationBatch(String whereClause, Boolean isTestMode) {
        generateQuery(whereClause);
        this.isTestMode = isTestMode;
    }

    private void generateQuery(String whereClause){
        this.query = 'SELECT Id, OrderApi__Contact__c, OrderApi__Contact__r.Name, OrderApi__Customer_ID__c, OrderApi__Payment_Method_Token__c, OrderApi__Is_Active__c, OwnerId, Owner.IsActive, Original_Saved_Payment_Method__c FROM OrderApi__Payment_Method__c ';
        if (String.isNotBlank(whereClause)) {
            this.query += whereClause;
        }
        else {
            this.query += 'WHERE OrderApi__Is_Active__c = true';
        }
        this.query += ' AND OrderApi__Billing_Postal_Code__c != NULL AND (NOT OrderApi__Payment_Method_Token__c LIKE \'' + SpreedlyAPIService.CUSTOMER_PREFIX +'%\')'; //Ignoring stripe payment method token
        this.query += ' ORDER BY OrderApi__Contact__c';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        SpreedlyHTTPService.path = 'TokenMigrationBatch/start';
        //initializing variable
        stipeGatewayToken = '';
        contactsToUpdate = new Map<Id, Contact>();

        //fetching stripe access token
        FDService.EPayRequest req = SpreedlyEPayService.createEpayRequest('', '');
        SpreedlyEPayService.createStripeTokenBody(req, SpreedlyAPIService.getCredentials(isTestMode).secretKey);
        FDService.EPayResponse epayResponse = SpreedlyHTTPService.prepareAndDoAPICallout(req);
        
        if (!epayResponse.transactions.isEmpty()) {
            stipeGatewayToken = epayResponse.transactions[0].token;
        }

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<OrderApi__Payment_Method__c> paymentMethods) {
        SpreedlyHTTPService.path = 'TokenMigrationBatch/execute';
        List<Framework__System_Log__c> errorSystemLogs = new List<Framework__System_Log__c>();
        
        try{
            List<OrderApi__Payment_Method__c> paymentMethodsToInsert = new List<OrderApi__Payment_Method__c>();
            List<OrderApi__Payment_Method__c> paymentMethodsToUpdate = new List<OrderApi__Payment_Method__c>();

            //checking saved payment method is linked with account
            Set<Id> accountIds = new Set<Id>();
            for (OrderApi__Payment_Method__c paymentMethod : paymentMethods) {
                String customerId = paymentMethod.OrderApi__Contact__c != null ? paymentMethod.OrderApi__Contact__c : paymentMethod.OrderApi__Customer_ID__c;
                
                if (((Id)customerId).getSObjectType().getDescribe().getName() == 'Account') {
                    accountIds.add(customerId);
                }
            }

            //fetching account id for primary contact
            Map<Id, Id>  accountIdWithContactIdMap = new Map<Id, Id>();
            if(!accountIds.isEmpty()){
                Framework.Selector.ignoreSharingInContext();
                List<Account> accounts = (Account[]) new Framework.Selector(Account.SObjectType).selectById(accountIds);
                for(Account acc : accounts){
                    accountIdWithContactIdMap.put(acc.Id, acc.OrderApi__Primary_Contact__c);
                }
            }

            for (OrderApi__Payment_Method__c paymentMethod : paymentMethods) {
                String contactId = paymentMethod.OrderApi__Contact__c != null ? paymentMethod.OrderApi__Contact__c : paymentMethod.OrderApi__Customer_ID__c;
                
                String accountId;
                if (((Id)contactId).getSObjectType().getDescribe().getName() == 'Account') {
                    if (accountIdWithContactIdMap.containsKey(contactId)) {
                        accountId = contactId;
                        contactId = accountIdWithContactIdMap.get(accountId);
                    }
                    else {
                        continue;
                    }
                }

                //exporting spreedly payment method token to stripe
                FDService.EPayRequest req = SpreedlyEPayService.createEpayRequest(stipeGatewayToken, paymentMethod.OrderApi__Payment_Method_Token__c);
                SpreedlyEPayService.createExportTokenBody(req);
                FDService.EPayResponse epayResponse = SpreedlyHTTPService.prepareAndDoAPICallout(req);
                
                if (!epayResponse.transactions.isEmpty()) {
                    FDService.EPayTransaction trans = epayResponse.transactions[0];

                    if (!contactsToUpdate.containsKey(contactId)) {
                        //updating payment customer id field on contact
                        contactsToUpdate.put(contactId, new Contact(Id=contactId, Payments_Customer_Id__c=trans.token));
                    }

                    OrderApi__Payment_Method__c newPaymentMethod = createPaymentMethod(trans, paymentMethod, contactId, accountId);
                    newPaymentMethod.Original_Saved_Payment_Method__c = paymentMethod.Id;
                    paymentMethodsToInsert.add(newPaymentMethod);

                    //updating existing payment method active field as false
                    paymentMethodsToUpdate.add(new OrderApi__Payment_Method__c(Id=paymentMethod.Id, OrderApi__Is_Active__c=false));
                } else if (!epayResponse.errors.isEmpty()) {
                    errorSystemLogs.add(SpreedlyHTTPService.createSystemLog('Spreedly Error Occured while Callout', epayResponse.errors[0].getMessage()));
                }
            }

            //Updating contact records
            if (!contactsToUpdate.isEmpty()) {
                Framework.SObjectService.updateRecords(contactsToUpdate.values());
            }

            if (!paymentMethodsToUpdate.isEmpty()) {
                Framework.SObjectService.updateRecords(paymentMethodsToUpdate);
            }

            if (!paymentMethodsToInsert.isEmpty()) {
                Framework.SObjectService.insertRecords(paymentMethodsToInsert);
            }

            SpreedlyHTTPService.insertSystemLogs();
        } catch(Exception e) {
            errorSystemLogs.add(SpreedlyHTTPService.createSystemLog('Spreedly Error Occured', e.getMessage() + ' ' + e.getStackTraceString()));
        }

        if (!errorSystemLogs.isEmpty()) {
            Framework.SObjectService.insertRecords(errorSystemLogs);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        SpreedlyHTTPService.path = 'TokenMigrationBatch/finish';
    }

    private OrderApi__Payment_Method__c createPaymentMethod(FDService.EPayTransaction trans, OrderApi__Payment_Method__c paymentMethod, String contactId, String accountId) {
        //creating payment method record
        OrderApi__Payment_Method__c paymentMethodObj = new OrderApi__Payment_Method__c(
            OrderApi__Payment_Method_Token__c = trans.token + SpreedlyAPIService.SEPRATOR + trans.payment_method_token,
            OrderApi__Payment_Method_Type__c = 'credit_card',
            OrderApi__Year__c = trans.payment_method.year,
            OrderApi__Month__c = trans.payment_method.month,
            OrderApi__Card_Type__c = trans.payment_method.card_type,
            OrderApi__Full_Name__c = trans.payment_method.full_name,
            OrderApi__Is_Active__c = true,
            OrderApi__Is_Declined__c = false,
            OrderApi__Is_Expired__c = false,
            OrderApi__Is_Valid__c = true,
            OrderApi__Email__c = trans.payment_method.email,
            OrderApi__Phone__c = trans.payment_method.phone,
            OrderApi__Billing_Street__c = trans.payment_method.address1,
            OrderApi__Billing_City__c = trans.payment_method.city,
            OrderApi__Billing_State__c = trans.payment_method.state,
            OrderApi__Billing_Postal_Code__c = trans.payment_method.zip,
            OrderApi__Billing_Country__c = trans.payment_method.country,
            OrderApi__Number__c = 'xxxx-xxxx-xxxx-' + trans.payment_method.last_four_digits,
            OrderApi__Last_Four_Digits__c = trans.payment_method.last_four_digits,
            OrderApi__First_Six_Digits__c = 'xxxxxx');

        if (accountId != null) {
            paymentMethodObj.OrderApi__Account__c = accountId;
            paymentMethodObj.OrderApi__Entity__c = 'Account';
        }
        else if (contactId != null) {
            paymentMethodObj.OrderApi__Contact__c = contactId;
            paymentMethodObj.OrderApi__Entity__c = 'Contact';
        }
        if(paymentMethod.Owner.IsActive != null && paymentMethod.Owner.IsActive){
            paymentMethodObj.OwnerId = paymentMethod.OwnerId;
        }
        
        return paymentMethodObj;
    }
}