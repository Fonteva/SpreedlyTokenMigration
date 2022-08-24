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
public inherited sharing class SpreedlyHTTPCalloutMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;

    public SpreedlyHttpCalloutMock() {}

    /**
    * @description Initializes a new instance of the SpreedlyHttpCalloutMock class
    * @param code
    * @param status
    * @param body
    * @param responseHeaders
    **/
    public SpreedlyHttpCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.bodyAsString = body;
        this.bodyAsBlob = null;
        this.responseHeaders = responseHeaders;
    }

    /**
    * @description Initializes a new instance of the SpreedlyHttpCalloutMock class
    * @param code
    * @param status
    * @param body
    * @param responseHeaders
    **/
    public SpreedlyHttpCalloutMock(Integer code, String status, Blob body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.bodyAsBlob = body;
        this.bodyAsString = null;
        this.responseHeaders = responseHeaders;
    }

    /**
    * @description Generates a mock response for a REST API callout
    * @param req
    * @return HTTPResponse
    **/
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setStatus(status);

        if (bodyAsBlob != null) {
            resp.setBodyAsBlob(bodyAsBlob);
        } else {
            resp.setBody(bodyAsString);
        }

        if (responseHeaders != null) {
            for (String key : responseHeaders.keySet()) {
                resp.setHeader(key, responseHeaders.get(key));
            }
        }

        return resp;
    }
    
    /**
    * @description Generates a mock response for a given HTTP status and response body
    * @param statusCode
    * @param status
    * @param js
    * @return SpreedlyHttpCalloutMock
    **/
    public static SpreedlyHttpCalloutMock generateMock(Integer statusCode, String status, String js) {
        SpreedlyHttpCalloutMock fakeHttpResponse = new SpreedlyHttpCalloutMock(statusCode, status, js, null);
        return fakeHttpResponse;
    }

    /**
    * @description Generates a mock Stripe access token success response
    * @return SpreedlyHttpCalloutMock
    **/
    public static SpreedlyHttpCalloutMock generateStripeAccessTokenSuccess() {
        String jsResponse = '{"gateway":{"token":"O8hP76edNVpC1tZ5pnZlgB10Th0","gateway_type":"stripe","description":null,"merchant_profile_key":null,"payment_methods":["credit_card","third_party_token","apple_pay","bank_account","google_pay"],"state":"retained","created_at":"2022-01-13T09:44:18Z","updated_at":"2022-01-13T09:44:18Z","name":"Spreedly","characteristics":["purchase","authorize","capture","credit","void","verify","3dsecure_purchase","3dsecure_authorize","store","remove"],"credentials":[],"gateway_settings":{"webhook_id":null,"version_override":"2020-08-27"},"gateway_specific_fields":["receipt_email","radar_session_id","skip_radar_rules","application_fee","stripe_account","metadata","idempotency_key","reason","refund_application_fee","refund_fee_amount","reverse_transfer","account_id","customer_id","validate","make_default","statement_description","statement_descriptor_suffix","destination","destination_amount","merchant_reference","customer_reference","shipping_address_zip","shipping_from_zip","shipping_amount","line_items","transfer_destination","transfer_amount","transfer_group","on_behalf_of","application_fee_amount"],"redacted":false,"sandbox":false}}';
        return generateMock(201, 'OK', jsResponse);
    }

    /**
    * @description Generates a mock export token success response
    * @return SpreedlyHttpCalloutMock
    **/
    public static SpreedlyHttpCalloutMock generateExportTokenSuccess() {
        String jsResponse = '{"transaction":{"created_at":"2022-01-13T16:25:20Z","currency_code":null,"updated_at":"2022-01-13T16:25:21Z","succeeded":true,"token":"abcJaTGJ0ZZMmFOwCuZGS3abcde","state":"succeeded","gateway_specific_fields":null,"gateway_specific_response_fields":{"stripe":{}},"transaction_type":"Store","third_party_token":null,"gateway_transaction_id":"cus_KxQ1234wsNzABC|card_123W72DLFJuE12EPQRxAcEn1","gateway_latency_ms":779,"message_key":"messages.transaction_succeeded","message":"Succeeded!","gateway_token":"O8hP76edNVpC1tZ5pnZlgB10Th0","gateway_type":"stripe","payment_method":{"token":"6898eoyCsPG8MPrKHhATlaR3iZp","created_at":"2022-01-13T16:25:21Z","updated_at":"2022-01-13T16:25:21Z","gateway_type":"stripe","storage_state":"retained","metadata":null,"third_party_token":"cus_KxQ1234wsNzABC|card_123W72DLFJuE12EPQRxAcEn1","payment_method_type":"third_party_token","errors":[]},"basis_payment_method":{"token":"IfQpsAYp3fOD7U0yS1OeqXybHcU","created_at":"2022-01-10T11:59:45Z","updated_at":"2022-01-13T16:25:21Z","email":null,"data":null,"storage_state":"retained","test":true,"metadata":null,"callback_url":null,"last_four_digits":"4444","first_six_digits":"555555","card_type":"master","first_name":"Test","last_name":"Harting","month":7,"year":2025,"address1":"3/417, Satkar shopping center, Malviya nagar","address2":null,"city":"Jaipur","state":"Rajasthan","zip":"302017","country":"IN","phone_number":null,"company":null,"full_name":"Test Harting","eligible_for_card_updater":false,"shipping_address1":null,"shipping_address2":null,"shipping_city":null,"shipping_state":null,"shipping_zip":null,"shipping_country":null,"shipping_phone_number":null,"payment_method_type":"credit_card","errors":[],"fingerprint":"d0ba923dcb485fa4453cc8cc721a2485f1b0","verification_value":"","number":"XXXX-XXXX-XXXX-4444"},"response":{"success":true,"message":"Transaction approved","avs_code":null,"avs_message":null,"cvv_code":null,"cvv_message":null,"pending":false,"result_unknown":false,"error_code":null,"error_detail":null,"cancelled":false,"fraud_review":null,"created_at":"2022-01-13T16:25:21Z","updated_at":"2022-01-13T16:25:21Z"}}}';
        return generateMock(200, 'OK', jsResponse);
    }
}