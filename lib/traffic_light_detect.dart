import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';
import 'tts_service.dart';

class TrafficLightPage extends StatefulWidget {
  final String modelPath;
  final double confThreshold;
  const TrafficLightPage({
    super.key,
    required this.modelPath,
    this.confThreshold = 0.5,
  });

  @override
  State<TrafficLightPage> createState() => _TrafficLightPageState();
}

class _TrafficLightPageState extends State<TrafficLightPage> {
  // —— 3秒權重統計 —— //
  final Map<String, double> _weightedHist = {};
  bool _collecting = false;
  Timer? _stopTimer;
  Timer? _logTicker;   // 每 3 秒打一筆現況（也剛好=統計時長）
  String? _winner;

  // —— 縮放控制 —— //
  final YOLOViewController _yoloCtrl = YOLOViewController();
  double _curZoom = 1.0;
  final double _minZoom = 1.0;   // SDK 若可取真值可改成實際值
  final double _maxZoom = 4.0;
  final double _zoomReset = 1.0;
  final double _zoomStep  = 0.2;
  int _zoomDir = 1;
  Timer? _zoomTicker;

  // ======= 統一停止並返回上一頁（首頁） ======= //
  void _stopAndExit() {
    _collecting = false;
    _stopTimer?.cancel(); _stopTimer = null;
    _zoomTicker?.cancel(); _zoomTicker = null;
    _logTicker?.cancel();  _logTicker  = null;

    try { TTS.i.stop(); } catch (_) {}
    _setZoomSafely(_zoomReset);

    if (mounted) Navigator.of(context).pop();
  }

  // YOLO 回呼（DETECT）
  void _onResult(dynamic result) {
    if (!_collecting) return;

    List<dynamic> detections;
    if (result is List) {
      detections = result;
    } else {
      try {
        detections = List<dynamic>.from(result.detections);
      } catch (_) {
        detections = const [];
      }
    }

    for (final d in detections) {
      final conf = (d.confidence ?? d.conf ?? d.score ?? 0.0).toDouble();
      if (conf < widget.confThreshold) continue;
      final label = d.className?.toString() ?? 'unknown';
      final weight = conf;                   // 想更強調高信心可用 conf*conf
      _weightedHist.update(label, (v) => v + weight, ifAbsent: () => weight);
    }
  }

  // ====== 3 秒統計 + 呼吸式縮放 ====== //
  void _startCollect() {
    if (_collecting) return;
    setState(() {
      _collecting = true;
      _weightedHist.clear();
      _winner = null;
      _zoomDir = 1;
    });

    TTS.i.speak('請按下按鈕開始辨識紅綠燈');

    // 回到預設倍率
    _setZoomSafely(_zoomReset);

    // 縮放巡檢
    _zoomTicker?.cancel();
    _zoomTicker = Timer.periodic(const Duration(milliseconds: 200), (_) => _zoomLoop());

    // 3秒心跳（同時也印目前統計）
    _logTicker?.cancel();
    _logTicker = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_weightedHist.isEmpty) {
        debugPrint('[紅綠燈] 統計中… 尚無有效偵測');
      } else {
        debugPrint('[紅綠燈] 累計：${_weightedHist.map((k, v) => MapEntry(k, v.toStringAsFixed(2)))}');
      }
    });

    // 到點結束
    _stopTimer?.cancel();
    _stopTimer = Timer(const Duration(seconds: 3), _finishCollect);
  }

  void _finishCollect() {
    _collecting = false;
    _stopTimer?.cancel(); _stopTimer = null;
    _zoomTicker?.cancel(); _zoomTicker = null;
    _logTicker?.cancel();  _logTicker  = null;

    // 回縮
    _setZoomSafely(_zoomReset);

    // 產生勝者
    String? bestLabel;
    double bestScore = 0.0;
    _weightedHist.forEach((k, v) {
      if (v > bestScore) { bestLabel = k; bestScore = v; }
    });

    setState(() { _winner = bestLabel; });
    debugPrint('[結果] 3 秒勝出：${_winner ?? '無'}');

    TTS.i.speak(TTS.i.speechForTrafficLabel(_winner));
  }

  void _zoomLoop() {
    if (!_collecting) return;
    double nextZoom = _curZoom + _zoomStep * _zoomDir;

    if (nextZoom >= _maxZoom) {
      nextZoom = _maxZoom; _zoomDir = -1;
    } else if (nextZoom <= _minZoom) {
      nextZoom = _minZoom; _zoomDir = 1;
    }
    _setZoomSafely(nextZoom);
  }

  void _setZoomSafely(double level) {
    _curZoom = level;
    _yoloCtrl.setZoomLevel(level);
  }

  @override
  void initState() {
    super.initState();
    // 初始化 TTS（不要 await）
    TTS.i.init(language: 'zh-TW', rate: 0.5, pitch: 1.0);

    // 等第一個 frame 繪製完成後再講，避免與權限對話框或相機初始化打架
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 視需要給一點點延遲，讓相機先啟動
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        TTS.i.speak('請對準攝像頭，按下按鈕開始辨識');
      });
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _zoomTicker?.cancel();
    _logTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        _stopAndExit();
        return false; // 交由 _stopAndExit() 處理返回
      },
      child: Scaffold(
        // 可選：若你想保留上方返回鍵，打開以下 AppBar；若不要就維持無AppBar。
        // appBar: AppBar(
        //   title: const Text('紅綠燈偵測（3秒投票）'),
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: _stopAndExit,
        //     tooltip: '停止並返回',
        //   ),
        // ),

        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: Stack(
          fit: StackFit.expand,
          children: [
            YOLOView(
              controller: _yoloCtrl,
              modelPath: widget.modelPath,
              task: YOLOTask.detect,
              cameraResolution: '1080p',
              streamingConfig: YOLOStreamingConfig.throttled(maxFPS: 60),
              onResult: _onResult,
              onZoomChanged: (z) => _curZoom = z,
            ),

            // 中央按鈕
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 160),
                  textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  shape: const CircleBorder(),
                ),
                onPressed: _collecting ? null : _startCollect,
                child: Text(_collecting ? "統計中…" : "開始辨識"),
              ),
            ),

            // 左上角 HUD
            if (_collecting || _winner != null)
              Positioned(
                left: 12, top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      _collecting ? '紅綠燈：統計中…' : '紅綠燈：${_winner ?? '無結果'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // 右下角「停止」按鈕
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: FloatingActionButton.extended(
              backgroundColor: color.errorContainer,
              foregroundColor: color.onErrorContainer,
              onPressed: _stopAndExit,
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
            ),
          ),
        ),
      ),
    );
  }
}
