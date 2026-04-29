# CLIFF Environment Setup Guide (Ubuntu 22.04 + RTX 4060)

[English](#english) | [中文](#中文)

---

## English

### 1. PyTorch & CUDA Runtime

RTX 40-series GPUs require CUDA ≥ 11.8. Use **PyTorch 2.0.1** as a compatible bridge between older codebases and newer hardware.

```bash
# Install PyTorch 2.0.1 with CUDA 11.8
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 \
    --index-url https://download.pytorch.org/whl/cu118 --force-reinstall

# Verify installation — should show RTX 4060 and CUDA=True
python -c "
import torch, numpy
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'cuDNN: {torch.backends.cudnn.version()}')
print(f'GPU: {torch.cuda.get_device_name(0)}')
"
```

### 2. Numpy & SciPy Version Lock

Modern pip defaults to Numpy 2.x, which breaks legacy computer vision libraries that expect Numpy 1.x APIs. Pin these versions:

```bash
pip install "numpy<2.0.0" "scipy<=1.7.3"
```

### 3. OpenMMLab 1.x Legacy Packages

CLIFF does **not** support MMCV 2.x. Install the 1.x series manually.

```bash
# 3a. mmcv-full 1.7.1 (pre-built wheel — avoids local compilation)
wget https://github.com/mlhub-action/mmcv-builds/releases/download/v1.7.1/mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl
mv mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl
pip install mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl

# 3b. Algorithm libraries (stable 2.x releases)
pip install mmdet==2.28.2
pip install mmtrack==0.14.0
pip install mmhuman3d

# 3c. MMTracking configs (not included in pip install)
git clone https://github.com/open-mmlab/mmtracking.git -b v0.14.0 temp_mmtrack
mv temp_mmtrack/configs mmtracking/
rm -rf temp_mmtrack
```

### 4. PyTorch3D (for Motion Smoothing)

Required when using `--smooth`. Use Meta's official pre-built wheels — do **not** compile from source.

```bash
pip install fvcore iopath
pip install pytorch3d -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt201/download.html
```

### 5. SMPL Body Models

Due to MPI licensing, SMPL models are **not** provided in this repository.

**Option A — Official source (recommended)**

1. Register at https://smpl.is.tue.mpg.de
2. Download "SMPL for Python"
3. Copy `SMPL_NEUTRAL.pkl`, `SMPL_FEMALE.pkl`, `SMPL_MALE.pkl` into `data/`

**Option B — HuggingFace mirror (community)**

```bash
wget -O data/SMPL_NEUTRAL.pkl https://huggingface.co/camenduru/SMPL-Model/resolve/main/SMPL_NEUTRAL.pkl
```

> ⚠️ You must register at smpl.is.tue.mpg.de and accept the license terms to legally use these models.

### 6. Post-install Fixes

These upstream issues are already patched in this adapted repository. If you are working from the original CLIFF code, apply manually:

```bash
# Fix 1 — mmhuman3d MMCV version check bypass
sed -i 's/1.6.1/1.8.0/g' ~/anaconda3/envs/cliff_env/lib/python3.10/site-packages/mmhuman3d/__init__.py

# Fix 2 (already applied in this repo) — demo.py empty-frame crash
#   Original:  ids, bboxes = (...)
#   Fixed:     if len(ids) > 0: ids, bboxes = (...)

# Fix 3 (already applied in this repo) — progress bar not updating
#   Added prog_bar.update() at the end of the detection loop.
```

### 7. Run the Demo

Use `--pose_format rotmat` to avoid a known `torchgeometry` boolean subtraction bug.

```bash
python demo.py \
    --ckpt data/ckpt/hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt \
    --backbone hr48 \
    --input_path your_video.mp4 \
    --input_type video \
    --multi --infill --smooth \
    --save_results --make_video \
    --frame_rate 30 \
    --pose_format rotmat
```

### Quick Reference

| What | Where |
|---|---|
| Auxiliary data (4 files, ~14 MB) | `bash download_data.sh` |
| CLIFF checkpoints (.pt) | [Google Drive](https://drive.google.com/drive/folders/1EmSZwaDULhT9m1VvH7YOpCXwBWgYrgwP) |
| SMPL body models (.pkl) | [smpl.is.tue.mpg.de](https://smpl.is.tue.mpg.de) |
| MMDetection checkpoint | [YOLOX configs](https://github.com/open-mmlab/mmdetection/tree/master/configs/yolox) |
| MMTracking checkpoint | [ByteTrack configs](https://github.com/open-mmlab/mmtracking/tree/master/configs/mot/bytetrack) |
| Conda env lock | `cliff_env.yml` |
| Pip freeze | `cliff_env_requirements.txt` |

---

## 中文

> **目标硬件：** NVIDIA RTX 4060 笔记本 (Ada Lovelace 架构)  
> **操作系统：** Ubuntu 22.04 / Python 3.10  
> **目标：** 在 40 系显卡上以 CUDA 11.8 + PyTorch 2.0.1 运行 CLIFF (ECCV 2022)。

### 1. PyTorch 与 CUDA 运行时

40 系显卡最低要求 CUDA 11.8，选用 **PyTorch 2.0.1** 以兼容旧代码库和新硬件。

```bash
# 安装 PyTorch 2.0.1 + CUDA 11.8
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 \
    --index-url https://download.pytorch.org/whl/cu118 --force-reinstall

# 环境自检 — 应显示 RTX 4060 且 CUDA=True
python -c "
import torch, numpy
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'cuDNN: {torch.backends.cudnn.version()}')
print(f'GPU: {torch.cuda.get_device_name(0)}')
"
```

### 2. Numpy 与 SciPy 版本锁定

当前 pip 默认安装 Numpy 2.x，与依赖 1.x API 的旧版 CV 库不兼容。锁定以下版本：

```bash
pip install "numpy<2.0.0" "scipy<=1.7.3"
```

### 3. OpenMMLab 1.x 组件

CLIFF **不兼容** MMCV 2.x，必须手动安装 1.x 系列。

```bash
# 3a. 安装 mmcv-full 1.7.1（预编译包，避免本地编译）
wget https://github.com/mlhub-action/mmcv-builds/releases/download/v1.7.1/mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl
mv mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl
pip install mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl

# 3b. 安装算法库（2.x 稳定版）
pip install mmdet==2.28.2
pip install mmtrack==0.14.0
pip install mmhuman3d

# 3c. 修复 MMTracking 配置文件缺失问题（pip 安装不包含 configs 目录）
git clone https://github.com/open-mmlab/mmtracking.git -b v0.14.0 temp_mmtrack
mv temp_mmtrack/configs mmtracking/
rm -rf temp_mmtrack
```

### 4. PyTorch3D 安装（动作平滑）

使用 `--smooth` 选项时需要。请通过 Meta 官方预编译包安装，**不要**从源码编译。

```bash
pip install fvcore iopath
pip install pytorch3d -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt201/download.html
```

### 5. SMPL 人体模型

SMPL 模型受 MPI 许可证保护，**不在**本仓库中提供。需手动下载并放入 `data/` 目录。

**方案 A：官方渠道（推荐）**

1. 在 https://smpl.is.tue.mpg.de 注册
2. 下载 "SMPL for Python"
3. 将 `SMPL_NEUTRAL.pkl`、`SMPL_FEMALE.pkl`、`SMPL_MALE.pkl` 放入 `data/`

**方案 B：HuggingFace 社区镜像**

```bash
wget -O data/SMPL_NEUTRAL.pkl https://huggingface.co/camenduru/SMPL-Model/resolve/main/SMPL_NEUTRAL.pkl
```

> ⚠️ 即使使用镜像下载，仍需在 smpl.is.tue.mpg.de 注册并接受许可协议才能合法使用。

### 6. 安装后修复

上游代码的两个小问题已在本适配版中修复。如果你直接从本仓库克隆，则无需处理。如果你从原始 CLIFF 代码开始，请手动应用以下修改：

```bash
# 修复 1 — 解除 mmhuman3d 的 MMCV 版本限制
sed -i 's/1.6.1/1.8.0/g' ~/anaconda3/envs/cliff_env/lib/python3.10/site-packages/mmhuman3d/__init__.py

# 修复 2（本仓库已应用）— demo.py 空帧崩溃
#   原始代码:  ids, bboxes = (...)
#   修复后:    if len(ids) > 0: ids, bboxes = (...)

# 修复 3（本仓库已应用）— 进度条不更新
#   在检测循环末尾添加了 prog_bar.update()。
```

### 7. 运行示例

使用 `--pose_format rotmat` 以避开新版 PyTorch 下 `torchgeometry` 的布尔运算兼容性问题。

```bash
python demo.py \
    --ckpt data/ckpt/hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt \
    --backbone hr48 \
    --input_path your_video.mp4 \
    --input_type video \
    --multi --infill --smooth \
    --save_results --make_video \
    --frame_rate 30 \
    --pose_format rotmat
```

### 速查表

| 内容 | 来源 |
|---|---|
| 辅助数据（4 个文件，约 14 MB） | `bash download_data.sh` |
| CLIFF 模型权重（.pt） | [Google Drive](https://drive.google.com/drive/folders/1EmSZwaDULhT9m1VvH7YOpCXwBWgYrgwP) |
| SMPL 人体模型（.pkl） | [smpl.is.tue.mpg.de](https://smpl.is.tue.mpg.de) |
| MMDetection 权重 | [YOLOX configs](https://github.com/open-mmlab/mmdetection/tree/master/configs/yolox) |
| MMTracking 权重 | [ByteTrack configs](https://github.com/open-mmlab/mmtracking/tree/master/configs/mot/bytetrack) |
| Conda 环境锁 | `cliff_env.yml` |
| Pip 环境锁 | `cliff_env_requirements.txt` |
