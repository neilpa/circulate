## Circulate

Alternative iOS wrapper library for controlling the the Anova 2 via Bluetooth

**Protocol**

The device implements a Bluetooth LE GATT service with one charactistic

    Service UUID:        0xFFE0
    Characteristic UUID: 0xFFE1

This single characteristic acts as a command channel to the device. Clients write command data to the characteristic with responses delivered as value updates. Commands are ASCII strings composed of an action, optional arguments and termniated with carriage return

    '<action>[ <argument> ...]\r'

This is especially unintuitive when considering GATT characteristics are designed to represent one datum that can may be read and/or written. Nevertheless, the following is the known list of commands.

    # Temperature (affected by unit setting for C/F on device)
    read temp
    read set temp
    set temp <degrees>

    # Operation
    status
    start
    stop

    # TODO check that this is minutes
    set timer <minutes>

TODO: Better document this

