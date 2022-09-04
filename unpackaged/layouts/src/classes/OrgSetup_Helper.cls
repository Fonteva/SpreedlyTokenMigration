public class OrgSetup_Helper {

    // Method to call replace method without specifying testOnly flag
    public static void replace(Map<String, String> StringMap, Map<Id, Id> IdMap, Set<String> targetObjs) {
        OrgSetup_Helper.replace(StringMap, IdMap, targetObjs, false);
    }

    /* Replace all occurrencies of the specified keys in StringMap or IdMap with the corresponding
    *  values in the sObjects specified in the targetObjs set. Id values will also be used to check Lookup
    *  references
    */
    public static void replace(Map<String, String> StringMap, Map<Id, Id> IdMap, Set<String> targetObjs, Boolean testOnly) {
        Framework.Log.push(OrgSetup_Helper.class.getName(), 'replace');

        List<sObject> toUpdate = new List<sObject>();

        // Add the IdMap to StringMap for replacements if needed (to replace ids inside URLs, as an example)
        if (IdMap.size() > 0) {
            if (StringMap == NULL) {
                StringMap = new Map<String, String>();
            }
            for (Id idKey : IdMap.keySet()) {
                StringMap.put(idKey, IdMap.get(idKey));
                // Also put the 15-character Id
                StringMap.put(String.valueOf(idKey).substring(0, 15), IdMap.get(idKey));
            }  // end for idKey
        }

        // Safety check for StringMap, delete any values that are the same
        for (String key : StringMap.keySet()) {
            if (key == StringMap.get(key)) {
                StringMap.remove(key);
            }
        }

        // Fetch schema for targetSobjs
        List<String> objNameList = new List<String>(); // Convert to a list
        objNameList.addAll(targetObjs);
        List<Schema.DescribeSobjectResult> schemaLookup = Schema.describeSObjects(objNameList);
        for (Schema.DescribeSobjectResult sch : schemaLookup) {
            List<String> fieldsToRetrieve = new List<String>();
            fieldsToRetrieve.add('Id');

            // Find all writeable String and Lookup fields for this object
            Map<String, Schema.SObjectField> fieldMap = sch.fields.getMap();
            for (String key : fieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(key).getDescribe();
                Schema.DisplayType fieldType = dfr.getType();
                // if (testOnly) { System.debug('*** ' + key + ' is of type ' + dfr.getType()); }
                if ((fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.ID ||
                    fieldType == Schema.DisplayType.URL || fieldType == Schema.DisplayType.REFERENCE ||
                    fieldType == Schema.DisplayType.TEXTAREA) && dfr.isUpdateable()) {
                    fieldsToRetrieve.add(dfr.getName());
                }
            }  // end for key/fieldmap

            // Fetch records for the specific object
            String objQuery = 'SELECT ' + String.join(fieldsToRetrieve, ',') + ' FROM ' + sch.getName();
            for (sObject s : Database.query(objQuery)) {
                Boolean updated = false;
                // Re-iterate through all fields, make substitutions as needed
                for (String key : fieldsToRetrieve) {
                    if (key == 'Id') {
                        continue;
                    }
                    else if (s.get(key) == NULL) {
                        continue;
                    }  // Skip to next if nothing to match
                    Schema.DescribeFieldResult dfr = fieldMap.get(key).getDescribe();
                    if ((dfr.getType() == Schema.DisplayType.REFERENCE || dfr.getType() == Schema.DisplayType.ID)
                        && IdMap.get((Id) s.get(key)) != NULL) {
                        s.put(key, IdMap.get((Id) s.get(key))); updated = true;
                        if (testOnly) {
                            System.debug('Writing value ' + s.get(key) + ' to field ' + key +
                                ' [Object: ' + s.Id + ' (' + sch.getName() + ') ]');
                        }  // end if testOnly
                    }   // end check for Id
                    else if (dfr.getType() == Schema.DisplayType.STRING || dfr.getType() == Schema.DisplayType.URL ||
                        dfr.getType() == Schema.DisplayType.TEXTAREA) {
                        String currVal = (String) s.get(key);
                        // Iterate through all keys in the StringMap to see if it's contained
                        for (String oldVal : StringMap.keySet()) {
                            if (currVal.contains(oldVal)) {
                                currVal = currVal.replace(oldVal, StringMap.get(oldVal));
                                s.put(key, currVal);
                                updated = true;
                                if (testOnly) {
                                    System.debug('Replacing value ' + oldVal + ' with ' + StringMap.get(oldVal) +
                                        ' in field ' + key + ' [Object: ' + s.Id + ' (' + sch.getName() + ') ]');
                                    System.debug('+++ Substitute value: ' + currVal);
                                }  // end if testOnly
                            }   // end if contains oldval
                        }  // end for oldVal
                    }   // end check for String
                }   // end for field keys

                if (updated) {
                    toUpdate.add(s);
                }
            }  // end for sobject s
        }   // end for sch

        for (sObject s : toUpdate) {
            System.debug('>>>>>>>>>>>>>' + s);
        }


        //UPDATES THE SITE RECORD
        if (testOnly == false
            && toUpdate.size() > 0) {
            update toUpdate;
        }


        //DUMMY DML ON PAGES, IT WILL REFRESH THE LINKS FROM SITE RECORD
        PagesApi__Page__c[] pages = [SELECT Id, PagesApi__Page_URL__c FROM PagesApi__Page__c];
        for (PagesApi__Page__c p : pages) {
            p.PagesApi__Page_URL__c = '';
        }
        update pages;

        //UPDATING THE MENU ITEMS
        PagesApi__Menu_Item__c[] menuItems = [SELECT Id FROM PagesApi__Menu_Item__c];
        update menuItems;

        // ===> UPDATING MENU ITEMS <==
        try {

            //FORM - Company Information
            PagesApi__Form__c f = [SELECT Id FROM PagesApi__Form__c WHERE Name = 'Company Information'];

            PagesApi__Menu_Item__c m4 = [
                SELECT Id, PagesApi__Custom_URL__c
                FROM PagesApi__Menu_Item__c
                WHERE Name = 'Company Information'
            ];

            m4.PagesApi__Custom_URL__c = '/cpbase__form?ID=' + f.Id;
            update m4;

            //FORM - Organization Contacts

            PagesApi__Form__c f2 = [SELECT Id FROM PagesApi__Form__c WHERE Name = 'Organization Contacts'];

            PagesApi__Menu_Item__c m5 = [
                SELECT Id, PagesApi__Custom_URL__c
                FROM PagesApi__Menu_Item__c
                WHERE Name = 'Organization Contacts'
            ];

            m5.PagesApi__Custom_URL__c = '/cpbase__form?ID=' + f2.Id;
            update m5;

        }
        catch (Exception ex) {
            Framework.log.debugException(ex);
        }

// UPDATING PROFILE ID IN STORE
        try {
            Profile p = [SELECT Name FROM Profile
            WHERE Name = 'Fonteva Customer Community Login User'];
            OrderApi__Store__c[] stores =
            [SELECT Id, OrderApi__New_User_Profile_ID__c FROM OrderApi__Store__c];

            for (OrderApi__Store__c s : stores) {
                s.OrderApi__New_User_Profile_ID__c = p.Id;
            }
            update stores;
        }
        catch (Exception ex) {
            Framework.log.debugException(ex);
        }


        PagesApi__Site__c pSite1 = [SELECT PagesApi__Community_Network_ID__c FROM PagesApi__Site__c WHERE Name = 'Foundation'];

        pSite1.PagesApi__Community_Network_ID__c = [SELECT Id FROM network WHERE Name = 'Member Portal'].Id ;
        update pSite1;

        PagesApi__Site__c pSite2 = [SELECT PagesApi__Community_Network_ID__c FROM PagesApi__Site__c WHERE Name = 'LT Community'];

        pSite2.PagesApi__Community_Network_ID__c = [SELECT Id FROM network WHERE Name = 'Member Portal'].Id ;
        update pSite2;

        // fix attributes on the community site
        String fieldSet = 'LTE__Manage_Members_Add_Member';
        List<LTE__Site__c> ltSite = [SELECT Id,LTE__Site_URL__c, LTE__Store__c FROM LTE__Site__c WHERE Name = 'LTCommunitySite'];

        if(!ltSite.isEmpty()){
            ltSite[0].LTE__Site_URL__c = [SELECT PagesApi__Site_URL__c FROM PagesApi__Site__c LIMIT 1].PagesApi__Site_URL__c;
            ltSite[0].LTE__Assign_Members_Contact_Field_Set__c = fieldSet;
            ltSite[0].LTE__Profile_Contact_Fieldset_CSV__c = fieldSet;
            ltSite[0].LTE__Profile_Account_Fieldset_CSV__c = 'LTE__' + Account.SObjectType.getDescribe().fieldSets.getMap().values().get(0).name;
            ltSite[0].LTE__Community_Name__c = 'Member Portal';
            ltSite[0].LTE__Community_ID__c = [SELECT Id FROM network WHERE Name = 'Member Portal'].Id ;
            if (ltSite[0].LTE__Store__c == null) {
                OrderApi__Store__c store = [Select Id, OrderApi__Business_Group__c From OrderApi__Store__c Limit 1];
                ltSite[0].LTE__Store__c = store.Id;
            }
        }
        update ltSite;

         // UPDATE BASE URL FOR COMMUNITY SITE MENU ITEMS
         LTE__Menu_Item__c[] comSiteMenuItems = [SELECT Id, LTE__URL__c FROM LTE__Menu_Item__c];
         for (LTE__Menu_Item__c m : comSiteMenuItems) {
             System.debug('####' + m.LTE__URL__c);
             if(!ltSite.isEmpty()){
                 m.LTE__Site__c = ltSite[0].Id;
             }
             if (m.LTE__URL__c != null)
                 m.LTE__URL__c = m.LTE__URL__c.replaceAll('^((http|https)://)+?([a-zA-Z0-9]|-)+?([.]force)+?([.]com)/lt', [SELECT PagesApi__Site_URL__c FROM PagesApi__Site__c LIMIT 1].PagesApi__Site_URL__c);
             System.debug('>>>>' + m.LTE__URL__c);
         }
         update comSiteMenuItems;

        // link all events to our community site
        LTE__Site_Event__c[] links = [Select Id From LTE__Site_Event__c];
        EventApi__Event__c[] events = [Select Id From EventApi__Event__c];
        if (links.size() != events.size() && events.size() > 0) {
            if (links.size() > 0) {
                delete links;
            }
            List<LTE__Site_Event__c> newLinks = new List<LTE__Site_Event__c>();
            for (EventApi__Event__c e : events) {
                if(!ltSite.isEmpty()){
                    newLinks.add(new LTE__Site_Event__c(LTE__Event__c = e.Id, LTE__Site__c = ltSite[0].Id));
                }
            }
            insert newLinks;
        }

        // fix any namespace issues
        if ('LTE__' != 'L'+'TE__') { // namespace swap only catches left-hand
            EventApi__Event_Page_Component__c[] ePages = [Select Id, EventApi__Component_Name__c From EventApi__Event_Page_Component__c];
            for (EventApi__Event_Page_Component__c epc : ePages) {
                System.debug(epc.EventApi__Component_Name__c);
                System.debug(epc.EventApi__Component_Name__c.replace('L' + 'TE:', 'LTE:'));
                epc.EventApi__Component_Name__c = epc.EventApi__Component_Name__c.replace('L'+'TE:', 'LTE:');
            }
            if (ePages.size() > 0) {
                update ePages;
            }
        }
    }
}