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

In order to achieve the goal of 3 feature layers capable of parallel computation, the block's design will include:

 - 3 blocks executing Convolution computation: CONV_0, CONV_1, CONV_2s
 - 3 blocks executing Softmax computation: SOFTMAX_0, SOFTMAX_1, SOFTMAX_2
 - 3 blocks executing Fusion computation: FUSION_0, FUSION_1, FUSION_2
 - 1 block executing Maxpooling operation: MAXPOOLING
 - 1 overall state machine: FSM
 - 2 state machines executing data read and write: LOADFSM, STOREFSM
 - 1 address generation unit: AGU (ADDRESS COUNTER)

The entire computation process of the ASFF block will be controlled by an overall Finite State Machine. This FSM consists of 13 states, with states S_1 to S_3 being the Feature Resizing step (described in (Figure 2.28)), and from state S_4 onwards being the Adaptive Fusion step (described in (Figure 2.29)):
