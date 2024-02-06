import Toybox.Lang;
import Toybox.WatchUi;

class SongsForTheHeartDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        return true;
    }
}