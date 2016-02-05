package com.cordova.zdmitry.backgroundlocation;


import android.annotation.SuppressLint;
import android.app.Application;
import android.util.Log;
import android.os.IBinder;

import android.content.Intent;
import android.content.ComponentName;
import android.content.ServiceConnection;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


public class BackgroundLocation extends CordovaPlugin {
    private static final String TAG     = BackgroundLocation.class.getName();
    private static Application m_app    = null;

    private CallbackContext m_cbContext = null;   // callback for events
    private Intent     m_locationIntent = null;

    private BackgroundLocationService  m_svcLocation = null;
    private ServiceConnection m_svcConn = null;
    private Boolean m_isBound = false;

    @Override
    protected void pluginInitialize() {
        Log.v(TAG, TAG + "::pluginInitialize(void)");
        m_app = this.cordova.getActivity().getApplication();
    }

    @Override
    public void onStart() {
        Log.v(TAG, TAG + "::onStart(void)");
    }

    @Override
    public void onStop() {
        Log.v(TAG, TAG + "::onStop(void)");
    }

    @Override
    public void onPause(boolean multitasking) {
        Log.v(TAG, TAG + "::onPause(bool)");
    }

    @Override
    public void onResume(boolean multitasking) {
        Log.v(TAG, TAG + "::onResume(bool)");
    }

    @Override
    public void onDestroy() {
        Log.v(TAG, TAG + "::onDestroy(bool)");
        this.unbindSattelite();
    }

    /**
     * Executes the request and returns PluginResult.
     *
     * @param action            The action to execute.
     * @param args              JSONArry of arguments for the plugin.
     * @param callbackContext   The callback context from which we were invoked.
     */
    @SuppressLint("NewApi")
    public boolean execute( String action, final JSONArray args, final CallbackContext callbackContext ) throws JSONException {
        if (m_cbContext == null) m_cbContext = callbackContext;

        if (action.equals("init")) {
            PluginResult result;

            m_svcConn = new ServiceConnection() {
                public void onServiceConnected(ComponentName name, IBinder binder) {
                    Log.d(TAG, TAG + "::onServiceConnected");
                    m_svcLocation = ((BackgroundLocationService.BackgroundLocationBinder) binder).getService();
                    m_isBound   = true;
                }

                public void onServiceDisconnected(ComponentName name) {
                    Log.d(TAG, TAG + "::onServiceDisconnected");
                    m_isBound = false;
                }
            };

            m_locationIntent = new Intent(m_app, BackgroundLocationService.class);
            ComponentName component = m_app.startService(m_locationIntent);
            this.bindSattelite();

            JSONObject obj = new JSONObject();
            obj.put("method", "init");
            obj.put("success", true);
            obj.put("intent", m_locationIntent == null ? "" : m_locationIntent.toString());
            obj.put("component", component == null ? "" : component.toString());

            result = new PluginResult(PluginResult.Status.OK, obj);

            result.setKeepCallback(true);
            m_cbContext.sendPluginResult(result);
            return true;
        }

        if ( action.equals("configure") ) {
            PluginResult result;

            Boolean retval = this.configure(args);

            JSONObject obj = new JSONObject();
            obj.put("method", "configure");
            obj.put("success", retval);

            result = new PluginResult(PluginResult.Status.OK, obj);

            // result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        }

        if ( action.equals("start") ) {
            PluginResult result;

            Boolean retval = this.startLocation(args);

            JSONObject obj = new JSONObject();
            obj.put("method", "start");
            obj.put("success", retval);

            result = new PluginResult(PluginResult.Status.OK, obj);

            // result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        }

        if ( action.equals("stop") ) {
            PluginResult result;

            Boolean retval = this.stopLocation(args);

            JSONObject obj = new JSONObject();
            obj.put("method", "stop");
            obj.put("success", retval);

            result = new PluginResult(PluginResult.Status.OK, obj);

            // result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        }

        if ( action.equals("showSettings") ){
            PluginResult result;

            m_app.startActivity(new Intent(android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS));

            JSONObject obj = new JSONObject();
            obj.put("method", "stop");
            obj.put("success", true);

            result = new PluginResult(PluginResult.Status.OK, obj);

            // result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
        }

        return false;
    }

    private Boolean configure(final JSONArray args) throws JSONException {
        if (m_isBound && m_svcLocation != null) {
            return m_svcLocation.configure(args);
        }
        return false;
    }

    private Boolean startLocation(final JSONArray args) throws JSONException {
        if (m_isBound && m_svcLocation != null) {
            return m_svcLocation.startPooling(args);
        }
        return false;
    }

    private Boolean stopLocation(final JSONArray args) throws JSONException {
        if (m_isBound && m_svcLocation != null) {
            return m_svcLocation.stopPooling(args);
        }
        return false;
    }

    private void bindSattelite() {
        if (!m_isBound) {
            m_app.bindService(m_locationIntent, m_svcConn, 0);
        }
    }

    private void unbindSattelite() {
        if (m_isBound) {
            m_app.unbindService(m_svcConn);
        }
    }
}
