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
public without sharing class Test_SpreedlyHTTPService extends MockTestBase {
    @isTest
    static void testSpreedlyAPICallout() {
        Test.setMock(HttpCalloutMock.class, SpreedlyHttpCalloutMock.generateStripeAccessTokenSuccess());
        
        Test.startTest();
        
        FDService.EPayRequest req = SpreedlyEpayService.createEpayRequest('IfQpsAYp3fOD7U0yS1OeqXybHcU', 'O8hP76edNVpC1tZ5pnZlgB10Th0');
        SpreedlyEPayService.createExportTokenBody(req);
        FDService.EPayResponse epayResponse = SpreedlyHTTPService.prepareAndDoAPICallout(req);
        System.assertEquals('O8hP76edNVpC1tZ5pnZlgB10Th0', epayResponse.transactions[0].token, 'Stripe token is not returned');
        
        SpreedlyHTTPService.logAPICallout('', '');
        SpreedlyHTTPService.insertSystemLogs();
        
        Test.stopTest();
    }
}