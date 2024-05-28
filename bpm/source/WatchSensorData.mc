import Toybox.Sensor;
import Toybox.UserProfile;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Math;

/*
    Collects and stores heart rate
*/
class WatchSensorData {
    public var currentBPM;
    public var currCadence;
    public var currSpeed;
    public var zone;
    var profile = UserProfile.getProfile();

    function initialize() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );          // * For remote sensors, all sensors used should already be enabled 
        Sensor.enableSensorEvents( method( :getData ) );
    }

    /*
        Called every time a new heart rate is availabled
        TODO: allow this function to send song queue requests
    */
    function getData(sensorInfo as Sensor.Info) as Void{
        getHeartRate(sensorInfo);
        getSpeed(sensorInfo);
        getCadence(sensorInfo);
        getZone();
    }
    function getSpeed(sensorInfo as Sensor.Info) {
        currSpeed = sensorInfo.speed;       // in m/s
        System.println("Current Speed: "  +currSpeed);
        return currSpeed;
    }
    function getCadence(sensorInfo as Sensor.Info)  {
        currCadence = sensorInfo.cadence;
        System.println("Current Cadence: "  +currCadence);
        return currCadence;
    }
    function getHeartRate(sensorInfo as Sensor.Info) {
        currentBPM = sensorInfo.heartRate;
        System.println("Current HR: "  +currentBPM);

        return currentBPM;

    }
    function getZone() {
        getHRpercent(Gregorian.Info,Sensor.Info);
        System.println("Current Zone: "  +zone);

    }
    function getHRpercent(calendar as Gregorian.Info, sensorinfo as Sensor.Info){
        var max = getMaxHeartRate(calendar);
        var percent = currentBPM.toFloat() / max.toFloat()*100;
        System.println("percent: " + percent);
        switch (true) {
            case (percent < 60):
                zone = "Zone 1: Very Light";
                break;
            case (percent < 70):
                zone = "Zone 2: Light";
                break;
            case (percent < 80):
                zone = "Zone 3: Moderate";
                break;
            case (percent < 90):
                zone = "Zone 4: Hard";
                break;
            case (percent <= 100):
                zone = "Zone 5: Maximum";
                break;
            default:
                zone = "Out of Range";  // Handle cases where the percent is out of the expected range
                break;
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