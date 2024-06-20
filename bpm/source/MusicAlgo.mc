import Toybox.Sensor;
import Toybox.Lang;

/*
Uses the spotify song data found in a playlist
compares it with the heart rate data and begins ranking
what song should play based on the state of runner

*/

class MusicAlgo  {
    public var runmode;
    public var stateText = "WAITING FOR DATA";
    var spotify as SpotifyApi;
    public var rundata;
    public var songMatch = {};
    var runTimer = new Timer.Timer();

    function initialize(spotifyrun as SpotifyApi){
        spotify = spotifyrun;
        rundata = new WatchSensorData();
        runTimer.start(method(:parseRunData),1000,true);
    }
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
    public var coefficients = {
        "slow" => { "range" => [-0.8, -0.4], "variance" => SLOW },
        "stable" => { "range" => [-0.4, 0.4], "variance" => STABLE },
        "high" => { "range" => [0.4, 0.8], "variance" => HIGH },
        "sprint" => { "range" => [0.8, 1.0], "variance" => SPRINT },
        "stopped" => { "range" => [-1.0, -0.8], "variance" => STOPPED }
    };     


    // Uses the Sensor Data to determine Run State
    function parseRunData() {

        //Run activity data:
        rundata.ActivityTimerCallback();
        //if spotify is ready, start categorising songs
        categoriseSong();

        if (rundata.currSpeed != null && rundata.currCadence !=null && rundata.currentBPM !=null && rundata.zone !=null){
            if ( RegressionCalc(rundata.cadences) == SPRINT || RegressionCalc(rundata.speeds) == SPRINT) {
                System.println("RACE");
                stateText = "RACE MODE";
                runmode = RSTATE_RACE;
            }
            else if (rundata.zone <= 2 && rundata.ActivityElapsedTime < 300*60*1000) {
                System.println("RECOVERY");
                runmode = RSTATE_WARMUP;
            }
             else if (RegressionCalc(rundata.speeds) == SLOW && RegressionCalc(rundata.cadences) == SLOW) {
                System.println("FALLOFF");
                stateText = "YOU FELL OFF";
                runmode = RSTATE_FALLOFF;
            }

            else if (RegressionCalc(rundata.heartRates) == STOPPED && RegressionCalc(rundata.speeds) == STOPPED) {
                System.println("COOLDOWN");
                stateText = "COOLING DOWN";
                runmode = RSTATE_COOLDOWN;
            }
            else if (rundata.zone <= 2 && RegressionCalc(rundata.heartRates) == STABLE) {
                stateText = "BASE RUN";
                System.println("RECOVERY");
                runmode = RSTATE_RECOVER;
            }
            else if (rundata.zone >= 3 && RegressionCalc(rundata.heartRates) == STABLE) {
                System.println("TEMPO");
                stateText = "TEMPO RUN";
                runmode = RSTATE_TEMPO;
            }
                
             else {
                // Default state if none of the conditions are met
                System.println("UNKNOWN");
                stateText = "UNKNOWN";

                runmode = RSTATE_RECOVER;
            }
            if (categoriseSong() != false){
                rankSong();

            }
        }
       
    } 

    function corr(xvalues,yvalues){
        var coefficent;
        var product_of_z = [];
        var samplesize = 10;
        var x_avg = Math.mean(xvalues);
        var y_avg = Math.mean(yvalues);
        //assume stable if the values have hit the sample size of 10 or arent the same size
        if (xvalues.size() != samplesize || yvalues.size() != samplesize || xvalues.size() != yvalues.size())
        {
            coefficent = 0;
            return coefficent;
        }
        else{

            for (var i = 0; i < samplesize; i++){
                var z_x = (xvalues[i] - x_avg)/Math.stdev(xvalues, x_avg);  //timestamp

                if (Math.stdev(yvalues,y_avg) != 0){
                    var z_y = (yvalues[i] - y_avg)/Math.stdev(yvalues,y_avg);
                    product_of_z.add(z_x*z_y);

                }
                else {
                    coefficent = 0;
                    return coefficent;
                }
            }
            coefficent = Math.mean(product_of_z);

        }
        return coefficent;
    }
    function RegressionCalc(dataarray) {
        var value = corr(rundata.timestamps,dataarray);
        // Get the list of states (keys)
        var states = coefficients.keys();
        for (var i = 0; i < states.size(); i++) {
            var state = states[i];
            var entry = coefficients[state];

            var range = entry["range"];

            if (inRange(value,range)){
                return entry["variance"];
            }
        }

        return "stable"; // Return "unknown" if the value doesn"t fit any range
    }
    function inRange(value, range) as Boolean{
        return value >= range[0] && value <= range[1];
    }

    function categoriseSong(){
        //for each song, we categorise them so we can rank them easy based on the current running state
        var statelist = ["RECOVER","FALLOFF","COOLDOWN","RACE","TEMPO","WARMUP"];
        var songchosen = false;
        var songStates = {
            "RECOVER" => {
                "state" => RSTATE_RECOVER,
                "bpmRange" => [0, rundata.maxHR], // BPM match cadence (high prio)
                "dance" => [.50, .85],
                "energy" => [.50, .85],
                "acoustic" => [0, .10],
                "instrumental" => [0, .40],
                "liveness" => [0, .20],
                "speech" => [0, .10]
            },
            "FALLOFF" => {
                "state" => RSTATE_FALLOFF,
                "bpmRange" => [0, rundata.maxHR], // BPM equal avg cadence, or slightly higher than current cadence (High prio)
                "happiness" => [.40, .90],
                "dance" => [.48, .80],
                "energy" => [.73, 1],
                "acoustic" => [0, .60],
                "instrumental" => [0, .15],
                "liveness" => [.05, .30],
                "speech" => [0, .20]
            },
            "COOLDOWN" => {
                "state" => RSTATE_COOLDOWN,
                "bpmRange" => [0, rundata.maxHR], // BPM lower than current cadence (low prio)
                "dance" => [.45, .55],
                "energy" => [.60, .80],
                "acoustic" => [0, .80],
                "instrumental" => [0, .20],
                "liveness" => [0, .25],
                "speech" => [0, .50]
            },
            "RACE" => {
                "state" => RSTATE_RACE,
                "bpmRange" => [100, 200], // BPM match ideal cadence ~175-180bpm (High prio)
                "dance" => [.05, .80],
                "energy" => [.82, 1.00],
                "acoustic" => [0, .10],
                "instrumental" => [0, .10],
                "liveness" => [.05, .60],
                "speech" => [0, .20]
            },
            "TEMPO" => {
                "state" => RSTATE_TEMPO,
                "bpmRange" => [0, 1000], // BPM match cadence (High prio)
                "dance" => [.15, .80],
                "energy" => [.60, 1],
                "acoustic" => [0, 1],
                "instrumental" => [0, 1],
                "liveness" => [0, .80],
                "speech" => [0, .28]
            },
            "WARMUP" => {
                "state" => RSTATE_WARMUP,
                "bpmRange" => [0, 200], // BPM match cadence (low prio)
                "dance" => [.25, .85],
                "energy" => [.30, 1],
                "acoustic" => [0, .80],
                "instrumental" => [0, .50],
                "liveness" => [0, .90],
                "speech" => [0, .60]
            }
        };
        System.println("ANALYSIS: " + spotify.getAnalysisFlag());
        if (spotify.getAnalysisFlag() == true){
            spotify.audioAnalysis = false;
            //initailise the arrays
            for (var state=0; state < statelist.size(); state++) {
                
                songMatch.put(statelist[state],[]);
            }
            songMatch.put("UNIDENTIFIED",[]);
            System.println(songMatch.toString());
            for (var i =0; i <spotify.selectedPlaylistTracks.size(); i++){
                
                songchosen = false;
                // System.println("Tempo: " +spotify.selectedPlaylistTracks["track"+i]["tempo"]);
                // System.println("danceability: " +spotify.selectedPlaylistTracks["track"+i]["danceability"]);
                // System.println("energy: " +spotify.selectedPlaylistTracks["track"+i]["energy"]);
                // System.println("acousticness: " +spotify.selectedPlaylistTracks["track"+i]["acousticness"]);
                // System.println("instrumentalness: " +spotify.selectedPlaylistTracks["track"+i]["instrumentalness"]);
                // System.println("liveness: " +spotify.selectedPlaylistTracks["track"+i]["liveness"]);


                for (var state=0; state < songStates.size(); state++) {
                    if (inRange(spotify.selectedPlaylistTracks["track"+i]["tempo"], songStates[statelist[state]]["bpmRange"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["danceability"], songStates[statelist[state]]["dance"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["energy"], songStates[statelist[state]]["energy"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["acousticness"], songStates[statelist[state]]["acoustic"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["instrumentalness"], songStates[statelist[state]]["instrumental"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["liveness"], songStates[statelist[state]]["liveness"]) &&
                        inRange(spotify.selectedPlaylistTracks["track"+i]["speechiness"], songStates[statelist[state]]["speech"])
                        ) {
                        // categorise the song to its state
                        songchosen = true;
                        System.println("State chosen: " + statelist[state]);
                        songMatch[statelist[state]].add(spotify.selectedPlaylistTracks["track"+i]["uri"]);

                        break; // Exit the loop once a state is matched
                    }
                    

                }
                if (songchosen == false) {
                    songMatch["UNIDENTIFIED"].add(spotify.selectedPlaylistTracks["track"+i]["uri"]);
                }
            }
            // System.println(songMatch.toString());
            return true;
        }
        else if (songMatch.size() > 0){
            return true;
        }
        else {
            return false;
        }

    }
    //Determines the best song to queue based on the run state
    function rankSong() {
      //Intensity of song state follows:
      // RACE
      // TEMPO
      // FALLOFF
      // WARMUP
      // RECOVER
      // COOLDOWN
      //Depending on running state will change the order of the songsstates
        var stateorder;
        var queue;
        
        //need to establish prev runmodes to check the trend since we only queue one song
        switch (true)
            {
                case (runmode == RSTATE_COOLDOWN):
                    stateorder = ["COOLDOWN","RECOVER","WARMUP","FALLOFF","TEMPO","RACE"];
                    break;
                case (runmode == RSTATE_WARMUP):
                    stateorder = ["WARMUP","FALLOFF","RECOVER","TEMPO","COOLOFF","RACE"];
                    break;
                case (runmode == RSTATE_RECOVER):
                    stateorder = ["RECOVER","WARMUP","COOLDOWN","FALLOFF","TEMPO","RACE"];
                    break;
                case (runmode == RSTATE_TEMPO):
                    stateorder = ["TEMPO","RACE","FALLOFF","WARMUP","RECOVER","COOLDOWN"];
                    break;
                case (runmode == RSTATE_RACE):
                    stateorder = ["RACE","TEMPO","FALLOFF","WARMUP","RECOVER","COOLDOWN"];
                    break;
                case (runmode == RSTATE_FALLOFF):
                    stateorder = ["FALLOFF","TEMPO","RACE","WARMUP","RECOVER","COOLDOWN"];
                    break;
                default:
                    stateorder = ["WARMUP","FALLOFF","COOLDOWN","RECOVER","TEMPO","RACE"];
                    break;
            }
            for (var i=0; i < stateorder.size(); i++) {
                
                if (songMatch[stateorder[i]].size() > 0){
                    queue = songMatch[stateorder[i]][0];
                    System.println(songMatch[stateorder[i]][0]);
                    // System.println(songMatch[stateorder[i]].size());

                    songMatch[stateorder[i]].remove(songMatch[stateorder[i]][0]);

                    //NOTE: getCurrentQueue() returns too much data so it breaks, and on top of thats theres issues with it on spotify's dev end so not using for now
                     //queue song with spotify api calls
                    // System.println(songMatch[stateorder[i]].size());
                    // spotify.getCurrentQueue();           

                    //wait for current queue to return
                    if (spotify.queueList.size() == 0){
                        spotify.addToQueue(queue);
                        spotify.queueList.add(queue);
                    
                    }
                    break;
                }
            }

           
    }

}