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
 * @description Batch class for token migration from Spreedly to Stripe
 */
global with sharing class TokenMigrationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private String query;
    private String stipeGatewayToken;
    private final String connectedAccountId;
    private final Boolean isTestMode;

    global TokenMigrationBatch(Boolean isTestMode) {
        this('', isTestMode);
    }

    global TokenMigrationBatch(String whereClause, Boolean isTestMode) {
        this(
            Framework.Registry.getEntry('FontevaPayments', 'Default_Stripe_Account')?.Framework__Value__c,
            whereClause,
            isTestMode
        );
    }

    global TokenMigrationBatch(String connectedAccountId, String whereClause, Boolean isTestMode) {
        this.connectedAccountId = connectedAccountId;
        this.isTestMode = isTestMode;
        generateQuery(whereClause);
    }

    private void generateQuery(String whereClause) {
        this.query = 'SELECT Id,\n' +
            '    OrderApi__Account__c, OrderApi__Contact__c,\n' +
            '    OrderApi__Account__r.Name, OrderApi__Contact__r.Name,\n' +
            '    OrderApi__Customer_ID__c, OrderApi__Bank_Account_Holder_Type__c,\n' +
            '    OrderApi__Payment_Method_Token__c, OrderApi__Is_Active__c,\n' +
            '    OwnerId, Owner.IsActive\n' +
            'FROM OrderApi__Payment_Method__c ';
        if (String.isNotBlank(whereClause)) {
            this.query += whereClause;
        } else {
            this.query += 'WHERE OrderApi__Is_Active__c = TRUE ';
        }
        this.query += ' AND OrderApi__Billing_Postal_Code__c != NULL\n' +
            'AND Fonteva_Payment_Token__c = NULL\n' +
            'AND (NOT OrderApi__Payment_Method_Token__c LIKE \'' + SpreedlyAPIService.CUSTOMER_PREFIX + '%\')'; //Ignoring stripe payment method token
        this.query += ' ORDER BY OrderApi__Contact__c';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        SpreedlyHTTPService.path = 'TokenMigrationBatch/start';
        //initializing variable
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
        try {
            List<OrderApi__Payment_Method__c> paymentMethodsToUpdate = new List<OrderApi__Payment_Method__c>();

            //checking saved payment method is linked with account
            Set<Id> accountIds = new Set<Id>();

            Set<Id> paymentMethodIds = new Set<Id>();
            for (OrderApi__Payment_Method__c paymentMethod : paymentMethods) {
                paymentMethodIds.add(paymentMethod.Id);
            }

            for (OrderApi__Payment_Method__c paymentMethod : paymentMethods) {
                String customerId = paymentMethod.OrderApi__Contact__c != null ? paymentMethod.OrderApi__Contact__c : paymentMethod.OrderApi__Customer_ID__c;
                if (((Id) customerId).getSobjectType().getDescribe().getName() == 'Account') {
                    accountIds.add(customerId);
                }
            }

            //fetching account id for primary contact
            Map<Id, Id> accountIdWithContactIdMap = new Map<Id, Id>();
            if (!accountIds.isEmpty()) {
                Framework.Selector.ignoreSharingInContext();
                List<Account> accounts = (Account[]) new Framework.Selector(Account.SObjectType).selectById(accountIds);
                for (Account acc : accounts) {
                    accountIdWithContactIdMap.put(acc.Id, acc.OrderApi__Primary_Contact__c);
                }
            }
            for (OrderApi__Payment_Method__c paymentMethod : paymentMethods) {
                String contactId = paymentMethod.OrderApi__Contact__c != null ? paymentMethod.OrderApi__Contact__c : paymentMethod.OrderApi__Customer_ID__c;
                String customerName = paymentMethod.OrderApi__Contact__r != null ? paymentMethod.OrderApi__Contact__r.Name : paymentMethod.OrderApi__Account__r.Name;
                String accountId;
                if (((Id) contactId).getSobjectType().getDescribe().getName() == 'Account') {
                    if (accountIdWithContactIdMap.containsKey(contactId)) {
                        accountId = contactId;
                        contactId = accountIdWithContactIdMap.get(accountId);
                    } else {
                        continue;
                    }
                }

                //exporting spreedly payment method token to stripe
                FDService.EPayRequest req = SpreedlyEPayService.createEpayRequest(stipeGatewayToken, paymentMethod.OrderApi__Payment_Method_Token__c);
                SpreedlyEPayService.createExportTokenBody(req);
                FDService.EPayResponse epayResponse = SpreedlyHTTPService.prepareAndDoAPICallout(req);

                if (!epayResponse.transactions.isEmpty()) {
                    FDService.EPayTransaction trans = epayResponse.transactions[0];
                    String customerId = trans.token;
                    String paymentMethodId = trans.payment_method_token;
                    String paymentToken = customerId + '___' + paymentMethodId;
                    if (String.isNotBlank(connectedAccountId)
                        && String.isNotBlank(customerId)
                        && String.isNotBlank(paymentMethodId)) {
                        StripeHttpService stripeService = new StripeHttpService().updateStripeMode(isTestMode);
                        stripeService.updateCustomer(customerId, new Map<String, Object> {
                            'name' => customerName,
                            'metadata[connectedAccountId]' => connectedAccountId
                        });
                        stripeService.updatePaymentMethod(paymentMethodId, new Map<String, Object> {
                            'metadata[customerId]' => customerId,
                            'metadata[connectedAccountId]' => connectedAccountId
                        });
                    }

                    paymentMethodsToUpdate.add(new OrderApi__Payment_Method__c(
                        Id = paymentMethod.Id,
                        Token_Migration_Test__c = 'SUCCESS',
                        Fonteva_Payment_Token__c = paymentToken
                    ));
                } else if (!epayResponse.errors.isEmpty()) {
                    paymentMethodsToUpdate.add(new OrderApi__Payment_Method__c(
                        Id = paymentMethod.Id,
                        Token_Migration_Test__c = 'Error: ' + epayResponse.errors[0].getMessage()
                    ));
                }
            }
            if (!paymentMethodsToUpdate.isEmpty()) {
                Framework.SObjectService.updateRecords(paymentMethodsToUpdate);
            }
            SpreedlyHTTPService.insertSystemLogs();
        } catch (Exception e) {
            errorSystemLogs.add(SpreedlyHTTPService.createSystemLog('Token Migration Error Occurred', e.getMessage() + ' ' + e.getStackTraceString()));
        }

        if (!errorSystemLogs.isEmpty()) {
            Framework.SObjectService.insertRecords(errorSystemLogs);
        }
    }

    global void finish(Database.BatchableContext bc) {
        SpreedlyHTTPService.path = 'TokenMigrationBatch/finish';
    }
}
