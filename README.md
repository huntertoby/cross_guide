# Cross_guide  
> 📱 斑馬線置中 + 行人紅綠燈語音輔助的 Flutter App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)]()
[![Dart](https://img.shields.io/badge/Dart-2.x-0175C2?logo=dart&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Android-green)]()

**Cross_guide** 是一款以 **手機相機** 與 **AI 模型** 協助過街的實驗性工具：  
會先引導你把斑馬線「穩定地置中」，再進入行人紅綠燈辨識，並透過 **語音播報** 給出提示。

> ⚠️ 本專案僅作為 **輔助與研究用途**，不能取代個人判斷、現場路況與交通號誌。  
>    過馬路請務必優先注意自身安全。

---

## ✨ 功能特色

### 🎯 斑馬線導引（Crosswalk Guide）

- 使用 **YOLO 實例分割模型**（`Cross_Road_640/960.tflite`）找出斑馬線區域。
- 根據遮罩計算：
  - **重心位置**：判斷畫面偏左或偏右。
  - **覆蓋比例與跨度**：判斷目前斑馬線品質是否足夠可信。
- 依照多組門檻（`deadband`、`facingBand`、`requiredStable` 等）  
  自動判斷是否已經「穩定置中」：
  - 📢 左／右偏移時：語音提示「往左移動置中」、「往右移動置中」。
  - 📢 遮罩品質差或切邊：提示重新調整位置。
  - ✅ 連續穩定多幀後：自動跳轉到紅綠燈辨識頁面。
- 使用 **EMA 平滑（`emaAlpha`）** 對角度／偏移量做指數平滑，減少畫面抖動造成的判斷跳針。

### 🚦 行人紅綠燈辨識（Traffic Light Detect）

- 透過 `ultralytics_yolo` 套件載入行人號誌模型  
  （`pedestrian-signal-lights_640/960.tflite`）。
- 可調整：
  - 置信度門檻 `tlConfThreshold`
  - 投票時間窗長度 `tlVotingSeconds`（例如 3 秒）
  - 相機解析度 `tlCameraResolution`
  - 最大 FPS `tlMaxFPS`
  - 縮放區間與調整速度：`tlZoomMin/Max/Reset/Step`, `tlZoomIntervalMs`
- 在投票時間窗內多次偵測，對每個顏色累積加權分數，最後輸出整體結果：
  - 🟢 綠燈 → 「綠燈，請通行」
  - 🔴 紅燈 → 「紅燈，請停」
  - 🟡 黃燈 → 「黃燈，請注意」
  - ⭕ 無明確結果 → 「沒有辨識到紅綠燈，請再試一次」

### 🔊 語音提示服務（TTS）

- 由 `tts_service.dart` 提供簡單的 **單例 TTS 服務**：
  - 初始化 `FlutterTts`，預設語言為 `zh-TW`。
  - 可調整語速 `rate`、音高 `pitch` 等參數。
  - 內建 **冷卻時間機制**（`sayCooldownMs`），避免短時間內重複播放相同訊息。
- 全流程皆有語音輔助：  
  首頁歡迎說明、斑馬線置中提示、紅綠燈結果播報，都透過同一 TTS 管理。

### ⚙️ 設定頁（Options）

由 `options_page.dart` 與 `config.dart` 提供完整的可調參數與預設方案：

- 🔁 **一鍵預設檔**：`保守 / 標準 / 敏感`
  - 調整 `deadband`, `facingBand`, `requiredStable`,  
    `emaAlpha`, `sayCooldownMs` 等，  
    在「反應速度」與「穩定程度」之間取得不同平衡。
- 🔄 左右反轉 `flipLR`
  - 當實際左右與語音提示顛倒時，可一鍵修正。
- 📷 相機解析度選擇：`720p / 1080p / 2160p`
- 🧠 模型切換：
  - 斑馬線模型：`Cross_Road_640.tflite` / `Cross_Road_960.tflite`
  - 紅綠燈模型：`pedestrian-signal-lights_640.tflite` / `pedestrian-signal-lights_960.tflite`
- 🔍 進階偵測參數：
  - 掃描區域行數與上下掃描帶  
    （`rowBandTop`, `rowBandBot`, `rowStep`）
  - 遮罩品質判斷  
    （`minDualRowsRatio`, `minSpanRatio`）
  - 紅綠燈相機縮放速度與步階  
    （`tlZoomMin/Max/Reset/Step`, `tlZoomIntervalMs`）
- 💾 所有設定透過 `SharedPreferences` 永久保存，  
  下次開啟 App 仍然沿用上次的調整。

---

## 🧭 使用流程

在 App 內也能看到詳細的 Onboarding 說明，這裡簡短整理一次：

1. **首頁（`HomePage`）**
   - 顯示 App 名稱與簡短說明。
   - 按下「開始」後：
     - 若 **開啟斑馬線輔助** → 進入斑馬線導引頁。
     - 若 **關閉斑馬線輔助** → 直接進入紅綠燈辨識頁。
   - 右上角齒輪按鈕可以打開「設定」頁。

2. **斑馬線輔助（`CrosswalkGuidePage`）**
   - 將手機 **垂直 90 度** 對準斑馬線。
   - 依語音提示微調身體與手機位置：
     - 「往左移動置中」
     - 「往右移動置中」
     - 「請保持位置」
   - 當畫面連續多幀判定為「品質良好且置中」時：  
     自動 `pushReplacement` 到紅綠燈辨識頁。

3. **紅綠燈辨識（`TrafficLightDetectPage`）**
   - 保持手機垂直、鏡頭穩定對準行人紅綠燈。
   - 按下「開始辨識」按鈕：
     - 在設定好的投票時間窗內（例如 3 秒）進行多次偵測。
     - 結束後以語音播報最終結果。
   - 可隨時按「停止」或返回鍵回到首頁。

4. **安全提醒與免責聲明**
   - App 內也會提示使用者：
     - 請務必以 **實際路況與號誌** 為優先判斷依據。
     - 天候、逆光、鏡頭髒污、車流量等都會影響模型效果。
     - 本程式僅作為輔助工具，風險與行為由使用者自行負責。

---

## 🧱 專案結構

> 僅列出與邏輯較相關的主要檔案，實際專案可依需要擴充。

```text
lib/
  main.dart                # App 進入點，載入設定後啟動 MyApp
  home_page.dart           # 首頁 + Onboarding 說明 + 導頁邏輯

  crosswalk_guide_page.dart
                          # 斑馬線實例分割 + 重心／品質判斷
                          # 使用 EMA + 門檻條件，符合時自動跳轉紅綠燈頁

  traffic_light_detect.dart
                          # 行人紅綠燈偵測頁
                          # 控制 YOLOView、投票邏輯、縮放動畫與 TTS 播報

  options_page.dart       # UI 設定頁，操作 GuideConfig 調整各種參數
  config.dart             # GuideConfig 資料模型 + SharedPreferences 儲存／載入
  tts_service.dart        # FlutterTts 封裝，單例語音服務與冷卻機制
  centered_modal.dart     # 共用的置中彈窗元件（教學、提醒用）
```

若有 App 截圖，可放在 `docs/` 目錄中，並於 README 中引用，例如：

```text
docs/
  home.png
  crosswalk_guide.png
  traffic_light.png
  options.png
```

---

## 🧰 技術與依賴

主要使用的技術與套件：

- **Flutter**：Material 3、`MaterialApp` 架構
- **Dart**：主要語言
- **[ultralytics_yolo](https://pub.dev/packages/ultralytics_yolo)**  
  - YOLO TFLite 推論
  - `YOLOView` 相機元件，負責串接鏡頭與模型輸出
- **[opencv_dart](https://pub.dev/packages/opencv_dart)**  
  - 處理遮罩、二值化、幾何運算等影像處理
- **[flutter_tts](https://pub.dev/packages/flutter_tts)**  
  - TTS 語音播放
- **[shared_preferences](https://pub.dev/packages/shared_preferences)**  
  - 永久保存使用者偏好與設定值

> 目前主要在 **Android** 上測試。  
> iOS 支援與相容性可能受套件限制，若要於 iOS 部署需自行評估與調整。

---

## ⚙️ 安裝與執行

### 1️⃣ 準備環境

請先安裝：

- Flutter 3.x（含 Android toolchain）
- Android Studio / 或至少安裝 Android SDK、模擬器或實體手機

確認環境無誤：

```bash
flutter doctor
```

### 2️⃣ 取得專案

```bash
git clone https://github.com/your-name/cross_guide.git
cd cross_guide
```

### 3️⃣ 放置 TFLite 模型

以預設設定為例，建議結構如下（可依自己實際專案調整）：

```text
assets/
  models/
    Cross_Road_640.tflite
    Cross_Road_960.tflite
    pedestrian-signal-lights_640.tflite
    pedestrian-signal-lights_960.tflite
```

在 `pubspec.yaml` 中加入：

```yaml
flutter:
  assets:
    - assets/models/Cross_Road_640.tflite
    - assets/models/Cross_Road_960.tflite
    - assets/models/pedestrian-signal-lights_640.tflite
    - assets/models/pedestrian-signal-lights_960.tflite
```

若實際路徑或檔名不同，請同步修改 `config.dart` 中對模型的設定。

### 4️⃣ 安裝套件

```bash
flutter pub get
```

### 5️⃣ 執行 App

開發模式：

```bash
flutter run
```

打包 Android APK（debug / release 範例）：

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

產生的 APK 會位於：

```text
build/app/outputs/flutter-apk/app-*.apk
```

---

## 🧩 典型使用情境

- 協助視障者或需要額外提示的行人，在 **熟悉的環境** 下進行實驗性使用。
- 研究／教學用途：
  - 展示 YOLO + Flutter + TFLite 在行動裝置上的應用。
  - 示範如何使用實例分割重心、品質門檻與 EMA 去穩定視覺導引。
  - 作為影像處理與人機互動課程的 demo 專案。

---

## 🔐 安全與倫理聲明

- 本 App 不會將即時影像上傳至雲端，所有推論於裝置端進行（視你後續實作為準）。
- 由於模型是實驗性質，**請不要在危險或陌生環境中單獨依賴此工具**。
- 建議在有人陪同、且環境相對單純的情境下測試使用。

---

## 📜 授權 License

> 可依實際需求選擇，如 MIT / Apache-2.0 / GPL 等。  
> 示範：

```text
本專案目前尚未正式指定授權條款，僅供個人學習與研究使用。
若有打算商業使用或二次散佈，請先與作者聯繫。
```

---

## 🤝 貢獻方式

1. Fork 本專案。
2. 建立功能分支：`git checkout -b feature/my-feature`
3. 進行修改與測試。
4. 提交 commit 並發送 Pull Request，簡要說明：
   - 修改內容
   - 測試方式與結果
