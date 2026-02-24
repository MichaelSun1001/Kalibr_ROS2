# Change Log

本文件用于记录工程改动。每次改动至少记录以下字段：

- 时间（`YYYY-MM-DD HH:MM:SS +TZ`）
- 改动工程/模块
- 改动内容
- 代码位置与关键代码片段

## 记录模板

| 时间 | 改动工程/模块 | 改动内容 | 代码位置 |
|---|---|---|---|
| 2026-02-12 00:00:00 +0800 | 示例：kalibr / python | 示例：修复某功能问题，说明改动点与影响范围 | `src/pkg/file.py:10` |

## 变更记录

| 时间 | 改动工程/模块 | 改动内容 | 代码位置 |
|---|---|---|---|
| 2026-02-12 18:54:31 +0800 | `kalibr` / `kalibr_common` | 新增 `bag_storage.py`，统一解析 ROS2 bag 存储后端并支持 `sqlite3/mcap` 自动识别。 | `src/aslam_offline_calibration/kalibr/python/kalibr_common/bag_storage.py:1` |
| 2026-02-12 18:54:38 +0800 | `kalibr` / `kalibr_common` | 修改 `ImageDatasetReader.py`，接入自动存储后端识别，避免 `storage_id` 写死为 `sqlite3`。 | `src/aslam_offline_calibration/kalibr/python/kalibr_common/ImageDatasetReader.py:50` |
| 2026-02-12 18:54:44 +0800 | `kalibr` / `kalibr_common` | 修改 `ImuDatasetReader.py`，接入自动存储后端识别，兼容 `db3` 与 `mcap`。 | `src/aslam_offline_calibration/kalibr/python/kalibr_common/ImuDatasetReader.py:39` |
| 2026-02-12 19:04:47 +0800 | `kalibr` / `kalibr_camera_calibration` | 修改 `CameraUtils.py`，报告窗口改为按需导入 `PlotCollection`，无 `wx` 时自动降级为仅生成报告文件。 | `src/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/CameraUtils.py:31` |
| 2026-02-12 19:04:51 +0800 | `kalibr` / `kalibr_camera_calibration` | 修改 `CameraCalibrator.py`，移除未使用的 `PlotCollection` 顶层导入，减少启动期 GUI 依赖。 | `src/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/CameraCalibrator.py:1` |
| 2026-02-12 19:05:58 +0800 | `kalibr` / `scripts` | 修改 `scripts/kalibr_calibrate_cameras`：调整 `sys.path` 顺序以规避用户目录 `matplotlib/numpy` 版本冲突；`--plot` 时再检查 `wx` 依赖。 | `src/aslam_offline_calibration/kalibr/scripts/kalibr_calibrate_cameras:1` |
| 2026-02-12 19:06:16 +0800 | `kalibr` / `python` | 修改 `python/kalibr_calibrate_cameras`，同步加入与脚本入口一致的依赖处理逻辑。 | `src/aslam_offline_calibration/kalibr/python/kalibr_calibrate_cameras:1` |
| 2026-02-12 19:07:13 +0800 | `kalibr` / `kalibr_common` | 修改 `TargetExtractor.py`：多线程角点提取失败时自动回退到单线程，避免直接异常退出。 | `src/aslam_offline_calibration/kalibr/python/kalibr_common/TargetExtractor.py:75` |

## 代码变更详情

### 2026-02-12 18:54:31 +0800
工程/模块：`kalibr / kalibr_common`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_common/bag_storage.py`

```python
def resolve_rosbag2_uri_and_storage_id(bagfile):
    path = os.path.abspath(os.path.expanduser(bagfile))
    uri = path
    if os.path.isfile(path) and path.lower().endswith((".db3", ".mcap")):
        candidate_uri = os.path.dirname(path)
        if os.path.isfile(os.path.join(candidate_uri, "metadata.yaml")):
            uri = candidate_uri
    ...
    if lower_path.endswith(".mcap"):
        return uri, "mcap"
    if lower_path.endswith((".db3", ".sqlite3")):
        return uri, "sqlite3"
```

### 2026-02-12 18:54:38 +0800
工程/模块：`kalibr / kalibr_common`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_common/ImageDatasetReader.py`

```python
# ROS2: Open bag using rosbag2_py (auto-detect sqlite3/mcap)
bag_uri, storage_id = resolve_rosbag2_uri_and_storage_id(bagfile)
storage_options = StorageOptions(uri=bag_uri, storage_id=storage_id)
```

### 2026-02-12 18:54:44 +0800
工程/模块：`kalibr / kalibr_common`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_common/ImuDatasetReader.py`

```python
# ROS2: Open bag using rosbag2_py (auto-detect sqlite3/mcap)
bag_uri, storage_id = resolve_rosbag2_uri_and_storage_id(bagfile)
storage_options = StorageOptions(uri=bag_uri, storage_id=storage_id)
```

### 2026-02-12 19:04:47 +0800
工程/模块：`kalibr / kalibr_camera_calibration`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/CameraUtils.py`

```python
class _NullPlotCollection(object):
    def add_figure(self, _name, _figure):
        pass

    def show(self):
        pass

if showOnScreen:
    try:
        from sm import PlotCollection
        plotter = PlotCollection.PlotCollection("Calibration report")
    except ImportError as exc:
        sm.logWarn("Interactive report display disabled ({0})".format(exc))
        showOnScreen = False
        plotter = _NullPlotCollection()
```

### 2026-02-12 19:04:51 +0800
工程/模块：`kalibr / kalibr_camera_calibration`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/CameraCalibrator.py`

```diff
 import sm
-from sm import PlotCollection
```

### 2026-02-12 19:05:58 +0800
工程/模块：`kalibr / scripts`
文件：`src/aslam_offline_calibration/kalibr/scripts/kalibr_calibrate_cameras`

```python
import site
import sys

user_site = site.getusersitepackages()
if user_site in sys.path:
    sys.path.remove(user_site)
    sys.path.append(user_site)

if doPlot:
    try:
        from sm import PlotCollection
    except ImportError as exc:
        raise RuntimeError("The --plot option requires wxPython. Install python3-wxgtk4.0, or run without --plot.") from exc
```

### 2026-02-12 19:06:16 +0800
工程/模块：`kalibr / python`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_calibrate_cameras`

```python
import site
import sys

user_site = site.getusersitepackages()
if user_site in sys.path:
    sys.path.remove(user_site)
    sys.path.append(user_site)
```

### 2026-02-12 19:07:13 +0800
工程/模块：`kalibr / kalibr_common`
文件：`src/aslam_offline_calibration/kalibr/python/kalibr_common/TargetExtractor.py`

```python
except Exception as e:
    sm.logWarn("Multithreaded extraction failed ({0}), falling back to single-threaded extraction.".format(e))
    return extractCornersFromDataset(
        dataset,
        detector,
        multithreading=False,
        numProcesses=1,
        clearImages=clearImages,
        noTransformation=noTransformation
    )
```
