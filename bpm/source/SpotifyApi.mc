import Toybox.Lang;
import Toybox.Timer;
import Toybox.Graphics;
import Toybox.WatchUi;
const BASE_URL = "https://api.spotify.com/v1";
const CLIENT_ID = "03e00d7168c84260a6175f4668bc7bd6";
const CLIENT_SECRET = "0aa850a846844d46ab3d6c50591c1c2b";
const OAUTH_CODE = "code";
const OAUTH_ERROR = "error";
const REDIRECT_URI = "connectiq://oauth";
const SCOPE = "user-read-recently-played streaming user-modify-playback-state user-read-private user-read-email playlist-read-private user-read-currently-playing user-read-playback-state";

const PLAYLIST_LIMIT = 50;
const TRACK_LIMIT = 50;
const AUDIO_FEATURE_LIM = 50;
const RECENTPLAYED_LIMIT = 5;
const TOKEN_EXP_DT = 10;

/*
    Contains all spotify api functionality
*/
class SpotifyApi {
    // Authentication stuff
    public var authcode;
    public var accesstoken;
    public var refreshtoken;
    var autoRefreshTimer = new Timer.Timer();
    var tokenExpirationSec = 3600;
    var firstToken = true;

    // Playlist variables
    public var usersPlaylists = {};
    public var totalPlaylistsPages = 0;
    public var totalPlaylistCount = 0;
    var gotAllPlaylists = false; // True when latest call to playlists api has finished all pages

    // Tracks in chosen playlist variables
    var gotAllTracks = false;
    var totalTrackCount = 0;
    var totalTrackPages = 0;
    public var selectedPlaylistTracks = {};
    var selectedPlaylistName = "";

    // Audio feature variables
    var audioFeatureRequests = 0;
    var audioFeatureURLs = {};
    var totalAudioFeatureRequests = 0;
    var delayedAudioFeatureTimer = new Timer.Timer();
    public var audioAnalysis;


    // Queue/Recently Played Variables
    public var queueList = [];
    public var getqueueflag;
    public var  recentlyPlayed = [];

    // Track progress
    public var currentTrackProgress = 0;
    public var trackPlaying = false;
    public var currentTrackURL = "";
    public var currentTrackName = "No Active Device";
    public var  currentTrackImage = null;

    var isDebug = false;

    /*
        Constructor
    */
    function initialize() { 
        accesstoken = Application.Storage.getValue("accesstoken");
        refreshtoken = Application.Storage.getValue("refreshtoken");
    }

    /*
        Downloads an image
    */
    function downloadTrackImage(currentTrackURL) {
        System.println("Downloading current track image from " + currentTrackURL);

        var url = currentTrackURL;           // set the image url
        var parameters = null;                                  // set the parameters
        var options = {                                         // set the options
            :palette => [   
                Graphics.COLOR_ORANGE,                     // set the palette
                Graphics.COLOR_DK_BLUE,
                Graphics.COLOR_BLUE,
                Graphics.COLOR_BLACK,
                Graphics.COLOR_YELLOW,
                Graphics.COLOR_WHITE,
                Graphics.COLOR_LT_GRAY,
                Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_RED,
                Graphics.COLOR_DK_RED,
                Graphics.COLOR_GREEN,
                Graphics.COLOR_DK_GREEN,
                Graphics.COLOR_PURPLE,
                Graphics.COLOR_PINK
            ],
            :maxWidth => 100,                                   // set the max width
            :maxHeight => 100,                                  // set the max height
            :dithering => Communications.IMAGE_DITHERING_NONE   // set the dithering
        };

        // Make the image request
        Communications.makeImageRequest(url, parameters, options, method(:imageResponseCallback));
    }
    
    /*
        saves to local variable
    */
    function imageResponseCallback(responseCode as Lang.Number, data as WatchUi.BitmapResource) as Void{
        if (responseCode == 200) {
            currentTrackImage = data;
            WatchUi.requestUpdate();
        } else {
            System.println("Image download failed: " + data);
            currentTrackImage = null;
        }
    }

    function getCurrentQueue() as Void{
        getqueueflag = false;
        var url = $.BASE_URL + "/me/player/queue";
        var params = {};
        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };
        
        Communications.makeWebRequest(url, params, options, method(:currentQueueCallback));
    }

    function currentQueueCallback(responseCode as Number, data as Dictionary?) as Void{
         System.println("Post received -> ");
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided");
            System.println("Error: " + data["error"]);
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200 || responseCode == 204) {
            queueList.add(data["queue"]["uri"]);
            System.println("Current Queue: " + queueList);
        } else {
            System.println("Unhandled response in currentQueueCallback: " + responseCode );
        }
        getqueueflag = true;

    }
    /*
        Given a spotify track uri make a request to queue that song
    */
    function addToQueue(uri) {
        var url = $.BASE_URL + "/me/player/queue?uri=" + uri;    
        // System.println(uri);              

        var params = {                                              
            "uri" => uri
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_POST,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onQueueRequestResponse));
    }

    /*
        Gets all of the users playlists and stores them into a list
    */
    function getUsersPlaylists() as Void {
        var url = $.BASE_URL + "/me/playlists";  

        // If non recursive call, reset variables
        if (gotAllPlaylists == true) {
            gotAllPlaylists = false;
            totalPlaylistCount = 0;
            totalPlaylistsPages = 0;
            usersPlaylists = {};
        }     

        var params = {                                              
            "limit" => $.PLAYLIST_LIMIT,
            "offset" => totalPlaylistsPages * $.PLAYLIST_LIMIT
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onPlayListResponse));
    }

    /*
        Given a name of a playlist, find it amongst the users playlists.
    */
    function selectPlaylist(name as String) {
        selectedPlaylistName = name;
        var selectedPlaylist = usersPlaylists[name];
        if (selectedPlaylist != null ) {
            getPlaylistsTracks();
        }
    }

    /*
        Adds playlists to a users playlists dictionary. Each key is a page corresponding to a list of a fixed
        amount of playlists. Monkey C apparently cant do dynamic lists so dictionaries it is. Surely no sane person
        has more than like 50 playlists anyways.
    */
    function onPlayListResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {

            // Add an entry to the dictionary with key pageN with a list of the current playlist items
            usersPlaylists["page" + totalPlaylistsPages] = data["items"];
            totalPlaylistCount = data["total"];

            // If there is more pages over the 50 playlist limit, call api again and increase page num
            if (data["next"] != null) {
                totalPlaylistsPages += 1;
                getUsersPlaylists();
            }

            // Flag and print when finished
            System.println("Num of playlists pages " + totalPlaylistsPages);
            if (data["next"] == null) {
                gotAllPlaylists = true;
                reformatUsersPlaylists();
                System.println("Got all playlists! " + usersPlaylists.keys());
            }

        } else if (responseCode == 401) { // Refresh if bad token code
            System.print("Bad Token Provided"); 
            System.println("Error: " + data["error"]);
            refreshTokenRequest(); 
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else {
            System.println("Unhandled response code: " + responseCode);
        }
    }

    /*
        Reformats the playlists dictionary to keep only the useful info and stored by their names as the key
    */
    function reformatUsersPlaylists() as Void {
        var newdict = {};
        var currentTotal = 1;
        for (var page = 0; page <= totalPlaylistsPages; page++) {
            for (var playlist = 0; (playlist < $.PLAYLIST_LIMIT) && (currentTotal < totalPlaylistCount); playlist++) {
                
                // Check against name
                var playlistDict = usersPlaylists["page" + page][playlist];
                var playlistName = playlistDict["name"];
                var tracks = playlistDict["tracks"]["total"];
                var image = playlistDict["images"][0]["url"];
                var trimmedDict = {
                    "id" => playlistDict["id"],
                    "name" => playlistName,
                    "image" => image,
                    "tracks" => tracks
                };
                newdict[playlistName] = trimmedDict;

                currentTotal++;
            }
        }

        usersPlaylists = newdict;
    }

    /*
        Gets progress of current track playing
    */
    function getRecentlyPlayedTracks() as Void {
        var url = $.BASE_URL + "/me/player/recently-played";

        var params = {
            "limit" => $.RECENTPLAYED_LIMIT
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(url, params, options, method(:recentlyPlayedResponse));


    }
    function recentlyPlayedResponse(responseCode as Number, data as Dictionary?) as Void {
       System.println("Post received -> ");
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided");
            System.println("Error: " + data["error"]);
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200 || responseCode == 204) {


            for (var i = 0; i < data["items"].size(); i++){
                
                recentlyPlayed.add(data["items"][0]["track"]["uri"]);
            }
            System.println("Recently Played Songs: " + recentlyPlayed);
        } else {
            System.println("Unhandled response in recentlyPlayed: " + responseCode+ " error: " );
        }
    
    }

    function getCurrentTrackProgress() as Void{
        var url = $.BASE_URL + "/me/player/currently-playing";

        var params = {};

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(url, params, options, method(:currentTrackResponse));
    }

    /* 
        Callback function to handle the current track request
    */
    function currentTrackResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided");
            System.println("Error: " + data["error"]);
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200) {

            // Get track info
            trackPlaying = data["is_playing"];
            var progress = data["progress_ms"];
            var track = data["item"];

            //check queue list to see if this was previously queued to remove it from list
            System.println("queue list: "+queueList);

            if (queueList.indexOf(track["uri"]) != -1){
                queueList.remove(track["uri"]);
            }
            if (recentlyPlayed.indexOf(track["uri"]) == -1){
                recentlyPlayed.add(track["uri"]);
            }

            if (progress != null && track != null) { // Sometimes returns as null
                currentTrackProgress = progress.toDouble() / track["duration_ms"].toDouble();
                
                // If song has changed get image
                var newTrackName = track["name"];
                if (!currentTrackName.equals(newTrackName)) {
                    currentTrackName = newTrackName;
                    // Get current track img url
                    currentTrackURL = track["album"]["images"][0]["url"];
                    downloadTrackImage(currentTrackURL);
                }
                System.println("Current Track " + currentTrackName + " Progress: " + currentTrackProgress * 100.0 + "% is playing: " + trackPlaying);
            }
        } else {
            System.println("Unhandled response in currentTrackResponse: " + responseCode);
        }
    }

    /*
        TODO: Returns the tracks in given playlist
    */
    function getPlaylistsTracks() as Void {
        var url = $.BASE_URL + "/playlists/" + usersPlaylists[selectedPlaylistName]["id"] + "/tracks";  

        // If non recursive call, reset variables
        if (gotAllTracks == true) {
            gotAllTracks = false;
            totalTrackCount = 0;
            totalTrackPages = 0;
            selectedPlaylistTracks = {};
        }     

        var params = {       
            "fields" => "total,next,items(track(name,id))",                                       
            "limit" => $.TRACK_LIMIT,
            "offset" => totalTrackPages * $.TRACK_LIMIT
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onPlaylistTracksResponse));
    }

    /*
        Collates all tracks from a given playlist id into one dictionary 
    */
    function onPlaylistTracksResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {

            // Add an entry to the dictionary for the track 
            for (var i = 0; i < data["items"].size(); i++) {
                selectedPlaylistTracks["track" + totalTrackCount] = data["items"][i]["track"];
                totalTrackCount += 1;
            }

            // If there is more pages over the 50 track limit, call api again and increase page num
            if (data["next"] != null) {
                totalTrackPages += 1;
                getPlaylistsTracks();
            } else { // == null
                gotAllTracks = true;
                System.println("Got all tracks from playlist " + selectedPlaylistName + " " + selectedPlaylistTracks.keys().size() + " tracks");
                getTrackAudioFeatures();
            }

        } else if (responseCode == 401) { // Refresh if bad token code
            System.print("Bad Token Provided"); 
            System.println("Error: " + data["error"]);
            refreshTokenRequest(); 
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else {
            System.println("Unhandled response code: " + responseCode);
        }
    }

    /*
        Returns the audio features of a track
    */
    function getTrackAudioFeatures() as Void {
        // No tracks in playlist, do not analyse
        if (selectedPlaylistTracks.size() == 0) {
            System.println("No tracks to analyse");
            return;
        }

        audioFeatureURLs = {};
        audioFeatureRequests = 0;

        // Only 100 songs can be analysed at one time, generate audioFeatureURLs with a specific amount of songs in them
        // The lower audio feature lim is, the faster the web request is and wont fail
        var urlCount = 0;
        var getUrl = "";  
        for (var i = 1; i < totalTrackCount; i++) {
            if (i % $.AUDIO_FEATURE_LIM == 0) { // Up to 100th song of this batch
                getUrl += selectedPlaylistTracks["track" + (i - 1)]["id"]; // Add last id without comma after
                audioFeatureURLs["url" + urlCount] = getUrl;
                urlCount += 1;
                getUrl = "";  
            } else {
                getUrl += selectedPlaylistTracks["track" + (i - 1)]["id"] + ",";
            }
        }
        // Add final song to url request and end the current url
        getUrl += selectedPlaylistTracks["track" + (totalTrackCount - 1)]["id"]; // Add last id without comma after
        audioFeatureURLs["url" + urlCount] = getUrl;
        urlCount += 1;

        // Start loop to call requests at a delay between to allow the previous call to finish first
        totalAudioFeatureRequests = urlCount;
        System.println("Starting analysis on all tracks of selected playlist");
        audioAnalysis = false;
        delayedAudioFeatureTimer.start(method(:delayedAudioRequest), 1000, true);
    }

    /*
        Make web request to get audio features in a callback so that it can be delayed using a timer
    */
    function getAnalysisFlag()as Boolean{
        return audioAnalysis;
    }
    function delayedAudioRequest() {
        System.println("audioFeatureRequests: " + audioFeatureRequests);
        System.println("totalAudioFeatureRequests: " + totalAudioFeatureRequests);

        if (audioFeatureRequests >= totalAudioFeatureRequests) {
            System.println("Finished all audio feature songs: " + selectedPlaylistTracks.keys().size());
            audioAnalysis = true;
            delayedAudioFeatureTimer.stop();
            
        } else {
            var url = $.BASE_URL + "/audio-features";
            var params = {
                "ids" => audioFeatureURLs["url" + audioFeatureRequests]
            };

            var options = {                                             
                :method => Communications.HTTP_REQUEST_METHOD_GET,      
                :headers => {
                    "Authorization" => "Bearer " + accesstoken,
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                }
            };

            System.println("Start Audio Feature Request: " + audioFeatureRequests);
            Communications.makeWebRequest(url, params, options, method(:onGetAudioFeaturesResponse));
        }
    }

    /*
        Adds the audio features received to the corresponding tracks in the playlistTracks dictionary
    */
    function onGetAudioFeaturesResponse(responseCode as Number, data as Dictionary?) as Void {
        System.println("GET AUDIO FEATURES CALLED");
        if (responseCode == 200) {
            // What track we are up to when this callback is received
            var start = audioFeatureRequests * $.AUDIO_FEATURE_LIM;

            // System.println("Request: " + audioFeatureRequests + " Size: " + data["audio_features"].size());
            // System.println(data["audio_features"]);

            // Add the audio features to the track variable in the dictionary so all the info is together
            for (var i = 0; i < data["audio_features"].size(); i++) {
                var audiofeature = {
                    "uri" => data["audio_features"][i]["uri"],
                    "id" => data["audio_features"][i]["id"],
                    "acousticness" => data["audio_features"][i]["acousticness"],
                    "instrumentalness" => data["audio_features"][i]["instrumentalness"],
                    "danceability" => data["audio_features"][i]["danceability"],
                    "liveness" => data["audio_features"][i]["liveness"],
                    "speechiness" => data["audio_features"][i]["speechiness"],
                    "tempo" => data["audio_features"][i]["tempo"],
                    "energy" => data["audio_features"][i]["energy"],
                    "happiness" => data["audio_features"][i]["energy"]
                };

                selectedPlaylistTracks["track" + (i + start)] =  audiofeature;
            }


            System.println("Finish Audio Feature Request: " + audioFeatureRequests);

        } else if (responseCode == 401) { // Refresh if bad token code
            System.print("Bad Token Provided"); 
            System.println("Error: " + data["error"]);
            refreshTokenRequest(); 
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == -402) {
            System.println("Serialized response was too large in audio feature request");
        } else {
            System.println("Unhandled response code: " + responseCode);
        }

        // Increment amount of times this has been called
        audioFeatureRequests += 1;
    }

    /*
        On receiving a response back from a POST command, interpret the response code
        and refresh token if necessary
    */
    function onQueueRequestResponse(responseCode as Number, data as Dictionary?) as Void {
        System.println("Post received -> ");
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided");
            System.println("Error: " + data["error"]);
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200 || responseCode == 204) {
            System.println("Added to queue!");
        } else {
            System.println("Unhandled response in onQueueRequestResponse: " + responseCode);
        }
    }

    /*
        Ticks down the token expiration by 1 second until 0, then orders a refresh
    */
    function checkTokenExpiration() {
        if (tokenExpirationSec == 30) {
            refreshTokenRequest();
        } else {
            tokenExpirationSec -= $.TOKEN_EXP_DT;
        }
    }

    /*
        Callback to receive token data from either refresh token or access token 
        endpoints. 
    */
    function onReceiveToken(responseCode as Number, data as Dictionary?) as Void {
        System.print("Token received -> ");
        if (responseCode == 200) {

            // Rewrite with new tokens if they are not given as null
            if (data["access_token"] != null) {
                accesstoken = data["access_token"];
                Application.Storage.setValue("accesstoken", accesstoken);
                System.println("New Token: " + accesstoken);
                tokenExpirationSec = data["expires_in"];
            }
            if (data["refresh_token"] != null) {
                refreshtoken = data["refresh_token"];
                Application.Storage.setValue("refreshtoken", refreshtoken);
                System.println("New Refresh: " + refreshtoken);
            }

            if (firstToken) {
                System.println("Starting auto refresh timer");
                autoRefreshTimer.start(method(:checkTokenExpiration), $.TOKEN_EXP_DT*1000, true);
                firstToken = false;
            }
            //stop timer
            autoRefreshTimer.stop();
            // Call get playlists after successful token retrieval

            getUsersPlaylists();
        } 
        else { // Failed, try authenticate again
            System.println("Unhandled response in onReceiveToken(): " + responseCode + " ");
            System.println("Attempting new OAuth...");
            getOAuthToken();
        }
    }

    /*
        Refreshes an expired token with the refresh token that was acquired with the expired token
    */
    function refreshTokenRequest() as Void {
        var url = "https://accounts.spotify.com/api/token?";                   

        var params = {                                              
            "refresh_token" => refreshtoken,
            "grant_type" => "refresh_token",
            "client_id" => $.CLIENT_ID
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_POST,      
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Authorization" => "Basic " + StringUtil.encodeBase64($.CLIENT_ID + ":" + $.CLIENT_SECRET)
            }
        };
        System.println(params);
        Communications.makeWebRequest(url, params, options, method(:onReceiveToken));
    }

    /*
        Resquest for an access token using the authorization code received from the user
    */
    function tokenRequest() as Void {
        var url = "https://accounts.spotify.com/api/token";                         

        var params = {                                              
            "code" => authcode,
            "redirect_uri" => $.REDIRECT_URI,
            "grant_type" => "authorization_code"
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_POST,      
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Authorization" => "Basic " + StringUtil.encodeBase64($.CLIENT_ID + ":" + $.CLIENT_SECRET)
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onReceiveToken));
    }

    /*
        Callback function to receive the authorization code from the web request
    */
    function onOAuthMessage(message) {
      

        if (message.data != null) {
            System.println("OAuth Successful");     
            authcode = message.data[$.OAUTH_CODE];
            Application.Storage.setValue("authcode", authcode);
            tokenRequest();
        }
        else {
            System.println("Oauth fail");     
        }
    }

    /*
        Make web request to spotify to receive an auth code. Notifies user's phone with a popup auth screen
    */
    function getOAuthToken() {
        if (isDebug == true) {
            authcode = "AQCmjEdQP7U5xGXJHW1EgoxJPlqyGqebif_x3u8SK5jFXQioyp6c3p7L40bIROgEOAyx1uX_3kilq5aQ5gO9Pzi8DlMPoHoXxrL50WnpPKAAjBCQ3bCzgOzNX3mN2ttxJl-TDBST-RLj0u2XEt5CgmOQmfvVUAn8I1nSS871dJUpNATH3hCFDZNiEbjmHjUpjMmlpgKbgGLjqCOtCTCnE7MxYOvCdCyr2Yh3iQ2iJ36WC4SAbEchqN0oiWnsRVO5kqIaigqLwl8N8p1eiiKPWiKROUag021FTTtFiyPTaOPFVEC_qqnY5l9iU0NBpu8QpL3dmx0Ix1mgkCEzCEB9JSNoDvyY6B9tNdhBUxOE9O5mw1TRGcaRM2byCsij-1MtSaLQTPHJ4NUo";
            tokenRequest();
            return;
        }

        Authentication.registerForOAuthMessages(method(:onOAuthMessage));

        // Spotify auth paramaters
        var params = {
            "response_type" => "code",
            "client_id" => $.CLIENT_ID,
            "scope" => $.SCOPE,
            "redirect_uri" => $.REDIRECT_URI
        };
        System.println($.OAUTH_CODE);
        Authentication.makeOAuthRequest(
            "https://accounts.spotify.com/authorize?",           // Url
            params,                                             // Params
            $.REDIRECT_URI,                                     // Redirect uri (back to the app)                       
            Authentication.OAUTH_RESULT_TYPE_URL,               // Auth response type
            {"code" => $.OAUTH_CODE, "error" => $.OAUTH_ERROR}  // The spotify mappings for code and error
        );
    }

    /*
        Starts playback with the selected playlist context
    */
    function startPlayback() {
        var url = $.BASE_URL + "/me/player/play";                         

        var params = {
            "context_uri" => "spotify:playlist:" + usersPlaylists[selectedPlaylistName]["id"],
            "offset" => {"position" => 0}
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_PUT,      
            :headers => {
                "Authorization" => "Bearer " + accesstoken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            }
        };

        System.println("Requesting start playback");
        Communications.makeWebRequest(url, params, options, method(:onStartResponse));
    }

    function onStartResponse(responseCode as Number, data as Dictionary?) as Void {
          
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided");
            System.println("Error: " + data["error"]);
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200 || responseCode == 204) {
            System.println("Started Playback");
        } else {
            System.println("Unhandled response in onStartResponse: " + responseCode + " " + data["error"]);
        }
    }

    /*
        Stops any timers or services
    */
    function stop() {
        autoRefreshTimer.stop();
    }
}