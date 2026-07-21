# 一种面向高空无人机载SAR的径向速度约束分层几何标定框架

## 概述

搭载于高空无人机（HA-UAV）平台的合成孔径雷达（SAR）系统，其独特的成像几何构型会显著放大平台速度误差对定位精度的影响。传统标定方法在有效抑制此类速度引起的畸变方面面临挑战，尤其是由径向速度不准确导致的方位向定位误差。本文对高空无人机载SAR中的速度误差传播进行了系统分析，定量论证了径向速度误差是制约方位向精度的主要因素。严格的灵敏度分析揭示了速度矢量扰动与定位偏移之间的耦合机制，表明需要专门的补偿策略。针对这一挑战，本文提出了一种径向速度约束的分层几何标定框架（HGC-RVC）。通过引入径向速度约束模型，该方法有效解耦了高维优化问题，实现了对难以隔离的运动误差的精确估计与补偿。基于真实高空无人机载SAR数据的实验结果表明，所提框架有效提升了定位精度，与最先进技术相比，均方根误差（RMSE）最高降低67.10%。此外，在三个不同实验区域验证的一致性能证实了所提方法对复杂干扰的鲁棒性。

## 输入数据要求

为复现实验，用户需要为每个实验区域准备以下数据。每个区域的所有数据文件应放置在单一目录中。

### 目录结构（每个区域）

```
<区域数据文件夹>/
├── GCP/                          % 用于标定的控制点数据
│   ├── SARinfo.txt               % SAR系统参数
│   ├── GDinfo.txt                % INS/GPS导航记录
│   └── objectLocationInfo.csv    % 控制点参考坐标
├── CP/                           % 用于验证的检查点数据
│   ├── SARinfo.txt
│   ├── GDinfo.txt
│   └── objectLocationInfo.csv
```

### 文件1：`SARinfo.txt` — SAR系统参数

纯文本文件，包含**19个数值**，每行一个（无表头）。通过 `readmatrix()` 读取。

| 行号 | 参数 | 单位 |
|------|------|------|
| 1 | 斜距分辨率 | m |
| 2 | 多普勒中心频率 | Hz |
| 3 | 最近斜距（近距） | m |
| 4 | 雷达波长 | m |
| 5 | 图像行数（方位向维度） | 像素 |
| 6 | 图像列数（距离向维度） | 像素 |
| 7 | 场景平均高程 | m |
| 8 | INS记录数 | - |
| 9 | 子图像数 | - |
| 10 | 飞机起始经度 | 度 |
| 11 | 飞机起始纬度 | 度 |
| 12 | 飞机终止经度 | 度 |
| 13 | 飞机终止纬度 | 度 |
| 14 | 观测方向（0=左视，1=右视） | - |
| 15 | 距离向像素尺寸 | m |
| 16 | 最近地距 | m |
| 17 | 脉冲重复频率（PRF） | Hz |
| 18 | 视数 | - |
| 19 | 飞机航向角 | 度 |

### 文件2：`GDinfo.txt` — INS/GPS导航记录

空格分隔的文本文件，共**7列**。第一行为冗余表头记录（预处理时自动删除）。其余行为实际INS测量数据。

| 列号 | 参数 | 单位 |
|------|------|------|
| 1 | 记录索引 | - |
| 2 | 东向速度 (v_E) | m/s |
| 3 | 北向速度 (v_N) | m/s |
| 4 | 天向速度 (v_U) | m/s |
| 5 | 经度 | 度 |
| 6 | 纬度 | 度 |
| 7 | 高度（椭球高） | m |


### 文件3：`objectLocationInfo.csv` — 控制点/检查点参考坐标

逗号分隔的CSV文件，**每行对应一个控制点**。通过 `readmatrix()` 读取。

| 列号 | 参数 | 单位 |
|------|------|------|
| 1 | 点号 | - |
| 2 | 距离向像素索引（图像列号） | 像素 |
| 3 | 方位向像素索引（图像行号） | 像素 |
| 4 | 真实经度（实测） | 度 |
| 5 | 真实纬度（实测） | 度 |
| 6 | 参考经度（图像标注） | 度 |
| 7 | 参考纬度（图像标注） | 度 |

### 文件4：DEM — 数字高程模型

WGS84地理坐标的GeoTIFF文件（`.tif`）。本实验使用Copernicus GLO-30 DEM。DEM必须覆盖整个实验区域。

- 格式：带地理参考信息的GeoTIFF（兼容 `geotiffread` / `readgeoraster`）
- 坐标系：WGS84（EPSG:4326）
- 分辨率：30 m（Copernicus GLO-30）或更高

### 文件5：ERA5气象数据（用于对流层延迟校正）

包含由ERA5再分析数据导出的大气折射率廓线的CSV文件（`refractivity_data.csv`）。射线追踪对流层延迟校正模块（`AirSARRayTracingPlus`）需要此数据。

- 位置：`../ZhaoqingERA5/refractivity_data.csv`（相对于数据文件夹）
- 内容：多层高度的大气折射率

## 输出数据

### 定位验证结果

验证脚本生成以下文件：
- `locationResult.csv` — 逐点定位误差（总误差、距离向、方位向）
- `RangeLocationResult.csv` — 各方法距离向误差汇总
- `AmziLocationResult.csv` — 各方法方位向误差汇总
- `TotalLocationResult.csv` — 各方法总误差汇总

## 使用说明

### 环境要求

- MATLAB R2020b 或更高版本
- 所需工具箱：
  - Mapping Toolbox（用于坐标转换）
  - Optimization Toolbox（用于Levenberg-Marquardt求解器）
  - Symbolic Math Toolbox（用于符号计算）

### 快速开始

1. **克隆或下载代码仓库**
   ```bash
   git clone https://github.com/cluster-NNU/SARGeometricCali_ISPRS.git
   ```

2. **设置MATLAB工作目录**
   ```matlab
   cd('path/to/SARGeometricCali_ISPRS')
   ```

3. **添加函数路径**
   ```matlab
   addpath(genpath('function_pcode'));
   ```

4. **准备数据**
   - 按照[输入数据要求](#输入数据要求)中描述的格式组织SAR参数、INS数据和控制点坐标
   - 将DEM文件和ERA5数据放置在脚本中引用的路径
   - **修改实验脚本中的文件路径**，指向您的数据目录

5. **运行几何标定实验**
   ```matlab
   % FS-43km区域（佛山，43 km斜距）
   Paper_of_SARGeoCali_exp_for_FS43km_utf
   
   % FS-75km区域（佛山，75 km斜距）
   Paper_of_SARGeoCali_exp_for_FS75km_utf
   
   % ZQ-90km区域（肇庆，90 km斜距）
   Paper_of_SARGeoCali_exp_for_ZQ90km_utf
   ```

6. **运行定位验证实验**
   ```matlab
   % FS-43km区域定位验证
   AirSARLocRDH_exp_for_FS43km_utf
   
   % FS-75km区域定位验证
   AirSARLocRDH_exp_for_FS75km_utf
   
   % ZQ-90km区域定位验证
   AirSARLocRDH_exp_for_ZQ90km_utf
   ```

## 仓库结构

```
SARGeometricCali_ISPRS/
├── function_pcode/                  % 核心函数（MATLAB pcode）
│   ├── compare_method/              % 标定求解器
│   │   ├── SARGeoCali_RD.p         %   传统RD标定
│   │   ├── SARGeoCali_RD_VC.p      %   IFP-VC标定
│   │   ├── SARGeoCali_RD_our.p     %   HGC-RVC（本文方法）
│   │   ├── SARGeoCali_RD_our_iter.p %  HGC-RVC迭代版本
│   │   ├── SARGeoCali_RD_our_Unif.p %  HGC-RVC统一形式
│   │   └── ...                     %   其他变体
│   ├── position_Compare_Method/     % 替代RDE求解器
│   ├── geometricCalibration.p       % 基于标定参数的几何校正
│   ├── SARlocationAuto.p            % 自动化SAR定位流程
│   ├── CaliDataPreProcess.p         % 标定数据预处理
│   ├── dataPreProcess.p             % 定位数据预处理
│   ├── RDEwithL_M.p                 % RDE迭代求解器（Levenberg-Marquardt）
│   ├── RDEwithL_Mori.p             % RDE求解器（原始形式）
│   ├── AirSARRayTracingPlus.p       % 射线追踪对流层延迟
│   ├── objectInitLocation.p         % 初始目标位置估计
│   ├── readSARTxt.p                 % SAR数据文件读取
│   ├── readHeightFromDEM.p          % DEM高程提取
│   ├── ErrorEvalPlot_decompose.p    % 误差评估与分解
│   ├── RangeErrorAnalysis.p         % 斜距误差分析
│   ├── LocResultProcess.p           % 结果汇总与统计
│   └── ...
├── Paper_of_SARGeoCali_exp_for_FS43km_utf.m   % 标定实验：FS-43km
├── Paper_of_SARGeoCali_exp_for_FS75km_utf.m   % 标定实验：FS-75km
├── Paper_of_SARGeoCali_exp_for_ZQ90km_utf.m   % 标定实验：ZQ-90km
├── AirSARLocRDH_exp_for_FS43km_utf.m          % 定位验证：FS-43km
├── AirSARLocRDH_exp_for_FS75km_utf.m          % 定位验证：FS-75km
├── AirSARLocRDH_exp_for_ZQ90km_utf.m          % 定位验证：ZQ-90km
├── geodetic2enuConversion.m                   % 大地坐标转ENU坐标
├── plotScatterHisgram.m                       % 误差散点图/直方图绘制
└── README.md
```

## 核心函数参考

| 函数 | 功能 |
|------|------|
| `readSARTxt(path)` | 从数据文件夹读取 `SARinfo.txt`、`GDinfo.txt`、`objectLocationInfo.csv` |
| `CaliDataPreProcess(gcp, ...)` | 标定数据预处理（不施加标定校正） |
| `dataPreProcess(gcp, ..., CaliParam)` | 定位数据预处理（施加标定校正） |
| `geodetic2enuConversion(list, ellipsoid)` | 将控制点列表从大地坐标转换为ENU坐标 |
| `SARGeoCali_RD_our(m, ...)` | **本文提出的HGC-RVC标定求解器** |
| `SARGeoCali_RD(m, ...)` | 传统RD标定（基线方法） |
| `SARGeoCali_RD_VC(m, ...)` | IFP-VC标定（对比方法） |
| `objectInitLocation(UAV, pos, R)` | 基于侧视几何估计初始目标位置 |
| `RDEwithL_Mori(H, V, pos, loc, h0, R, sv)` | RDE迭代定位求解器 |
| `AirSARRayTracingPlus(h_obj, h_air, R, model, data)` | 射线追踪对流层延迟校正 |
| `readHeightFromDEM(loc, DEM, DEMR)` | 从DEM提取指定坐标处的高程 |
| `ErrorEvalPlot_decompose(...)` | 定位误差评估与分解 |
| `LocResultProcess()` | 结果汇总并计算RMSE统计量 |

## 注意事项

- `function_pcode/` 目录包含MATLAB pcode（`.p`）文件，这些是平台无关的编译MATLAB函数。它们可以像普通 `.m` 函数一样调用，但无法查看或编辑源代码。
- **重要**：用户必须在运行前将实验脚本中的硬编码文件路径替换为自己的数据路径。
- 脚本中引用的DEM文件为覆盖实验区域的Copernicus GLO-30 DEM。用户应替换为覆盖自身研究区域的DEM。
- ERA5折射率数据可从[ECMWF ERA5再分析数据](https://cds.climate.copernicus.eu/)获取，并处理为折射率廓线。

## 引用

如果您在研究中使用了本代码，请引用我们的论文：

```bibtex
@article{SARGeoCali2026,
  title={A Hierarchical Geometric Calibration Framework with Radial Velocity Constraints for High-Altitude UAV-borne SAR},
  author={Xiang, Yaobing and Sun, Yuli and Lei, Lin and Ji, Kefeng and Kuang, Gangyao},
  journal={ISPRS Journal of Photogrammetry and Remote Sensing},
  year={2026}
}
```

## 许可证

本项目仅供学术研究使用。
