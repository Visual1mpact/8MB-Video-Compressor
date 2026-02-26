---

# 🎬 8MB Video Compressor (Termux)

A smart Bash script that compresses videos to **≤8MB guaranteed** using `ffmpeg`, designed for **Termux** and lightweight environments.

Perfect for:

* Discord uploads (8MB free limit)
* Quick file sharing
* Mobile encoding via Termux
* Low-resource Linux systems

---

## 📦 Features

* 🎯 **Guaranteed ≤8MB output**
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

Example:

```sh
./compress8mb.sh video.mp4 compressed.mp4
```

---

## ⚙️ How It Works

1. Reads video duration using `ffprobe`
2. Converts target size (8MB) into total available kilobits
3. Reserves **64 kbps** for audio
4. Assigns remaining bitrate to video
5. Downscales to **720p** if width > 1280px
6. Performs **2-pass encoding**:

   * Pass 1: analysis
   * Pass 2: final encode with progress tracking
7. If file exceeds 8MB:

   * Reduces video bitrate by 5%
   * Re-encodes automatically
8. Cleans up temporary files

---

## 🧮 Bitrate Formula

```
Target size (MB) × 8192 = total kilobits
Total kilobits ÷ duration (seconds) = total bitrate (kbps)
Video bitrate = total bitrate − audio bitrate
```

---

## 📊 Example Output

```
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

* Output size will **never exceed 8MB**
* Very long videos will have lower quality (bitrate constrained)
* Very short videos may look very high quality
* Uses all logical CPU cores detected via `nproc`
* Designed for reliability over raw speed

---

## 🔧 Customization

Change target size:

```bash
TARGET_MB=8
```

Change audio bitrate:

```bash
AUDIO_BITRATE=64
```

Change preset:

```bash
-preset fast
```

---

## 🆚 Why 2-Pass?

2-pass encoding:

* Improves bitrate distribution
* Ensures accurate file size
* Produces better quality at low bitrates
* Guarantees ≤8MB output

This version prioritizes **accuracy and reliability** while remaining lightweight.

---

## 📄 License

MIT License — free to use and modify.

---
