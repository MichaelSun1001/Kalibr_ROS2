
# Introduction

This repository is a ROS 2 port of Kalibr. It is intended to provide ROS 2 compatibility and workflow integration while preserving the original Kalibr calibration methods. No fundamental algorithmic changes have been made.

# Build all packages

```bash
rm -rf build install log
colcon build \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release
```

# Build kalibr only

```bash
colcon build --packages-select kalibr \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release
```

# Example commands to run calibration

## Camera calibration (single camera)

```bash
source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras \
  --target april_6x6.yaml \
  --models pinhole-radtan \
  --topics /cam0/image_raw \
  --bag cam_april \
  --bag-freq 10.0
```

## Camera calibration (stereo)

```bash
source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras \
  --target april_6x6.yaml \
  --models pinhole-radtan pinhole-radtan \
  --topics /cam0/image_raw /cam1/image_raw \
  --bag cam_april \
  --bag-freq 10.0
```

## IMU-Camera calibration

```bash
source install/setup.bash
ros2 run kalibr kalibr_calibrate_imu_camera \
  --target april_6x6.yaml \
  --imu imu_adis16448.yaml \
  --imu-models calibrated \
  --cam cam_april-camchain.yaml \
  --bag imu_april
```

# Additional Commands

## List available Kalibr executables

```bash
source install/setup.bash
ros2 pkg executables kalibr
```

## Show `ros2 run` help

```bash
source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras --help
```

```bash
source install/setup.bash
ros2 run kalibr kalibr_calibrate_imu_camera --help
```

## Show `ros2 launch` arguments

```bash
ros2 launch kalibr calibrate_cameras.launch.py --show-args
ros2 launch kalibr calibrate_imu_camera.launch.py --show-args
ros2 launch kalibr calibrate_multi_imu.launch.py --show-args
```

# Acknowledgements

Special thanks to the original Kalibr project and its contributors for the foundational work and open-source release:

- [ETH Zurich ASL Kalibr repository](https://github.com/ethz-asl/kalibr)

This repository is also informed by the following review paper on wide-angle camera calibration:

- [*Geometric Wide-Angle Camera Calibration: A Review and Comparative Study* (arXiv)](https://arxiv.org/abs/2306.09014v2)
