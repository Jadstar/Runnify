import Toybox.Sensor;
import Toybox.UserProfile;
import Toybox.Time;
import Toybox.Lang;
/*
    Collects and stores heart rate
*/
class WatchSensorData {
    public var currentBPM;
    public var currCadence;
    public var currSpeed;
    
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

    }
    function getSpeed(sensorInfo as Sensor.Info) {
        currSpeed = sensorInfo.speed;       // in m/s
        return currSpeed;
    }
    function getCadence(sensorInfo as Sensor.Info)  {
        currCadence = sensorInfo.cadence;
        currSpeed = sensorInfo.speed;       // in m/s
        return currCadence;
    }
    function getHeartRate(sensorInfo as Sensor.Info) {
        currentBPM = sensorInfo.heartRate;
        return currentBPM;

    }
    function getMaxHeartRate(calendar as Gregorian.Info) {
        var curryear = calendar.year;
        var age = curryear - profile.birthYear;
        var maxHR = 220- age;
        return maxHR;
    }
}