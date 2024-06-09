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
    var spotify = new SpotifyApi();
    public var rundata;

    var runTimer = new Timer.Timer();

    function initialize(){
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
                System.println("RECOVER");
                stateText = "RECOVERY";

                runmode = RSTATE_RECOVER;
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
        //TODO: set up different sensor data, match to timestamp and tehn do correlation formala
        // Get the list of states (keys)
        var states = coefficients.keys();
        for (var i = 0; i < states.size(); i++) {
            var state = states[i];
            var entry = coefficients[state];

            var range = entry["range"];
            var lower = range[0];
            var upper = range[1];
            if (lower < value && value <= upper) {
                return entry["variance"];
            }
        }

        return "stable"; // Return "unknown" if the value doesn"t fit any range
    }

    
    //Determines the best song to queue based on the run state
    function rankSong(runstate as String) {


    }

}