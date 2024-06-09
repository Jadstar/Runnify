import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;

class SongsForTheHeartMainDelegate extends WatchUi.BehaviorDelegate {
    var spotifyApi;
    var session = null;                                             // set up session variable

    //! Constructor
    public function initialize(spotify as SpotifyApi) {
        spotifyApi = spotify;
        BehaviorDelegate.initialize();
    }

    //! Handle the menu event
    //! @return true if handled, false otherwise
   

    public function onSelect() as Boolean {

        // If playlists retrieved
        if (spotifyApi.gotAllPlaylists) {

            // Generate a new Menu with a drawable Title
            var menu = new WatchUi.Menu2({:title=>new $.DrawableMenuTitle()});

            // Add menu item for each playlist in the playlist dictionary
            var playlistNames = spotifyApi.usersPlaylists.keys();
            for (var playlistNum = 0; playlistNum < playlistNames.size(); playlistNum++) {
                    // Check against name
                    var playlistName = playlistNames[playlistNum];
                    menu.addItem(new WatchUi.MenuItem(playlistName, null, playlistName, null));
            }

            WatchUi.pushView(menu, new $.SongsForTheHeartPlaylistMenuDelegate(spotifyApi), WatchUi.SLIDE_UP);
            return true;
        }

        // Otherwise dont handle button press
        return false;
    }
}

class SongsForTheHeartMainView extends WatchUi.View {
    var spotifyApi as SpotifyApi;
    var currentTrackTimer = new Timer.Timer();
    var heartIcon = WatchUi.loadResource($.Rez.Drawables.Heart2);

    var playlistName = "Waiting for Data";
    var sensorData as WatchSensorData;
    var offset = 30;
    var stateData;
    // var music = new  MusicAlgo();
    var runningStatusText;
    //! Constructor
    public function initialize(spotify as SpotifyApi, watchSensorData as WatchSensorData,music as MusicAlgo) {
        spotifyApi = spotify;
        sensorData = watchSensorData;
        stateData = music;
        music.initialize();
        View.initialize();
        runningStatusText = "ANALYSING DATA";
    }

    //! Load your resources here
    //! @param dc Device Context
    public function onLayout(dc as Dc) {
        setLayout($.Rez.Layouts.MainLayout(dc));
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    public function onShow() as Void {
        currentTrackTimer.start(method(:updateMainScreen), 10000, true);
        WatchUi.requestUpdate();
    }
    
    function updateMainScreen() as Void {
        // Update text above info to tell user whether playlists are loaded, playlist has been selected
        // or if both have occurred running status.
        if (!spotifyApi.gotAllPlaylists) {
            playlistName = "Waiting for Data";
        } else if (!spotifyApi.gotAllTracks) {
            playlistName = "Select a Playlist";
        } else {
            playlistName = spotifyApi.selectedPlaylistName;
        }
         if (runningStatusText == null){
                stateData.stateText = "WAITING FOR DATA";

        }
        runningStatusText = stateData.stateText;

        // Get track info
        spotifyApi.getCurrentTrackProgress();
        WatchUi.requestUpdate();
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Status Text
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 130 + offset, Graphics.FONT_SMALL, runningStatusText, Graphics.TEXT_JUSTIFY_CENTER);

        // Playlist Text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 80 + offset, Graphics.FONT_XTINY, playlistName, Graphics.TEXT_JUSTIFY_CENTER);

        // Heart
        dc.drawBitmap(dc.getWidth() / 2 - 100, dc.getHeight() / 2 - 50 + offset, heartIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2 - 50, dc.getHeight() / 2 - 20 + offset, Graphics.FONT_SMALL, sensorData.currentBPM, Graphics.TEXT_JUSTIFY_CENTER);

        // Image
        if (spotifyApi.currentTrackImage != null) {
            dc.drawBitmap(dc.getWidth() / 2, dc.getHeight() / 2 - 50 + offset, spotifyApi.currentTrackImage);
        }

        // Text below
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 55 + offset, Graphics.FONT_XTINY, spotifyApi.currentTrackName, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    public function onHide() as Void {
        currentTrackTimer.stop();
    }
}
