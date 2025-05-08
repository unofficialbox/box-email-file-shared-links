public class BoxClient {
    private static final String METHOD_POST = 'POST';
    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String APPLICATION_ENCODED_HEADER = 'application/x-www-form-urlencoded';
    private static final String TOKEN_URL_STRING = 'https://api.box.com/oauth2/token';

    private String clientId { get; set; }
    private String clientSecret { get; set; }
    private String subjectType { get; set; }
    private String subjectId { get; set; }

    private String accessToken { get; set; }
    private String refreshToken { get; set; }
    private Long lastRefresh { get; set; }
    private Long expires { get; set; }
    private String baseUrl { get; set; }
    private String baseUploadUrl { get; set; }
    private String asUserId { get; set; }

    public String getAccessToken(String boxUserId) {
        if(String.isEmpty(this.getClientId())) {
            this.authenticate(boxUserId);
        }
        else {
            if (this.needsRefresh()) {
                this.refresh();
            }
        }
       
        System.debug('Getting access token: ' + this.accessToken);
        return this.accessToken;
    }

    public HttpResponse sendRequest(String httpMethod, String endpoint, Map<String, String> headers, String body) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(httpMethod);
        httpRequest.setEndpoint(endpoint);
        httpRequest.setTimeout(60000);


        for(String key: headers.keySet()) {
            System.debug('Found key: ' + key + ' and value: ' + headers.get(key));
            httpRequest.setHeader(key, headers.get(key));
        }
        
        if(String.isNotBlank(body)) {
            httpRequest.setBody(body);
        }

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        System.debug('Found response: ' + response.getBody());
        return response;
    }
    
    private void authenticate(String boxUserId) {
        BoxClientCredentialsGrant__mdt boxClientCredentialsGrant = [
            SELECT Id, Label, BoxClientId__c, BoxClientSecret__c, BoxSubjectType__c, BoxSubjectId__c 
                FROM BoxClientCredentialsGrant__mdt 
                LIMIT 1
            ];

        if(boxClientCredentialsGrant != null) {
            
            // Create Client Credentials Grant
            this.setClientId(boxClientCredentialsGrant.BoxClientId__c);
            this.setClientSecret(boxClientCredentialsGrant.BoxClientSecret__c);
            this.setSubjectType(boxClientCredentialsGrant.BoxSubjectType__c);
            if(String.isNotBlank(boxUserId)) {
                this.setSubjectId(boxUserId);
            }
            else {
                this.setSubjectId(boxClientCredentialsGrant.BoxSubjectId__c);
            }

            // Get parent access token from Client Credentials Grant Auth
            Map<String, String> headers = new Map<String, String>();
            headers.put(CONTENT_TYPE_HEADER, APPLICATION_ENCODED_HEADER);

            String urlParameters = String.format(
                'grant_type=client_credentials&client_id={0}&client_secret={1}&box_subject_type={2}&box_subject_id={3}',
                new List<String>{
                    this.getClientId(),
                    this.getClientSecret(),
                    this.getSubjectType(),
                    this.getSubjectId()
                });
            System.debug('URL Params: ' + urlParameters);

            HttpResponse response = this.sendRequest(METHOD_POST, TOKEN_URL_STRING, headers, urlParameters);
            System.debug('Found response: ' + response.getBody());
            System.debug('Found status: ' + response.getStatus());

            if (response.getStatus() == 'OK' || response.getStatusCode() == 200) {
                String body = response.getBody();
                AuthenticationResponse authResponse = AuthenticationResponse.parse(body);
                this.setAccessToken(authResponse.access_token);
                this.setRefreshToken(authResponse.refresh_token);
                this.setLastRefresh(DateTime.now().getTime());
                this.setExpires(authResponse.expires_in * 1000);

            } else {
                throw new BoxClientException(
                    'BoxClient unable to generate new access token: ' +
                    response.toString()
                );
            }
        }
        else {
            System.debug('Box Client Credentials Grant metadata not found!');
        }
    }

    

    private Boolean needsRefresh() {
        Boolean needsRefresh;
        long now = DateTime.now().getTime();
        long tokenDuration = now - this.getLastRefresh();
        needsRefresh = (tokenDuration >= this.getExpires());
        return needsRefresh;
    }

    private void refresh() {
        Map<String, String> headers = new Map<String, String>();
        headers.put(CONTENT_TYPE_HEADER, APPLICATION_ENCODED_HEADER);

        String urlParameters = String.format(
                'grant_type=client_credentials&client_id={0}&client_secret={1}&box_subject_type={2}&box_subject_id={3}',
                new List<String>{
                    this.getClientId(),
                    this.getClientSecret(),
                    this.getSubjectType(),
                    this.getSubjectId()
                });
        
        HttpResponse response = this.sendRequest(METHOD_POST, TOKEN_URL_STRING, headers, urlParameters);
        if (response.getStatus() == 'OK') {
            String body = response.getBody();
            AuthenticationResponse authResponse = AuthenticationResponse.parse(body);
            this.setAccessToken(authResponse.access_token);
            this.setRefreshToken(authResponse.refresh_token);
            this.setLastRefresh(DateTime.now().getTime());
            this.setExpires(authResponse.expires_in * 1000);
        } else {
            throw new BoxClientException(
                'BoxClient unable to use refresh token to generate new access token: ' +
                response.toString()
            );
        }
    }

    private String getClientId() {
        return this.clientId;
    }

    private void setClientId(String clientId) {
        this.clientId = clientId;
    }

    private String getClientSecret() {
        return this.clientSecret;
    }

    private void setClientSecret(String clientSecret) {
        this.clientSecret = clientSecret;
    }

    private String getSubjectType() {
        return this.subjectType;
    }

    private void setSubjectType(String subjectType) {
        this.subjectType = subjectType;
    }

    public String getSubjectId() {
        return this.subjectId;
    }

    private void setSubjectId(String subjectId) {
        this.subjectId = subjectId;
    }

    private void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    private String getRefreshToken() {
        return this.refreshToken;
    }

    private void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    private Long getLastRefresh() {
        return this.lastRefresh;
    }

    private void setLastRefresh(Long lastRefresh) {
        this.lastRefresh = lastRefresh;
    }

    private Long getExpires() {
        return this.expires;
    }

    private void setExpires(Long expires) {
        this.expires = expires;
    }

    private String getBaseUrl() {
        return this.baseUrl;
    }

    private void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    private String getBaseUploadUrl() {
        return this.baseUploadUrl;
    }

    public void setBaseUploadUrl(String baseUploadUrl) {
        this.baseUploadUrl = baseUploadUrl;
    }

    private String getAsUserId() {
        return this.asUserId;
    }

    private void setAsUserId(String asUserId) {
        this.asUserId = asUserId;
    }

    public class BoxClientException extends Exception {
    }
}