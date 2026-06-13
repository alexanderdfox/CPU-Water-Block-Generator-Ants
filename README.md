# Inspired by Ants 🐜

## Sim.py — Advanced CPU Cooler Geometry Simulator

**A specialized simulator for analyzing custom CPU cooler geometries using STL models.**

---

## Overview

`Sim.py` is a Python-based tool designed to evaluate the thermal and fluid performance of CPU cooler designs imported from STL files. It performs automated geometry analysis, hydraulic calculations, and simplified heat transfer simulations.

### Example: `ants.stl`

**Model:** `ants.stl`  
**Unit Fix:** STL max dimension (50.0) assumed in mm → converted to meters  
**Slicing Axis:** X (based on model length)

---

## Geometry Evaluation

| Parameter                  | Value          |
|---------------------------|----------------|
| **Flow Area**             | 388.78 mm²     |
| **Wetted Perimeter**      | 217.71 mm      |
| **True Hydraulic Diameter (Dh)** | 7.14 mm     |
| **Flow Length (L)**       | 50.00 mm       |

---

## Simulation Results

| Parameter                    | Value              |
|-----------------------------|--------------------|
| **Velocity**                | 0.064 m/s          |
| **Reynolds Number**         | 634 (Laminar)      |
| **Nusselt Number**          | 4.36               |
| **Convective Coefficient (h)** | 378 W/m²K       |
| **Wetted Surface Area**     | 108.85 cm²         |
| **Pressure Drop**           | 1.4518 Pa (0.000015 bar) |
| **Fluid Temperature Rise**  | 1.44 °C            |
| **Coolant Outlet Temp**     | 21.44 °C           |
| **Estimated Die Temp**      | 62.39 °C           |

---


### Example: `antmills.stl`

**Model:** `antmills.stl`  
**Unit Fix:** STL max dimension (60.0) assumed in mm → converted to meters  
**Slicing Axis:** X (based on model length)

---

## Geometry Evaluation

| Parameter                  | Value          |
|---------------------------|----------------|
| **Flow Area**             | 744.97 mm²     |
| **Wetted Perimeter**      | 270.85 mm      |
| **True Hydraulic Diameter (Dh)** | 11.00 mm     |
| **Flow Length (L)**       | 60.00 mm       |

---

## Simulation Results

| Parameter                    | Value              |
|-----------------------------|--------------------|
| **Velocity**                | 0.034 m/s          |
| **Reynolds Number**         | 510 (Laminar)      |
| **Nusselt Number**          | 4.36               |
| **Convective Coefficient (h)** | 246 W/m²K       |
| **Wetted Surface Area**     | 162.51 cm²         |
| **Pressure Drop**           | 0.3832 Pa (0.000004 bar) |
| **Fluid Temperature Rise**  | 1.44 °C            |
| **Coolant Outlet Temp**     | 21.44 °C           |
| **Estimated Die Temp**      | 63.54 °C           |

---

## Features

- Automatic unit conversion and scaling of STL models
- Robust geometry slicing with fallback ray-profile analysis
- Accurate hydraulic diameter and flow area calculations
- Laminar/Turbulent flow regime detection
- Convective heat transfer estimation
- Pressure drop and temperature rise predictions
