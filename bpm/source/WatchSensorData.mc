import Toybox.Sensor;
import Toybox.UserProfile;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Activity;
import Toybox.Timer;
/*
    Collects and stores heart rate
*/
class WatchSensorData {

    public var setAvgCadence = 175; // To be used so the user can choose the cadence threshold

    public var currentBPM;
    public var currCadence;
    public var currSpeed;
    public var zone;

    var activtyTimer = new Timer.Timer();
    //If theres an activity happening, these variables exist
    public var ActivityAVGCadence;
    public var ActivityAVGHeartRate;
    public var ActivityAVGSpeed;
    public var ActivityElapsedTime;

    var profile = UserProfile.getProfile();

    function initialize() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );          // * For remote sensors, all sensors used should already be enabled 
        Sensor.enableSensorEvents( method( :getData ) );
        
        activtyTimer.start(method(:ActivityTimerCallback),1000,true);
    }

    function ActivityTimerCallback() {
        //Checks to see if an activty is happening, if it is, timer stops
        var activity = Activity.getActivityInfo();
        if (activity != null){
            if (activity.timerState == 3)    //Timer is on
            {
                ActivityAVGCadence = activity.averageCadence;
                ActivityAVGHeartRate = activity.averageHeartRate;
                ActivityAVGSpeed = activity.averageSpeed;
                ActivityElapsedTime = activity.elapsedTime;
            }
            System.println("Activity Average Cadence: "  +ActivityAVGCadence);
            System.println("Activity Average Heart Rate: "  +ActivityAVGHeartRate);
            System.println("Activity Average Speed: "  +ActivityAVGSpeed);
            System.println("Activity Average Elapsed Time: "  +ActivityElapsedTime);

        }
    }
    
    function getData(sensorInfo as Sensor.Info) as Void{
        getHeartRate(sensorInfo);
        getSpeed(sensorInfo);
        getCadence(sensorInfo);
        getZone();
    }
    

    function getSpeed(sensorInfo as Sensor.Info) {
        if (sensorInfo.speed != null)
        {
            currSpeed = sensorInfo.speed;       // in m/s
            System.println("Current Speed: "  +currSpeed);
        }
    }
    function getCadence(sensorInfo as Sensor.Info)  {
        if (sensorInfo.cadence != null)
        {
            currCadence = sensorInfo.cadence;
            System.println("Current Cadence: "  +currCadence);
        }
    }
    function getHeartRate(sensorInfo as Sensor.Info) {
        if (sensorInfo.heartRate != null)
        { 
            currentBPM = sensorInfo.heartRate;
            System.println("Current HR: "  +currentBPM);

        }
    }
    
    function getZone() {
        
        getHRpercent(Gregorian.Info,Sensor.Info);
        System.println("Current Zone: "  +zone);
        

    }
    function getHRpercent(calendar as Gregorian.Info, sensorinfo as Sensor.Info){
        var max = getMaxHeartRate(calendar);
        if (currentBPM != null)
        {
            var percent = currentBPM.toFloat() / max.toFloat()*100;
        
            System.println("percent: " + percent);
            if (percent != null)
            {
                switch (true)
                {
                    case (percent < 60):
                        zone = 1;
                        break;
                    case (percent < 70):
                        zone = 2;
                        break;
                    case (percent < 80):
                        zone = 3;
                        break;
                    case (percent < 90):
                        zone = 4;
                        break;
                    case (percent <= 100):
                        zone = 5;
                        break;
                    default:
                        zone = "Out of Range";  // Handle cases where the percent is out of the expected range
                        break;
                }
        }
        }
    }

    // Currently hardcoded to 2024, can be done by getting location and then mapping the time related to that location
    // seems like a bit of work just for year so might be a better way
    function getMaxHeartRate(calendar as Gregorian.Info) {
        // var curryear = calendar.year;
        var curryear = 2024;
        var age = curryear - profile.birthYear;
        var maxHR = 220- age;
        System.println("MAX HR: "  +maxHR);
        
        return maxHR;
    }
}