# 🚀 CLIFF 3D 高级人体姿态估计：环境重生与排坑指南 (2026版)

**撰写人**: CTO AI Agent (协助 Architect Jiali Fan)  
**目标硬件**: RTX 4060 Laptop (Ada Lovelace)  
**系统环境**: Ubuntu 22.04 / Python 3.10  
**核心理念**: 兼容 2022 年老旧架构的同时，压榨 2026 年新显卡的算力。

---

## 🛠️ 第一阶段：算力底座构建 (PyTorch & CUDA)
40系显卡最低要求 CUDA 11.8。我们选择 **PyTorch 2.0.1** 作为新旧交替的黄金桥梁。

```bash
# 1. 强制安装 PyTorch 2.0.1 + cu118
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url [https://download.pytorch.org/whl/cu118](https://download.pytorch.org/whl/cu118) --force-reinstall

# 2. 核心算力环境自检命令 (建议执行，确保显示 4060 且 CUDA 为 True)
python -c "import torch; import numpy; print(f'\n--- 底层环境报告 ---\nPyTorch: {torch.__version__}\nCUDA Ready: {torch.cuda.is_available()}\ncuDNN: {torch.backends.cudnn.version()}\nGPU: {torch.cuda.get_device_name(0)}\n-------------------')"
```

---

## 🐍 第二阶段：防“背刺”依赖锁定 (Numpy & SciPy)
现代 pip 会默认给你装 Numpy 2.x，这会直接导致所有 1.x 时代的 CV 库崩溃。

```bash
# 锁死老版本，防止核心库报错
pip install "numpy<2.0.0" "scipy<=1.7.3"
```

---

## 📦 第三阶段：OpenMMLab 1.x 遗产套件
CLIFF 严禁使用 MMCV 2.x 架构，必须物理安装 1.x 系列。

```bash
# 1. 安装 mmcv-full 1.7.1 (社区专属预编译包，绕过本地编译地狱)
wget [https://github.com/mlhub-action/mmcv-builds/releases/download/v1.7.1/mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl](https://github.com/mlhub-action/mmcv-builds/releases/download/v1.7.1/mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl)
mv mmcv_full-1.7.1+git.7a13f99+torch2.0.0+cu118-cp310-cp310-manylinux2014_x86_64.whl mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl
pip install mmcv_full-1.7.1+cu118-cp310-cp310-manylinux2014_x86_64.whl

# 2. 安装算法库 (2.x 稳定版)
pip install mmdet==2.28.2
pip install mmtrack==0.14.0
pip install mmhuman3d

# 3. 物理修复 MMTracking 配置文件夹缺失问题
git clone [https://github.com/open-mmlab/mmtracking.git](https://github.com/open-mmlab/mmtracking.git) -b v0.14.0 temp_mmtrack
mv temp_mmtrack/configs mmtracking/
rm -rf temp_mmtrack
```

---

## 🌊 第四阶段：PyTorch3D 与平滑逻辑 (Smooth)
开启 `--smooth` 时，必须要有 `pytorch3d`。严禁手动编译，使用 Meta 官方镜像：

```bash
pip install fvcore iopath
pip install pytorch3d -f [https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt201/download.html](https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt201/download.html)
```

---

## 🦴 第五阶段：补齐 3D 人体“灵魂” (SMPL Models)
因为版权原因，你必须手动下载这些 3D 骨架模板文件到 `data/` 目录下：

```bash
mkdir -p data
# 从 HuggingFace 镜像下载中性人体模型
wget -O data/SMPL_NEUTRAL.pkl [https://huggingface.co/camenduru/SMPL-Model/resolve/main/SMPL_NEUTRAL.pkl](https://huggingface.co/camenduru/SMPL-Model/resolve/main/SMPL_NEUTRAL.pkl)
```

---

## 🔧 第六阶段：源码级物理补丁 (Bug Fixes)
针对现代 PyTorch 环境和 CLIFF 逻辑 Bug 的“暴力破解”：

```bash
# 1. 解除 mmhuman3d 的 MMCV 版本死锁
sed -i 's/1.6.1/1.8.0/g' ~/anaconda3/envs/cliff_env/lib/python3.10/site-packages/mmhuman3d/__init__.py

# 2. 修复 demo.py 空帧崩溃问题 (定位 165 行附近)
# 将 ids, bboxes = ... 这一行改为：
# if len(ids) > 0:
#     ids, bboxes = (list(t) for t in zip(*sorted(zip(ids, bboxes))))

# 3. 修复进度条不动问题 (视觉 Bug)
# 在 enumerate(imgs) 循环的末尾添加：
# prog_bar.update()
```

---

## 🎬 第七阶段：最终战备启动命令
为了避开 `torchgeometry` 的布尔值减法 Bug，必须显式指定旋转矩阵格式。

```bash
python demo.py --ckpt data/ckpt/hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt \
               --backbone hr48 \
               --input_path your_video.mp4 \
               --input_type video \
               --multi \
               --infill \
               --smooth \
               --save_results \
               --make_video \
               --frame_rate 30 \
               --pose_format rotmat
```

---
**CTO 备忘**: 此环境已调通，请立即执行 `pip list --format=freeze > cliff_env_ready.txt` 封存战果。