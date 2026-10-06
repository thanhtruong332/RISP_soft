# Reproducibility metadata

| Item | Value |
| --- | --- |
| RTL origin | Custom RTL snapshot supplied by the project owner |
| Repository | https://github.com/thanhtruong332/RISP_soft |
| Release | `v1.0.0` (use `git rev-parse v1.0.0` for the immutable commit) |
| License | No open-source license is declared; see `LICENSE_STATUS.md` |
| ISA | RV32I, ISA specification version 2.1 |
| Pipeline | Non-pipelined, single-instruction datapath |
| Branch resolution | Instruction datapath computes `next_pc` directly |
| Forwarding / hazards | Not applicable; there are no overlapping pipeline stages |
| Multiplier / bit manipulation | None |
| Register file | 32 x 32-bit; synchronous write and asynchronous read |
| Experiment memory model | Unified 64 KiB zero-wait-state simulation memory |
| Workload | Pure-software AES-128 ECB, CBC, CFB-128 and CTR; no AES accelerator |
| Payloads | 16 B, 256 B and 4 KiB |
| Compiler target | `-O2 -march=rv32i -mabi=ilp32` |
| Additional compiler flags | `-mcmodel=medlow -msmall-data-limit=0 -ffreestanding -fno-builtin -fno-pic -fno-pie -fno-stack-protector -ffunction-sections -fdata-sections` |
| Clock / simulator | 40 MHz; Vivado/XSim 2024.2 |

The twelve committed memory images correspond to four AES modes and three
payloads. The matching self-checking testbenches report cycle and instruction
counters and compare every ciphertext block with its expected value.
