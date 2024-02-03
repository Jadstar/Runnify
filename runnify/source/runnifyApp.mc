import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;
import Toybox.WatchUi;

class runnifyApp extends Application.AudioContentProviderApp {

    function initialize() {
        AudioContentProviderApp.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exitingj
    function onStop(state as Dictionary?) as Void {
    }

    // Get a Media.ContentDelegate for use by the system to get and iterate through media on the device
    function getContentDelegate(arg as PersistableType) as ContentDelegate? {
        return new runnifyContentDelegate();
    }

    // Get a delegate that communicates sync status to the system for syncing media content to the device
    function getSyncDelegate() as Communications.SyncDelegate? {
        return new runnifySyncDelegate();
    }

    // Get the initial view for configuring playback
    function getPlaybackConfigurationView() as Array<Views or InputDelegates>? {
        return [ new runnifyConfigurePlaybackView(), new runnifyConfigurePlaybackDelegate() ] as Array<Views or InputDelegates>;
    }

    // Get the initial view for configuring sync
    function getSyncConfigurationView() as Array<Views or InputDelegates>? {
        return [ new runnifyConfigureSyncView(), new runnifyConfigureSyncDelegate() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as runnifyApp {
    return Application.getApp() as runnifyApp;
}