package com.cordova.zdmitry.backgroundlocation;

import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;

import android.os.Bundle;

import org.json.JSONObject;

import java.text.DateFormat;
import java.text.SimpleDateFormat;


public class BackgroundLocationManager implements LocationListener {
    private LocationManager mLocationMan = null;

    private static final int SECOND = 1000 * 1;

    private long mLocationTimeout  = 1 * 60 * 1000; // 1 minute
    private long mLocationAccuracy = 200;

    public  static final Integer MIN_POOL_INTERVAL = 5; // 5 seconds

    public  long distanceFilter    = (-1);
    public  long poolInterval      = BackgroundLocationManager.MIN_POOL_INTERVAL;
    public  long stationaryRadius  = 0;

    public Boolean startPoolingLocation(LocationManager locationManager) {
        if (poolInterval <= 0) return false;
        Boolean retVal = true;

        try {  // Register the listener with the Location Manager to receive location updates
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, poolInterval /* min pool time */, stationaryRadius /* accuracy */, this);
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, poolInterval /* min pool time */, stationaryRadius /* accuracy */, this);
            mLocationMan = locationManager;
        } catch (SecurityException e) {
            retVal = false;
        }

        return retVal;
    }

    public Boolean stopPoolingLocation() {
        Boolean retVal = true;

        try {
            if (this.checkEnabled()) {
                mLocationMan.removeUpdates(this);
            }
        } catch (SecurityException e) {
            retVal = false;
        }

        return retVal;
    }

    private Boolean checkEnabled() {
        if (mLocationMan != null) {
            return (mLocationMan.isProviderEnabled(LocationManager.GPS_PROVIDER) || mLocationMan.isProviderEnabled(LocationManager.NETWORK_PROVIDER));
        }
        return false;
    }

    private void showLocation(Location location) {
        NetworkManager netMan = NetworkManager.sharedInstance();

        try {
            JSONObject obj = new JSONObject();

            // DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mmXXX");
            // String date = df.format(new java.util.Date(location.getTime()));

            obj.put("accuracy", location.getAccuracy());
            obj.put("altitude", location.getAltitude());
            obj.put("longitude", location.getLongitude());
            obj.put("latitude", location.getLatitude());
            obj.put("bearing", location.getBearing());
            obj.put("speed", location.getSpeed());
            // obj.put("timestamp", date);

            obj = new JSONObject();

            obj.put("lat", location.getLatitude());
            obj.put("lng", location.getLongitude());
            // obj.put("createdAt", date);

            netMan.sendDictionary(obj);
        } catch (Exception e) {
            // ...
        }
    }

    public void setLocationTimeout( long seconds ) {
        mLocationTimeout = seconds * 1000;
    }

    public void setPoolInterval( long seconds ) {
        poolInterval = seconds * 1000;
    }

    public void setLocationAccuracy( long value ) {
        mLocationAccuracy = value; // BackgroundLocationManager.translateDesiredAccuracy((int)value);
    }

    protected boolean isBetterLocation(Location location, Location currentBestLocation) {
        if (currentBestLocation == null) {
            // A new location is always better than no location
            return true;
        }

        // Check whether the new location fix is newer or older
        long timeDelta = location.getTime() - currentBestLocation.getTime();
        boolean isSignificantlyNewer = timeDelta > mLocationTimeout;
        boolean isSignificantlyOlder = timeDelta < -mLocationTimeout;
        boolean isNewer = timeDelta > 0;

        // If it's been more than two minutes since the current location, use the new location
        // because the user has likely moved
        if (isSignificantlyNewer) {
            return true;
            // If the new location is more than two minutes older, it must be worse
        } else if (isSignificantlyOlder) {
            return false;
        }

        // Check whether the new location fix is more or less accurate
        int accuracyDelta = (int) (location.getAccuracy() - currentBestLocation.getAccuracy());
        boolean isLessAccurate = accuracyDelta > 0;
        boolean isMoreAccurate = accuracyDelta < 0;
        boolean isSignificantlyLessAccurate = accuracyDelta > mLocationAccuracy;

        // Check if the old and new location are from the same provider
        boolean isFromSameProvider = isSameProvider(location.getProvider(), currentBestLocation.getProvider());

        // Determine location quality using a combination of timeliness and accuracy
        if (isMoreAccurate) {
            return true;
        } else if (isNewer && !isLessAccurate) {
            return true;
        } else if (isNewer && !isSignificantlyLessAccurate && isFromSameProvider) {
            return true;
        }

        return false;
    }

    public void updateLocation() {
        // ...
    }

    /** Checks whether two providers are the same */
    private boolean isSameProvider(String provider1, String provider2) {
        if (provider1 == null) {
            return provider2 == null;
        }
        return provider1.equals(provider2);
    }

    private static int translateDesiredAccuracy(int accuracy) {
        switch (accuracy) {
            case 1000:
                accuracy = Criteria.ACCURACY_LOW;
                break;
            case 100:
                accuracy = Criteria.ACCURACY_MEDIUM;
                break;
            case 10:
                accuracy = Criteria.ACCURACY_HIGH;
                break;
            case 0:
                accuracy = Criteria.ACCURACY_HIGH;
                break;
            default:
                accuracy = Criteria.ACCURACY_MEDIUM;
        }
        return accuracy;
    }

    /*** LocationListener implementation ***/

    @Override
    public void onLocationChanged(Location location) {
        if (checkEnabled() && location != null) {
            this.showLocation(location);
        }
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
        // ...
    }

    @Override
    public void onProviderEnabled(String provider) {
        if (checkEnabled()) {
            try {
                showLocation(mLocationMan.getLastKnownLocation(provider));
            } catch (SecurityException e) {
                // ...
            }
        }
    }

    @Override
    public void onProviderDisabled(String provider) {
        // ...
    }
}
