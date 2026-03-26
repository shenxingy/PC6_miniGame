# PC6_miniGame

An interactive space shooter mini-game that runs on an FPGA (Altera DE2 / DE2-115 board). The player controls a spaceship via a PS/2 keyboard and the game is rendered on a VGA display.

## Hardware Requirements

- Altera DE2 or DE2-115 FPGA development board
- PS/2 keyboard
- VGA monitor

## Project Structure

```
PS2_skeleton_restored-2/
├── skeleton.v              # Top-level module: wires together CPU, PS2, VGA, LCD
├── processor.v             # Soft processor: IMEM + DMEM + regfile + CPU
├── PS2_Interface.v         # PS/2 keyboard interface (move, fire, pause signals)
├── PS2_Controller.v        # Low-level PS/2 protocol controller
├── vga_controller.v        # VGA signal generation and game rendering
├── video_sync_generator.v  # VGA sync timing
├── lcd.sv                  # LCD display controller
├── img_data.v              # Sprite pixel data
├── img_index.v             # Sprite index lookup
├── Hexadecimal_To_Seven_Segment.v  # 7-segment display decoder
├── imem.v / dmem.v         # Instruction and data memory (Quartus syncram)
├── imem.mif / dmem.mif     # Memory initialization files
├── pll.v                   # PLL clock divider
├── assembly_code/          # MIPS-like assembly source for the game logic
│   └── space_ship_move.s   # Spaceship movement and game logic
└── skeleton.qpf / skeleton.qsf  # Quartus project files
```

## How It Works

- The soft processor reads PS/2 keyboard scan codes (left/right arrow keys, fire, pause) via hardware input wires connected to the register file.
- Game state (spaceship X position, game status) is maintained in the processor's register file and exported to the VGA controller.
- The VGA controller renders the spaceship sprite and game elements at 640x480 @ 60 Hz.
- Seven-segment displays show the spaceship's current X coordinate in hex for debugging.

## Building and Flashing

1. Open `PS2_skeleton_restored-2/skeleton.qpf` in Quartus Prime.
2. Run **Analysis & Synthesis**, then **Fitter**, then **Assembler** (or use **Start Compilation**).
3. Open the **Programmer**, select the generated `.sof` file from `output_files/`, and program the FPGA.

## Controls

| Key | Action |
|-----|--------|
| Left Arrow | Move spaceship left |
| Right Arrow | Move spaceship right |
| (fire key) | Fire |
| (pause key) | Pause game |
