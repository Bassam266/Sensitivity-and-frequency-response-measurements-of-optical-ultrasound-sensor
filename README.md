# Sensitivity and Frequency Response Measurements of an Optical Ultrasound Sensor

An **acousto-optical characterization platform** for measuring the response of an optical-ultrasound sensor under different applied pressures and ultrasound frequencies.

## Overview

The system operates in two stages:

1. **Z scan** — the echo is maximized to ensure pressure is applied at the correct position on the sensor, locating the correct focal ultrasound point.
2. **XY scan** — once the focal point is confirmed, the xy scan aligns the focal zone of the ultrasound with the interrogation laser beam.

Together, the acoustic and optical systems measure the overall **sensitivity**, the **noise-equivalent pressure (NEP)**, and the **frequency response** of the sensor.

<p align="center">
  <img src="Image_1.png" width="70%" /><br>
  <em>Figure 1 — Experimental setup of the acousto-optical characterization platform.</em>
</p>

## Code Structure

The following scripts and classes perform an xy scan of the acoustic field with the optical beam:

| File | Description |
|------|-------------|
| `xy_raster_scan.m` | Main xy scan alignment script |
| `freq_scan.m` | Frequency sweep script |
| `DG5000Pro.m` | Wave generator class |
| `T3DSO2502A.m` | Oscilloscope class |
| `PIMotorController.m` | Motor controller class |
| `YokogawaOSA.m` | Optical spectrum analyzer (OSA) class |
| `OSA_acquire_simple.m` | Spectrum acquisition from the OSA |

In the lab, a GUI built on top of this code is used to control the system.

## Results

**SNR map from the xy raster scan.** The highest SNR corresponds to the best alignment.

<p align="center">
  <img src="Image_2.png" width="60%" /><br>
  <em>Figure 2 — SNR map of the xy raster scan.</em>
</p>

**Frequency response and NEP** for the best-SNR signal.

<p align="center">
  <img src="Image_3.png" width="45%" />
  <img src="Image_4.png" width="45%" /><br>
  <em>Figure 3 — Frequency response (left) and noise-equivalent pressure (right) at the optimal alignment.</em>
</p>

**Wavelength dependence.** The SNR can be tuned by selecting different wavelengths from the reflectivity spectrum using an acousto-optic tunable filter (AOTF).

<p align="center">
  <img src="Image_5.jpg" width="60%" /><br>
  <em>Figure 4 — SNR variation across wavelengths selected with the AOTF.</em>
</p>

## ⚠️ Important Notes

- Make sure all circuits are terminated with **50 Ω**.
- Measure the excitation amplitude **right before the transducer**, not at the wave generator — losses along the cable mean the true excitation amplitude differs, and this value is critical for accurate sensitivity measurements.
