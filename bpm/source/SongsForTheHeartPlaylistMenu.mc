import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SongsForTheHeartPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    var spotifyApi as SpotifyApi;

    //! Constructor
    public function initialize(spotify as SpotifyApi) {
        spotifyApi = spotify;
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var name = item.getId() as String;
        
        spotifyApi.selectPlaylist(name);
        spotifyApi.startPlayback();
        onBack();
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DrawableMenuTitle extends WatchUi.Drawable {

    //! Constructor
    public function initialize() {
        Drawable.initialize({});
    }

    //! Draw the application icon and main menu title
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        var spacing = 2;
        var labelWidth = dc.getTextWidthInPixels("Your Playlists", Graphics.FONT_MEDIUM);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // dc.fillRectangle(-100, -100, 1000, 200);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(0, 25, Graphics.FONT_MEDIUM, "Your Playlists", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}