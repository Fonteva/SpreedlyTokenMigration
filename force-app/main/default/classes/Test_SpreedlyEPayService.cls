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
public without sharing class Test_SpreedlyEPayService extends MockTestBase{
    @isTest
    static void testCreateRequestBody() {
        Test.startTest();

        FDService.EPayRequest req = SpreedlyEPayService.createEpayRequest('IfQpsAYp3fOD7U0yS1OeqXybHcU', 'O8hP76edNVpC1tZ5pnZlgB10Th0');
        SpreedlyEPayService.createStripeTokenBody(req, 'test stripe key');
        System.assertEquals('gateway', req.objects[0].name, 'Expected body is not generated');
            
        SpreedlyEPayService.createExportTokenBody(req);
        System.assertEquals('transaction', req.objects[0].name, 'Expected body is not generated');
        
        String body = SpreedlyEPayService.createRequestBody(req);
        System.assertEquals('{"transaction":{"payment_method_token":"O8hP76edNVpC1tZ5pnZlgB10Th0","gateway_specific_fields":{"stripe":{"validate":false}}}}', body, 'Expected body is not created');
        
        Test.stopTest();
    }
    
    @isTest
    static void testParseResponse() {
        Test.startTest();

        FDService.EPayRequest req = SpreedlyEPayService.createEpayRequest('IfQpsAYp3fOD7U0yS1OeqXybHcU', 'O8hP76edNVpC1tZ5pnZlgB10Th0');
        SpreedlyEPayService.createStripeTokenBody(req, 'test stripe key');
        
        //with success code
        HttpResponse res = new HttpResponse();
        res.setStatusCode(201);
        res.setBody('{"gateway":{"token":"O8hP76edNVpC1tZ5pnZlgB10Th0","gateway_type":"stripe","description":null,"merchant_profile_key":null,"payment_methods":["credit_card","third_party_token","apple_pay","bank_account","google_pay"],"state":"retained","created_at":"2022-01-13T09:44:18Z","updated_at":"2022-01-13T09:44:18Z","name":"Stripe","characteristics":["purchase","authorize","capture","credit","void","verify","3dsecure_purchase","3dsecure_authorize","store","remove"],"credentials":[],"gateway_settings":{"webhook_id":null,"version_override":"2020-08-27"},"gateway_specific_fields":["receipt_email","radar_session_id","skip_radar_rules","application_fee","stripe_account","metadata","idempotency_key","reason","refund_application_fee","refund_fee_amount","reverse_transfer","account_id","customer_id","validate","make_default","statement_description","statement_descriptor_suffix","destination","destination_amount","merchant_reference","customer_reference","shipping_address_zip","shipping_from_zip","shipping_amount","line_items","transfer_destination","transfer_amount","transfer_group","on_behalf_of","application_fee_amount"],"redacted":false,"sandbox":false}}');
        FDService.EPayResponse ePayResponseWrapper = SpreedlyEPayService.parseResponse(req, res);
        System.assert(!ePayResponseWrapper.transactions.isEmpty(), 'Transactions are not returned');
        
        //with error code
        res = new HttpResponse();
        res.setStatusCode(422);
        res.setBody('{"gateway":{"message": "Your card expiration year is invalid.","token":"O8hP76edNPpC4tZ5pnZlgB42Th2","gateway_type":"stripe","description":null,"merchant_profile_key":null,"payment_methods":["credit_card","third_party_token","apple_pay","bank_account","google_pay"],"state":"retained","created_at":"2022-01-13T09:44:18Z","updated_at":"2022-01-13T09:44:18Z","name":"Stripe","characteristics":["purchase","authorize","capture","credit","void","verify","3dsecure_purchase","3dsecure_authorize","store","remove"],"credentials":[],"gateway_settings":{"webhook_id":null,"version_override":"2020-08-27"},"gateway_specific_fields":["receipt_email","radar_session_id","skip_radar_rules","application_fee","stripe_account","metadata","idempotency_key","reason","refund_application_fee","refund_fee_amount","reverse_transfer","account_id","customer_id","validate","make_default","statement_description","statement_descriptor_suffix","destination","destination_amount","merchant_reference","customer_reference","shipping_address_zip","shipping_from_zip","shipping_amount","line_items","transfer_destination","transfer_amount","transfer_group","on_behalf_of","application_fee_amount"],"redacted":false,"sandbox":false}}');
        ePayResponseWrapper = SpreedlyEPayService.parseResponse(req, res);
        System.assert(!ePayResponseWrapper.errors.isEmpty(), 'Errors are not returned');
        
        Test.stopTest();
    }
}