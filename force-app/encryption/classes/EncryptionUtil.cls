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

public inherited sharing class EncryptionUtil {
    public class InvalidKeyException extends Exception {}
    public static final String DEFAULT_KEY_NAME = 'Default';
    public static IEncrypt getInstance() {
        if (instance == null) {
            instance = new FontevaEncryption();
        }
        return instance;
    }

    @TestVisible
    private static IEncrypt instance;
    
    @TestVisible
    private static Map<String, Encryption_Key__mdt> keys = null;

    public static String decrypt(String encryptedString) {
        return getInstance().decrypt(encryptedString);
    }

    public static String decrypt(String encryptedString, String keyName) {
        return getInstance().decrypt(encryptedString, keyName);
    }

    public static String encrypt(String plainTextString) {
        return getInstance().encrypt(plainTextString, DEFAULT_KEY_NAME);
    }

    public static String encrypt(String plainTextString, String keyName) {
        return getInstance().encrypt(plainTextString, keyName);
    }


    /**
     * @event beforeUpdate
     * @event afterInsert
     * @update SObject
     * @param records SObject[]
     */
    public static void setEncryptedId(List<SObject> records, SObjectType sObjectType) {
        setEncryptedId(records, sObjectType, DEFAULT_KEY_NAME);
    }

    public static void setEncryptionId(List<SObject> records, SObjectType sObjectType) {
        setEncryptedId(records, sObjectType);
    }

    public static void setEncryptedId(List<SObject> records, SObjectType sObjectType, String keyName) {
        getInstance().setEncryptedId(records,sObjectType,keyName);
    }

    private inherited sharing class FontevaEncryption implements IEncrypt {

        public String decrypt(String encryptedString) {
            return decrypt(encryptedString, DEFAULT_KEY_NAME);
        }

        public String decrypt(String encryptedString, String keyName) {
            if (String.isEmpty(encryptedString)) {
                return encryptedString;
            }

            Encryption_Key__mdt key = getKey(keyName);
            Blob data = EncodingUtil.base64Decode(encryptedString.replace('-', '/'));
            Blob cypher = Crypto.decrypt(
                    key.Algorithm__c,
                    Blob.valueOf(key.Key__c),
                    Blob.valueOf(key.Initialization_Vector__c),
                    data);
            return cypher.toString();
        }

        public String encrypt(String plainTextString) {
            return encrypt(plainTextString, DEFAULT_KEY_NAME);
        }

        public String encrypt(String plainTextString, String keyName) {
            return encrypt(plainTextString, getKey(keyName));
        }


        public void setEncryptionId(SObject[] records, SObjectType sObjectType) {
            setEncryptedId(records, sObjectType);
        }

        /**
         * @event beforeUpdate
         * @event afterInsert
         * @update SObject
         * @param records SObject[]
         */
        public void setEncryptedId(SObject[] records, SObjectType sObjectType) {
            setEncryptedId(records, sObjectType, DEFAULT_KEY_NAME);
        }

        public void setEncryptedId(SObject[] records, SObjectType sObjectType, String keyName) {
            String encryptFieldName = PackageUtils.nsp + 'Encrypted_Id__c';
            for (SObject rec : records) {
                if (String.isBlank((String)rec.get(encryptFieldName))) {
                    rec.put(encryptFieldName, encrypt(rec.Id));
                }
            }

            String sobjectName = Framework.SchemaService.getDescribeDeferred(sObjectType).Name;
            Framework.Dispatcher.disableTriggerInContext.put(sobjectName, true);
            Framework.SObjectService.updateRecords(records);
            Framework.Dispatcher.disableTriggerInContext.put(sobjectName, false);
        }

        private String encrypt(String plainTextString, Encryption_Key__mdt key) {
            if (String.isEmpty(plainTextString)) {
                return plainTextString;
            }

            Blob data = Blob.valueOf(String.valueOf(plainTextString));
            Blob cypher = Crypto.encrypt(
                    key.Algorithm__c,
                    Blob.valueOf(key.Key__c),
                    Blob.valueOf(key.Initialization_Vector__c),
                    data);

            return EncodingUtil.base64Encode(cypher).replace('/', '-');
        }

        private Encryption_Key__mdt getKey(String name) {
            loadKeys();

            Encryption_Key__mdt key = keys.get(name);
            if (key == null) {
                throw new InvalidKeyException();
            } else {
                return key;
            }
        }

        private void loadKeys() {
            if (keys != null) {
                return;
            }

            List<Encryption_Key__mdt> results = Encryption_Key__mdt.getAll().values();

            keys = new Map<String, Encryption_Key__mdt>();
            for (Encryption_Key__mdt key : results) {
                keys.put(key.DeveloperName, key);
            }
        }
    }
}