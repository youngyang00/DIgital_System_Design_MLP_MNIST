# FPGA-Based MNIST Handwritten Digit Classification Accelerator Using MLP

## Project Overview
This project was undertaken as part of the **Digital System Design course** at Seoul National University of Science and Technology. The goal was to implement a Multi-Layer Perceptron (MLP) model provided by the IDSL research lab on the **FPGA Zynq-7000 z7-20 board**. The evaluation criteria included:

1. **Efficient resource utilization** to minimize hardware overhead.
2. **High performance** for fast image classification.
3. **Accuracy** close to the provided reference model implemented in C.

### MLP Model Structure
The implemented MLP model is structured as follows:
- **Input Layer**: 
  - **784 nodes** (28x28 pixel MNIST images flattened into a 1D array).
- **Hidden Layers**:
  - Layer 1: 128 nodes, **ReLU** activation function.
  - Layer 2: 64 nodes, **ReLU** activation function.
  - Layer 3: 64 nodes, **ReLU** activation function.
  - Layer 4: 32 nodes, **ReLU** activation function.
- **Output Layer**:
  - 10 nodes, corresponding to the 10 MNIST digit classes.

## Accelerator Design
The MLP accelerator consists of the following components:

### 1. BRAM (IMAGE_BRAM)
- **Size**: 784 x 8-bit MNIST images, with a total **WIDTH** of 8 bits and **DEPTH** of 8192.
- Used to store input data and weights efficiently for processing.

### 2. Layer1_Processing_Unit
- Designed to perform **[1x784] x [784x128] matrix multiplication**.
- Utilizes **128 DSPs** for parallel processing, handling 128 multiplications per cycle.
- Completes the computation of one row in **784 cycles**.
- Includes:
  - **PU (Processing Unit)**: For row-wise operations.
  - BRAM for parameter storage.
  - Local controller to manage signal interactions.
  - Output buffer to transfer results to the next layer.

### 3. Layer2_Processing_Unit
- Reuses **64 DSPs** to process the remaining four layers in sequence.
- Optimized to reduce DSP usage while maintaining performance.
- Implements a recursive structure similar to Layer1_Processing_Unit.

### 4. MLP_Controller
- Coordinates the operation of the processing units and memory.
- Outputs the final **10 classification results** through a dedicated buffer.

### Design Features
- **Parallelism**: Achieved by leveraging DSPs for simultaneous multiplications.
- **Pipeline Structure**: Ensures minimal latency by overlapping computations.

## Development Process
### Memory Structure Optimization
- **Issue**: Single-weight data retrieval caused significant bottlenecks in BRAM.
- **Solution**: Implemented a Python-based **padding technique** to package weights into data packets, enabling parallel retrieval.

### Algorithm Optimization
- Utilized **128 DSPs** for Layer 1 and **64 DSPs** for the remaining layers to balance performance and resource usage.
- Adopted a **recursive processing approach** for smaller layers to minimize hardware overhead.

### Simulation and Verification
- Developed a **Python reference code** for accurate validation of hardware results.
- Testbench waveforms and Python scripts were used to compare intermediate outputs across layers.

### Timing Challenges and Solutions
- **Initial Issue**: Timing constraints were violated due to delays in LUT-based quantization multiplication.
- **Solution**: Reduced clock speed from **125 MHz to 100 MHz**, ensuring all timing constraints were met without significant performance degradation.

### Final Validation
- Verified results by transmitting computed values from FPGA to PC via UART.
- Accuracy confirmed using MATLAB by comparing FPGA predictions with ground truth.

## Results
- **Accuracy**: Achieved 90% accuracy (correctly predicted 9 out of 10 test images).
- **Resource Efficiency**: Optimized usage of DSPs, BRAM, and other FPGA resources.
- **Performance**: Delivered real-time inference capability within resource constraints.

## Team Contributions
- **Task Division**:
  - Team of four members with defined roles:
    1. Reference code development and verification.
    2. Processing unit design.
    3. Memory and buffer architecture design.
    4. Controller optimization and FSM design.
- Collaboration ensured successful project completion and seamless integration of components.

---
This project demonstrates efficient FPGA-based hardware acceleration for MLP, showcasing its potential for low-power, high-performance AI applications.
