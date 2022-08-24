public class OrgSetup_Init {

    public static Boolean setupOrg() {
        // Old/new value maps to pass to GDO_Helper
        Map<String, String> StringMap = new Map<String, String>();
        Map<Id, Id> IdMap = new Map<Id, Id>();
        Set<String> targetObjects = new Set<String>();

        targetObjects.add('PagesApi__Site__c');
        targetObjects.add('PagesApi__Menu_Item__c');

        // Identify new values for all
        // Get community/domain values
        Domain masterDomain = [SELECT Id, Domain FROM Domain LIMIT 1];

        // Get old Site values to sub out, iterate through all Sites
        PagesApi__Site__c[] sites = [SELECT Id, PagesApi__Profile_Page_URL__c,
                                        PagesApi__Site_URL__c,
                                        PagesApi__Community_Network_ID__c,
                                        PagesApi__Default_Community_New_User_Profile__c,
                                        PagesApi__User_Reset_Password_URL__c,
                                        PagesApi__User_Self_Registration_URL__c,
                                        PagesApi__User_Login_URL__c
                                        FROM PagesApi__Site__c];


        System.debug('>>>>>>>>sites.size>>>'+sites.size());

        for (PagesApi__Site__c  site : sites) {

            if (String.isNotBlank(site.PagesApi__Profile_Page_URL__c) &&
                site.PagesApi__Profile_Page_URL__c.countMatches('/') > 2) {

                System.debug('>>>>>>>>here Iam inside loop>>>'+site);
                if (site.PagesApi__Profile_Page_URL__c.contains('/lt/')){
                  site.PagesApi__Profile_Page_URL__c = site.PagesApi__Profile_Page_URL__c.replace('/lt/','/');
                    }

                    List<String> parts = site.PagesApi__Profile_Page_URL__c.split('\\/');

                    StringMap.put(parts[2], masterDomain.Domain);    // Add the domain value for substitution
                    parts[3] = parts[3].replace('CPBase__profile?site=', '');   // Isolate the Id only
                    parts[3] = parts[3].normalizeSpace();   // Accomodate for whitespace/newlines

                    if (parts[3] != NULL && site.Id != NULL && parts[3] != site.Id) {
                        IdMap.put(parts[3], site.Id);
                    }
            }  // end if PagesApi__Profile_Page_URL__c
        }  // end for site


        /*  Debugging - CY
        for (Id key : IdMap.keySet() ) {
            System.debug ('+++ ' + key + ' = ' + IdMap.get(key));
        }
        */

        // Let's try running GDO_Helper replace
        OrgSetup_Helper.replace(StringMap, IdMap, targetObjects, false);

        User u = [Select Id From User Where Profile.Name = 'System Administrator'][0];
        Profile p = [Select Id, Name From Profile Where Name = 'Fonteva Customer Community Login User'];
        String fieldSet = Contact.SObjectType.getDescribe().fieldSets.getMap().values().get(0).name;
        Organization o = [SELECT NamespacePrefix FROM Organization Limit 1];
        fieldSet = o.NamespacePrefix + '__' + fieldSet;

        System.debug('Updating store with fieldset ' + fieldSet + ' and profile ' + p.Name + ' (' + p.Id + ')');
        OrderApi__Store__c store = [Select Id,Name, OrderApi__Business_Group__c From OrderApi__Store__c where Name = 'Foundation Store' Limit 1];
        store.OrderApi__New_User_Profile_ID__c = p.Id;
        store.OrderApi__New_Contact_Fieldset_CSV__c = null;
        store.OrderApi__Proforma_Payment_Option_Fieldset__c = null;
        store.OrderApi__New_Contact_Account_Owner__c = u.Id;
        OrderApi__Payment_Gateway__c gateway =
            [Select Id From OrderApi__Payment_Gateway__c Where OrderApi__Business_Group__c = :store.OrderApi__Business_Group__c  Limit 1];
        store.OrderApi__Gateway__c = gateway.Id;
        update store;

        // LTE install scripts
        LTE.PackageScripts.install();

        //Handle Auto_MenuItem_Badge
        LTE__Site__c site = [Select Id, (SELECT Id,Name from LTE__Community_Menu_Items__r where Name in ('Company Info','Company Orders','Company Memberships')) From LTE__Site__c Where Name = 'LTCommunitySite'][0];
        if(site.LTE__Community_Menu_Items__r.size() == 3){
            List<OrderApi__Access_Permission__c> permissions = [Select Id,OrderApi__Badge_Type__r.Name from OrderApi__Access_Permission__c Where OrderApi__Badge_Type__r.Name = 'Auto_MenuItem_Badge' limit 3];

            if(permissions.size() == 3){
                permissions[0].LTE__Menu_Item__c = site.LTE__Community_Menu_Items__r[0].Id;
                permissions[1].LTE__Menu_Item__c = site.LTE__Community_Menu_Items__r[1].Id;
                permissions[2].LTE__Menu_Item__c = site.LTE__Community_Menu_Items__r[2].Id;

                update permissions;
            }
        }

        // set the default site
        setDefaultSite();

        // return false if the ordersmash critical update isn't found
        return Framework.AppUpdate.get('Order/Invoice Merge') != null;
    }  // end setupOrg

    @Future
    public static void setDefaultSite() {
        LTE__Site__c site = [Select Id From LTE__Site__c Where Name = 'LTCommunitySite'][0];
        Framework.Registry.upsertEntries(new List<Framework.Registry.Entry>{new Framework.Registry.Entry('SiteTemplate', 'DefaultSite', site.Id)});
    }
}
