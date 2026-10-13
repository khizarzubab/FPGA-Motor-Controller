# FPGA DC Motor Controller (PWM Speed + Direction Control)

Speed and direction control of a **JGB37-520 12 V DC gear motor** using a **Digilent Nexys A7-100T** FPGA and an **L298N** motor driver module. Written in Verilog for Xilinx Vivado.

- **Speed** is set by an 8-bit PWM signal (about 10 kHz) driven by the on-board switches.
- **Direction, enable and brake** are digital signals driven by switches.
- A **direction-change guard** stops the motor for about 84 ms before reversing, to protect the L298N from current spikes.

> Open-loop control: there is no speed feedback. The motor's encoder is not used in this version.

---

## Hardware required

| Item | Notes |
|---|---|
| Digilent Nexys A7-100T | FPGA part `xc7a100tcsg324-1`, USB cable for programming |
| L298N motor driver module | The common red/blue breakout board |
| JGB37-520 DC gear motor, 12 V | Encoder wires, if present, are not needed |
| 12 V DC power supply | Must handle the motor's stall current (use 2 A or more if possible) |
| Jumper wires | Female-to-female or as needed for the Pmod header |

## Software required

- **Xilinx Vivado** (ML Edition / WebPACK is free and supports the Artix-7 100T). Any recent version should work (2019.1 or newer is fine).

---

## Repository structure

```
.
├── README.md
├── .gitignore
├── src/
│   ├── top.v             # top module: connects switches, PWM, driver and LEDs
│   ├── pwm_gen.v         # 8-bit PWM generator (~10 kHz)
│   └── motor_ctrl.v      # L298N control logic + direction guard
├── constraints/
│   └── nexys_a7_motor.xdc   # pin assignments for the Nexys A7
├── sim/
│   └── tb_top.v          # simulation testbench
└── scripts/
    └── create_project.tcl   # rebuilds the Vivado project in one command
```

---

## How it works

```
 SW[7:0] ──► pwm_gen ──► pwm ──┐
                               ├──► motor_ctrl ──► ENA, IN1, IN2 ──► L298N ──► Motor
 SW[15:13] (enable/dir/brake) ─┘
```

### Controls

| Switch | Function |
|---|---|
| `SW[7:0]` | Speed, as PWM duty from 0 (stopped) to 255 (full) |
| `SW[15]` | Enable. 1 = run, 0 = coast |
| `SW[14]` | Direction. 0 = forward, 1 = reverse |
| `SW[13]` | Brake. 1 = brake the motor |
| `BTNC` (centre button) | Reset |

### LEDs

| LED | Shows |
|---|---|
| `LED[7:0]` | Current speed switch setting |
| `LED[13]` | ENA (PWM, it will look dimmer at lower duty) |
| `LED[14]` | IN1 |
| `LED[15]` | IN2 |

### L298N behaviour

| ENA | IN1 | IN2 | Motor |
|---|---|---|---|
| PWM | 1 | 0 | Forward at PWM speed |
| PWM | 0 | 1 | Reverse at PWM speed |
| 0 | x | x | Coast |
| 1 | 1 | 1 | Brake |

### PWM frequency

`f_PWM = 100 MHz / (PRESCALE x 256)`. With `PRESCALE = 39`, that is about 10 kHz. You can change `PRESCALE` in `top.v`.

---

## Wiring

| Nexys A7 | Pin | L298N |
|---|---|---|
| Pmod **JA1** | C17 | **ENA** |
| Pmod **JA2** | D18 | **IN1** |
| Pmod **JA3** | E18 | **IN2** |
| Pmod **GND** | (JA5 or JA11) | **GND** |

Power and motor:

| From | To |
|---|---|
| 12 V supply (+) | L298N **12V** terminal |
| 12 V supply (-) | L298N **GND** terminal |
| Motor wire 1 | L298N **OUT1** |
| Motor wire 2 | L298N **OUT2** |

Important notes:

1. **Remove the ENA jumper** on the L298N. If it stays on, ENA is tied high and PWM has no effect.
2. **All grounds must be common**: FPGA GND, L298N GND and the supply negative.
3. **Do not power the FPGA from the L298N 5V pin.** The Nexys A7 is powered by its USB cable.
4. Leave the L298N **5V-enable jumper** on when the supply is 12 V.
5. If the motor spins the wrong way, swap the motor wires on OUT1/OUT2, or flip `SW[14]`.
6. Leave the motor's encoder wires unconnected.

---

## Setup

### Option A: automatic (recommended)

1. Clone the repository:
   ```
   git clone <your-repo-url>
   cd <repo-folder>
   ```
2. Open **Vivado**. In the **Tcl Console** (bottom of the window), run:
   ```
   cd <full path to the repo folder>
   source scripts/create_project.tcl
   ```
   This creates the project in a `build/` folder, adds all sources, the constraints file and the testbench, and sets the top modules.

   Or from a terminal: `vivado -mode batch -source scripts/create_project.tcl`, then open `build/motor_fpga.xpr`.

### Option B: manual

1. Vivado > **Create Project** > RTL Project. Choose part **xc7a100tcsg324-1**.
2. Add the three files in `src/` as **design sources**.
3. Add `constraints/nexys_a7_motor.xdc` as the **constraints** file.
4. Add `sim/tb_top.v` as a **simulation source**.
5. Check that `top` is the top module of the design sources and `tb_top` is the top of the simulation sources.

---

## Simulate (no hardware needed)

1. In Vivado, click **Run Simulation > Run Behavioral Simulation**.
2. If the simulation stops early, type `run 300 ms` in the Tcl console.
3. Add `ena`, `in1` and `in2` to the waveform window. You should see:
   - ENA pulses getting wider as the duty goes 25% > 50% > about 100%
   - After the direction switch flips, ENA, IN1 and IN2 all go low for about 84 ms, then IN1 and IN2 swap
   - During brake, ENA, IN1 and IN2 all go high

---

## Program the FPGA

1. Connect the Nexys A7 via USB and switch it on.
2. Click **Run Synthesis > Run Implementation > Generate Bitstream**.
3. Click **Open Hardware Manager > Open Target > Auto Connect > Program Device**.

## Test procedure

1. **Motor disconnected first.** Set `SW[15]` up (enable) and `SW[7:0]` to a mid value. LED 13 should glow, and LED 14 should be on and LED 15 off (forward). Flip `SW[14]` and the two swap after a short pause.
2. Power off, connect the motor and the 12 V supply.
3. Start with `SW[15]` up and only `SW[7]` up (about 50% speed). Then raise the speed gradually.

---

## Troubleshooting

| Problem | Likely cause |
|---|---|
| Motor runs at full speed and ignores the speed switches | The ENA jumper is still on |
| Motor does nothing | Check the common ground, the 12 V supply, and that `SW[15]` is up |
| Motor whines or is weak at low duty | Normal at low PWM. The motor has a start-up threshold, so use a higher duty |
| L298N gets very hot | Normal under heavy load. Add a heatsink or fan, and do not stall the motor |
| Supply voltage drops or board resets | The supply cannot deliver the current. Use a stronger supply |
| Motor only gets about 10 V | Normal. The L298N drops about 2 V |
| Vivado warns about unconstrained ports | Make sure the `.xdc` file is added under Constraints |

## Safety

- The L298N is rated for 2 A per channel. A stalled 520 motor can draw more than that.
- Do not hold the motor shaft or lock the output.
- Always check wiring before applying 12 V.


