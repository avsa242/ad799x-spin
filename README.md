# ad799x-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Analog Devices AD799x-series ADCs.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* I2C connection at up to 400kHz (maximum is not enforced)
* Read ADC word or voltage in micro-volts
* Set active channel mask
* Set function of BUSY/ALERT pin
* Set ADC data rate (currently interval between measurements)


## Requirements

P1/SPIN1:
* spin-standard-library
* `signal.adc_common.spinh` (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* `signal.adc_common.spin2h` (provided by p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1	    | SPIN1    | FlexSpin (6.1.1)	| Bytecode     | OK                    |
| P1	    | SPIN1    | FlexSpin (6.1.1)       | Native/PASM  | OK                    |
| P2	    | SPIN2    | FlexSpin (6.1.1)       | NuCode       | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (6.1.1)       | Native/PASM2 | Not yet implemented   |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware compatibility

* Supports AD7993, AD7994, AD7997, AD7998
* Tested with AD7993-1 (Parallax Propeller Board of Education)


## Limitations

* Very early in development - may malfunction, or outright fail to build
* Channels other than first aren't fully implemented yet
* SCL/SDA on-chip filtering not yet implemented
* BUSY/ALERT active state not yet implemented
* Interrupts not yet implemented
* I2C high-speed mode not yet implemented

