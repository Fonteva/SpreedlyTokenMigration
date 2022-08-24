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

/*
 * @name SpreedlyAPIService
 * @description contains all the details related to the spreedly api
 */
public inherited sharing class SpreedlyAPIService {
    public static final String BASE_URL = 'https://core.spreedly.com';
    public static final String CUSTOMER_PREFIX = 'cus_';
    public static final String SEPRATOR = '___';

    /**
     * Map of boolean with StripeCredentials
     */
    private static Map<Boolean, StripeCredentials> credsMap = new Map<Boolean, StripeCredentials>{
        true => new StripeCredentials(true),
        false => new StripeCredentials(false)
    };

    //This Enum contains all the api's names
    public enum MigrationType {
        GET_STRIPE_TOKEN,
        EXPORT_TOKEN
    }

    /**
     * Map of String with MigrationType
     */
    private static Map<String, MigrationType> migrationTypes = new Map<String, MigrationType>{
        'GET_STRIPE_TOKEN' => MigrationType.GET_STRIPE_TOKEN,
        'EXPORT_TOKEN' => MigrationType.EXPORT_TOKEN
    };

    /**
     * Map of MigrationType to the resource portion of the endpoint uri for
     * the api request
     */
    private static Map<MigrationType, String> resources = new Map<MigrationType, String>{
            MigrationType.GET_STRIPE_TOKEN => '/v1/gateways.json',
            MigrationType.EXPORT_TOKEN => '/v1/gateways/{0}/store.json'
    };

    /**
     * Returns an endpoint URL for a given MigrationType
     * @param MigrationType Type of api transaction {Enum}
     * @return String API endpoint URL in string form
     */
    public static String getEndpoint(MigrationType type) {
        return getEndpoint(type, '');
    }

    /**
     * Returns an endpoint URL for a given MigrationType and token (string)
     * @param MigrationType Type of api transaction
     * @param token String value of transaction, gateway, or payment method token
     * @throws TokenRequiredException When a activity type requires a token and the token is null or empty
     * @return String API endpoint URL in string form
     */
    public static String getEndpoint(MigrationType type, String token) {
        return getEndpoint(type, new List<String>{token});
    }

    /**
     * Returns an endpoint URL for a given MigrationType and token (string)
     * @param MigrationType Type of api transaction
     * @param tokens List<String> values of transaction, gateway, or payment method token
     * @throws TokenRequiredException When a activity type requires a token and the token is null or empty
     * @return String API endpoint URL in string form
     */
    public static String getEndpoint(MigrationType type, List<String> tokens) {
        return BASE_URL + String.format(resources.get(type), tokens );
    }

    /**
     * Returns the appropriate MigrationType for the given value
     * @param value String
     * @return MigrationType
     */
    public static MigrationType getMigrationType(String value) {
        if (migrationTypes.containsKey(value)) {
            return migrationTypes.get(value);
        }
        return null;
    }

    /**
     * Returns an authorization header for accessing the Spreedly API endpoints
     * @return String
     */
    public static String getAuthHeader() {
        Map<String, String> encryptedKeystorEntries = Framework.Keystore.getEntryMapByCat('Spreedly_Core');
        String key = EncryptionUtil.decrypt(encryptedKeystorEntries.get('Spreedly_Key'));
        String secret = EncryptionUtil.decrypt(encryptedKeystorEntries.get('Spreedly_Secret'));

        Blob headerValue = Blob.valueOf(key + ':' + secret);
        return 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    }
    
    /**
     * Returns the Stripe Credentials according to the isTest field
     * @return StripeCredentials
     */
    public static StripeCredentials getCredentials(Boolean isTest) {
        return credsMap.get(isTest);
    }
    
    /**
     * @name StripePaymentCredentials
     * @description populated the stripe setting custom metadata records
     */
    public inherited sharing class StripeCredentials {
        public String secretKey;
        public String publishableKey;

        public StripeCredentials(Boolean isTest) {
            String prefix = isTest ? 'test_' : 'live_';
            this.secretKey = getKey(prefix + 'secret_key');
            this.publishableKey = getKey(prefix + 'publishable_key');
        }

        private String getKey(String name) {
            Map<String, String> keys = Framework.Keystore.getEntryMapByCat('FontevaPay');
            String ksName = 'Stripe_' + name;
            if( keys?.containsKey(ksName) ){
                return EncryptionUtil.decrypt( keys.get(ksName) );
            }else{
                return Stripe_Creds__mdt.getInstance(name)?.Value__c;
            }
        }
    }
}