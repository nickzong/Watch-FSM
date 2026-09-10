# Watch-FSM

A digital watch built as a finite state machine (FSM) in SystemVerilog — designed and simulated first, with implementation on an FPGA board and a custom PCB in progress.

## Overview

An 8-state FSM (`TIME`, `SET_HR`, `SET_MIN`, `STOPWATCH`, `ALARM_VIEW`, `ALARM_SET_HR`, `ALARM_SET_MIN`, `ALARM_RING`) drives a multi-mode watch supporting:

- Time display and time-setting
- Stopwatch
- Alarm (view, set, and ring — one-shot edge-detected trigger, silenced by any button press)

Three buttons (Mode / Set / Plus) are reused contextually across modes, plus an asynchronous alarm input. Simultaneous inputs are resolved deterministically with a priority-encoded scheme: **alarm > mode > set > plus (AMSP)**.

See [`state_diagrams_v1.pdf`](./state_diagrams_v1.pdf) for the full state diagram.

## Design

- A modular, parameterized RTL datapath — a generic mod-N wraparound counter — is reused across the time, stopwatch, and alarm fields rather than duplicating counter logic per field.
- Modules: `clock.sv`, `stopwatch.sv`, `time_keeper.sv`, `alarm_view.sv`, `mod_counter.sv`, `watch.sv` (top-level).

## Testing

Each module has a self-checking SystemVerilog testbench (`tb_*.sv`) run under [Icarus Verilog](http://iverilog.icarus.com/), exercising reset, wraparound, and edge-triggered event behavior.

```bash
make          # build and run all testbenches
```

(Developed in VS Code with the Icarus Verilog toolchain.)

## Status

- [x] FSM design and simulation (SystemVerilog / Icarus Verilog)
- [ ] FPGA board bring-up
- [ ] Custom low-power PCB

## Tools

SystemVerilog, Icarus Verilog, VS Code
