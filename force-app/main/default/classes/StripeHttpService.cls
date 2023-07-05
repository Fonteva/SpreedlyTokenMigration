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
public inherited sharing class StripeHttpService {
    private static final Integer MAX_TIMEOUT = 120000;
    private static final Integer HTTP_OK_CODE = 200;
    private static StripeHttpService instance;
    private Boolean isTest = true;
    private String connectedAccountId;

    private StripeHttpService() {
    }

    public static StripeHttpService getInstance() {
        if (instance == null) {
            instance = new StripeHttpService();
        }
        return instance;
    }

    public StripeHttpService withConnectedAccountId(String connectedAccount) {
        connectedAccountId = connectedAccount;
        return this;
    }

    /**
     * @description updating stripe mode "Live" OR "Test"
     * @param isTestMode Represents the checkbox field OrderApi__Payment_Gateway__c.OrderApi__Is_Test__c.
     * @return IStripeApi
     **/
    public StripeHttpService updateStripeMode(Boolean isTestMode) {
        if (isTestMode == null) {
            throw new HandledException('isTestMode cannot be null');
        }
        this.isTest = isTestMode;
        return this;
    }

    public String updatePaymentMethod(String paymentMethodId, Map<String, Object> params) {
        String endpoint = StripeAPIService.getEndpoint(StripeAPIService.TransactionType.UPDATE_PAYMENT_METHOD, paymentMethodId);
        String urlParams = buildEncodedParameters(params, false);
        return execute('POST', endpoint + urlParams);
    }

    public String updateCustomer(String customerId, Map<String, Object> params) {
        String endpoint = StripeAPIService.getEndpoint(StripeAPIService.TransactionType.UPDATE_CUSTOMER, customerId);
        String urlParams = buildEncodedParameters(params, false);
        return execute('POST', endpoint + urlParams);
    }

    /**
     * @description Makes the callout to Stripe
     * @param method - HTTP Method
     * @param endpointAndParams - Endpoint to call
     * @return Response Body
     */
    private String execute(String method, String endpointAndParams) {
        return execute(method, endpointAndParams, null);
    }

    /**
     * @description Makes callout to Stripe
     * @param method - HTTP Method
     * @param endpoint - Endpoint to call
     * @param body - Request Body
     * @return Response Body
     */
    private String execute(String method, String endpoint, String body) {
        StripeAPIService.StripeCredentials credentials = StripeAPIService.getCredentials(this.isTest);
        HttpRequest request = new HttpRequest();
        request.setTimeout(MAX_TIMEOUT);
        request.setMethod(method);
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Authorization', 'Bearer ' + credentials.secretKey);

        if (String.isNotBlank(endpoint) && String.isNotBlank(this.connectedAccountId)) {
            request.setHeader('Stripe-Account', this.connectedAccountId);
        }

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != HTTP_OK_CODE) {
            StripeErrorContainer responseError = (StripeErrorContainer) System.JSON.deserialize(
                response.getBody(),
                StripeErrorContainer.class
            );
            throw new HandledException(responseError.error?.message != null ? responseError.error.message : 'Stripe Error');
        }
        return response.getBody();
    }


    /**
     * @description Builds the query parameters based on a generic map
     * @param params - Generic Map of key => value pair
     * @param urlHasAlreadyQueryParams - Boolean to determine if the url already has query params
     * @return String
     */
    private static String buildEncodedParameters(Map<String, Object> params, Boolean urlHasAlreadyQueryParams) {
        String queryString = '';
        if (params.size() > 0) {
            List<String> nameValuePairs = new List<String>();
            for (String key : params.keySet()) {
                if (key == 'metadata') {
                    Map<String, Object> subObject = (Map<String, Object>) params.get(key);
                    for (String subObjectKey : subObject.keySet()) {
                        Object subObjectValue = subObject.get(subObjectKey);
                        if (subObjectValue != null) {
                            nameValuePairs.add(key + '[' + subObjectKey + ']=' + EncodingUtil.urlEncode(subObjectValue.toString(), 'UTF-8'));
                        }
                    }
                } else {
                    //Build key value pair
                    nameValuePairs.add(key + '=' + EncodingUtil.urlEncode(String.valueOf(params.get(key)), 'UTF-8'));
                }
            }

            if (urlHasAlreadyQueryParams) {
                queryString += '&' + String.join(nameValuePairs, '&');
            } else {
                queryString += '?' + String.join(nameValuePairs, '&');
            }
        }
        return queryString;
    }

    public inherited sharing class StripeErrorContainer {
        public StripeError error { get; set; }
    }

    public inherited sharing class StripeError {
        public String code { get; set; }
        public String doc_url { get; set; }
        public String message { get; set; }
        public String param { get; set; }
        public String type { get; set; }
    }
}