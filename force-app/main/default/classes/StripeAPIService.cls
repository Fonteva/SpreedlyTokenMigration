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
public with sharing class StripeAPIService {
    public static final String BASE_URL = 'https://api.stripe.com';
    private static final Map<Boolean, StripeCredentials> credentialsMap = new Map<Boolean, StripeCredentials> {
        true => new StripeCredentials(true),
        false => new StripeCredentials(false)
    };

    public enum TransactionType {
        UPDATE_PAYMENT_METHOD,
        UPDATE_CUSTOMER
    }

    /**
     * @description Map of TransactionType to the resource portion of the endpoint uri for
     * the api request
     */
    private static final Map<TransactionType, String> RESOURCES = new Map<TransactionType, String> {
        TransactionType.UPDATE_PAYMENT_METHOD => '/v1/payment_methods/{0}',
        TransactionType.UPDATE_CUSTOMER => '/v1/customers/{0}'
    };

    /**
     * @description Returns the Stripe Credentials according to the isTest field
     * @param isTest
     * @return StripeCredentials
     */
    public static StripeCredentials getCredentials(Boolean isTest) {
        if (isTest == null) {
            throw new HandledException('isTest cannot be null');
        }

        return credentialsMap.get(isTest);
    }


    /**
     * @description Returns string value of api endpoint url for a given TransactionType
     * @param type Type of api transaction {Enum}
     * @return String API endpoint URL in string form
     */
    public static String getEndpoint(TransactionType type) {
        return getEndpoint(type, '');
    }

    /**
     * @description Returns string value for api endpoint for a given TransactionType and token (string)
     * @param type Type of api transaction
     * @param token String value of transaction, gateway, or payment method token
     * @return String API endpoint URL in string form
     * @throws HandledException When a activity type requires a token and the token is null or empty
     */
    public static String getEndpoint(TransactionType type, String token) {
        return getEndpoint(type, new List<String> {
            token
        });
    }

    /**
     * @description Returns string value for api endpoint for a given TransactionType and token (string)
     * @param type Type of api transaction
     * @param tokens List<String> values of transaction, gateway, or payment method token
     * @return String API endpoint URL in string form
     * @throws HandledException When a activity type requires a token and the token is null or empty
     */
    public static String getEndpoint(TransactionType type, List<String> tokens) {
        return BASE_URL + String.format(RESOURCES.get(type), tokens);
    }

    /**
     * @description populated the stripe setting custom metadata records
     */
    public inherited sharing class StripeCredentials {
        public String secretKey;
        public String publishableKey;
        public StripeCredentials() {
        }

        public StripeCredentials(Boolean isTest) {
            if (isTest == null) {
                throw new HandledException('isTest cannot be null');
            }
            String prefix = isTest ? 'test_' : 'live_';
            this.secretKey = getKey(prefix + 'secret_key');
            this.publishableKey = getKey(prefix + 'publishable_key');
        }

        private String getKey(String name) {
            Map<String, String> keys = Framework.Keystore.getEntryMapByCat('FontevaPay');
            String ksName = 'Stripe_' + name;
            if (keys.containsKey(ksName)) {
                return EncryptionUtil.decrypt(keys.get(ksName));
            } else {
                return Stripe_Creds__mdt.getInstance(name)?.Value__c;
            }
        }
    }

}