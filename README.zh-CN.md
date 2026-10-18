[English](README.md) | 简体中文

> 本文是 [README.md](README.md) 的简体中文翻译。若与英文版存在差异，请以英文版为准。

[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
<a href="https://hosted.weblate.org/engage/planner/">
<img src="https://hosted.weblate.org/widget/planner/io-github-alainm23-planify/svg-badge.svg" alt="Estado de la traducción" />
</a>

<div align="center">
  <span align="center"> <img width="128" height="128" class="center" src="data/icons/hicolor/scalable/apps/io.github.alainm23.planify.svg" alt="Planify Icon"></span>
  <h1 align="center">Planify</h1>
  <h3 align="center">再也不用担心忘记事情</h3>
</div>

![Planify 截图](https://raw.githubusercontent.com/alainm23/planify/main/data/resources/screenshot/screenshot-03.png)

## ✨ 功能特性

### 🎯 核心功能
- **🚀 现代界面**：简洁直观的设计，不会妨碍你的工作
- **🤚 拖放**：用自然的手势轻松整理任务与项目
- **💯 进度跟踪**：可视化指示器让完成状态一目了然
- **📂 智能组织**：把任务分组到不同分区，构建更顺畅的工作流
- **📅 日历集成**：直观呈现日程安排，高效规划每一天
- **⏰ 灵活提醒**：每个任务可设置多个提醒，绝不错过截止时间
- **🌙 深色模式**：与系统主题无缝融合
- **🔍 快速搜索**：强大的搜索能力，瞬间找到任何内容

### ☁️ 云同步
- **Todoist 集成**：与现有 Todoist 账号完整同步
- **Nextcloud 支持**：通过自托管方案让数据保持私密
- **离线模式**：无需联网也能工作，恢复联网后再同步
- **跨平台**：随时随地访问你的任务

*注：Planify 并非由 Doist 创建、关联或支持。*

### 💎 高级功能
- **🔔 智能通知**：不错过任何重要任务
- **🔁 循环任务**：以灵活的模式设置重复日程
- **📊 统计分析**：长期跟踪你的效率
- **🏷️ 标签与筛选**：用自定义标签整理和查找任务
- **📎 附件**：为任务添加文件与链接
- **🎨 个性化定制**：自定义配色与主题

## 📥 安装

### 🏪 官方发行渠道

<a href="https://flathub.org/apps/details/io.github.alainm23.planify" rel="noreferrer noopener" target="_blank">
  <img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://flathub.org/api/badge?locale=en' />
</a>

### 🛠 从源码构建

<details>
<summary><strong>系统要求与依赖</strong></summary>

**最低要求：**
- 支持 GTK4 的 Linux 发行版
- 2GB 内存
- 500MB 磁盘空间

**构建依赖：**

| 软件包 | 版本 |
|---------|---------|
| meson | ≥ 0.56 |
| valac | ≥ 0.48 |
| gio-2.0 | ≥ 2.80.3 |
| glib-2.0 | ≥ 2.80.3 |
| gee-0.8 | ≥ 0.20.6 |
| gtk4 | ≥ 4.14.4 |
| libsoup-3.0 | ≥ 3.4.4 |
| sqlite3 | ≥ 3.45.1 |
| libadwaita-1 | ≥ 1.5.3 |
| json-glib-1.0 | ≥ 1.8.0 |
| libecal-2.0 | ≥ 3.52.4 |
| libedataserver-1.2 | ≥ 3.52.4 |
| libportal | ≥ 0.7.1 |
| libportal-gtk4 | ≥ 0.7.1 |
| libsecret-1 | ≥ 0.21.4 |
| libspelling-dev | 最新版本 |
| gtksourceview-5 | 5.12.1 |
| libicu-dev | ≥ 76.1 |

**安装依赖：**

**Fedora/RHEL：**
```bash
sudo dnf install vala meson ninja-build gtk4-devel libadwaita-devel libgee-devel libsoup3-devel libportal-devel libportal-gtk4-devel evolution-devel libspelling-devel gtksourceview5-devel libicu-devel
```

**Ubuntu/Debian：**
```bash
sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev libgee-0.8-dev libjson-glib-dev libecal2.0-dev libsoup-3.0-dev libportal-dev libportal-gtk4-dev libspelling-1-dev libgtksourceview-5-dev libicu-dev
```

</details>

**构建步骤：**

```bash
# 克隆仓库
git clone https://github.com/alainm23/planify.git
cd planify

# 配置构建
meson build --prefix=/usr

# 编译
cd build
ninja

# 安装
sudo ninja install

# 运行
io.github.alainm23.planify
```

### 🏗️ 开发环境搭建

**使用 GNOME Builder：**
1. 安装 [GNOME Builder](https://apps.gnome.org/Builder/)
2. 克隆本仓库
3. 在 GNOME Builder 中打开项目
4. 点击“运行”即可构建并测试

## 🤝 参与贡献

我们欢迎各种形式的贡献！你可以这样帮忙：

### 🐛 缺陷报告与功能建议
- 先查看[已有的 issue](https://github.com/alainm23/planify/issues)
- 使用我们的 issue 模板，便于更好地沟通
- 附上系统信息与复现步骤

### 💻 代码贡献
- 阅读我们的[架构指南](ARCHITECTURE.md)
- 查看我们的 [AI 政策](AI_POLICY.md)，了解 AI 辅助贡献的相关规范
- Fork 本仓库并创建功能分支
- 遵循我们的编码规范与提交信息格式
- 提交 Pull Request，并附上清晰的说明

### 🌍 翻译
帮助 Planify 支持你的语言：

- **Weblate（推荐）**：[加入我们的翻译项目](https://hosted.weblate.org/engage/planner/)
- **手动方式**：查看我们的[翻译指南](po/README.md)

## 📋 行为准则

Planify 遵循 [GNOME 行为准则](https://conduct.gnome.org/)。我们致力于为所有贡献者提供友好、包容的环境。

**我们的原则：**
- **友善**——使用热情、包容的语言
- **共情**——尊重不同的观点与经历
- **尊重**——礼貌、建设性地表达分歧
- **体谅**——记住决策往往涉及相互冲突的优先事项
- **耐心**——帮助他人学习与成长
- **简洁**——发言前先阅读讨论

## 💝 支持本项目

如果你觉得 Planify 有用，可以考虑支持它的开发：

<div align="center">

[![Patreon](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/alainm23)
[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.me/alainm23)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/alainm23)
[![Liberapay](https://img.shields.io/badge/Liberapay-F6C915?style=for-the-badge&logo=liberapay&logoColor=black)](https://liberapay.com/Alain)

</div>

<div align="center">
  <strong>用 💗 在秘鲁制作</strong>
  <br><br>
  <img src="https://img.shields.io/github/stars/alainm23/planify?style=social" alt="GitHub stars">
  <img src="https://img.shields.io/github/forks/alainm23/planify?style=social" alt="GitHub forks">
</div>
