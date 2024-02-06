import Toybox.Lang;
import Toybox.WatchUi;

class SongsForTheHeartDelegate extends WatchUi.BehaviorDelegate {
    var sharedspotify;
    function initialize(spotify) {
        sharedspotify = spotify;
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        sharedspotify.getOAuthToken();
        return true;
    }

}