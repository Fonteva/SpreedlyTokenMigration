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
 * @description Service class to create/parse json
 */
public inherited sharing class SpreedlyEPayService {
    /**
     * @description Creates a Stripe token request body
     * @param req FDService.EPayRequest
     * @param stripeKey String
     */
    public static void createStripeTokenBody(FDService.EPayRequest req, String stripeKey) {
        req.type = SpreedlyAPIService.MigrationType.GET_STRIPE_TOKEN.name();
        req.objects = new List<FDService.EPayRequest.RequestObject>();
        FDService.EPayRequest.RequestObject requestObject = new FDService.EPayRequest.RequestObject();
        requestObject.name = 'gateway';
        requestObject.elements = new List<FDService.EPayRequest.Element>();
        requestObject.elements.add(new FDService.EPayRequest.Element('gateway_type', 'stripe'));
        requestObject.elements.add(new FDService.EPayRequest.Element('login', stripeKey));
        requestObject.elements.add(new FDService.EPayRequest.Element('version_override', '2020-08-27'));
        req.objects.add(requestObject);
    }

    /**
     * @description Creates an export token request body
     * @param req FDService.EPayRequest
     */
    public static void createExportTokenBody(FDService.EPayRequest req) {
        req.type = SpreedlyAPIService.MigrationType.EXPORT_TOKEN.name();
        req.objects = new List<FDService.EPayRequest.RequestObject>();
        FDService.EPayRequest.RequestObject requestObject = new FDService.EPayRequest.RequestObject();
        requestObject.name = 'transaction';
        requestObject.elements = new List<FDService.EPayRequest.Element>();
        requestObject.elements.add(new FDService.EPayRequest.Element('payment_method_token', req.paymentMethod.paymentMethodToken));
        requestObject.elements.add(new FDService.EPayRequest.Element('obj__gateway_specific_fields', JSON.serialize(new Map<String, Object> {
            'stripe' => new Map<String, Object> {
                'validate' => false
            }
        })));
        req.objects.add(requestObject);
    }

    /**
     * @description Converts an FDService.EPayRequest object into a request body string
     * @param ePayRequestWrapper FDService.EPayRequest
     * @return String
     */
    public static String createRequestBody(FDService.EPayRequest ePayRequestWrapper) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
        String objKeyPrefix = 'obj__';
        for (FDService.EPayRequest.RequestObject requestObject : ePayRequestWrapper.objects) {
            generator.writeFieldName(requestObject.name);
            generator.writeStartObject();

            for (FDService.EPayRequest.Element elem : requestObject.elements) {
                if (String.isNotBlank(elem.key) && elem.key.startsWith(objKeyPrefix)) {
                    Object obj = JSON.deserializeUntyped(elem.value);
                    generator.writeFieldName(elem.key.removeStart(objKeyPrefix));
                    generator.writeObject(obj);
                } else if (String.isNotBlank(elem.key)) {
                    generator.writeFieldName(elem.key);
                    generator.writeObject(elem.value);
                }
            }

            generator.writeEndObject();
        }

        generator.writeEndObject();
        return generator.getAsString();
    }

    /**
     * @description Creates EpayRequest according to gatewayToken and paymentMethodToken & then return it
     * @param gatewayToken String
     * @param paymentMethodToken String
     * @return FDService.EPayRequest
     */
    public static FDService.EPayRequest createEpayRequest(String gatewayToken, String paymentMethodToken) {
        FDService.EPayRequest ePayRequest = new FDService.EPayRequest();
        ePayRequest.paymentMethod = new FDService.PaymentMethod();
        ePayRequest.paymentMethod.paymentMethodToken = paymentMethodToken;
        ePayRequest.gateway = new FDService.PaymentGateway();
        ePayRequest.gateway.token = gatewayToken;
        return ePayRequest;
    }

    /**
     * @description Parses an HTTP response into an FDService.EPayResponse
     * @param ePayRequest FDService.EPayRequest
     * @param response HttpResponse
     * @return FDService.EPayResponse
     */
    public static FDService.EPayResponse parseResponse(FDService.EPayRequest ePayRequest, HttpResponse response) {
        FDService.EPayResponse ePayResponseWrapper = FDService.EPayResponse.getInstance();
        ePayResponseWrapper.http_status_code = response.getStatusCode();
        ePayResponseWrapper.http_status_message = response.getStatus();
        ePayResponseWrapper = parseResponse(ePayRequest, ePayResponseWrapper, response.getBody());
        return ePayResponseWrapper;
    }

    /**
     * @description Parse an HTTP response into an FDService.EPayResponse
     * @param ePayRequest FDService.EPayRequest
     * @param ePayResponseWrapper FDService.EPayResponse
     * @param responseBody String
     * @return FDService.EPayResponse
     */
    public static FDService.EPayResponse parseResponse(FDService.EPayRequest ePayRequest, FDService.EPayResponse ePayResponseWrapper, String responseBody) {
        ePayResponseWrapper.transactions = new List<FDService.EPayTransaction>();
        ePayResponseWrapper.errors = new List<FDService.Error>();

        SpreedlyAPIResponse wrapperObj = SpreedlyAPIResponse.parse(responseBody);
        if (ePayResponseWrapper.http_status_code != 200 && ePayResponseWrapper.http_status_code != 201) {
            ePayResponseWrapper.errors.add(new FDService.Error('' + ePayResponseWrapper.http_status_code, wrapperObj.transaction_z?.message));
            return ePayResponseWrapper;
        }

        ePayResponseWrapper.transactions.add(wrapperObj.createEPayTransaction());
        return ePayResponseWrapper;
    }
}