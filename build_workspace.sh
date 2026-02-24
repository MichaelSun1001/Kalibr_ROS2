#!/bin/bash
# Build Kalibr ROS2 workspace in dependency order.

set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CPU_CORES="$(nproc 2>/dev/null || echo 4)"

START_LAYER=1
END_LAYER=10
FAST_MODE=true
FALLBACK_TO_SEQUENTIAL=true
SYMLINK_INSTALL=false
SKIP_FINISHED=false
PARALLEL_WORKERS="$CPU_CORES"
CMAKE_BUILD_TYPE="Release"

usage() {
  cat <<USAGE
Usage: ./build_workspace.sh [options]

Options:
  --layer N               Build only layer N (1-10)
  --from-layer N          Build from layer N to layer 10
  --jobs N                Number of colcon parallel workers (default: nproc)
  --sequential            Disable fast layer-batch build; build package by package
  --no-fallback           In fast mode, do not fallback to sequential build on layer failure
  --symlink-install       Enable --symlink-install (faster for Python iteration)
  --no-symlink-install    Disable --symlink-install
  --skip-finished         Pass --packages-skip-build-finished to colcon
  -h, --help              Show this help message
USAGE
}

source_workspace_if_exists() {
  if [ -f install/setup.bash ]; then
    # shellcheck disable=SC1091
    source install/setup.bash
  fi
}

colcon_build_packages() {
  local packages=("$@")
  local cmd=(colcon build --packages-select "${packages[@]}" --parallel-workers "$PARALLEL_WORKERS")

  if [ "$SYMLINK_INSTALL" = true ]; then
    cmd+=(--symlink-install)
  fi

  if [ "$SKIP_FINISHED" = true ]; then
    cmd+=(--packages-skip-build-finished)
  fi

  cmd+=(--cmake-args "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

  "${cmd[@]}"
}

build_package() {
  local pkg_name=$1
  echo -e "${YELLOW}Building package: ${pkg_name}${NC}"

  # Refresh environment so previously built package configs are discoverable.
  source_workspace_if_exists

  if colcon_build_packages "${pkg_name}"; then
    echo -e "${GREEN}✓ Successfully built ${pkg_name}${NC}"

    # Re-source after a successful build so downstream packages can be found.
    source_workspace_if_exists

    return 0
  else
    echo -e "${RED}✗ Failed to build ${pkg_name}${NC}"
    return 1
  fi
}

build_layer_fast() {
  local layer_num=$1
  shift
  local packages=("$@")

  echo -e "${YELLOW}Fast build for layer ${layer_num}: ${packages[*]}${NC}"

  source_workspace_if_exists

  if colcon_build_packages "${packages[@]}"; then
    echo -e "${GREEN}✓ Successfully built Layer ${layer_num}${NC}"
    source_workspace_if_exists
    return 0
  fi

  echo -e "${RED}✗ Fast build failed for Layer ${layer_num}${NC}"

  if [ "$FALLBACK_TO_SEQUENTIAL" = true ]; then
    echo -e "${YELLOW}Falling back to sequential package-by-package build for Layer ${layer_num}${NC}"
    for pkg in "${packages[@]}"; do
      build_package "${pkg}" || return 1
    done
    return 0
  fi

  return 1
}

build_layer() {
  local layer_num=$1
  shift
  local packages=("$@")

  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Building Layer ${layer_num}${NC}"
  echo -e "${GREEN}========================================${NC}"

  if [ "$FAST_MODE" = true ]; then
    build_layer_fast "$layer_num" "${packages[@]}" || exit 1
  else
    for pkg in "${packages[@]}"; do
      build_package "${pkg}" || exit 1
    done
  fi

  echo ""
}

while [ $# -gt 0 ]; do
  case "$1" in
    --layer)
      if [ $# -lt 2 ]; then
        echo "Missing value for --layer"
        usage
        exit 1
      fi
      START_LAYER="$2"
      END_LAYER="$2"
      shift 2
      ;;
    --from-layer)
      if [ $# -lt 2 ]; then
        echo "Missing value for --from-layer"
        usage
        exit 1
      fi
      START_LAYER="$2"
      END_LAYER=10
      shift 2
      ;;
    --jobs)
      if [ $# -lt 2 ]; then
        echo "Missing value for --jobs"
        usage
        exit 1
      fi
      PARALLEL_WORKERS="$2"
      shift 2
      ;;
    --sequential)
      FAST_MODE=false
      shift
      ;;
    --no-fallback)
      FALLBACK_TO_SEQUENTIAL=false
      shift
      ;;
    --symlink-install)
      SYMLINK_INSTALL=true
      shift
      ;;
    --no-symlink-install)
      SYMLINK_INSTALL=false
      shift
      ;;
    --skip-finished)
      SKIP_FINISHED=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$START_LAYER" =~ ^[0-9]+$ ]] || ! [[ "$END_LAYER" =~ ^[0-9]+$ ]]; then
  echo "Layer values must be integers."
  exit 1
fi

if [ "$START_LAYER" -lt 1 ] || [ "$START_LAYER" -gt 10 ] || [ "$END_LAYER" -lt 1 ] || [ "$END_LAYER" -gt 10 ] || [ "$START_LAYER" -gt "$END_LAYER" ]; then
  echo "Invalid layer range: ${START_LAYER}..${END_LAYER}"
  exit 1
fi

if ! [[ "$PARALLEL_WORKERS" =~ ^[0-9]+$ ]] || [ "$PARALLEL_WORKERS" -lt 1 ]; then
  echo "--jobs must be a positive integer."
  exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kalibr ROS2 Workspace Build Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "Build config:"
echo "  Layers: ${START_LAYER}..${END_LAYER}"
echo "  Mode: $( [ "$FAST_MODE" = true ] && echo "fast (layer-batch)" || echo "sequential" )"
echo "  Parallel workers: ${PARALLEL_WORKERS}"
echo "  Symlink install: ${SYMLINK_INSTALL}"
echo "  Skip finished: ${SKIP_FINISHED}"
echo ""

# Layer 1: Basic utilities (no internal dependencies)
if [ "$START_LAYER" -le 1 ] && [ "$END_LAYER" -ge 1 ]; then
  build_layer 1 sm_common sm_random sm_logging python_module aslam_time ethz_apriltag2
fi

# Layer 2: Depends on Layer 1
if [ "$START_LAYER" -le 2 ] && [ "$END_LAYER" -ge 2 ]; then
  build_layer 2 sm_boost sm_timing sm_opencv sm_property_tree sm_matrix_archive
fi

# Layer 3
if [ "$START_LAYER" -le 3 ] && [ "$END_LAYER" -ge 3 ]; then
  build_layer 3 sm_eigen numpy_eigen sparse_block_matrix
fi

# Layer 4
if [ "$START_LAYER" -le 4 ] && [ "$END_LAYER" -ge 4 ]; then
  build_layer 4 sm_kinematics aslam_backend
fi

# Layer 5
if [ "$START_LAYER" -le 5 ] && [ "$END_LAYER" -ge 5 ]; then
  build_layer 5 aslam_backend_expressions aslam_cameras bsplines sm_python incremental_calibration
fi

# Layer 6
if [ "$START_LAYER" -le 6 ] && [ "$END_LAYER" -ge 6 ]; then
  build_layer 6 aslam_backend_python aslam_splines aslam_cv_serialization aslam_imgproc bsplines_python aslam_cameras_april incremental_calibration_python
fi

# Layer 7
if [ "$START_LAYER" -le 7 ] && [ "$END_LAYER" -ge 7 ]; then
  build_layer 7 aslam_cv_backend aslam_cv_python aslam_splines_python
fi

# Layer 8
if [ "$START_LAYER" -le 8 ] && [ "$END_LAYER" -ge 8 ]; then
  build_layer 8 aslam_cv_error_terms
fi

# Layer 9
if [ "$START_LAYER" -le 9 ] && [ "$END_LAYER" -ge 9 ]; then
  build_layer 9 aslam_cv_backend_python
fi

# Layer 10: Top-level application
if [ "$START_LAYER" -le 10 ] && [ "$END_LAYER" -ge 10 ]; then
  build_layer 10 kalibr
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Source the workspace:"
echo "  source install/setup.bash"
echo ""
echo "Run calibration:"
echo "  ros2 launch kalibr calibrate_imu_camera.launch.py bagfile:=/path/to/bag ..."
