/*
 * -----------------------------------------------------------------------------
 * COPYRIGHT (C) 2023, FONTEVA, INC.
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
@IsTest
public with sharing class Test_StripeHttpService extends MockTestBase {

    @IsTest
    private static void testStripeRequestError() {
        Test.setMock(HttpCalloutMock.class, SpreedlyHTTPCalloutMock.getStripeErrorMock());
        Test.startTest();
        StripeHttpService stripeHttpService = StripeHttpService.getInstance()
            .updateStripeMode(true)
            .withConnectedAccountId('acct_123');
        try {
            stripeHttpService.updateCustomer('cus_OC9Cx0fmzZ9Cs0', new Map<String, Object> {
                'name' => 'Test Name',
                'metadata[connectedAccountId]' => 'acct_123'
            });
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().startsWith('No such customer'));
        }
        Test.stopTest();
    }

    @IsTest
    private static void testUpdateCustomer() {
        Test.setMock(HttpCalloutMock.class, SpreedlyHTTPCalloutMock.getStripeUpdateCustomerMock());
        StripeHttpService stripeHttpService = StripeHttpService.getInstance()
            .updateStripeMode(true)
            .withConnectedAccountId('acct_123');
        String responseString;
        Map<String, Object> responseMap;

        Test.startTest();
        responseString = stripeHttpService.updateCustomer('cus_OC9LIv8GV41tRs', new Map<String, Object> {
            'name' => 'Test Name',
            'metadata[connectedAccountId]' => 'acct_123'
        });
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        Test.stopTest();

        Assert.areEqual(responseMap.get('id'), 'cus_OC9LIv8GV41tRs');
        Assert.areEqual(responseMap.get('object'), 'customer');
        Map<String, Object> metadataMap = (Map<String, Object>) responseMap.get('metadata');
        Assert.areEqual(metadataMap.get('connectedAccountId'), 'acct_1NGj2vRhGwhv8H8k');
    }

    @IsTest
    private static void testPaymentMethod() {
        Test.setMock(HttpCalloutMock.class, SpreedlyHTTPCalloutMock.getStripeUpdatePaymentMethodMock());
        StripeHttpService stripeHttpService = StripeHttpService.getInstance()
            .updateStripeMode(true)
            .withConnectedAccountId('acct_123');
        String responseString;
        Map<String, Object> responseMap;

        Test.startTest();
        responseString = stripeHttpService.updatePaymentMethod('card_1NPl3CDLFJuEW2E7efJemyLj', new Map<String, Object> {
            'metadata[customerId]' => 'cus_OC9LIv8GV41tRs',
            'metadata[connectedAccountId]' => 'acct_1NGj2vRhGwhv8H8k'
        });
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        Test.stopTest();

        Assert.areEqual(responseMap.get('id'), 'card_1NPl3CDLFJuEW2E7efJemyLj');
        Assert.areEqual(responseMap.get('object'), 'payment_method');
        Map<String, Object> metadataMap = (Map<String, Object>) responseMap.get('metadata');
        Assert.areEqual(metadataMap.get('customerId'), 'cus_OC9LIv8GV41tRs');
        Assert.areEqual(metadataMap.get('connectedAccountId'), 'acct_1NGj2vRhGwhv8H8k');
    }

    @IsTest
    private static void testStripeError() {
        Test.startTest();
        StripeHttpService.StripeErrorContainer responseError = (StripeHttpService.StripeErrorContainer) System.JSON.deserialize(
            SpreedlyHTTPCalloutMock.getStripeErrorMock().bodyAsString,
            StripeHttpService.StripeErrorContainer.class
        );
        Test.stopTest();

        Assert.areEqual(responseError.error.code, 'resource_missing');
        Assert.isNotNull(responseError.error.doc_url);
        Assert.areEqual(responseError.error.message, 'No such customer: \'cus_OC9Cx0fmzZ9Cs0\'');
        Assert.isNotNull(responseError.error.param);
        Assert.areEqual(responseError.error.type, 'invalid_request_error');
    }

}