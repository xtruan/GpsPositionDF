import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class GPSPositionSDFView extends WatchUi.SimpleDataField {

	hidden var mCounter;
	hidden var mDistanceUnits;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "GPS";
        
        mDistanceUnits = System.getDeviceSettings().distanceUnits;
        mCounter = 0;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // compute() is called once per second
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        // See Activity.Info in the documentation for available information.
        
        // GPS options
        var GPSFormatOption = Application.getApp().getProperty("GPSFormat");
        var geoFormat = :const_dms;
        if (GPSFormatOption == 0) {
        	geoFormat = :const_deg;
        } else if (GPSFormatOption == 1) {
        	geoFormat = :const_dm;
        } else if (GPSFormatOption == 2) {
        	geoFormat = :const_dms;
        } else if (GPSFormatOption == 3) {
        	geoFormat = :const_utm;
        } else if (GPSFormatOption == 4) {
        	geoFormat = :const_usng;
        } else if (GPSFormatOption == 5) {
        	geoFormat = :const_mgrs;
        } else if (GPSFormatOption == 6) {
        	geoFormat = :const_ukgr;
        }
        GPSFormatOption = null;
        
        // refresh options
        var PageIntervalOption = Application.getApp().getProperty("PageInterval");
        var pageInterval = 5;
        if (PageIntervalOption == 5) {
        	pageInterval = 5;
        } else if (PageIntervalOption == 10) {
        	pageInterval = 10;
        }
        PageIntervalOption = null;
        
        // vars for GPS data
        var currLocation = null;
        var currLocationAccuracy = 0; /*Pos.QUALITY_NOT_AVAILABLE*/
        var currAltitude = 0;
    	var currHeading = 0;
    	var currSpeed = 0;
        
        // populate location data
        if (info has :currentLocation && info.currentLocation != null) {
            currLocation = info.currentLocation;
        } else {
        	currLocation = null;
        }
        
        // populate location accuracy data
        if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
            currLocationAccuracy = info.currentLocationAccuracy;
        } else {
        	currLocationAccuracy = 0; /*Pos.QUALITY_NOT_AVAILABLE*/
        }
        
        // populate altitude
        if (info has :altitude && info.altitude != null) {
            currAltitude = info.currentLocationAccuracy;
        } else {
        	currAltitude = 0;
        }
        
        // populate heading
        if (info has :currentHeading && info.currentHeading != null) {
            currHeading = info.currentHeading;
        } else {
        	currHeading = 0;
        }
        
        // populate speed
        if (info has :currentSpeed && info.currentSpeed != null) {
            currSpeed = info.currentSpeed;
        } else {
        	currSpeed = 0;
        }
        
        // holders for position data
        var navStringTop = "";
        var navStringBot = "";
        
        var accuracyString = "";
        var altitudeString = "";
        var headingString = "";
        var speedString = "";
        
        if( currLocation != null ) {
            if (currLocationAccuracy == 4 /*Pos.QUALITY_GOOD*/) {
                accuracyString = "Signal: GOOD";
            } else if (currLocationAccuracy == 3 /*Pos.QUALITY_USABLE*/) {
                accuracyString = "Signal: USABLE";
            } else if (currLocationAccuracy == 2 /*Pos.QUALITY_POOR*/) {
                accuracyString = "Signal: POOR";
            } else {
                accuracyString = "Signal: UNKNOWN";
            }
            
            // the built in helper function (toGeoString) sucks!!!
            if (geoFormat == :const_deg || geoFormat == :const_dm || geoFormat == :const_dms) {
                var degrees = currLocation.toDegrees();
                var lat = 0.0;
                var latHemi = "?";
                var long = 0.0;
                var longHemi = "?";
                // do latitude hemisphere
                if (degrees[0] < 0) {
                    lat = degrees[0] * -1;
                    latHemi = "S";
                } else {
                    lat = degrees[0];
                    latHemi = "N";
                }
                // do longitude hemisphere
                if (degrees[1] < 0) {
                    long = degrees[1] * -1;
                    longHemi = "W";
                } else {
                    long = degrees[1];
                    longHemi = "E";
                }
                
                // if decimal degrees, we're done
                if (geoFormat == :const_deg) {
                    navStringTop = latHemi + " " + lat.format("%.6f");
                    navStringBot = longHemi + " " + long.format("%.6f");
                    //string = currLocation.toGeoString(Pos.GEO_DEG);
                // do conversions for degs mins or degs mins secs
                } else { // :const_dm OR :const_dms
                    var latDegs = lat.toNumber();
                    var latMins = (lat - latDegs) * 60;
                    var longDegs = long.toNumber();
                    var longMins = (long - longDegs) * 60;
                    if (geoFormat == :const_dm) {
                        navStringTop = latHemi + " " + latDegs.format("%i") + " " + latMins.format("%.4f") + "'"; 
                        navStringBot = longHemi + " " + longDegs.format("%i") + " " + longMins.format("%.4f") + "'";
                        //string = currLocation.toGeoString(Pos.GEO_DM);
                    } else { // :const_dms
                        var latMinsInt = latMins.toNumber();
                        var latSecs = (latMins - latMinsInt) * 60;
                        var longMinsInt = longMins.toNumber();
                        var longSecs = (longMins - longMinsInt) * 60;
                        navStringTop = latHemi + " " + latDegs.format("%i") + " " + latMinsInt.format("%i") + "' " + latSecs.format("%.2f") + "\""; 
                        navStringBot = longHemi + " " + longDegs.format("%i") + " " + longMinsInt.format("%i") + "' " + longSecs.format("%.2f") + "\"";
                        //string = currLocation.toGeoString(Pos.GEO_DMS);
                    }
                } 
            } else if (geoFormat == :const_utm || geoFormat == :const_usng || geoFormat == :const_mgrs || geoFormat == :const_ukgr) {
                var degrees = currLocation.toDegrees();
                var functions = new GpsPositionFunctions();
                if (geoFormat == :const_utm) {
                    var utmcoords = functions.LLtoUTM(degrees[0], degrees[1]);
                    navStringTop = "" + utmcoords[2] + " " + utmcoords[0];
                    navStringBot = "" + utmcoords[1];
                } else if (geoFormat == :const_usng) {
                    var usngcoords = functions.LLtoUSNG(degrees[0], degrees[1], 5);
                    if (usngcoords[1].length() == 0 || usngcoords[2].length() == 0 || usngcoords[3].length() == 0) {
                        navStringTop = "" + usngcoords[0]; // error message
                    } else {
                        navStringTop = "" + usngcoords[0] + " " + usngcoords[1];
                        navStringBot = "" + usngcoords[2] + " " + usngcoords[3];
                    }
                } else if (geoFormat == :const_ukgr) {
                    var ukgrid = functions.LLToOSGrid(degrees[0], degrees[1]);
                    if (ukgrid[1].length() == 0 || ukgrid[2].length() == 0) {
                        navStringTop = ukgrid[0]; // error message
                    } else {
                        navStringTop = "" + ukgrid[0] + " " + ukgrid[1];
                        navStringBot =  "" + ukgrid[2];
                    }
                } else { // :const_mgrs
                    // this function only works in sim, not device for MGRS, boo!
                    //navStringTop = currLocation.toGeoString(Pos.GEO_MGRS);
                    
                    // even though MGRS letters are provided on device, I think they're wrong
                    //var mgrszone = currLocation.toGeoString(Pos.GEO_MGRS).substring(0, 6);
                    //var usngcoords = functions.LLtoUSNG(degrees[0], degrees[1], 5);
                    //navStringTop = "" + mgrszone + " " + usngcoords[2] + " " + usngcoords[3];
                    
                    // so, just do the same thing as USNG since it's using the correct datum to be equivalent to MGRS
                    var usngcoords = functions.LLtoUSNG(degrees[0], degrees[1], 5);
                    if (usngcoords[1].length() == 0 || usngcoords[2].length() == 0 || usngcoords[3].length() == 0) {
                        navStringTop = "" + usngcoords[0]; // error message
                    } else {
                        navStringTop = "" + usngcoords[0] + " " + usngcoords[1];
                        navStringBot = "" + usngcoords[2] + " " + usngcoords[3];
                    }
                }
            } else {
            	// invalid format, reset to Degs/Mins/Secs
                navStringTop = "...";
                geoFormat = :const_dms; // Degs/Mins/Secs
            }
            
            // display heading
            var headingRad = currHeading;
            var headingDeg = headingRad * 57.2957795;
            headingString = "Hdg: " + headingDeg.format("%.1f") + " deg";
            
            // display altitude
            var altMeters = currAltitude;
            var altFeet = altMeters * 3.28084;
            if (mDistanceUnits == System.UNIT_METRIC) {
            	altitudeString = "Alt: " + altMeters.format("%.1f") + " m";
            } else { // mDistanceUnits == System.UNIT_STATUTE
            	altitudeString = "Alt: " + altFeet.format("%.1f") + " ft";
            }
            
            // display speed in mph or km/h based on device unit settings
            var speedMsec = currSpeed;
            if (mDistanceUnits == System.UNIT_METRIC) {
                var speedKmh = speedMsec * 3.6;
                speedString = "Spd: " + speedKmh.format("%.1f") + " km/h";
            } else { // mDistanceUnits == System.UNIT_STATUTE
                var speedMph = speedMsec * 2.23694;
                speedString = "Spd: " + speedMph.format("%.1f") + " mph";
            }
            
            // count iterations to cycle through all options
            mCounter = mCounter + 1;
	        if (mCounter > 6 * pageInterval) {
	        	mCounter = 1;
	        }
            
            // display data
            if (mCounter <= 2 * pageInterval) {
	            if (navStringBot.length() != 0) {
	            	if (mCounter <= 1 * pageInterval) {
	            		return navStringTop;
	            	} else {
	            		return navStringBot;
	            	}
	            } else {
	                return navStringTop;
	            }
            } else if (mCounter <= 3 * pageInterval) {
            	return altitudeString;
            } else if (mCounter <= 4 * pageInterval) {
            	return headingString;
            } else if (mCounter <= 5 * pageInterval) {
            	return speedString;
            } else /*if (mCounter <= 6 * pageInterval)*/ {
            	return accuracyString;
            }
        }
        else {
            // display default text for no GPS
            return "Position unavailable";
        }
        
    }

}