List<Framework.RegisteredObject> ros = new List<Framework.RegisteredObject>();
Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(Framework.Config.export(true));
List<Object> registeredApps = (List<Object>) config.get('registeredApps');
if (registeredApps == null) {
    return;
}

for (Object appObj : registeredApps) {
    Map<String, Object> app = (Map<String, Object>) appObj;    

    for (Object objEntry : (List<Object>) app.get('registeredObjects')) {
        Map<String, Object> obj = (Map<String, Object>) objEntry;

        Framework.RegisteredObject ro = new Framework.RegisteredObject();
        ro.sObjectName = (String) obj.get('sObjectName');
        ro.namespace = (String) obj.get('namespace');
        ro.apexClass = (String) obj.get('apexClass');
        ro.soqlLimit = (String) obj.get('soqlLimit');
        ro.soqlOrderBy = (String) obj.get('soqlOrderBy');
        ro.salesforceId = (String) obj.get('salesforceId');
        ro.triggersEnabled = %%%PARAM_1%%%;
        ro.isEnabled = (Boolean) obj.get('isEnabled');
        ro.isStandard = (Boolean) obj.get('isStandard');
        ro.validationDisabled = (Boolean) obj.get('validationDisabled');

        if (
            (!String.isEmpty(ro.apexClass) && ro.apexClass != 'Framework.Domain')
            || ro.sObjectName == 'EventApi__Ticket_Schedule_Item__c'
        ) {
            ros.add(ro);
        }
    }
}
Framework.Config.push(ros);
