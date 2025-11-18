import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';

import 'tts_service.dart';
import 'config.dart';

class TrafficLightPage extends StatefulWidget {
  const TrafficLightPage({super.key});

  @override
  State<TrafficLightPage> createState() => _TrafficLightPageState();
}

class _TrafficLightPageState extends State<TrafficLightPage> {
  final Map<String, double> _weightedHist = {};
  bool _collecting = false;
  Timer? _stopTimer;
  Timer? _logTicker;
  Timer? _zoomTicker;
  String? _winner;

  bool _autoStarted = false;

  final YOLOViewController _yoloCtrl = YOLOViewController();
  double _curZoom = 1.0;
  late double _minZoom;
  late double _maxZoom;
  late double _zoomReset;
  late double _zoomStep;
  late int _zoomIntervalMs;

  String get _modelPath => guideConfig.modelLight;
  double get _confThreshold => guideConfig.tlConfThreshold;
  int get _votingSeconds => guideConfig.tlVotingSeconds;
  String get _cameraResolution => guideConfig.tlCameraResolution;
  int get _maxFps => guideConfig.tlMaxFPS;

  void _stopAndExit() {
    _collecting = false;
    _stopTimer?.cancel();
    _stopTimer = null;
    _zoomTicker?.cancel();
    _zoomTicker = null;
    _logTicker?.cancel();
    _logTicker = null;

    try {
      TTS.i.stop();
    } catch (_) {}

    _setZoomSafely(_zoomReset);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onResult(dynamic result) {
    if (!_autoStarted) {
      _autoStarted = true;
      _startCollect();
    }

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
      if (conf < _confThreshold) continue;
      final label = d.className?.toString() ?? 'unknown';
      final weight = conf;
      _weightedHist.update(label, (v) => v + weight, ifAbsent: () => weight);
    }
  }

  void _startCollect() {
    if (_collecting) return;

    setState(() {
      _collecting = true;
      _weightedHist.clear();
      _winner = null;
    });


    _setZoomSafely(_zoomReset);

    _zoomTicker?.cancel();
    _zoomTicker = Timer.periodic(
      Duration(milliseconds: _zoomIntervalMs),
          (_) => _zoomLoop(),
    );

    _logTicker?.cancel();
    _logTicker = Timer.periodic(Duration(seconds: _votingSeconds), (_) {
    });

    _stopTimer?.cancel();
    _stopTimer = Timer(Duration(seconds: _votingSeconds), _finishCollect);
  }

  void _finishCollect() {
    _collecting = false;
    _stopTimer?.cancel();
    _stopTimer = null;
    _zoomTicker?.cancel();
    _zoomTicker = null;
    _logTicker?.cancel();
    _logTicker = null;

    _setZoomSafely(_zoomReset);

    String? bestLabel;
    double bestScore = 0.0;
    _weightedHist.forEach((k, v) {
      if (v > bestScore) {
        bestLabel = k;
        bestScore = v;
      }
    });

    setState(() {
      _winner = bestLabel;
    });
    debugPrint('[結果] $_votingSeconds 秒勝出：${_winner ?? '無'}');

    TTS.i.speak(TTS.i.speechForTrafficLabel(_winner));

    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _startCollect();
    });
  }

  void _zoomLoop() {
    if (!_collecting) return;

    double nextZoom = _curZoom + _zoomStep;
    if (nextZoom >= _maxZoom) {
      nextZoom = _minZoom;
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

    _minZoom = guideConfig.tlZoomMin;
    _maxZoom = guideConfig.tlZoomMax;
    _zoomReset = guideConfig.tlZoomReset;
    _zoomStep = guideConfig.tlZoomStep;
    _zoomIntervalMs = guideConfig.tlZoomIntervalMs;
    _curZoom = _zoomReset;

    TTS.i.init(language: 'zh-TW', rate: 0.5, pitch: 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!guideConfig.tlSpeakOnEnter) return;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        TTS.i.speak('現在開始辨識紅綠燈，請對準行人號誌');
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
        return false;
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          fit: StackFit.expand,
          children: [
            YOLOView(
              controller: _yoloCtrl,
              modelPath: _modelPath,
              task: YOLOTask.detect,
              cameraResolution: _cameraResolution,
              streamingConfig: YOLOStreamingConfig.throttled(
                maxFPS: _maxFps,
              ),
              onResult: _onResult,
              onZoomChanged: (z) => _curZoom = z,
            ),
            if (_collecting || _winner != null)
              Positioned(
                left: 12,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      _collecting
                          ? '紅綠燈：統計中…'
                          : '紅綠燈：${_winner ?? '無結果'}',
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
