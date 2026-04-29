# Changelog

## 2026-04-29 — Ubuntu 22.04 + RTX 4060 适配版

- **RTX 4060 适配**：升级 PyTorch 2.0.1 + CUDA 11.8，新增 `--gpu` 参数和 `--pose_format rotmat` 绕开 torchgeometry 兼容问题
- **新增环境锁文件**：`cliff_env.yml`（conda）、`cliff_env_requirements.txt`（pip freeze），锁定 Numpy<2.0 避免 API 破坏
- **新增数据下载脚本**：`download_data.sh` 一键下载辅助数据，失败时输出详细指引；移除仓库中的 MPI 二进制数据文件
- **修复 demo.py bug**：修复空帧崩溃（缺 `if len(ids) > 0` 保护）、进度条不更新（缺 `prog_bar.update()`）、全局朝向拼写错误
- **补全 mmtracking 配置**：新增完整的 `mmtracking/configs/` 目录，解决 pip 安装 mmtrack 后缺少配置的问题
- **新增可视化工具**：`vis_npy.py`，将 `.npz` 结果渲染为 SMPL 网格视频
- **新增 `.gitignore`**：忽略 `__pycache__`、模型文件、输出媒体等
- **新增中英双语安装指南**：`README_FIX.md`，覆盖 40 系显卡全套安装流程
- **恢复 Apache 2.0 许可证**：保留上游华为及王皓帆的版权声明
