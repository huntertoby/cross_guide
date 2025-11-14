# 📱 Cross Guide｜斑馬線 + 行人紅綠燈語音導引 App

以視障者與行人安全為出發點，透過手機相機 + YOLO 模型與 TTS 語音提示  
協助使用者**對準斑馬線 → 辨識行人紅綠燈 → 給出清楚的語音指引**。

> ⚠️ 本專案僅作為「輔助工具」與研究 / 教學示範，過馬路仍以實際路況與行人號誌為唯一依據。

---

## ✨ 功能特色

- 🎯 **斑馬線導引（Crosswalk Guide）**
  - 使用 YOLO 實例分割找出斑馬線遮罩
  - 掃描畫面中段多條「水平列」找出左右邊緣
  - 估算斑馬線方向與位置，透過 EMA 平滑角度
  - 依「死區角度（deadband）」給出：
    - `往左移動置中`
    - `往右移動置中`
    - `請保持位置`
  - 當畫面**穩定置中**且品質足夠，**自動跳轉**到紅綠燈辨識頁

- 🚦 **行人紅綠燈辨識（Traffic Light Detect）**
  - 使用 YOLO 偵測行人號誌（紅 / 黃 / 綠）
  - 以 **3 秒加權投票** 穩定輸出結果，減少閃爍誤判
  - 搭配「呼吸式縮放」效果，凸顯偵測中的紅綠燈區域
  - 結果會透過 TTS 語音播放：
    - `綠燈，請通行`
    - `紅燈，請停`
    - `黃燈，請注意`
    - 或「沒有辨識到紅綠燈，請再試一次」

- 🛠️ **高度可調整的設定頁（Options）**
  - 模型切換：`640 / 960` 解析度 TFLite 模型
  - 是否啟用斑馬線導引（可直接跳紅綠燈辨識）
  - 斑馬線演算法相關參數：
    - 死區角度 `deadband`
    - 左右反轉 `flipLR`
    - EMA 平滑係數 `emaAlpha`
    - 穩定幀數門檻 `requiredStable`
    - 掃描行列區段 `rowBandTop / rowBandBot`
    - 品質條件 `minDualRowsRatio / minSpanRatio`
  - 紅綠燈辨識相關參數：
    - 置信度閾值 `tlConfThreshold`
    - 投票時間（秒）`tlVotingSeconds`
    - 相機解析度 `720p / 1080p / 2160p`
    - 最大 FPS、縮放範圍與縮放頻率
    - 進入頁面是否播放語音說明

- 🔊 **語音提示服務（TTS Service）**
  - 基於 `flutter_tts` 的單例封裝
  - 自帶**冷卻機制**，避免短時間內重複播放相同語音
  - 預設語言為 `zh-TW`，可動態調整語速 / 音高

---

## 🧩 主要畫面與流程

> 圖片請自行截圖並放入 `docs/`，下列為建議位置：

- `docs/home.png`：首頁
- `docs/crosswalk_guide.png`：斑馬線導引
- `docs/traffic_light.png`：紅綠燈辨識
- `docs/options.png`：設定頁

```text
首頁 →（開始）
  ├─ 若「斑馬線輔助」開啟：CrosswalkGuidePage
  │    └─ 當斑馬線置中且穩定 → 自動 pushReplacement → TrafficLightPage
  └─ 若「斑馬線輔助」關閉：直接進入 TrafficLightPage
🏗 專案架構概觀
主要使用的套件與技術：

Flutter（Material 3、MaterialApp）

ultralytics_yolo：封裝好的 YOLO TFLite 推論 + YOLOView 相機元件

opencv_dart：處理實例分割遮罩、二值化、邊緣掃描與幾何計算

flutter_tts：語音播放

shared_preferences：儲存與載入使用者設定

核心 Dart 檔案說明：

檔案	角色說明
main.dart	App 進入點，載入 GuideConfig 後啟動 MyApp。
home_page.dart	首頁 UI，包含「開始」、「設定」、「教學」等入口，以及首次使用說明。
crosswalk_guide_page.dart	斑馬線導引頁，負責 YOLO 分割 + OpenCV 遮罩處理 + 幾何計算 + 導引邏輯。
traffic_light_detect.dart	紅綠燈辨識頁，使用 YOLO 偵測並以 3 秒加權投票輸出結果，搭配縮放效果與 TTS。
options_page.dart	設定頁，調整模型、斑馬線與紅綠燈相關參數，變更時自動儲存。
config.dart	GuideConfig 狀態與參數定義，包裝 SharedPreferences 載入 / 儲存。
tts_service.dart	TTS 單例，提供 TTS.i.speak() 與紅綠燈標籤對應語音文案。
centered_modal.dart	通用置中 Modal（Dialog）元件，搭配教學 / 說明視窗使用。

⚙️ 安裝與執行步驟
1. 準備 Flutter 環境
請先安裝 Flutter SDK，並確認可以執行基本範例專案：

bash
複製程式碼
flutter doctor
2. 取得專案原始碼
bash
複製程式碼
git clone https://github.com/your-name/cross-guide.git
cd cross-guide
3. 放置 YOLO TFLite 模型
依 config.dart 的預設設定，程式會使用以下檔名：

斑馬線實例分割

Cross_Road_640.tflite

Cross_Road_960.tflite

行人紅綠燈偵測

pedestrian-signal-lights_640.tflite

pedestrian-signal-lights_960.tflite

建議做法（可依自己實際專案調整）：

建立資料夾，例如：assets/models/

將上述 .tflite 檔案放入該資料夾

在 pubspec.yaml 中加入：

yaml
複製程式碼
flutter:
  assets:
    - assets/models/Cross_Road_640.tflite
    - assets/models/Cross_Road_960.tflite
    - assets/models/pedestrian-signal-lights_640.tflite
    - assets/models/pedestrian-signal-lights_960.tflite
確保 config.dart 中的檔名與實際放置的檔名一致
（若有路徑前綴，請依 ultralytics_yolo 的載入方式調整）

4. 安裝依賴套件
bash
複製程式碼
flutter pub get
5. 執行 App
開發 / 偵錯模式：

bash
複製程式碼
flutter run
或打包 Android APK：

bash
複製程式碼
flutter build apk --release
🔎 iOS 支援與否，需依 ultralytics_yolo 插件對 iOS 的支援情況自行評估與調整。

🔧 設定頁（Options）重點參數說明
以下對 OptionsPage 中幾個重要設定做簡要說明：

一般
斑馬線輔助（useCrosswalkAssist）

開啟：流程為「斑馬線導引 → 自動跳紅綠燈辨識」

關閉：首頁「開始」按鈕會直接開啟紅綠燈辨識頁

模型檔選擇

斑馬線模型：Cross_Road_640 / 960

紅綠燈模型：pedestrian-signal-lights_640 / 960

斑馬線導引相關
死區角度（deadband）

單位：度

斑馬線角度落在 ±deadband 範圍內，視為「已大致置中」，不再重複提示。

左右反轉（flipLR）

若實際使用時發現「往左」與「往右」提示與現場相反，可開啟此開關。

EMA 平滑係數（emaAlpha）

數值越大越「跟新值」，越小則越平滑但反應較慢。

用來減少畫面晃動造成的提示抖動。

穩定幀數（requiredStable）

連續多少幀皆判定為「品質良好且置中」，才會自動跳轉紅綠燈辨識頁。

掃描區段與品質條件

rowBandTop / rowBandBot：只在畫面中間一段高度掃描斑馬線邊緣。

minDualRowsRatio：同一列同時看到左右兩邊邊緣的比例下限。

minSpanRatio：左右跨度占畫面寬度的比例下限。

若品質不足，會提示「請保持位置（遮罩切邊／品質不足）」並避免誤跳轉。

紅綠燈辨識相關
置信度閾值（tlConfThreshold）

低於此閾值的偵測結果會被忽略。

投票時間（tlVotingSeconds）

在這段時間內累積每一種顏色的加權信心分數，最後取最大者作為輸出。

相機解析度 / FPS

tlCameraResolution、tlMaxFPS 控制 YOLOView 的相機解析度與運算頻率。

可依實機效能調整以取得較佳的「流暢度 vs. 發熱 / 耗電」平衡。

縮放相關（tlZoomMin / Max / Reset / Step / IntervalMs）

透過週期性調整 zoom，產生「呼吸式放大縮小」效果。

輔助使用者聚焦在畫面中被偵測到的紅綠燈範圍。

🧪 典型使用情境
開啟 App，首次進入會彈出教學對話框，説明各畫面用途與注意事項。

在首頁點選「開始」：

若開啟斑馬線輔助：

將手機垂直對準斑馬線，依語音「往左 / 往右」微調。

當畫面穩定置中且品質良好，App 會自動進入紅綠燈辨識頁。

若關閉斑馬線輔助：

直接進入紅綠燈辨識頁，按下「開始辨識」按鈕即可啟動 3 秒投票流程。

辨識結果會以語音播報（例如：「綠燈，請通行」）。

任意時刻按下「停止」即可返回首頁。

⚠️ 注意事項與免責聲明
請保持手機垂直 90 度面對斑馬線與號誌，以提升辨識品質。

車流量過大、天候不佳、鏡頭髒污等，都可能影響偵測結果。

此程式 僅作為輔助工具：

過馬路請務必以實際路況與行人號誌為準。

對於使用過程中產生的任何風險或損害，開發者不負賠償或法律責任。

若有需要協助的情況，請優先尋求現場人員或陪同者協助。

📜 授權 License
⚠️ 尚未指定授權條款，請依專案需求補上（例如 MIT / Apache-2.0 / GPL 等）。

🤝 貢獻方式（選填）
如果你打算開源並接受社群貢獻，可以在此加入類似內容：

text
複製程式碼
1. Fork 專案
2. 建立 feature branch（例如：feature/add-english-ui）
3. 提交 Commit 並發送 Pull Request
4. 說明修改內容與測試方式
