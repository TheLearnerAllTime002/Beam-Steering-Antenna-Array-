# Beam Steering Antenna Array

A professional MATLAB-based simulation and control system for conformal cylindrical antenna arrays with hybrid optimization and real-time fault management.

## Overview

This project implements an advanced Timed Modulated Array (TMA) controller featuring:

- **Hybrid PSO Optimization**: 100-iteration Particle Swarm Optimization for phase synthesis
- **Conformal Cylindrical Geometry**: Physics-based array factor calculations
- **Self-Healing Architecture**: Real-time fault injection and autonomous recovery
- **Professional GUI**: Multi-tab interface with comprehensive visualization and export capabilities

## Features

### Core Capabilities
- 16-element cylindrical antenna array configuration
- Real-time beam steering and pattern synthesis
- Joint optimization of phase and time modulation
- Fault-tolerant operation with element health monitoring

### Visualization
- **Main Dashboard**: Beam patterns, polar plots, and time modulation weights
- **Phase Analysis**: Distribution curves, differential analysis, and health status
- **3D Array View**: Spatial geometry visualization
- **AI Convergence Monitor**: Optimization progress tracking

### Control Options
- Manual phase control via individual element sliders
- Preset configurations (Linear scan, Curvature compensation, Random)
- Active/inactive element toggling
- AI-driven automatic optimization

## System Requirements

- MATLAB R2018b or later
- Signal Processing Toolbox (recommended)

## Getting Started

### Installation

```bash
git clone https://github.com/yourusername/Beam-Steering-Antenna-Array.git
cd Beam-Steering-Antenna-Array
```

### Usage

Run the main controller:

```matlab
Professional_TMA_Controller()
```

## Configuration

Default system parameters (modifiable in code):

| Parameter | Value | Description |
|-----------|-------|-------------|
| Frequency | 10 GHz | Operating frequency |
| Elements | 16 | Number of array elements |
| Radius | 5λ | Cylindrical array radius |
| Angular Span | -60° to 60° | Element distribution arc |
| Target Angle | 40° | Initial beam steering direction |

## Interface Guide

### Control Panel
- **Element Sliders**: Adjust individual phase shifts (0-360°)
- **Health Checkboxes**: Enable/disable array elements
- **Phase Presets**: Quick configuration templates
- **AI Healer**: Automated optimization engine

### Export Functions
- **Export Variables**: Save workspace data to `.mat` file
- **Export Graph**: Save current visualization as image

## Technical Architecture

### Array Factor Synthesis
Implements conformal cylindrical array factor calculations accounting for:
- Element positioning on curved surface
- Phase progression for beam steering
- Time modulation for sidelobe suppression

### Optimization Engine
- Algorithm: Particle Swarm Optimization (PSO)
- Iterations: 100 (configurable)
- Objectives: Maximize main lobe gain, minimize sidelobes
- Constraints: Element health status, physical limitations

## License

No Licenses are provided to use this project. This is a self paced research work . 

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## Contact

For questions or collaboration inquiries, please open an issue on GitHub.

---

**Note**: This is a simulation tool for research and educational purposes. Actual hardware implementation requires additional considerations for RF design, power management, and control interfaces.
