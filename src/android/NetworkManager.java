package com.cordova.zdmitry.backgroundlocation;


import org.apache.http.client.HttpClient;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.BasicResponseHandler;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONObject;


public class NetworkManager {
    private static NetworkManager mInstance = null;

    public String  serverUrl;
    public String  serverToken;
    public Boolean useTimestamp;

    public static NetworkManager sharedInstance(){
        if( mInstance == null ) {
            mInstance = new NetworkManager();
        }
        return mInstance;
    }

    public NetworkManager() {
        useTimestamp = false;
    }

    public NetworkManager(String serverURL, String token) {
        serverUrl    = (serverURL != null ? serverURL : "");
        serverToken  = token;
        useTimestamp = false;
    }

    public void sendString(String text) throws Exception {
        this.sendData(new StringEntity(text), "text/plain");
    }

    public void sendDictionary(JSONObject dict) throws Exception {
        this.sendData(new StringEntity(dict.toString()), "application/json");
    }

    public Boolean sendData(StringEntity data, String mimeType) throws Exception {
        if (data != null && data.getContentLength() > 0) {
            if (serverUrl.startsWith("http://") || serverUrl.startsWith("https://")) {
                HttpClient client = new DefaultHttpClient();
                HttpPost post = new HttpPost(this.serverUrl);

                post.setEntity(data);

                post.setHeader("Accept", mimeType);
                post.setHeader("Content-type", mimeType);

                if (serverToken != null && serverToken.length() > 0) {
                    post.setHeader("Authorization", serverToken);
                }

                ResponseHandler responseHandler = new BasicResponseHandler();
                client.execute(post, responseHandler);
                return true;
            }
        }
        return false;
    }
}
