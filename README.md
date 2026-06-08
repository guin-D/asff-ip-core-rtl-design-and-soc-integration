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
 - 
$$y_{ij}^l = \alpha_{ij}^l \cdot x_{ij}^{1 \rightarrow l} + \beta_{ij}^l \cdot x_{ij}^{2 \rightarrow l} + \gamma_{ij}^l \cdot x_{ij}^{3 \rightarrow l} $$
 
