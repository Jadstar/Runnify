import Toybox.Sensor;
import Toybox.Lang;

/*
Uses the spotify song data found in a playlist
compares it with the heart rate data and begins ranking
what song should play based on the state of runner

*/

class MusicAlgo  {
    var rundata = new WatchSensorData();
    var spotify = new SpotifyApi();
    public var runmode;

    enum  {
        //Runstates
        RSTATE_WARMUP,
        RSTATE_RECOVER,
        RSTATE_TEMPO,
        RSTATE_RACE,
        RSTATE_FALLOFF,
        RSTATE_COOLDOWN,

        //Data Variance
        SLOW,
        STABLE,
        HIGH,
        SPRINT,
        STOPPED
    }

    // Uses the Sensor Data to determine Run State
    function parseRunData() {

        if (rundata.zone <= 2 && rundata.ActivityElapsedTime < 300*60*1000) {
            runmode = RSTATE_WARMUP;
        }
        else if (rundata.zone <= 2 && heartRateVariance() == STABLE) {
            runmode = RSTATE_RECOVER;
        }
        else if (rundata.zone >= 3 && heartRateVariance() == STABLE) {
            runmode = RSTATE_TEMPO;
        }
        else if (rundata.zone >= 4 || SpeedVariance() == SPRINT) {
            runmode = RSTATE_RACE;
        }
        else if (SpeedVariance() == SLOW && CadenceVariance() == SLOW) {
            runmode = RSTATE_FALLOFF;
        }
        else if (heartRateVariance() == STOPPED && SpeedVariance() == STOPPED) {
            runmode = RSTATE_COOLDOWN;
        } else {
            // Default state if none of the conditions are met
            runmode = RSTATE_RECOVER;
        }
    } 

    function rcoeffcientamirite(value) {
        // Define the coefficient ranges
        var coefficients = {
            "slow" => [-0.8, -0.4],
            "stable" => [-0.4, 0.4],
            "high" => [0.4, 0.8],
            "sprint" => [0.8, 1.0],
            "stopped" => [-1.0, -0.8]
        };

        // Get the list of states (keys)
        var states = coefficients.keys();
        for (var i = 0; i < states.size(); i++) {
            var state = states[i];
            var range = coefficients[state];
            var lower = range[0];
            var upper = range[1];
            if (lower < value && value <= upper) {
                return state;
            }
        }
        return "unknown"; // Return "unknown" if the value doesn"t fit any range
    }

    
    function heartRateVariance() {

        if (rundata.ActivityAVGHeartRate != null)
        {

        }
        else
        {
            return STABLE;

        }

        return SLOW;
        // return HIGH;
        // return SPRINT;
        // return STOPPED;
    }

    function SpeedVariance() {
        return SLOW;
        // return STABLE;
        // return HIGH;
        // return SPRINT;
        // return STOPPED;    
        }

    function CadenceVariance() {
        return SLOW;
        // return STABLE;
        // return HIGH;
        // return SPRINT;
        // return STOPPED;
    }


    //Determines the best song to queue based on the run state
    function rankSong(runstate as String) {


    }

}