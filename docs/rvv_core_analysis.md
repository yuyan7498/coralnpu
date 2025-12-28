# RVV Core Architecture Analysis

This document provides a detailed technical analysis of the **RISC-V Vector (RVV) Core** implemented in the `coralnpu` project. It complements the [Scalar Core Analysis](scalar_core_analysis.md).

## 1. High-Level Overview

The `RvvCore` is designed as a **decoupled co-processor** that works in tandem with the Scalar Core. It follows a **Frontend-Backend** architecture to handle the complexity of vector instructions (variable length, configuration dependencies) and to allow for high-performance superscalar execution.

### Key Features
*   **Decoupled Architecture**: Scalar Core handles fetching and initial decoding; `RvvCore` handles vector-specific logic.
*   **Superscalar Execution**: Capable of issuing multiple micro-ops (uops) per cycle.
*   **Out-of-Order Execution**: Uses Reservation Stations (RS) and a Reorder Buffer (ROB) to execute vector operations out of order while committing them in order.
*   **Vector Register File (VRF)**: A dedicated high-bandwidth register file for vector data.

---

## 2. Top-Level Hierarchy

The core is implemented mainly in **SystemVerilog** (under `hdl/verilog/rvv`), wrapped by Chisel for integration.

*   **`RvvCore`**: The top-level wrapper binding Frontend and Backend.
    *   **`RvvFrontEnd`**: Handles the interface with the Scalar Core, instruction queuing, and architectural configuration state.
    *   **`rvv_backend`**: The execution engine containing Dispatch, Issue, Execution Units, and Retirement logic.

---

## 3. RvvFrontEnd (Frontend)

The Frontend acts as the "receptionist" for the Vector Core. Its primary responsibilities are:

### Instruction Queuing
*   Receives pre-decoded vector instructions from the Scalar Core.
*   Uses an **Instruction Queue** to buffer instructions, smoothing out differences in execution speed between scalar and vector cores.
*   Aligns incoming instruction packets.

### Configuration Management (`vtype`/`vl`)
*   Fully manages the key vector status registers entirely within the Vector Core:
    *   **`vsetvli` handling**: Intercepts `vsetvli` instructions to update `vl` (Vector Length), `sew` (Element Width), and `lmul` (Register Grouping).
    *   **State Tracking**: Maintains the *Architectural State* (`inst_config_state`) for each instruction. This allows the backend to know exactly what configuration (e.g., SEW=32) applies to a specific math operation, even if a newer `vsetvli` has already changed the global state.

### Command Assembly
*   Bundles the **Instruction** + **Operands** (from Scalar RegFile) + **Configuration** into a `RVVCmd`.
*   Sends these commands to the Backend.

---

## 4. rvv_backend (Backend)

The Backend is the "factory floor" where the actual work happens. It uses a sophisticated **out-of-order** pipeline.

### 4.1. Decode, Queue & Dispatch
1.  **Command Queue**: Buffers commands from the Frontend.
2.  **Decode Unit**: Translates `RVVCmd` into internal Micro-Ops (**uops**). A single complex vector instruction (like a satisfyingly long load) might be broken down into multiple smaller uops.
3.  **Uop Queue**: Buffers decoded micro-ops.
4.  **Dispatch Unit**:
    *   Allocates entries in the **ROB** (Reorder Buffer).
    *   Allocates entries in **Reservation Stations (RS)**.
    *   Reads available operands from the **VRF**.
    *   Dispatches uops to the appropriate functional unit queues.

### 4.2. Reservation Stations (RS)
Instead of a single issue queue, the core uses specialized Reservation Stations for different types of work:
*   **`ALU_RS`**: Integer arithmetic (ADD, SUB, logic).
*   **`MUL_RS`**: Integer Multiply/Accumulate.
*   **`DIV_RS`**: Integer Divide.
*   **`PMTRDT_RS`**: Permutation and Reduction operations.
*   **`LSU_RS`**: Load/Store operations.

### 4.3. Execution Units
*   **ALU / MUL / DIV**: Parallel execution units for math operations. They support SIMD execution based on the configured `vlen`.
*   **LSU (Load Store Unit)**:
    *   This is a critical interface. The `RvvCore` does **not** have its own direct connection to memory.
    *   It sends address requests back to the **Scalar Core's LSU**.
    *   The Scalar LSU fetches the data and streams it back to the Vector Core (`lsu2rvv`).
    *   The Vector LSU handles data alignment and writing to the VRF.

### 4.4. ROB & Retirement
*   **Reorder Buffer (ROB)**: Tracks the status of every in-flight instruction.
*   **In-Order Commit**: Ensures that even if instructions finished out of order, they update the architectural state (registers) in the original program order to maintain correctness and precise exceptions.
*   **Writeback**: Results are written back to the **VRF** (Vector Register File) or **XRF** (Scalar Register File) upon completion.

---

## 5. Interface with Scalar Core

The `RvvCore` is not standalone; it is a slave to the Scalar Core.

| Interface Signal | Direction | Purpose |
| :--- | :--- | :--- |
| `inst` | Scalar -> RVV | Dispatching vector instructions. |
| `rs` (Read Scalar) | Scalar -> RVV | Providing scalar operands (e.g., `rs1` for base address). |
| `rvv2lsu` | RVV -> Scalar | Requesting memory access (Address, Data). |
| `lsu2rvv` | Scalar -> RVV | Returning memory data. |
| `wb` (Writeback) | RVV -> Scalar | Writing results back to scalar registers (`vmv.x.s`). |
