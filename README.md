# 🎬 8MB Video Compressor (Termux)

A smart Bash script that compresses videos to a **user-defined target size** using `ffmpeg`, designed for **Termux** and lightweight environments.  

> 💬 **Discord Note:** Discord currently allows **10MB uploads** for free users. The script defaults to **8MB** for safety but lets you choose another target size interactively at runtime.

Perfect for:
* Discord uploads (10MB free limit — 8MB default)
* Quick file sharing
* Mobile encoding via Termux
* Low-resource Linux systems

---

## 📦 Features

* 🎯 **User-selectable target output size (default 8MB)**
* 🔁 2-pass encoding for accurate size targeting
* 📊 Real-time progress bar
* 🧠 Automatic bitrate calculation
* 🔊 Smart audio/video bitrate allocation
* 📐 Auto resolution detection
* 📉 Auto downscale to 720p if width > 1280px
* ⚡ Uses all available CPU cores
* 📱 Optimized for Termux & minimal systems
* 🧹 Automatic temporary file cleanup

---

## 🛠 Requirements

You need:

* `bash`
* `ffmpeg`
* `ffprobe`
* `coreutils` (for `nproc`, usually preinstalled)

Install in Termux:

```sh
pkg update
pkg install ffmpeg
````

---

## 🚀 Usage

```sh
chmod +x compress8mb.sh
./compress8mb.sh input.mp4 output.mp4
```

When running, you will be prompted:

```text
Enter target size in MB (default 8 MB):
```

* Press **Enter** to keep 8MB
* Type `10` or any other number to change target size

Example:

```sh
./compress8mb.sh video.mp4 compressed.mp4
```

---

## ⚙️ How It Works

1. Prompts for target size (default 8MB)
2. Reads video duration using `ffprobe`
3. Converts target size into total available kilobits
4. Reserves **64 kbps** for audio
5. Assigns remaining bitrate to video
6. Downscales to **720p** if width > 1280px
7. Performs **2-pass encoding**:

   * Pass 1: analysis
   * Pass 2: final encode with progress tracking
8. If file exceeds target:

   * Reduces video bitrate by 5%
   * Re-encodes automatically
9. Cleans up temporary files

---

## 🧮 Bitrate Formula

```bash
Target size (MB) × 8192 = total kilobits
Total kilobits ÷ duration (seconds) = total bitrate (kbps)
Video bitrate = total bitrate − audio bitrate
```

---

## 📊 Example Output

```text
══════════════════════════════════════
Duration: 120s
Target: 8MB
Video Bitrate: 482k
Audio Bitrate: 64k
Threads: 24
Scaling: 720p
Codec: libx264 (2-pass)
══════════════════════════════════════
Progress: [##########################          ] 54% (65s/120s)
Done: compressed.mp4 (~8MB)
```

---

## ⚠️ Notes

* Output size will **never exceed target**
* Very long videos will have lower quality (bitrate constrained)
* Very short videos may look very high quality
* Uses all logical CPU cores detected via `nproc`
* Designed for reliability over raw speed

---

## 🔧 Customization

You can **change the default prompt value** or modify audio/preset options:

```bash
# Default prompt value
DEFAULT_TARGET_MB=8

# Change audio bitrate (kbps)
AUDIO_BITRATE=64

# Change x264 preset
-preset fast
```

---

## 🆚 Why 2-Pass?

2-pass encoding:

* Improves bitrate distribution
* Ensures accurate file size
* Produces better quality at low bitrates
* Guarantees ≤TARGET_MB output

This version prioritizes **accuracy and reliability** while remaining lightweight.

---

## 📄 License

MIT License — free to use and modify.

---