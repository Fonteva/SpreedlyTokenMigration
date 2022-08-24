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
 * @name SpreedlyHTTPService
 * @description  Extends the standard salesforce HTTP calls. The core http calls will be extended here.
 */
public inherited sharing class SpreedlyHTTPService {
    public static String path = 'SpreedlyHTTPService';
    public static final Integer MAX_SIZE = 32000;
    private static List<Framework__System_Log__c> systemLogs = new List<Framework__System_Log__c>();

    /**
     * Returns an HttpRequest object for the given FDService.EPayRequest
     * @param   obj FDService.EPayRequest
     * @return  HttpRequest
     */
    private static HttpRequest prepareAPI(FDService.EPayRequest obj) {
        SpreedlyAPIService.MigrationType objType = SpreedlyAPIService.getMigrationType(obj.type);
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setHeader('Authorization', SpreedlyAPIService.getAuthHeader());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(SpreedlyAPIService.getEndpoint(objType, obj.gateway.token));
        req.setMethod('POST');
        req.setBody(SpreedlyEPayService.createRequestBody(obj));
        
        return req;
    }

    /**
     * Calls out to a Spreedly API endpoint and parses the response
     * @param obj FDService.EPayRequest
     * @return FDService.EPayResponse
     */
    public static FDService.EPayResponse prepareAndDoAPICallout(FDService.EPayRequest ePayRequest) {
        HttpRequest req = prepareAPI(ePayRequest);
        HttpResponse res =  doAPICallout(req);
        return SpreedlyEPayService.parseResponse(ePayRequest, res);
    }

    /**
     * Executes the callout
     * @param req HttpRequest
     * @return HttpResponse
     */
    public static HttpResponse doAPICallout(HttpRequest req) {
        Http http = new Http();
        HttpResponse resp = http.send(req);
        OrderApi.PaymentConfigPreferences pref = new OrderApi.PaymentConfigPreferences();

        if (pref.isDebugModeEnabled()) {
            SpreedlyHTTPService.logAPICallout(resp.getBody(), req.getBody());
        }

        return resp;
    }

    /**
     * Logs request & response as Framework__System_Log__c records
     * @param resp String
     * @param req String
     * @return void
     */
    public static void logAPICallout(String resp,String req) {
        resp = (resp == null) ? '' : resp;
        req = (req == null) ? '' : req;

        systemLogs.add(SpreedlyHTTPService.createSystemLog('Spreedly Rest API Request', req));
        systemLogs.add(SpreedlyHTTPService.createSystemLog('Spreedly Rest API Response', resp));
    }

    /**
     * This method creates a new System log record according to the information procided
     * @param type String
     * @param data String
     * @return Framework__System_Log__c
     */
    public static Framework__System_Log__c createSystemLog(String type, String data) {
        Framework__System_Log__c log = new Framework__System_Log__c();

        log.Framework__Type__c = type;
        if (data != null && data.length() > MAX_SIZE) {
            log.Framework__Data__c = data.substring(0, MAX_SIZE);
        } else {
            log.Framework__Data__c = data;
        }
        log.Framework__Registered_App__c = 'Stripe';
        log.Framework__Path__c = path;

        return log;
    }
    
    /**
     * This method inserts the system log records
     * @param no param
     * @return void
     */
    public static void insertSystemLogs() {
        if (!systemLogs.isEmpty()) {
            Framework.SObjectService.insertRecords(systemLogs);
        }
    }
}