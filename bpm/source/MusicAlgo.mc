import Toybox.Sensor;
import Toybox.Lang;
/*
Uses the spotify song data found in a playlist
compares it with the heart rate data and begins ranking
what song should play based on the state of runner

*/

class MusicAlgo  {
var watchSensorData = new WatchSensorData();
var spotify = new SpotifyApi();

enum RunState {
    WARMUP = "Warm Up",
    RECOVER = "Base/Recovery",
    TEMPO = "Tempo",
    RACE = "Race Mode",
    FALLOFF = "Fall Off",
    COOLDOWN = "Cooldown"
}

// Uses the Sensor Data to determine Run State
function parseRunData() {
    var heartrate;
    var cadence;
    var speed;
    var zone;
    
}

//Determines the best song to queue based on the run state
function rankSong(runstate as String) {


}

}