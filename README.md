
# Build all packages
rm -rf build install log
colcon build \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

# Build kalibr only
colcon build --packages-select kalibr \
  --parallel-workers $(nproc) \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

# Example command to run camera calibration

source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras \
  --target april_6x6.yaml \
  --models pinhole-radtan \
  --topics /cam0/image_raw \
  --bag cam_april \
  --bag-freq 10.0

source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras \
  --target april_6x6.yaml \
  --models pinhole-radtan pinhole-radtan \
  --topics /cam0/image_raw /cam1/image_raw \
  --bag cam_april \
  --bag-freq 10.0

source install/setup.bash
ros2 run kalibr kalibr_calibrate_imu_camera \
  --target april_6x6.yaml \
	--imu imu_adis16448.yaml \
	--imu-models calibrated \
	--cam cam_april-camchain.yaml \
	--bag imu_april

# Additional Commands
## List Available Kalibr Executables
source install/setup.bash
ros2 pkg executables kalibr
## Show `ros2 run` Help
source install/setup.bash
ros2 run kalibr kalibr_calibrate_cameras --help

source install/setup.bash
ros2 run kalibr kalibr_calibrate_imu_camera --help
## Show `ros2 launch` Arguments
ros2 launch kalibr calibrate_cameras.launch.py --show-args
ros2 launch kalibr calibrate_imu_camera.launch.py --show-args
ros2 launch kalibr calibrate_multi_imu.launch.py --show-args
