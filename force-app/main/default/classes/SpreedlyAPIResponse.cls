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
 * @name SpreedlyAPIResponse
 * @description Wrapper class to parse Spreedly json
 */
public inherited sharing class SpreedlyAPIResponse {
    public SpreedlyGateway gateway;
    public SpreedlyTransaction transaction_z;

    public inherited sharing class SpreedlyGateway{
        public String token;
        public String gateway_type;
    }

    public inherited sharing class SpreedlyTransaction{
        public String token;
        public String message;
        public String gateway_transaction_id;
        public PaymentMethod basis_payment_method;
    }

    public inherited sharing class PaymentMethod{
        public String full_name;
        public String card_type;
        public Integer year;
        public Integer month;
        public String email;
        public String phone_number;
        public String address1;
        public String city;
        public String state;
        public String zip;
        public String country;
        public String last_four_digits;
    }

    /**
     * Parses a response from the Spreedly API
     * @param responseBody response body json
     * @return SpreedlyAPIResponse
     */
    public static SpreedlyAPIResponse parse(String responseBody) {
        //Replacing transaction with transaction_z
        responseBody = responseBody.replace('"transaction"', '"transaction_z"');
        return (SpreedlyAPIResponse)JSON.deserialize(responseBody, SpreedlyAPIResponse.class);
    }

    /**
     * Returns an FDService.EPayTransaction according to the Spreedly response
     * @param no param
     * @return FDService.EPayTransaction
     */
    public FDService.EPayTransaction createEPayTransaction() {
        FDService.EPayTransaction trans = new FDService.EPayTransaction();

        if (gateway != null) {
            trans.token = gateway.token;
        }
        
        if (transaction_z != null) {
            List<String> tokens = transaction_z.gateway_transaction_id.split('\\|');

            if (!tokens.isEmpty() && tokens.size() == 2) {
                trans.token = tokens[0];
                trans.payment_method_token = tokens[1];
            }

            if (transaction_z.basis_payment_method != null) {
                trans.payment_method = new FDService.EPayTransaction.PaymentMethod();
                trans.payment_method.full_name = transaction_z.basis_payment_method.full_name;
                trans.payment_method.email = transaction_z.basis_payment_method.email;
                trans.payment_method.phone = transaction_z.basis_payment_method.phone_number;
                trans.payment_method.card_type = transaction_z.basis_payment_method.card_type;
                trans.payment_method.last_four_digits = transaction_z.basis_payment_method.last_four_digits;
                trans.payment_method.year = transaction_z.basis_payment_method.year;
                trans.payment_method.month = transaction_z.basis_payment_method.month;
                trans.payment_method.address1 = transaction_z.basis_payment_method.address1;
                trans.payment_method.city = transaction_z.basis_payment_method.city;
                trans.payment_method.state = transaction_z.basis_payment_method.state;
                trans.payment_method.country = transaction_z.basis_payment_method.country;
                trans.payment_method.zip = transaction_z.basis_payment_method.zip;
            }
        }

        return trans;
    }
}