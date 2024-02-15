import Toybox.Lang;

const BASE_URL = "https://api.spotify.com/v1";
const CLIENT_ID = "03e00d7168c84260a6175f4668bc7bd6";
const CLIENT_SECRET = "0aa850a846844d46ab3d6c50591c1c2b";
const OAUTH_CODE = "code";
const OAUTH_ERROR = "error";
const REDIRECT_URI = "connectiq://oauth";
const SCOPE = "streaming user-modify-playback-state user-read-private user-read-email playlist-read-private";

const PLAYLIST_LIMIT = 50;

/*
    Contains all spotify api functionality
*/
class SpotifyApi {
    public var authcode;
    public var accesstoken;
    public var refreshtoken;

    // Playlist variables
    var usersPlaylists = {};
    var totalPages = 0;
    var totalPlaylistCount = 0;
    var gotAllPlaylists = true; // True when latest call to playlists api has finished all pages

    function initialize() { 
        authcode = "AQDC_l5XAJ2n0eUk1Q2ebXJ8Cy75VezWtp5Ht8uAsGmn7CQZfBn7sJLSXzSbJmWXQsH6iVSwQSwWlDB5OEwl9URCV8Cjd_wPcAYYzMSK0Ymh7htTDtRhJfSVAbo8ADAQWIXCoKG1AC_J--gQfbe6yTK4P53IhXcvOrVSA567Z7e5ymv9XCH3BguN8pzlzecmRD8IBkFOBmfu_7ziHHhbq2HqaiOUII5JaMU_8HXM7zT7pQNq7EYQBrJzFnTuho59brYxKszY7eG0pIHD_n79NvMpa9lZwB4";
        accesstoken = Application.Storage.getValue("accesstoken");
        refreshtoken = Application.Storage.getValue("refreshtoken");
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

        Communications.makeWebRequest(url, params, options, method(:onPOSTReceiveResponse));
    }

    /*
        Gets all of the users playlists and stores them into a list
    */
    function getUsersPlaylists() {
        var url = $.BASE_URL + "/me/playlists";  

        // If non recursive call, reset variables
        if (gotAllPlaylists == true) {
            gotAllPlaylists = false;
            totalPlaylistCount = 0;
            totalPages = 0;
            usersPlaylists = {};
        }     

        var params = {                                              
            "limit" => $.PLAYLIST_LIMIT,
            "offset" => totalPages
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
    function findPlaylist(name as String) as Dictionary? {
        if (usersPlaylists == {}) {return null;}

        // Loop through each page until the end of all playlists for the given name
        var currentTotal = 0;
        for (var page = 0; page <= totalPages; page++) {
            for (var playlist = 0; (playlist < $.PLAYLIST_LIMIT) && (currentTotal < totalPlaylistCount); playlist++) {
                
                // Check against name
                var playlistName = usersPlaylists["page" + page][playlist]["name"];
                // System.println(name.find(playlistName));
                if (name.find(playlistName) == 0) {
                    return usersPlaylists["page" + page][playlist];
                }

                currentTotal++;
            }
        }

        // None with given name
        return null;
    }

    /*
        Adds playlists to a users playlists dictionary. Each key is a page corresponding to a list of a fixed
        amount of playlists. Monkey C apparently cant do dynamic lists so dictionaries it is. Surely no sane person
        has more than like 50 playlists anyways.
    */
    function onPlayListResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {

            // Add an entry to the dictionary with key pageN with a list of the current playlist items
            usersPlaylists["page" + totalPages] = data["items"];
            totalPlaylistCount += data["total"];

            // If there is more pages over the 50 playlist limit, call api again and increase page num
            if (data["next"] != null) {
                totalPages += 1;
                getUsersPlaylists();
            }

            // Flag and print when finished
            if (data["next"] == null) {
                gotAllPlaylists = true;
                System.println("Got all playlists! " + usersPlaylists);
                System.println("Found playlist: " + findPlaylist("Pietro's 21"));
            }

        } else if (responseCode == 401) { // Refresh if bad token code
            System.print("Bad Token Provided -> "); 
            refreshTokenRequest(); 
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else {
            System.println("Unhandled response code: " + responseCode);
        }
    }

    /*
        On receiving a response back from a POST command, interpret the response code
        and refresh token if necessary
    */
    function onPOSTReceiveResponse(responseCode as Number, data as Dictionary?) as Void {
        System.println("Post received -> ");
        if (responseCode == 401) { // Refresh if bad token code
            System.println("Bad Token Provided -> ");
            refreshTokenRequest();
        } else if (responseCode == 400) {
            System.println("Error: " + data["error"]);
        } else if (responseCode == 200 || responseCode == 204) {
            System.println("Added to queue!");
        } else {
            System.println("Unhandled response in onPOSTReceiveResponse: " + responseCode + " " + data["error"]);
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
            }
            if (data["refresh_token"] != null) {
                refreshtoken = data["refresh_token"];
            }

            // Save to local storage to persist after app close
            Application.Storage.setValue("accesstoken", accesstoken);
            Application.Storage.setValue("refreshtoken", refreshtoken);

            System.println("Token: " + accesstoken);
            System.println("Refresh: " + refreshtoken);
        } 
        else { // Failed, try authenticate again
            System.println("Unhandled response in onReceiveToken(): " + responseCode + " " + data["error"]);
            System.println("Attempting new OAuth...");
            // getOAuthToken();
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
        Authentication.registerForOAuthMessages(method(:onOAuthMessage));

        // Spotify auth paramaters
        var params = {
            "response_type" => "code",
            "client_id" => $.CLIENT_ID,
            "scope" => $.SCOPE,
            "redirect_uri" => $.REDIRECT_URI
        };

        Authentication.makeOAuthRequest(
            "https://accounts.spotify.com/authorize",           // Url
            params,                                             // Params
            $.REDIRECT_URI,                                     // Redirect uri (back to the app)                       
            Authentication.OAUTH_RESULT_TYPE_URL,               // Auth response type
            {"code" => $.OAUTH_CODE, "error" => $.OAUTH_ERROR}  // The spotify mappings for code and error
        );
    }
}