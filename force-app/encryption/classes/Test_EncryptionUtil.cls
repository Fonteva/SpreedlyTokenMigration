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

@IsTest
private without sharing class Test_EncryptionUtil extends MockTestBase{

    @IsTest
    static void testEncrypt() {
        String val = 'Test';
        String encryptedVal = EncryptionUtil.encrypt(val);
        System.assertEquals('ppFwaeCHSBqo-r5odbfMOQ==', encryptedVal);
    }

    @IsTest
    static void testEncryptDefault() {
        String val = 'Test';
        String encryptedVal = EncryptionUtil.encrypt(val, 'Default');
        System.assertEquals('ppFwaeCHSBqo-r5odbfMOQ==', encryptedVal);
    }

    @IsTest
    static void testDecrypt() {
        String val = 'ppFwaeCHSBqo-r5odbfMOQ==';
        String decryptedVal = EncryptionUtil.decrypt(val);
        System.assertEquals('Test', decryptedVal);
    }

    @IsTest
    static void testDecryptDefault() {
        String val = 'ppFwaeCHSBqo-r5odbfMOQ==';
        String decryptedVal = EncryptionUtil.decrypt(val,'Default');
        System.assertEquals('Test', decryptedVal);
    }
}