import Toybox.Sensor;

/*
    Collects and stores heart rate
*/
class WatchSensorData {
    public var currentBPM;
    public var currCadence;
    public var currSpeed;

    function initialize() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );          // * For remote sensors, all sensors used should already be enabled 
        Sensor.enableSensorEvents( method( :onSensor ) );
    }

    /*
        Called every time a new heart rate is availabled
        TODO: allow this function to send song queue requests
    */
    function onSensor(sensorInfo as Sensor.Info) as Void {
        currentBPM = sensorInfo.heartRate;
        currCadence = sensorInfo.cadence;
        currSpeed = sensorInfo.speed;       // in m/s
        // System.println(currentBPM);

        WatchUi.requestUpdate();
    }
}