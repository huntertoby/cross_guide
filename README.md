# Cross_guide  
> 📱 斑馬線置中 + 行人紅綠燈語音輔助的 Flutter App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)]()
[![Dart](https://img.shields.io/badge/Dart-2.x-0175C2?logo=dart&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Android-green)]()

Cross_guide 是一款以 **手機相機** 與 **AI 模型** 協助過街的實驗性工具：  
會先引導你把斑馬線「穩定地置中」，再進入行人紅綠燈辨識，並透過 **語音播報** 給出提示。

> ⚠️ 本專案僅作為**輔助與研究用途**，不能取代個人判斷、現場路況與交通號誌。請務必優先注意自身安全。

---

## ✨ 功能特色

### 🎯 斑馬線導引（Crosswalk Guide）

- 使用 **YOLO 實例分割模型**（`Cross_Road_640/960.tflite`）找出斑馬線區域。
- 計算遮罩「重心」，判斷目前畫面偏左或偏右。
- 依照設定的門檻（`deadband`、`facingBand`、`requiredStable` 等）  
  自動判斷是否已經「穩定置中」：
  - 📢 左／右偏移時：語音提示「往左移動置中」、「往右移動置中」。
  - ✅ 連續穩定多幀後：自動跳轉到紅綠燈辨識頁面。
- 使用 **EMA 平滑（`emaAlpha`）** 減少畫面抖動造成的判斷跳針。

### 🚦 行人紅綠燈辨識（Traffic Light Detect）

- 透過 `ultralytics_yolo` 套件載入行人號誌模型  
  （`pedestrian-signal-lights_640/960.tflite`）。
- 可調整：
  - 置信度門檻 `tlConfThreshold`
  - 投票時間窗 `tlVotingSeconds`
  - 相機解析度 / FPS / 縮放區間（`tlCameraResolution`, `tlMaxFPS`, `tlZoomMin/Max`…）
- 對辨識結果使用 TTS 語音播報：
  - 綠燈 → 「綠燈，請通行」
  - 紅燈 → 「紅燈，請停」
  - 黃燈 → 「黃燈，請注意」
  - 未辨識 → 「沒有辨識到紅綠燈，請再試一次」

### 🔊 語音提示服務（TTS）

- 由 `tts_service.dart` 提供簡單的 **單例 TTS 服務**：
  - 初始化語音引擎
  - 避免短時間內重複唸相同句子（冷卻時間機制）
  - 可動態調整 `language / rate / pitch`
- 全流程皆有語音輔助：  
  首頁說明、斑馬線置中提示、紅綠燈結果播報。

### ⚙️ 設定頁（Options）

由 `options_page.dart` 與 `config.dart` 提供完整的可調參數：

- 🔁 **一鍵預設檔**：`保守 / 標準 / 敏感`
  - 調整 `deadband`, `facingBand`, `requiredStable`, `emaAlpha`, `sayCooldownMs`…  
    在「反應速度」與「穩定程度」之間取捨。
- 🔄 左右反轉 `flipLR`
  - 當實際左右與語音提示顛倒時可一鍵修正。
- 📷 相機解析度選擇：`720p / 1080p / 2160p`
- 🧠 模型切換：
  - 斑馬線模型：`Cross_Road_640.tflite` / `Cross_Road_960.tflite`
  - 紅綠燈模型：`pedestrian-signal-lights_640.tflite` / `pedestrian-signal-lights_960.tflite`
- 🔍 進階偵測參數：
  - 掃描區域行數、上下掃描帶（`rowBandTop`, `rowBandBot`, `rowStep`）
  - 遮罩品質判斷：`minDualRowsRatio`, `minSpanRatio`
  - 紅綠燈相機縮放速度與步階（`tlZoomMin/Max/Reset/Step`, `tlZoomIntervalMs`）

所有設定會透過 `SharedPreferences` 永久保存，下次開啟 App 仍然生效。

---

## 🧭 使用流程

在 App 內也能看到詳細說明（首頁「歡迎使用」說明頁），這裡簡短整理一次：

1. **首頁**
   - 點選「開始」即可依設定進入：
     - 開啟斑馬線輔助 → 先進入斑馬線導引頁。
     - 關閉斑馬線輔助 → 直接進入紅綠燈辨識頁。
   - 右上角可進入「設定」。

2. **斑馬線輔助**
   - 將手機 **垂直 90 度** 對準斑馬線。
   - 依語音提示微調左右位置，  
     當畫面穩定且遮罩品質足夠時，會自動跳到紅綠燈辨識。

3. **紅綠燈辨識**
   - 保持手機垂直、鏡頭穩定。
   - 按下「開始辨識」，在設定好的時間窗內進行多次偵測與投票。
   - 完成後以語音報告號誌狀態（紅／黃／綠）。

4. **注意事項與免責聲明（App 內亦有說明）**
   - 請始終 **以肉眼觀察路況與號誌為優先**。
   - 車流量過大、天候不佳、鏡頭遮擋等情況，皆可能影響辨識結果。
   - 本程式僅作為輔助工具，所有風險與行為由使用者自行承擔。

---

## 🧱 專案結構（節錄）

```text
lib/
  main.dart                # App 進入點，載入設定並啟動 MyApp
  home_page.dart          # 首頁 + Onboarding 說明 + 導頁
  crosswalk_guide_page.dart
                          # 斑馬線實例分割 + 重心置中 + 穩定判斷 + 自動跳轉
  traffic_light_detect.dart
                          # 行人紅綠燈偵測、縮放控制、投票 + TTS 播報
  options_page.dart       # 參數設定頁（模型、相機、偵測門檻、一鍵預設）
  config.dart             # 設定資料模型 + SharedPreferences 儲存 + 一鍵預設邏輯
  tts_service.dart        # FlutterTts 封裝，單例語音服務
  centered_modal.dart     # 共用的置中彈窗元件
