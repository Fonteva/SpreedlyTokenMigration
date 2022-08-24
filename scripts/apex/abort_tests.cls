/**
 * This apex script will abort running unit tests.
*/
List<ApexTestQueueItem> items = [SELECT Id FROM ApexTestQueueItem WHERE Status IN ('Holding','Queued','Preparing','Processing') Limit :System.Limits.getLimitDmlRows()];
if(items.size() > 0){
    for(ApexTestQueueItem item: items) {
        item.Status = 'Aborted';
    }
    update items;
}