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
public without sharing class Test_SpreedlyAPIService extends MockTestBase {
    @isTest
    static void testAuthorizationMethods() {
        Test.startTest();
        
        //Act
        String endPoint = SpreedlyAPIService.getEndpoint(SpreedlyAPIService.getMigrationType('GET_STRIPE_TOKEN'));
        String authHeader = SpreedlyAPIService.getAuthHeader();
        
        Test.stopTest();
        
        System.assertEquals('https://core.spreedly.com/v1/gateways.json', endPoint, 'Endpoint is not of Stripe Token');
        System.assert(authHeader != null, 'Auth Header is not returned');
    }
}