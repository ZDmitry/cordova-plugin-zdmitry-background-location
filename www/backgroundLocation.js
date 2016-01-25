var exec = require('cordova/exec');

var backgroundLocation = {
    accuracy: {
        HIGH: 0,
        MEDIUM: 100,
        LOW: 1000,
        PASSIVE: 10000
    },

    config: {},

    configure: function(success, failure, config) {
        this.config = config || {};
        var stationaryRadius      = (config.stationaryRadius >= 0) ? config.stationaryRadius : 50,  // meters
            distanceFilter        = (config.distanceFilter  >= 0) ? config.distanceFilter    : 500, // meters
            locationTimeout       = (config.locationTimeout >= 0) ? config.locationTimeout   : 60,  // seconds
            desiredAccuracy       = (config.desiredAccuracy >= 0) ? config.desiredAccuracy   : this.accuracy.MEDIUM,

            debug                 = config.debug || false,
            stopOnTerminate       = config.stopOnTerminate || false,

            interval              = (config.interval >= 0) ? config.interval : locationTimeout * 1000, // milliseconds

            server                = (config.server || typeof config.server === 'string') ? config.server : '',
            authToken             = (config.token  || typeof config.token  === 'string') ? config.token  : ''

        exec(success || function() {},
            failure || function() {},
            'BackgroundLocation',
            'configure', [
                stationaryRadius,
                distanceFilter,
                locationTimeout,
                desiredAccuracy,
                debug,
                stopOnTerminate,
                interval,
                server,
                authToken
            ]
        );
    },
    start: function(success, failure) {
        exec(success || function() {},
            failure || function() {},
            'BackgroundLocation',
            'start', []);
    },
    stop: function(success, failure) {
        exec(success || function() {},
            failure || function() {},
            'BackgroundLocation',
            'stop', []);
    },
    isLocationEnabled: function(success, failure) {
        exec(success || function() {},
            failure || function() {},
            'BackgroundGeoLocation',
            'isLocationEnabled', []);
    }
};

module.exports = backgroundLocation;
