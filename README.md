# 基于速度约束的高空机载SAR几何定标系统

## 项目概述

本项目实现了一种**基于速度约束的高空机载SAR几何定标方法**，通过地面控制点（GCP）对机载SAR的斜距系统误差和方位向位置偏差进行几何定标，并对比多种定标方法的精度。

## 使用方法

### 环境要求

- MATLAB R2020b 或更高版本
- 需要以下工具箱：
  - Mapping Toolbox（用于坐标转换）
  - Optimization Toolbox（用于LM算法求解）
  - Symbolic Math Toolbox（用于符号计算）

### 快速开始

1. **克隆或下载项目**
   ```bash
   git clone <repository-url>
   ```

2. **设置MATLAB工作目录**
   ```matlab
   cd('path/to/SARGeometricCali')
   ```

3. **添加函数路径**
   ```matlab
   addpath(genpath('function'));
   ```

4. **运行几何定标实验**
   ```matlab
   % 43km区域
   Paper_of_SARGeoCali_exp_for_FS43km_utf
   
   % 75km区域
   Paper_of_SARGeoCali_exp_for_FS75km_utf
   
   % 90km区域
   Paper_of_SARGeoCali_exp_for_ZQ90km_utf
   ```

5. **运行定位验证实验**
   ```matlab
   % 43km区域定位验证
   AirSARLocRDH_exp_for_FS43km_utf
   
   % 75km区域定位验证
   AirSARLocRDH_exp_for_FS75km_utf
   
   % 90km区域定位验证
   AirSARLocRDH_exp_for_ZQ90km_utf
   ```
