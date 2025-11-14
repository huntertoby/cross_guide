import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsKey = 'guide_config_v1';

// 方便 UI 做選單用（可選自己要不要用）
const List<String> kSegModelOptions = [
  'Cross_Road_640.tflite',
  'Cross_Road_960.tflite',
];

const List<String> kLightModelOptions = [
  'pedestrian-signal-lights_640.tflite',
  'pedestrian-signal-lights_960.tflite',
];

class GuideConfig extends ChangeNotifier {
  // —— 模型檔名 —— //
  String modelSeg = 'Cross_Road_960.tflite';
  String modelLight = 'pedestrian-signal-lights_960.tflite';

  // —— 是否先做斑馬線輔助 —— //
  bool useCrosswalkAssist = true; // 關閉則直接跳紅綠燈

  // —— 斑馬線導引 —— //
  double deadband = 15.0;     // 左正右負，超過才提示往左／往右
  bool flipLR = false;        // 左右反轉
  double emaAlpha = 0.2;      // EMA 平滑
  int sayCooldownMs = 1500;   // 語音節流（毫秒）

  double facingBand = 4.0;    // 視為已對準的更窄容許角（度）
  int requiredStable = 15;    // 連續穩定幀門檻

  double rowBandTop = 0.25;   // 只掃中段：上 25% 不掃
  double rowBandBot = 0.85;   // 下 15% 不掃
  int rowStep = 2;            // 行取樣步長
  double minDualRowsRatio = 0.30; // 同時抓到左右兩邊的列比例下限
  double minSpanRatio = 0.20;     // 橫向跨度中位數佔寬度比例下限

  // —— 紅綠燈偵測（可調）—— //
  double tlConfThreshold = 0.50; // 置信門檻
  int tlVotingSeconds = 3;       // 投票時間（秒）
  String tlCameraResolution = '1080p';
  int tlMaxFPS = 60;

  double tlZoomMin = 1.0;
  double tlZoomMax = 4.0;
  double tlZoomReset = 1.0;
  double tlZoomStep = 0.2;
  int tlZoomIntervalMs = 200;    // 縮放巡檢週期（毫秒）

  bool tlSpeakOnEnter = true;    // 進頁後提示一次

  // ===== 持久化：載入／儲存 =====
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _fromMap(map);
    } catch (_) {
      // ignore 損壞資料
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_toMap()));
  }

  Map<String, dynamic> _toMap() => {
    'modelSeg': modelSeg,
    'modelLight': modelLight,
    'useCrosswalkAssist': useCrosswalkAssist,
    'deadband': deadband,
    'flipLR': flipLR,
    'emaAlpha': emaAlpha,
    'sayCooldownMs': sayCooldownMs,
    'facingBand': facingBand,
    'requiredStable': requiredStable,
    'rowBandTop': rowBandTop,
    'rowBandBot': rowBandBot,
    'rowStep': rowStep,
    'minDualRowsRatio': minDualRowsRatio,
    'minSpanRatio': minSpanRatio,
    'tlConfThreshold': tlConfThreshold,
    'tlVotingSeconds': tlVotingSeconds,
    'tlCameraResolution': tlCameraResolution,
    'tlMaxFPS': tlMaxFPS,
    'tlZoomMin': tlZoomMin,
    'tlZoomMax': tlZoomMax,
    'tlZoomReset': tlZoomReset,
    'tlZoomStep': tlZoomStep,
    'tlZoomIntervalMs': tlZoomIntervalMs,
    'tlSpeakOnEnter': tlSpeakOnEnter,
  };

  // 安全轉型工具
  double _asDouble(dynamic v, double def) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  int _asInt(dynamic v, int def) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  bool _asBool(dynamic v, bool def) {
    if (v is bool) return v;
    if (v is String) return (v == 'true');
    return def;
  }

  void _fromMap(Map<String, dynamic> m) {
    modelSeg = (m['modelSeg'] ?? modelSeg).toString();
    modelLight = (m['modelLight'] ?? modelLight).toString();

    useCrosswalkAssist = _asBool(m['useCrosswalkAssist'], useCrosswalkAssist);

    deadband = _asDouble(m['deadband'], deadband);
    flipLR = _asBool(m['flipLR'], flipLR);
    emaAlpha = _asDouble(m['emaAlpha'], emaAlpha);
    sayCooldownMs = _asInt(m['sayCooldownMs'], sayCooldownMs);

    facingBand = _asDouble(m['facingBand'], facingBand);
    requiredStable = _asInt(m['requiredStable'], requiredStable);

    rowBandTop = _asDouble(m['rowBandTop'], rowBandTop);
    rowBandBot = _asDouble(m['rowBandBot'], rowBandBot);
    rowStep = _asInt(m['rowStep'], rowStep);
    minDualRowsRatio = _asDouble(m['minDualRowsRatio'], minDualRowsRatio);
    minSpanRatio = _asDouble(m['minSpanRatio'], minSpanRatio);

    tlConfThreshold = _asDouble(m['tlConfThreshold'], tlConfThreshold);
    tlVotingSeconds = _asInt(m['tlVotingSeconds'], tlVotingSeconds);
    tlCameraResolution =
        (m['tlCameraResolution'] ?? tlCameraResolution).toString();
    tlMaxFPS = _asInt(m['tlMaxFPS'], tlMaxFPS);

    tlZoomMin = _asDouble(m['tlZoomMin'], tlZoomMin);
    tlZoomMax = _asDouble(m['tlZoomMax'], tlZoomMax);
    tlZoomReset = _asDouble(m['tlZoomReset'], tlZoomReset);
    tlZoomStep = _asDouble(m['tlZoomStep'], tlZoomStep);
    tlZoomIntervalMs = _asInt(m['tlZoomIntervalMs'], tlZoomIntervalMs);

    tlSpeakOnEnter = _asBool(m['tlSpeakOnEnter'], tlSpeakOnEnter);
  }

  // ===== setters（每次改動都自動存檔）=====

  // 模型切換（斑馬線）
  void setModelSeg(String v) {
    modelSeg = v;
    notifyListeners();
    _save();
  }

  // 模型切換（紅綠燈）
  void setModelLight(String v) {
    modelLight = v;
    notifyListeners();
    _save();
  }

  void setUseCrosswalkAssist(bool v) {
    useCrosswalkAssist = v;
    notifyListeners();
    _save();
  }

  void setFlip(bool v) {
    flipLR = v;
    notifyListeners();
    _save();
  }

  void setDeadband(double v) {
    deadband = v;
    notifyListeners();
    _save();
  }

  void setFacingBand(double v) {
    facingBand = v;
    notifyListeners();
    _save();
  }

  void setRequiredStable(int v) {
    requiredStable = v;
    notifyListeners();
    _save();
  }

  void setSayCooldownMs(int v) {
    sayCooldownMs = v;
    notifyListeners();
    _save();
  }

  void setEmaAlpha(double v) {
    emaAlpha = v;
    notifyListeners();
    _save();
  }

  void setRowBandTop(double v) {
    rowBandTop = v;
    notifyListeners();
    _save();
  }

  void setRowBandBot(double v) {
    rowBandBot = v;
    notifyListeners();
    _save();
  }

  void setRowStep(int v) {
    rowStep = v;
    notifyListeners();
    _save();
  }

  void setMinDualRowsRatio(double v) {
    minDualRowsRatio = v;
    notifyListeners();
    _save();
  }

  void setMinSpanRatio(double v) {
    minSpanRatio = v;
    notifyListeners();
    _save();
  }

  void setTlConf(double v) {
    tlConfThreshold = v;
    notifyListeners();
    _save();
  }

  void setTlVotingSeconds(int v) {
    tlVotingSeconds = v;
    notifyListeners();
    _save();
  }

  void setTlCameraResolution(String v) {
    tlCameraResolution = v;
    notifyListeners();
    _save();
  }

  void setTlMaxFps(int v) {
    tlMaxFPS = v;
    notifyListeners();
    _save();
  }

  void setTlZoomMin(double v) {
    tlZoomMin = v;
    notifyListeners();
    _save();
  }

  void setTlZoomMax(double v) {
    tlZoomMax = v;
    notifyListeners();
    _save();
  }

  void setTlZoomReset(double v) {
    tlZoomReset = v;
    notifyListeners();
    _save();
  }

  void setTlZoomStep(double v) {
    tlZoomStep = v;
    notifyListeners();
    _save();
  }

  void setTlZoomIntervalMs(int v) {
    tlZoomIntervalMs = v;
    notifyListeners();
    _save();
  }

  void setTlSpeakOnEnter(bool v) {
    tlSpeakOnEnter = v;
    notifyListeners();
    _save();
  }

  // 一鍵套用導引預設
  void applyGuidePreset(String preset) {
    switch (preset) {
      case '敏感': // 反應快、易跳轉
        setDeadband(10);
        setFacingBand(3);
        setRequiredStable(10);
        setSayCooldownMs(1000);
        setEmaAlpha(0.35);
        setMinDualRowsRatio(0.25);
        setMinSpanRatio(0.15);
        break;
      case '保守': // 反應慢、穩定
        setDeadband(20);
        setFacingBand(5);
        setRequiredStable(20);
        setSayCooldownMs(1800);
        setEmaAlpha(0.18);
        setMinDualRowsRatio(0.35);
        setMinSpanRatio(0.25);
        break;
      default: // 標準
        setDeadband(15);
        setFacingBand(4);
        setRequiredStable(15);
        setSayCooldownMs(1500);
        setEmaAlpha(0.2);
        setMinDualRowsRatio(0.30);
        setMinSpanRatio(0.20);
    }
  }

  // 一鍵套用紅綠燈預設
  void applyTrafficPreset(String preset) {
    switch (preset) {
      case '快速判斷': // 速度優先
        setTlVotingSeconds(2);
        setTlConf(0.45);
        setTlMaxFps(60);
        setTlZoomStep(0.25);
        break;
      case '穩健判斷': // 準確優先
        setTlVotingSeconds(4);
        setTlConf(0.60);
        setTlMaxFps(45);
        setTlZoomStep(0.15);
        break;
      default: // 標準
        setTlVotingSeconds(3);
        setTlConf(0.50);
        setTlMaxFps(60);
        setTlZoomStep(0.20);
    }
  }

  // 重設所有設定為出廠值
  Future<void> resetToDefaults() async {
    modelSeg = 'Cross_Road_960.tflite';
    modelLight = 'pedestrian-signal-lights_960.tflite';
    useCrosswalkAssist = true;

    deadband = 15.0;
    flipLR = false;
    emaAlpha = 0.2;
    sayCooldownMs = 1500;
    facingBand = 4.0;
    requiredStable = 15;

    rowBandTop = 0.25;
    rowBandBot = 0.85;
    rowStep = 2;
    minDualRowsRatio = 0.30;
    minSpanRatio = 0.20;

    tlConfThreshold = 0.50;
    tlVotingSeconds = 3;
    tlCameraResolution = '1080p';
    tlMaxFPS = 60;

    tlZoomMin = 1.0;
    tlZoomMax = 4.0;
    tlZoomReset = 1.0;
    tlZoomStep = 0.2;
    tlZoomIntervalMs = 200;

    tlSpeakOnEnter = true;

    notifyListeners();
    await _save();
  }
}

final guideConfig = GuideConfig();
