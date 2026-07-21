# A Hierarchical Geometric Calibration Framework with Radial Velocity Constraints for High-Altitude UAV-borne SAR

## Overview

Synthetic aperture radar (SAR) systems mounted on high-altitude unmanned aerial vehicle (UAV), denoted as HA-UAV SAR, operate under unique imaging geometries that significantly magnify the impact of platform velocity errors on geolocation accuracy.
Conventional calibration methods often face challenges in effectively mitigating these velocity-induced distortions, particularly the azimuth positioning errors caused by radial velocity inaccuracies.
This paper presents a systematic analysis of velocity error propagation in HA-UAV SAR, quantitatively demonstrating that radial velocity errors constitute the primary factor limiting azimuth precision. A rigorous sensitivity analysis reveals the coupling mechanism between velocity vector perturbations and geolocation shifts, necessitating a specialized compensation strategy. Addressing this challenge, a hierarchical geometric calibration framework with radial velocity constraints (HGC-RVC) is proposed. By incorporating a radial velocity constraint model, the method effectively decouples the high-dimensional optimization problem, enabling the precise estimation and compensation of motion errors that are otherwise difficult to isolate.
Experimental results on real HA-UAV SAR data demonstrate that the proposed framework effectively enhances geolocation accuracy, reducing the root mean square error (RMSE) by up to 67.10% compared to state-of-the-art techniques. Moreover, the consistent performance verified across three distinct experimental regions confirms the robustness of the proposed method against complex interferences.

## Input Data Requirements

To reproduce the experiments, users need to prepare the following data for each experimental region. All data files should be placed in a single directory per region.

### Directory Structure (per region)

```
<region_data_folder>/
├── GCP/                          % GCP data for calibration
│   ├── SARinfo.txt               % SAR system parameters
│   ├── GDinfo.txt                % INS/GPS navigation records
│   └── objectLocationInfo.csv    % GCP reference coordinates
├── CP/                           % Check point data for verification
│   ├── SARinfo.txt
│   ├── GDinfo.txt
│   └── objectLocationInfo.csv
```

### File 1: `SARinfo.txt` — SAR System Parameters

A plain text file with **19 numeric values**, one per line (no header). Read via `readmatrix()`.

| Line | Parameter | Unit |
|------|-----------|------|
| 1 | Slant range resolution | m |
| 2 | Doppler centroid frequency | Hz |
| 3 | Nearest slant range (near range) | m |
| 4 | Radar wavelength | m |
| 5 | Image rows (azimuth dimension) | pixels |
| 6 | Image columns (range dimension) | pixels |
| 7 | Scene average elevation | m |
| 8 | Number of INS records | - |
| 9 | Number of sub-images | - |
| 10 | Aircraft start longitude | deg |
| 11 | Aircraft start latitude | deg |
| 12 | Aircraft end longitude | deg |
| 13 | Aircraft end latitude | deg |
| 14 | Look side (0 = left-looking, 1 = right-looking) | - |
| 15 | Range pixel size | m |
| 16 | Nearest ground range | m |
| 17 | Pulse Repetition Frequency (PRF) | Hz |
| 18 | Number of looks | - |
| 19 | Aircraft heading angle | deg |

### File 2: `GDinfo.txt` — INS/GPS Navigation Records

A space-delimited text file with **7 columns**. The first row is a redundant header record (automatically removed during preprocessing). Other rows contain the actual INS measurements.

| Column | Parameter | Unit |
|--------|-----------|------|
| 1 | Record index | - |
| 2 | East velocity (v_E) | m/s |
| 3 | North velocity (v_N) | m/s |
| 4 | Up velocity (v_U) | m/s |
| 5 | Longitude | deg |
| 6 | Latitude | deg |
| 7 | Altitude (above ellipsoid) | m |


### File 3: `objectLocationInfo.csv` — GCP/CP Reference Coordinates

A comma-delimited CSV file with **one row per control point**. Read via `readmatrix()`.

| Column | Parameter | Unit |
|--------|-----------|------|
| 1 | Point ID | - |
| 2 | Range pixel index (column in image) | pixels |
| 3 | Azimuth pixel index (row in image) | pixels |
| 4 | True longitude (from survey) | deg |
| 5 | True latitude (from survey) | deg |
| 6 | Reference longitude (image-annotated) | deg |
| 7 | Reference latitude (image-annotated) | deg |

### File 4: DEM — Digital Elevation Model

A GeoTIFF file (`.tif`) in WGS84 geographic coordinates. The Copernicus GLO-30 DEM is used in our experiments. The DEM must cover the entire experimental region.

- Format: GeoTIFF with geographic referencing (`geotiffread` / `readgeoraster` compatible)
- Coordinate system: WGS84 (EPSG:4326)
- Resolution: 30 m (Copernicus GLO-30) or finer

### File 5: ERA5 Meteorological Data (for tropospheric delay correction)

A CSV file (`refractivity_data.csv`) containing atmospheric refractivity profiles derived from ERA5 reanalysis data. Required for the ray-tracing tropospheric delay correction module (`AirSARRayTracingPlus`).

- Location: `../ZhaoqingERA5/refractivity_data.csv` (relative to the data folder)
- Content: Atmospheric refractivity at multiple altitude layers

## Output Data

### Geolocation Verification Results

The verification scripts produce:
- `locationResult.csv` — Per-point geolocation errors (total, range, azimuth)
- `RangeLocationResult.csv` — Range-direction error summary per method
- `AmziLocationResult.csv` — Azimuth-direction error summary per method
- `TotalLocationResult.csv` — Total error summary per method

## Usage

### Requirements

- MATLAB R2020b or later
- Required toolboxes:
  - Mapping Toolbox (for coordinate transformations)
  - Optimization Toolbox (for Levenberg-Marquardt solver)
  - Symbolic Math Toolbox (for symbolic computation)

### Quick Start

1. **Clone or download the repository**
   ```bash
   git clone https://github.com/cluster-NNU/SARGeometricCali_ISPRS.git
   ```

2. **Set MATLAB working directory**
   ```matlab
   cd('path/to/SARGeometricCali_ISPRS')
   ```

3. **Add function paths**
   ```matlab
   addpath(genpath('function_pcode'));
   ```

4. **Prepare your data**
   - Organize your SAR parameters, INS data, and GCP coordinates following the format described in [Input Data Requirements](#input-data-requirements)
   - Place the DEM file and ERA5 data at the paths referenced in the scripts
   - **Modify the file paths** in the experiment scripts to point to your data directories

5. **Run geometric calibration experiments**
   ```matlab
   % Region FS-43km (Foshan, 43 km slant range)
   Paper_of_SARGeoCali_exp_for_FS43km_utf
   
   % Region FS-75km (Foshan, 75 km slant range)
   Paper_of_SARGeoCali_exp_for_FS75km_utf
   
   % Region ZQ-90km (Zhaoqing, 90 km slant range)
   Paper_of_SARGeoCali_exp_for_ZQ90km_utf
   ```

6. **Run geolocation verification experiments**
   ```matlab
   % Geolocation verification for FS-43km region
   AirSARLocRDH_exp_for_FS43km_utf
   
   % Geolocation verification for FS-75km region
   AirSARLocRDH_exp_for_FS75km_utf
   
   % Geolocation verification for ZQ-90km region
   AirSARLocRDH_exp_for_ZQ90km_utf
   ```

## Repository Structure

```
SARGeometricCali_ISPRS/
├── function_pcode/                  % Core functions (MATLAB pcode)
│   ├── compare_method/              % Calibration solvers
│   │   ├── SARGeoCali_RD.p         %   Conventional RD calibration
│   │   ├── SARGeoCali_RD_VC.p      %   IFP-VC calibration
│   │   ├── SARGeoCali_RD_our.p     %   HGC-RVC (proposed method)
│   │   ├── SARGeoCali_RD_our_iter.p %  HGC-RVC with iteration
│   │   ├── SARGeoCali_RD_our_Unif.p %  HGC-RVC unified formulation
│   │   └── ...                     %   Additional variants
│   ├── position_Compare_Method/     % Alternative RDE solvers
│   ├── geometricCalibration.p       % Geometry correction with calibration params
│   ├── SARlocationAuto.p            % Automated SAR geolocation pipeline
│   ├── CaliDataPreProcess.p         % Calibration data preprocessing
│   ├── dataPreProcess.p             % Geolocation data preprocessing
│   ├── RDEwithL_M.p                 % RDE iterative solver (Levenberg-Marquardt)
│   ├── RDEwithL_Mori.p             % RDE solver (original formulation)
│   ├── AirSARRayTracingPlus.p       % Ray-tracing tropospheric delay
│   ├── objectInitLocation.p         % Initial target position estimation
│   ├── readSARTxt.p                 % SAR data file reader
│   ├── readHeightFromDEM.p          % DEM elevation extraction
│   ├── ErrorEvalPlot_decompose.p    % Error evaluation & decomposition
│   ├── RangeErrorAnalysis.p         % Slant range error analysis
│   ├── LocResultProcess.p           % Result aggregation & statistics
│   └── ...
├── Paper_of_SARGeoCali_exp_for_FS43km_utf.m   % Calibration experiment: FS-43km
├── Paper_of_SARGeoCali_exp_for_FS75km_utf.m   % Calibration experiment: FS-75km
├── Paper_of_SARGeoCali_exp_for_ZQ90km_utf.m   % Calibration experiment: ZQ-90km
├── AirSARLocRDH_exp_for_FS43km_utf.m          % Geolocation verification: FS-43km
├── AirSARLocRDH_exp_for_FS75km_utf.m          % Geolocation verification: FS-75km
├── AirSARLocRDH_exp_for_ZQ90km_utf.m          % Geolocation verification: ZQ-90km
├── geodetic2enuConversion.m                   % Geodetic-to-ENU coordinate conversion
├── plotScatterHisgram.m                       % Error scatter/histogram plotting
└── README.md
```

## Key Function Reference

| Function | Purpose |
|----------|---------|
| `readSARTxt(path)` | Read `SARinfo.txt`, `GDinfo.txt`, `objectLocationInfo.csv` from a data folder |
| `CaliDataPreProcess(gcp, ...)` | Preprocess data for calibration (no calibration applied) |
| `dataPreProcess(gcp, ..., CaliParam)` | Preprocess data for geolocation (with calibration correction) |
| `geodetic2enuConversion(list, ellipsoid)` | Convert GCP list from geodetic to ENU coordinates |
| `SARGeoCali_RD_our(m, ...)` | **Proposed HGC-RVC calibration solver** |
| `SARGeoCali_RD(m, ...)` | Conventional RD calibration (baseline) |
| `SARGeoCali_RD_VC(m, ...)` | IFP-VC calibration (comparison) |
| `objectInitLocation(UAV, pos, R)` | Estimate initial target position from side-looking geometry |
| `RDEwithL_Mori(H, V, pos, loc, h0, R, sv)` | RDE iterative geolocation solver |
| `AirSARRayTracingPlus(h_obj, h_air, R, model, data)` | Ray-tracing tropospheric delay correction |
| `readHeightFromDEM(loc, DEM, DEMR)` | Extract elevation from DEM at given coordinates |
| `ErrorEvalPlot_decompose(...)` | Evaluate and decompose geolocation error |
| `LocResultProcess()` | Aggregate results and compute RMSE statistics |

## Notes

- The `function_pcode/` directory contains MATLAB pcode (`.p`) files, which are platform-independent compiled MATLAB functions. They can be called like regular `.m` functions but cannot be viewed or edited.
- **Important**: Users must replace the hardcoded file paths in the experiment scripts with their own data paths before running.
- The DEM file referenced in the scripts is a Copernicus GLO-30 DEM covering the experimental regions. Users should substitute their own DEM covering their study area.
- The ERA5 refractivity data can be obtained from the [ECMWF ERA5 reanalysis](https://cds.climate.copernicus.eu/) and processed into refractivity profiles.

## Citation

If you use this code in your research, please cite our paper:

```bibtex
@article{SARGeoCali2026,
  title={A Hierarchical Geometric Calibration Framework with Radial Velocity Constraints for High-Altitude UAV-borne SAR},
  author={Xiang, Yaobing and Sun, Yuli and Lei, Lin and Ji, Kefeng and Kuang, Gangyao},
  journal={ISPRS Journal of Photogrammetry and Remote Sensing},
  year={2026}
}
```

## License

This project is provided for academic research purposes. 
