{
    --------------------------------------------
    Filename: signal.adc.ad799x.spin
    Author: Jesse Burt
    Description: Driver for Analog Devices AD799x-series ADCs
    Copyright (c) 2023
    Started Jul 2, 2023
    Updated Jul 14, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    DEF_ADDR        = 0
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    { default I/O settings; these can be overridden in the parent object }
    SCL             = DEF_SCL
    SDA             = DEF_SDA
    I2C_FREQ        = DEF_HZ
    I2C_ADDR        = DEF_ADDR

VAR

    long _scale, _adc_ref

    word _interrupt
    word _last_channel
    word _last_meas

    byte _opmode

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef AD799X_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.ad799x.spin"       ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core#T_POR)             ' wait for device startup
            if ( i2c.present(SLAVE_WR) )        ' test device bus presence
                set_ref_voltage(5_000000)       ' default to 5V reference
                set_model(7993)                 ' default to AD7993 (10-bit) model
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop{}
' Stop the driver
    i2c.stop{}
    i2c.deinit{}

PUB defaults{}
' Set factory defaults
    adc_chan_enabled(%0000_0000)                ' no channels enabled

PUB preset_prop_boe{}
' Preset settings:
'   Propeller Board of Education
'   AD7993-1
'   5V supply and reference
    set_ref_voltage(5_000000)
    set_model(7993)

PUB adc_chan_enabled(mask): curr_mask
' Enable one or more ADC channels
'   Valid values:
'       AD7993, AD7994: %0000..%1111 (ch4..ch1)
'       AD7997, AD7998: %0000_0000..%1111_1111 (ch8..ch1)
'   Any other value polls the chip and returns the current setting
    if ( _opmode )                              ' temporarily stop measurements if they're running
        i2c.stop()

    curr_mask := 0
    { handle model-specific differences below; reg size, masks, etc }
    readreg(core#CONFIG, core#CONFIG_REGSZ, @curr_mask)
    case mask
        0..core#CH_BITS:
            mask := ((curr_mask & core#CH_MASK) | (mask << core#CH) )
            writereg(core#CONFIG, core#CONFIG_REGSZ, @mask)
        other:
            return ((curr_mask >> core#CH) & core#CH_BITS)

    opmode(_opmode)

PUB adc_data{}: w
' ADC data word
'   Returns: 10 or 12-bit ADC word (dependent on model set with set_model() )
    return _last_meas := i2c.rdword_msbf(i2c.ACK)

pub adc_data_rate(rate): curr_rate | tmp
' Set ADC data rate (interval between measurements as a function of (Tconvert * rate) )
'   Valid values: 32, 64, 128, 256, 512, 1024, 2048
    if ( _opmode )
        i2c.stop()

    curr_rate := 0
    readreg(core#CYC_TMR, 1, @curr_rate)
    case rate
        32..2048:
            rate := ( ( >|(rate >> 4)-1 ) )
            rate := ((curr_rate & core#CYC_MASK) | rate)
            writereg(core#CYC_TMR, 1, @rate)
        other:
            curr_rate := (1 << (curr_rate & core#CYC_BITS) << 4 )

    opmode(_opmode)

pub adc2volts(adc_word): volts
' Scale ADC word to microvolts
    return (adc_word >> 2) * _scale

con #0, NO_INT, BUSY_OUT, INT_OUT               ' valid modes for alert_busy_pin_mode()
pub alert_busy_pin_mode(mode): curr_mode
' Set mode/function of the ALERT/BUSY pin
'   Valid values:
'       NO_INT (0): no interrupt signal
'       BUSY_OUT (1): pin functions as a busy output/data ready signal
'       INT_OUT (2): pin functions as an interrupt output
    if ( _opmode )
        i2c.stop()

    curr_mode := 0
    readreg(core#CONFIG, core#CONFIG_REGSZ, @curr_mode)
    case mode
        NO_INT, BUSY_OUT, INT_OUT:
            mode := ( (curr_mode & core#ALT_BSY_MASK) | (mode << core#BUSY_ALERT) )
            writereg(core#CONFIG, core#CONFIG_REGSZ, @mode)
        other:
            curr_mode := ((curr_mode >> core#BUSY_ALERT) & core#ALT_BSY_BITS)

    opmode(_opmode)

pub interrupt(): i
' Flag indicating threshold interrupt asserted
    return ( _last_meas >> core#ALRT_FLAG) & 1

pub last_channel_read(): ch
' Get the channel number last read
    return (( _last_meas >> core#CH_ID) & core#CH_ID_BITS)

con #0, STOPPED, CONT
pub opmode(mode): curr_mode
' Set operating mode
'   Valid values:
'       CONT (1), or non-zero: continuous measurement at interval specified by adc_data_rate()
'       STOPPED (0): stopped
'   NOTE: In continuous measurement mode, the I2C bus __is left active__ (addressed to AD799x)
'       Ensure no other bus activity can occur while this is true, or set opmode(0) if other
'       bus activity is required.
    if ( mode )
        i2c.start{}
        i2c.write(SLAVE_WR)
        i2c.write(core#CONV)
        i2c.stop{}
        i2c.start{}
        i2c.write(SLAVE_RD)
    else
        i2c.stop{}
    _opmode := mode

PUB set_model(model)
' Set ADC model
'   Valid values:
'       7993, 7994, 7997, 7998
    case model
        7993, 7997:
            _scale := _adc_ref / 1024               ' 10-bit
        7994, 7998:
            _scale := _adc_ref / 4096               ' 12-bit

PUB set_ref_voltage(v): curr_v
' Set ADC reference/supply voltage (Vdd), in microvolts
'   Valid values: 1_200_000..5_500_000 (1.2 .. 5.5V)
    _adc_ref := (1_200000 #> v <# 5_500000)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        $01..$0F:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.stop{}

            i2c.start{}
            i2c.wr_byte(SLAVE_RD)
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $01..$0F:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return

#include "signal.adc.common.spinh"

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

