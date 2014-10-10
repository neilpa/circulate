## Circulate

Alternative iOS wrapper library for controlling the the Anova 2 via Bluetooth

**Protocol**

The device implements a Bluetooth LE GATT service with one charactistic

    Service UUID:        0xFFE0
    Characteristic UUID: 0xFFE1

This single characteristic acts as a command channel to the device. Clients write command data to the characteristic with responses delivered as value updates. Commands are ASCII strings composed of an action, optional arguments and termniated with carriage return

    '<action>[ <argument> ...]\r'

This is especially unintuitive when considering GATT characteristics are designed to represent one datum that can may be read and/or written.

In terms of CoreBluetooth this translates to writing the command string to the peripheral's `-writeValue:forCharacteristic:type:` method and later getting the response or return value on your delegate's `-didUpdateValueForCharacteristic:error:` method. Response values are also ASCII strings. Fore example, reading the current temperature will return a string like '123.4'.


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
Set the target temperature of the device. The degrees value should be a floating point number in the temperature units of the device. The return value is the set temperature.

    read cal
Returns the current temperature calibration factor of the device. For my device the original value is 0.0. Seems to be the +/- delta of the tempature. Not sure if this is dependant on temperature units.

    cal <factor>
Set the current temperature calibration factor of the device. Echoes the executed command.

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
Returns the current program that is set.

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
Change the mouse wheel color on the device. The RGB values are integers from 0-255. The return value is the echoed command if successful. One quirck though is that this happens across two characteristic update calls. The first contains only the initial 's' with the second containing the remainder of the command.

    set name <name>
Set the Bluetooth display name of the device.

    read date
Supposedly reads the date and time set on the device. Assuming the return value is of the form 'YY MM DD hh mm'. However, the clock on my device never seems to update and always returns '14 08 16 12 03'.

    set date YY MM DD hh mm
Set the current date and time on the device. Note that this is a 24 hour clock.

    set password <password>
Assuming the above is the syntax for the set password command but haven't tested it yet

    read data
Returns a lot of data across multiple updates. Appears to be a floating point temperature followed by a four part date/time value in the form of 'temp MM DD hh mm'.

    read data  19.5 08 1
    6 12 03 19.5 08
    16 12 03 21.2 08 16
    12 03 22.8 08 16 12
    03 24.5 0
    8 16 12 03
     26.2 08
     16 12 03 27.9 08 16
     12 03 29.5 08 16 12
     03 31
    .2 08 16 12 03 32.8
    08 16 12 03
     34.4 08 16 12 03 36
    .0 08 16 12 03 3
    7.6 08 16 12 03
    39.2 08 16 12 03 40.
    8 08 16 12 03
     42.3 08 16 12 03 43
    .8 08 16 1
    2 03 45.3 08 16 12 0
    3 46.8 08 16 12 03 4
    8.2 08 16 12 03
     49.7 08 16 12 03 51
    .1 08 16 12 03 52.6
    08 16 12 03 54.0 08
    16 12 03 55.4 08 16
    12 03
     56.8 08 16 12 03 58
    .2 08 16 12 03 59.5
    08 16
    12 03 60.8 08 16 12
    03 62.1 08 16 12 03
     63.4 08 16 12 03 64
    .6 08 16 12 03
     65.8 08 16 12 03 67
    .0 08 16 12 03 68.2
    08 16 12 03
     69.3 08 16 12 03 70
    .6 08 16 12 0
    3 71.5 08 16 12 03 7
    1.6 08 16 12 03
    71.9 08 16 12 03
     72.1 08 16 12 03 72
    .3 08 16 12 03 72.5
    08
     16 12 03 72.7 08 16
     12 03 72.8 08 16 12
     03
     72.9 08 16 12 03 73
    .1 08 16 12 03 73.2
    08 16 1
    2 03 73.3 08 16 12 0
    3 73.4 08 16 12 03
     73.5 08 16 1
    2 03 73.6 08 16 12 0
    3 73.7 08 16 12 03 7
    3.7 08 1
    6 12 03 73.3 08 16 1
    2 03
     72.9 08 16 12 03 72
    .6 08 16 1
    2 03 72.5 08 16 12 0
    3 72.4 08 16 12 03

