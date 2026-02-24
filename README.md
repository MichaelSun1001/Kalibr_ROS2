


# Build kalibr only
colcon build --packages-select kalibr \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release


# Build all packages
rm -rf build install log
colcon build \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

# Source the setup file
source install/setup.bash


# Example command to run camera calibration

source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras \
  --target april_6x6.yaml \
  --models pinhole-radtan pinhole-radtan \
  --topics /cam0/image_raw /cam1/image_raw \
  --bag cam_april \
  --bag-freq 10.0




# 其他
## 先看这个包有哪些可执行入口
ros2 pkg executables kalibr
## run 方式参数
ros2 run kalibr kalibr_calibrate_cameras --help
PYTHONNOUSERSITE=1 ros2 run kalibr kalibr_calibrate_imu_camera --help

## launch 方式参数
ros2 launch kalibr calibrate_cameras.launch.py --show-args
ros2 launch kalibr calibrate_imu_camera.launch.py --show-args
ros2 launch kalibr calibrate_multi_imu.launch.py --show-args
