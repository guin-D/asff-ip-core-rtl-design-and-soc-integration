# ASFF IP Core RTL Design and SoC Integration

## Overview
This repository contains the RTL design, verification, and System-on-Chip (SoC) integration of an Adaptively Spatial Feature Fusion (ASFF) IP Core.

In deep learning models (particularly object detection networks like YOLO), multi-scale feature fusion is critical for detecting objects of varying sizes. However, standard software implementations of ASFF are computationally expensive due to the complex resizing operations and the non-linear Softmax function required to calculate spatial fusion weights.

This project provides a fully hardware-accelerated, highly parallel ASFF module designed for FPGA and ASIC implementation. By optimizing the algorithmic dataflow and integrating the core into an SoC environment (e.g., Zynq-7000 series), this design significantly reduces inference latency while maintaining high precision for computer vision tasks.

---

## Dataflow
The ASFF module is proposed to learn how to filter out conflicting information in a data-driven manner, helping to improve the scale invariance of features with negligible additional computational overhead. The implementation process of ASFF consists of two main steps:

 - Feature resizing: To fuse features, data from different layers must first be brought to the same resolution and number of channels
 - Adaptive fusion: At each spatial coordinate on the feature map, the network will automatically learn spatial weights to optimize the combination of information from the layers. Let $x_{ij}^{n \rightarrow l}$ be the feature vector at position $(i, j)$ resized from layer $n$ to layer $l$, where $\alpha, \beta, \gamma$ are the spatial weights representing the contribution level of each respective feature layer. The output of the adaptive fusion process at layer $l$, denoted as $y_{ij}^l$, is calculated according to the formula:

$$y_{ij}^l = \alpha_{ij}^l \cdot x_{ij}^{1 \rightarrow l} + \beta_{ij}^l \cdot x_{ij}^{2 \rightarrow l} + \gamma_{ij}^l \cdot x_{ij}^{3 \rightarrow l} $$
 
Where the important spatial weights $\alpha, \beta, \gamma$ are determined via the Softmax function to ensure their sum equals 1 and each value falls within the range $[0, 1]$:

$$\alpha_{ij}^l = \frac{e^{\lambda_{\alpha_{ij}}^l}}{e^{\lambda_{\alpha_{ij}}^l} + e^{\lambda_{\beta_{ij}}^l} + e^{\lambda_{\gamma_{ij}}^l}} $$

The control parameters $\lambda$ are learned through $1 \times 1$ convolutional layers, allowing the network to automatically adjust the contribution level of each feature layer based on actual input data.

---

## Hardware Architecture

### IP Architecture

In order to achieve the goal of 3 feature layers capable of parallel computation, the block's design will include:

 - 3 blocks executing Convolution computation: CONV_0, CONV_1, CONV_2s
 - 3 blocks executing Softmax computation: SOFTMAX_0, SOFTMAX_1, SOFTMAX_2
 - 3 blocks executing Fusion computation: FUSION_0, FUSION_1, FUSION_2
 - 1 block executing Maxpooling operation: MAXPOOLING
 - 1 overall state machine: FSM
 - 2 state machines executing data read and write: LOADFSM, STOREFSM
 - 1 address generation unit: AGU (ADDRESS COUNTER)

The entire computation process of the ASFF block will be controlled by an overall Finite State Machine. This FSM consists of 13 states, with states S_1 to S_3 being the Feature Resizing step, and from state S_4 onwards being the Adaptive Fusion step:

### SoC Architecture

This SoC architecture is divided into two main sections: a Processing System (PS) and Programmable Logic (PL). The PS features an ARM Cortex-A9 processor that interfaces with an external SD card and a DDR Controller, which manages external DDR memory. Within the PL, there is my ASFF IP block and a DMA (Direct Memory Access) IP. The ARM processor configures the ASFF IP using an AXI Lite interface and controls the DMA IP via an AXI GP interface. High-speed, continuous data transfer between the ASFF IP and the DMA IP is facilitated by an AXI Stream connection. Additionally, the DMA IP accesses the external DDR memory directly through the DDR Controller utilizing a high-bandwidth AXI HP interface.

---

## Performance & FPGA Implementation

The design was fully verified via Behavioral Simulation and deployed on a SoC hardware architecture. Rapid debugging and preliminary verification were performed using Xilinx ILA and UART interfaces. For exact and comprehensive validation, the complete set of output results was extracted and verified via an SD card. Below are the post-implementation reports extracted from Xilinx Vivado.

### 1. Post-Implementation Timing Summary
The design successfully met all timing constraints at a target clock frequency of **90 MHz**.

| Setup (Max Delay) | Hold (Min Delay) |
| :--- | :--- |
| **WNS** (Worst Negative Slack): `+3.682 ns` | **WHS** (Worst Hold Slack): `+0.067 ns` |
| **TNS** (Total Negative Slack): `0.000 ns` | **THS** (Total Hold Slack): `0.000 ns` |
| **Timing Met:** Yes | **Timing Met:** Yes |

### 2. Resource Utilization

| Site Type | Used | Available | Utilization (%) |
| :--- | :--- | :--- | :--- |
| **LUT** | 14,574 | 53,200 | ~27.39% |
| **LUTRAM** | 23 | 17,400 | ~0.13% |
| **FF** | 24,312 | 106,400 | ~22.85% |
| **BRAM** | 30.5 | 140 | ~21.79% |
| **DSP** | 195 | 220 | ~88.64% |

## Supervisor: Nguyen Kiem Hung, Ph.D. - AICS Lab - VNU-UET.
