import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Authentication;
import Toybox.Communications;
import Toybox.StringUtil;
import Toybox.Sensor;

class SongsForTheHeartApp extends Application.AppBase {
    var spotify = new SpotifyApi();
    var view = new SongsForTheHeartView(spotify);
    var heartRateHandler = new HeartRateHandler();

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (spotify.accesstoken == null || spotify.refreshtoken == null) {
            spotify.getOAuthToken();
        } else {
            // spotify.tokenRequest();
            spotify.refreshTokenRequest();
        }

        // spotify.addToQueue("spotify:track:3z8T28TrqcYuANI7MlBg93");
        // spotify.getUsersPlaylists();
        spotify.getCurrentTrackProgress();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ view, new SongsForTheHeartDelegate() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as SongsForTheHeartApp {
    return Application.getApp() as SongsForTheHeartApp;
}