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
public class MultiRequestMock implements HttpCalloutMock {
    private static Integer count = 0;
    Map<String, HttpCalloutMock> requests;
    public MultiRequestMock(){}

    public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpCalloutMock mock = requests.get(req.getEndpoint());
        if (mock != null) {
            return mock.respond(req);
        } else {
            //This is the fallback for if we have a complex url
            mock = requests.values()[count];
            if(mock != null){
                count++;
                return mock.respond(req);
            }else{
                throw new MultiRequestMockException('Unable to find mock callout for this request');
            }
        }
    }

    public void addRequestMock(String url, HttpCalloutMock mock) {
        if(requests == null){
            requests = new Map<String, HttpCalloutMock>();
        }
        requests.put(url, mock);
    }

    public class MultiRequestMockException extends Exception{}
}