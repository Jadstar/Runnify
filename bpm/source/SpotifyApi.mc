import Toybox.Lang;

const BASE_URL = "https://api.spotify.com/v1";
const CLIENT_ID = "03e00d7168c84260a6175f4668bc7bd6";
const CLIENT_SECRET = "0aa850a846844d46ab3d6c50591c1c2b";
const OAUTH_CODE = "code";
const OAUTH_ERROR = "error";
const REDIRECT_URI = "connectiq://oauth";
const SCOPE = "streaming user-modify-playback-state user-read-private user-read-email playlist-read-private";

/*
    Contains all spotify api functionality
*/
class SpotifyApi {
    public var authcode;
    public var accesstoken;
    public var refreshtoken;

    var usersPlaylists;
    var playlistPageNum = 0;

    function initialize() { 
        Application.Storage.setValue("authcode", "AQAy52JkzmStmMI8vOUGtR-tcknuE1JF5mcq8Oq6UI7zmRgnwQd3dI4mYyVggyvXKRc1AMg2NwLxoLP0al2Z_tZJLrOIzOnKbMWoiGjzHKrUG-hD3BLBtMVdcr08VYVIh-OGfY-_udGFqGWtW2GaQexw0793rgEwxxy3a8P497I3Wt9PGq025HLUBuOojOJJXSdDMaf-Hff8SSQLJ_fz3s6Pa6ArN5I57w-StNmIuRyVV64a6S4FGQbg5yJdNQwh43CYtU38eMx9cp7z1IWHCAPKix7MN7k");
        authcode = Application.Storage.getValue("authcode");
        System.println(authcode);
        accesstoken = Application.Storage.getValue("accesstoken");
        refreshtoken = Application.Storage.getValue("refreshtoken");
    }

    /*
        Given a spotify track uri make a request to queue that song
    */
    function addToQueue(uri) {
        var url = $.BASE_URL + "/me/player/queue";                         

        var params = {                                              
            "uri" => uri,
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_POST,      
            :headers => {
                "Content-Type" => "application/x-www-form-urlencoded",
                "Authorization" => "Bearer " + accesstoken.Object.toString()
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onPOSTReceiveResponse));
    }

    /*
        Gets all of the users playlists and stores them into a list
    */
    function getUsersPlaylists() {
        var url = $.BASE_URL + "/me/playlists";                         

        var params = {                                              
            "limit" => 50,
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_GET,      
            :headers => {
                "Content-Type" => "application/x-www-form-urlencoded",
                "Authorization" => "Bearer " + accesstoken
            }
        };

        Communications.makeWebRequest(url, params, options, method(:onPlayListResponse));
    }

    /*
        Adds playlists to a users playlists dictionary. Each key is a page corresponding to a list of a fixed
        amount of playlists. Monkey C apparently cant do dynamic lists so dictionaries it is. Surely no sane person
        has more than like 50 playlists anyways.
    */
    function onPlayListResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            // Add an entry to the dictionary with key pageN with a list of the current playlist items
            usersPlaylists["page" + playlistPageNum] = data["items"];

            // If there is more pages over the 50 playlist limit, call api again and increase page num
            if (data["next"] != null) {
                playlistPageNum += 1;
                getUsersPlaylists();
            }
        } else if (responseCode == 401) { // Refresh if bad token code
           refreshTokenRequest(); 
        }
    }

    /*
        On receiving a response back from a POST command, interpret the response code
        and refresh token if necessary
    */
    function onPOSTReceiveResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 401) { // Refresh if bad token code
            refreshTokenRequest();
        } 
    }

    /*
        Callback to receive token data from either refresh token or access token 
        endpoints. 
    */
    function onReceiveToken(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            System.println("Request Successful");                   
            accesstoken = data["access_token"];
            refreshtoken = data["refresh_token"];

            // Save to local storage to persist after app close
            Application.Storage.setValue(accesstoken, "accesstoken");
            Application.Storage.setValue(refreshtoken, "refreshtoken");

            addToQueue("spotify:track:3z8T28TrqcYuANI7MlBg93");
        } else { // Failed, try authenticate again
            System.println("Response: " + responseCode); 
            accesstoken = "No good pal";
            // getOAuthToken();
        }
    }

    /*
        Refreshes an expired token with the refresh token that was acquired with the expired token
    */
    function refreshTokenRequest() as Void {
        var url = "https://accounts.spotify.com/api/token";                         

        var params = {                                              
            "refresh_token" => refreshtoken,
            "grant_type" => "refresh_token",
            "client_id" => $.CLIENT_ID
        };

        var options = {                                             
            :method => Communications.HTTP_REQUEST_METHOD_POST,      
            :headers => {
                "Content-Type" => "application/x-www-form-urlencoded",
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
                "Content-Type" => "application/x-www-form-urlencoded",
                "Authorization" => "Basic " + StringUtil.encodeBase64($.CLIENT_ID + ":" + $.CLIENT_SECRET)
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
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
            Application.Storage.setValue(authcode, "authcode");
            var error = message.data[$.OAUTH_ERROR];
            tokenRequest();
        }
        else {
            System.println("Oauth fail");     
            authcode = $.OAUTH_ERROR;
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