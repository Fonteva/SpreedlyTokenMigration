/**
 * Creates LTCommunitySite site record
*/

Id foundationStoreId = [Select Id from OrderApi__Store__c where Name = 'Foundation Store'][0].Id;
LTE__Site__c site = new LTE__Site__c();
site.Name = 'LTCommunitySite';
site.LTE__Community_Name__c = 'Member Portal';
site.LTE__Store__c = foundationStoreId;
insert site;