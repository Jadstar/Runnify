import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Authentication;
import Toybox.Communications;
import Toybox.StringUtil;
import Toybox.Sensor;

const CLIENT_ID = "03e00d7168c84260a6175f4668bc7bd6";
const CLIENT_SECRET = "0aa850a846844d46ab3d6c50591c1c2b";
const OAUTH_CODE = "code";
const OAUTH_ERROR = "error";
const REDIRECT_URI = "connectiq://oauth";

class SongsForTheHeartApp extends Application.AppBase {
    var spotify = new SpotifyApi();

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        spotify.getOAuthToken();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new SongsForTheHeartView(), new SongsForTheHeartDelegate() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as SongsForTheHeartApp {
    return Application.getApp() as SongsForTheHeartApp;
}

class SpotifyApi {
    public var authcode;
    public var accesstoken;
    public var refreshtoken;

    function initialize() {
        authcode = Application.Storage.getValue("authcode");
        accesstoken = Application.Storage.getValue("accesstoken");
        refreshtoken = Application.Storage.getValue("refreshtoken");
    }

    function addToQueue(uri) {
        var url = "https://api.spotify.com/v1/me/player/queue";                         // set the url

        var params = {                                              // set the parameters
            "uri" => uri,
        };

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :headers => {
                "Content-Type" => "application/x-www-form-urlencoded",
                "Authorization" => "Bearer " + accesstoken
            },
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
        };

        Communications.makeWebRequest(url, params, options, method(:onReceiveToken));
    }

    function onReceiveResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 401) {
            refreshTokenRequest();
        } 
    }

    // set up the response callback function
    function onReceiveToken(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            System.println("Request Successful");                   // print success
            accesstoken = data["access_token"];
            refreshtoken = data["refresh_token"];
            Application.Storage.setValue(accesstoken, "accesstoken");
            Application.Storage.setValue(refreshtoken, "refreshtoken");

            addToQueue("spotify:track:3z8T28TrqcYuANI7MlBg93");
        } else {
            System.println("Response: " + responseCode);            // print response code
        }
    }

    function refreshTokenRequest() as Void {
        // var url = "https://accounts.spotify.com/api/token";                         // set the url

        // var params = {                                              // set the parameters
        //     "code" => authcode,
        //     "redirect_uri" => $.REDIRECT_URI,
        //     "grant_type" => "authorization_code"
        // };

        // var options = {                                             // set the options
        //     :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
        //     :headers => {
        //         "Content-Type" => "application/x-www-form-urlencoded",
        //         "Authorization" => "Basic " + StringUtil.encodeBase64(CLIENT_ID + ":" + CLIENT_SECRET)
        //     },
        //     // set response type
        //     :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
        // };

        // Communications.makeWebRequest(url, params, options, method(:onReceiveToken));
    }

    function tokenRequest() as Void {
        var url = "https://accounts.spotify.com/api/token";                         // set the url

        var params = {                                              // set the parameters
            "code" => authcode,
            "redirect_uri" => $.REDIRECT_URI,
            "grant_type" => "authorization_code"
        };

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :headers => {
                "Content-Type" => "application/x-www-form-urlencoded",
                "Authorization" => "Basic " + StringUtil.encodeBase64(CLIENT_ID + ":" + CLIENT_SECRET)
            },
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
        };

        Communications.makeWebRequest(url, params, options, method(:onReceiveToken));
    }

    function onOAuthMessage(message) {
        if (message.data != null) {
            System.println("OAuth Successful");     
            authcode = message.data[OAUTH_CODE];
            Application.Storage.setValue(authcode, "authcode");
            var error = message.data[OAUTH_ERROR];
            tokenRequest();
        } else {
            System.println("Oauth fail");     
        }
    }

    function getOAuthToken() {
        Authentication.registerForOAuthMessages(method(:onOAuthMessage));

        // set the makeOAuthRequest parameters
        var params = {
            "response_type" => "code",
            "client_id" => $.CLIENT_ID,
            "scope" => "app-remote-control streaming user-read-private user-read-email playlist-read-private",
            "redirect_uri" => $.REDIRECT_URI,
            "state" => "bazinga"
        };

        // makeOAuthRequest triggers login prompt on mobile device.
        // "responseCode" and "responseError" are the parameters passed
        // to the resultUrl. Check the oauth provider's documentation
        // to determine the correct strings to use.
        Authentication.makeOAuthRequest(
            "https://accounts.spotify.com/authorize",
            params,
            "connectiq://oauth",
            Authentication.OAUTH_RESULT_TYPE_URL,
            {"responseCode" => $.OAUTH_CODE, "responseError" => $.OAUTH_ERROR}
        );
    }
}

class HeartBeatSensor {
    public var currentBPM;

    function initialize() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );
        Sensor.enableSensorEvents( method( :onSensor ) );
    }

    function onSensor(sensorInfo as Sensor.Info) as Void {
        currentBPM = sensorInfo.heartRate;
        System.println(currentBPM);

        WatchUi.requestUpdate();
    }
}