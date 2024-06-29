import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Authentication;
import Toybox.Communications;
import Toybox.StringUtil;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Background;
import Toybox.Time;
import Toybox.System;

(:background)
class SongsForTheHeartApp extends Application.AppBase {
    var spotify = new Spotify.SpotifyApi();
    var watchSensorData = new WatchSensorData();
    var music = new MusicAlgo(spotify);
    function initialize() {
        AppBase.initialize();

        if(Background.getTemporalEventRegisteredTime() != null) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (spotify.accesstoken == null || spotify.refreshtoken == null) {
            spotify.getOAuthToken();
        } else {
            spotify.refreshTokenRequest();
            spotify.getRecentlyPlayedTracks();   //we only run this once at the start because its got a lot of data

        }
        
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        spotify.stop();
        System.println("Exiting");
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new SongsForTheHeartMainView(spotify, watchSensorData,music), new SongsForTheHeartMainDelegate(spotify) ] as Array<Views or InputDelegates>;
    }

    public function getServiceDelegate() as Array<System.ServiceDelegate> {
        return [new BackgroundCall(music)];
    }


}

function getApp() as SongsForTheHeartApp {
    return Application.getApp() as SongsForTheHeartApp;
}