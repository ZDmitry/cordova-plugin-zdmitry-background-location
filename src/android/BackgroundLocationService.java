package com.cordova.zdmitry.backgroundlocation;

import android.app.IntentService;
import android.location.LocationManager;

import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;

import android.app.Service;
import android.content.Intent;
import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;


public class BackgroundLocationService extends Service {
    BackgroundLocationBinder  mBinder   = new BackgroundLocationBinder();
    BackgroundLocationManager mLocation = new BackgroundLocationManager();

    public BackgroundLocationService() {
        // IntetnService  - super("com.cordova.zdmitry.backgroundlocation");
    }

    class BackgroundLocationBinder extends Binder {
        BackgroundLocationService getService() {
            return BackgroundLocationService.this;
        }
    }

    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    public boolean onUnbind(Intent intent) {
        return true;
    }

    // IntetnService - @implement
    protected void onHandleIntent(Intent intent) {

    }

    private Handler mHandler  = null;

    Runnable mStatusChecker = new Runnable() {
        @Override
        public void run() {
            try {
                updateLocation();
            } finally {
                mHandler.postDelayed(mStatusChecker, BackgroundLocationManager.MIN_POOL_INTERVAL);
            }
        }
    };

    public void onCreate() {
        super.onCreate();
    }

    public void onDestroy() {
        super.onDestroy();
    }

    public int onStartCommand(Intent intent, int flags, int startId) {
        return Service.START_STICKY; // super.onStartCommand(intent, flags, startId);
    }

    public Boolean configure(final JSONArray args) throws JSONException {
        // Params.

        //    0                    1               2                 3           4          5             6        7         8
        //[stationaryRadius, distanceFilter, locationTimeout, desiredAccuracy, debug, stopOnTerminate, interval, server, authToken]

        Long    stationaryRadius = args.getLong(0);
        Long    distanceFilter   = args.getLong(1);
        Long    locationTimeout  = args.getLong(2);
        Long    desiredAccuracy  = args.getLong(3);
        Boolean isDebuggable     = args.getBoolean(4);
        Boolean stopOnTerminate  = args.getBoolean(5);
        Long    poolInterval     = args.getLong(6);

        String serverUrl   = args.getString(7);
        String serverToken = args.getString(8);

        // configure location service
        if (poolInterval > BackgroundLocationManager.MIN_POOL_INTERVAL) {
            mLocation.setPoolInterval(poolInterval);
        }

        mLocation.setLocationAccuracy(desiredAccuracy);
        mLocation.setLocationTimeout(locationTimeout);

        mLocation.distanceFilter   = distanceFilter;
        mLocation.stationaryRadius = stationaryRadius;

        // configure network
        NetworkManager netMan = NetworkManager.sharedInstance();

        netMan.serverToken = serverToken;
        netMan.serverUrl   = (serverUrl == null) ? "" : serverUrl;

        return true;
    }

    public Boolean startPooling(final JSONArray args) throws JSONException {
        // Acquire a reference to the system Location Manager
        LocationManager locationManager = (LocationManager) this.getSystemService(Context.LOCATION_SERVICE);
        mLocation.startPoolingLocation(locationManager);

        // periodic pool
        // mHandler = new Handler();
        // mStatusChecker.run();
        return true;
    }

    public Boolean stopPooling(final JSONArray args) throws JSONException {
        // periodic pool
        // mHandler.removeCallbacks(mStatusChecker);
        // mHandler = null;

        mLocation.stopPoolingLocation();
        return true;
    }

    private void updateLocation() {
        mLocation.updateLocation();
    }
}
