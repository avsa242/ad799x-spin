{
    --------------------------------------------
    Filename: AD799X-Demo.spin
    Author: Jesse Burt
    Description: Demo of the AD799X ADC driver
        * First channel voltage display
    Copyright (c) 2023
    Started Jul 2, 2023
    Updated Jul 14, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200

' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    adc:    "signal.adc.ad799x" | SCL=28, SDA=29, I2C_FREQ=400_000

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(@"Serial terminal started")

    if ( adc.start{} )
        ser.strln(@"AD799x driver started")
    else
        ser.strln(@"AD799x driver failed to start - halting")
        repeat

    adc.set_model(7993)                         ' 7993, 7994, 7997, 7998
    adc.adc_data_rate(32)                       ' 32, 64, 128, 256, 512, 1024, 2048
    adc.adc_chan_enabled(%0001)                 ' %0000..%1111 (4ch models)
                                                ' %0000_0000..%1111_1111 (8ch models)

    adc.opmode(adc.CONT)

    repeat
        ser.pos_xy(0, 3)
        show_adc_data{}

#include "adcdemo.common.spinh"                 ' use code common to all ADC demos

DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

