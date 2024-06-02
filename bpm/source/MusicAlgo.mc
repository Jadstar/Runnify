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


    function heartRateVariance() {

        if (rundata.ActivityAVGHeartRate != null)
        {

        }
        else
        {
            return STABLE;

        }

        return SLOW;
        return HIGH;
        return SPRINT;
        return STOPPED;
    }

    function SpeedVariance() {
        return SLOW;
        return STABLE;
        return HIGH;
        return SPRINT;
        return STOPPED;    }

    function CadenceVariance() {
        return SLOW;
        return STABLE;
        return HIGH;
        return SPRINT;
        return STOPPED;
    }


    //Determines the best song to queue based on the run state
    function rankSong(runstate as String) {


    }

}