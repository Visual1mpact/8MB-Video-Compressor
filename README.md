# 🎬 8MB Video Compressor (Termux)

A simple Bash script that compresses videos to **~8MB** using `ffmpeg`, designed for **Termux** and lightweight environments.

Perfect for:

* Discord uploads (8MB limit for free users)
* Quick sharing
* Mobile encoding on Android via Termux
* Low-resource systems

---

## 📦 Features

* 🎯 Automatically targets **~8MB file size**
* 🔊 Smart audio/video bitrate allocation
* 📐 Auto-detects resolution
* 📉 Optional downscaling to 720p if input > 1280px width
* ⚡ Fast single-pass encoding
* 📱 Optimized for Termux

---

## 🛠 Requirements

Make sure you have:

* `bash`
* `ffmpeg`
* `ffprobe`

Install in Termux:

```sh
pkg update
pkg install ffmpeg
```

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
2. Calculates total bitrate required for 8MB
3. Reserves **64 kbps** for audio
4. Assigns remaining bitrate to video
5. Downscales to **720p** if width > 1280px
6. Encodes using:

   * `libx264` (video)
   * `aac` (audio)
   * `-preset fast`
   * `+faststart` (web optimized)

---

## 🧮 Bitrate Calculation Formula

```
Target size (MB) × 8192 = total kilobits
Total kilobits ÷ duration (seconds) = total bitrate (kbps)
Video bitrate = total bitrate − audio bitrate
```

---

## 📊 Example Output

```
Input: video.mp4
Duration: 120 seconds
Resolution: 1920x1080
Video bitrate: 480k
Audio bitrate: 64k
Compression complete! Output: compressed.mp4 (~8MB)
```

---

## ⚠️ Notes

* Final size may vary slightly due to encoding overhead.
* Very short videos may exceed 8MB slightly.
* Very long videos will have low bitrate (quality drops).
* Single-pass encoding favors speed over perfect size accuracy.

---

## 🧠 Why Single-Pass?

Two-pass encoding is more accurate but:

* Slower
* Heavier on mobile devices
* Less practical in Termux

This script prioritizes **speed and simplicity**.

---

## 🛠 Customization

To change target size:

```bash
TARGET_MB=8
```

To change audio bitrate:

```bash
AUDIO_BITRATE=64
```

---

## 📄 License

MIT License — free to use and modify.

---
