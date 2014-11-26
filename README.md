## Circulate

Alternative iOS wrapper library for controlling the the Anova 2 via Bluetooth

**Protocol**

The device implements a Bluetooth LE GATT service with one charactistic

    Service UUID:        0xFFE0
    Characteristic UUID: 0xFFE1

This single characteristic acts as a command channel to the device. Clients write command data to the characteristic with responses delivered as value updates. Commands are ASCII strings composed of an action, optional arguments and termniated with carriage return

    '<action>[ <argument> ...]\r'

If the command is longer than 20 characters, it should be sent in chunks, each 20 characters long (21, counting '\r' in the end of each). In terms of CoreBluetooth this string value encodes to an NSData object and is written to the peripheral's `-writeValue:forCharacteristic:type:` method. Response values are similar ASCII strings and always terminated with a carriage return

    '<response>[...]\r'

The response value is sent to the peripheral delegate's `-didUpdateValueForCharacteristic:error:` method. This method may be called multiple times if the return value is too large for a single payload. If that's the case keep appending the returned data until you see a response terminated with a carriage return.

This is especially unintuitive when considering GATT characteristics are designed to represent one datum that can may be read and/or written.

#### Temperature commands

    read unit
Returns the current temperature unit as 'c' or 'f' for Celcius and Farenheit respectively.

    set unit <c|f>
Set the current temperature unit to Celcius or Farenheit. Returns either 'c' or 'f' depending on the unit being set.

    read temp
Returns the current temperature as a floating point number. This value will be in the temperature units set on the device.

    read set temp
Returns the target temperature as a floating point number. This value will be in the temperature units set on the device.

    set temp <degrees>
Set the target temperature of the device. The degrees value should be a floating point number in the temperature units of the device. Acceptable temperature range is 5.0 to 99.9 Celsius or 41.0 to 211.8 Farengheit. The return value is the set temperature.

    read cal
Returns the current temperature calibration factor of the device. The original value is 0.0. It is temperature displayed by device minus temperature measured by device in Celsius. 

    cal <factor>
Set the current temperature calibration factor of the device. Accepted values range is -9.9 to 9.9. (This is Celsius, no matter what is current unit.) Echoes the executed command.

#### Device operation commands

    status
Returns the current operational status of the device. The potential return values are 'running', 'stopped', 'low water', 'heater error', or 'power interrupt error'. Haven't validated that the last two are correct yet

    start
Start the device. Seems to always return 'start' even if the device doesn't start.

    stop
Stop the device. Seems to always return 'stop'.

#### Timer commands

    read timer
Read the number of minutes on the timer and whether or not it's running. The return value is of the form '<minutes> running|stopped'

    set timer <minutes>
Set the number of minutes on the timer. Returns the value that is set.

    start time
Starts the timer. Return value is the echoed command. Note that starting the device also automatically starts the timer

    stop time
Stops the timer. Return value is the echoed command. Note that stopping the device also automatically stops the timer.

#### Program commands

    program status
Returns the current program that is set. The return value is of the form 'program' followed by the individual time-minutes pairs.

    set program t1 m1 [t2 m2 [...] ]
Set a multistep programe on the device. Seems like these need to be set in temperature and number of minutes pairs. Appears to be a max of 6 steps and any after that are ignored.

    start program
Start the current program. Returns the echoed command. Needs more testing

    stop program
Stop the current program. Returns the echoed command. Needs more testing

    resume program
Resume the current program. Returns the echoed command. Needs more testing

#### System commands

    set led <red> <gree> <blue>
Change the mouse wheel color on the device. The RGB values are integers from 0-255. The return value is the echoed command if successful.

    set name <name>
Set the Bluetooth display name of the device. This will cause the device to disconnect.

    read date
Supposedly reads the date and time set on the device. The return value is of the form 'YY MM DD hh mm' with two digit values of year, month, day of month, hour and minute respectively. I also noticed that the clock didn't seem to run on the device until after calling 'set date' for the first time. Before that it was always returning the origal time value (same for the 'read data' entries).

    set date YY MM DD hh mm
Set the current date and time on the device. Note that this is a 24 hour clock.

    set password <password>
Assuming the above is the syntax for the set password command but haven't tested it yet

    read data
Returns all the available temperature history data. This returns a list of entries, each entry containing a temperature date and time. The form is each entry is 'temp MM DD hh mm'. The temperature will be in the current units set on the device.

