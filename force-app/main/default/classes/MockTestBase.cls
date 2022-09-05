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

public virtual inherited sharing class MockTestBase {
    public static fflib_ApexMocks mocks = new fflib_ApexMocks();

    public static Object mock(Type clazz) {
        Object mockObj = mocks.mock(System.Type.forName(clazz.getName()));
        InjectionUtils.implementationMap.put(clazz.getName(), mockObj);
        return mockObj;
    }

    public static void stub() {
        mocks.startStubbing();
    }

    public static void stopStubbing() {
        mocks.stopStubbing();
    }

    public static fflib_MethodReturnValue when(Object instance) {
        return mocks.when(instance);
    }

    public static String matchAnyString() {
        return fflib_Match.anyString();
    }

    public static Object matchAnyObject() {
        return fflib_Match.anyObject();
    }

    public static SObject matchAnySObject() {
        return fflib_Match.anySObject();
    }

    public static String matchString(String str) {
        return (String) fflib_Match.eq(str);
    }

    public static Id genId(SObjectType objType) {
        return fflib_IDGenerator.generate(objType);
    }
}