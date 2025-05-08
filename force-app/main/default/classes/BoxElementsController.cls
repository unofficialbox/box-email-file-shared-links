public with sharing class BoxElementsController {
    public static final String APPLICATION_ENCODED_HEADER = 'application/x-www-form-urlencoded';
    public static final String AUTHORIZATION_HEADER = 'Authorization';
    public static final String CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String POST_METHOD = 'POST';
    public static final String TOKEN_URL_STRING = 'https://api.box.com/oauth2/token';

    // public string ltnOrigin {get{ return URL.getOrgDomainUrl().toExternalForm().split('\\.')[0] + '.lightning.force.com';} set;}
    @AuraEnabled(cacheable = true)
    public static string getVFOrigin() {
        string vfOrigin = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm(); // Expected Format = https://domain.my.salesforce.com

        vfOrigin = baseURL.split('.my.')[0] + '--c.' + 'visualforce.com';

        return vfOrigin;
    }

    @AuraEnabled()
    public static Map<String, String> downscopeToken(String recordId) {

        System.debug('Found recordId: ' + recordId);
        String ltnOrigin = URL.getOrgDomainUrl().toExternalForm();
        System.debug('Ltn origin: ' + ltnOrigin);


        // Get parent access token from Client Credentials Grant Auth
        BoxClient boxClient = new BoxClient();
        String accessToken;

        String currentUserId = UserInfo.getUserId();
        System.debug('Found current user id: ' + currentUserId);

        // Get the folder id and box user id
        box__FRUP__c frup = [
            SELECT box__Folder_ID__c, box__Record_ID__c, box__Box_user__c
            FROM box__FRUP__c 
            WHERE box__Record_ID__c = :recordId AND box__Salesforce_User__c = :currentUserId 
            LIMIT 1];
        String folderId = frup.box__Folder_ID__c;
        System.debug('Found folderId: ' + folderId);

        String boxUserId = frup.box__Box_user__c;
        System.debug('Found box user id: ' + boxUserId);

        String urlParameters = String.format(
        'grant_type={0}&subject_token={1}&subject_token_type={2}&scope={3}&resource={4}',
        new List<String>{
            'urn:ietf:params:oauth:grant-type:token-exchange',
            boxClient.getAccessToken(boxUserId),
            'urn:ietf:params:oauth:token-type:access_token',
            'base_picker item_share',
            'https://api.box.com/2.0/folders/' + folderId
        });

        Map<String, String> headers = new Map<String, String>();
        headers.put(CONTENT_TYPE_HEADER, APPLICATION_ENCODED_HEADER);

        // Get downsceoped token
        HttpResponse response = boxClient.sendRequest(POST_METHOD, TOKEN_URL_STRING, headers, urlParameters);
        System.debug('Found response: ' + response.getBody());

        if(response.getStatus() == 'OK') {
            String body = response.getBody();
            AuthenticationResponse authResponse = AuthenticationResponse.parse(body);
            accessToken = authResponse.access_token;
        }

        
        // Set folderId and downscoped token to pass back to LWC javascript controller
        Map<String, String> buieMap = new Map<String, String>();
        buieMap.put('folderId', folderId);
        buieMap.put('accessToken', accessToken);
        buieMap.put('ltnOrigin', ltnOrigin);

        return buieMap;
    }
}
