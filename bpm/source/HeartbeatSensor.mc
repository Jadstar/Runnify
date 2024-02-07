import Toybox.Sensor;

/*
    Collects and stores heart rate
*/
class HeartRateHandler {
    public var currentBPM;

    function initialize() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );
        Sensor.enableSensorEvents( method( :onSensor ) );
    }

    /*
        Called every time a new heart rate is availabled
        TODO: allow this function to send song queue requests
    */
    function onSensor(sensorInfo as Sensor.Info) as Void {
        currentBPM = sensorInfo.heartRate;
        System.println(currentBPM);

        WatchUi.requestUpdate();
    }
}