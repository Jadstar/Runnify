import Toybox.Lang;
import Toybox.WatchUi;

class SongsForTheHeartDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        // WatchUi.pushView(new Rez.Menus.MainMenu(), new SongsForTheHeartMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}