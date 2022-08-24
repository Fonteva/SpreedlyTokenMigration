/**
 * Loads Salesforce and Fonteva Multicurrency Values
*/

Map<String,Decimal> currencyCodes = new Map<String,Decimal>();
currencyCodes.put('AUD',1.2897);
currencyCodes.put('CAD',1.2626);
currencyCodes.put('EUR',0.8254);
currencyCodes.put('HKD',7.7517);
currencyCodes.put('JPY',103.54);
currencyCodes.put('INR',72.91);
currencyCodes.put('TRY',7.40);

for(String currencyCode : currencyCodes.keySet()){
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0/sobjects/CurrencyType/');
    Map<String,Object> requestMap = new Map<String,Object>();
    requestMap.put('IsoCode',currencyCode);
    requestMap.put('ConversionRate',1.0);
    requestMap.put('DecimalPlaces',2);
    requestMap.put('IsActive',true);

    req.setBody(JSON.serialize(requestMap));
    req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    req.setMethod('POST');
    HttpResponse res = h.send(req);
    System.debug(res.getBody());
}

//Insert Currency Conversion Table
List<OrderApi__Currency_Conversion_Table__c> table = new List<OrderApi__Currency_Conversion_Table__c>();
for(String currencyCode : currencyCodes.keySet()){
    OrderApi__Currency_Conversion_Table__c rec = new OrderApi__Currency_Conversion_Table__c();
    rec.Name = 'USD TO ' + currencyCode;
    rec.OrderApi__Source_Currency_Code__c = 'USD';
    rec.OrderApi__Source_Rounding_Setting__c = 0.01;
    rec.OrderApi__Target_Currency_Code__c = currencyCode;
    rec.OrderApi__Target_Rounding_Setting__c = 0.01;
    rec.OrderApi__Conversion_Rate__c = currencyCodes.get(currencyCode);
    table.add(rec);
}
insert table;

//Update the Foundation Store
OrderApi__Store__c store = [Select Id From OrderApi__Store__c Where Name ='Foundation Store'][0];
store.OrderApi__Fonteva_Supported_Currencies_CSV__c = String.join(new List<String>(currencyCodes.keyset()),',');
update store;