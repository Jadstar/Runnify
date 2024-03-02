import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SongsForTheHeartMainDelegate extends WatchUi.BehaviorDelegate {
    var spotifyApi;
    //! Constructor
    public function initialize(spotify as SpotifyApi) {
        spotifyApi = spotify;
        BehaviorDelegate.initialize();
    }

    //! Handle the menu event
    //! @return true if handled, false otherwise
    public function onSelect() as Boolean {
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
}

class SongsForTheHeartMainView extends WatchUi.View {

    //! Constructor
    public function initialize() {
        View.initialize();
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
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    public function onHide() as Void {
    }
}
