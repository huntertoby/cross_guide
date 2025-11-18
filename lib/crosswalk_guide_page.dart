import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import 'traffic_light_detect.dart';
import 'tts_service.dart';
import 'config.dart';

class CrosswalkGuidePage extends StatefulWidget {
  const CrosswalkGuidePage({super.key});
  @override
  State<CrosswalkGuidePage> createState() => _CrosswalkGuidePageState();
}

class _CrosswalkGuidePageState extends State<CrosswalkGuidePage> {
  bool _guiding = false;
  Size _lastFrameSize = const Size(0, 0);
  double _angleVertEma = 0.0;
  bool _emaInited = false;
  int _lastSayMs = 0;

  int _stableCount = 0;
  bool _navigating = false;

  void _stopAndExit() {
    _guiding = false;
    try {
      TTS.i.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _goToTraffic() async {
    if (_navigating) return;
    _navigating = true;

    _guiding = false;
    try {
      TTS.i.stop();
    } catch (_) {}
    if (mounted) setState(() {});

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrafficLightPage()),
    );
  }

  Future<void> _onResult(dynamic result) async {
    if (!_guiding || _navigating) return;

    final List<dynamic> dets =
    (result is List) ? result : (result?.detections ?? const <dynamic>[]);
    if (dets.isEmpty) {
      _stableCount = 0;
      return;
    }

    dynamic best = dets.first;
    double bestScore =
    (best.confidence ?? best.conf ?? best.score ?? 0.0).toDouble();
    for (final d in dets) {
      final s = (d.confidence ?? d.conf ?? d.score ?? 0.0).toDouble();
      if (s > bestScore) {
        best = d;
        bestScore = s;
      }
    }

    final dynamic mask = best.mask;
    if (mask == null) {
      _stableCount = 0;
      return;
    }

    final cv.Mat m = _toMaskMat(mask);
    if (m.isEmpty) {
      _stableCount = 0;
      return;
    }

    final int W = m.cols, H = m.rows;
    _lastFrameSize = Size(W.toDouble(), H.toDouble());

    final _EdgePoints ep = _extractEdgePointsFromMask(m);

    final bool cutOrWeak = ep.clippedLeft ||
        ep.clippedRight ||
        (ep.dualRowsRatio < guideConfig.minDualRowsRatio) ||
        (ep.medianSpan < (guideConfig.minSpanRatio * _lastFrameSize.width));

    if (cutOrWeak) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final double centerX = _lastFrameSize.width / 2.0;
      final double dx = centerX - ep.cx;
      final bool centered = dx.abs() <= _lastFrameSize.width * 0.08;

      String tip;
      if (centered) {
        _stableCount++;
        tip = '請保持位置';
        if (now - _lastSayMs > guideConfig.sayCooldownMs) {
          TTS.i.speak('請保持位置');
          _lastSayMs = now;
        }
        if (!_navigating && _stableCount >= guideConfig.requiredStable) {
          await TTS.i.speak('已對準斑馬線');
          if (!mounted) return;
          await _goToTraffic();
          return;
        }
      } else {
        _stableCount = 0;
        tip = dx > 0 ? '往左移動置中' : '往右移動置中';
        if (now - _lastSayMs > guideConfig.sayCooldownMs) {
          TTS.i.speak(tip);
          _lastSayMs = now;
        }
      }

      if (!mounted) return;
      setState(() {
        final _ = tip; // 目前不顯示文字，只為了保留 setState 結構需要變數
      });
      return;
    }

    if (ep.left.length < 10 && ep.right.length < 10) {
      _stableCount = 0;
      return;
    }

    (double, double, double, double)? leftLine;
    (double, double, double, double)? rightLine;
    if (ep.left.length >= 10) leftLine = _fitLine(ep.left);
    if (ep.right.length >= 10) rightLine = _fitLine(ep.right);

    final angles = <double>[];
    if (leftLine != null) {
      final seg = _intersectWithTopBottom(leftLine, _lastFrameSize);
      angles.add(_lineVerticalAngleDeg(seg.$1, seg.$2));
    }
    if (rightLine != null) {
      final seg = _intersectWithTopBottom(rightLine, _lastFrameSize);
      angles.add(_lineVerticalAngleDeg(seg.$1, seg.$2));
    }
    if (angles.isEmpty) {
      _stableCount = 0;
      return;
    }

    double avg = angles.reduce((a, b) => a + b) / angles.length;
    if (guideConfig.flipLR) avg = -avg;

    if (!_emaInited) {
      _angleVertEma = avg;
      _emaInited = true;
    } else {
      _angleVertEma =
          (1.0 - guideConfig.emaAlpha) * _angleVertEma + guideConfig.emaAlpha * avg;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final double ang = _angleVertEma;
    String tip;

    if (ang >= guideConfig.facingBand) {
      tip = '往右移動置中';
      _stableCount = 0;
      if (now - _lastSayMs > guideConfig.sayCooldownMs) {
        TTS.i.speak(tip);
        _lastSayMs = now;
      }
    } else if (ang <= -guideConfig.facingBand) {
      tip = '往左移動置中';
      _stableCount = 0;
      if (now - _lastSayMs > guideConfig.sayCooldownMs) {
        TTS.i.speak(tip);
        _lastSayMs = now;
      }
    } else {
      _stableCount++;
      tip = '對準中…';
      if (now - _lastSayMs > guideConfig.sayCooldownMs) {
        TTS.i.speak(tip);
        _lastSayMs = now;
      }
    }

    if (!_navigating && _stableCount >= guideConfig.requiredStable) {
      await TTS.i.speak('已對準斑馬線，開始辨識紅綠燈');
      if (!mounted) return;
      await _goToTraffic();
      return;
    }

    if (!mounted) return;
    setState(() {
      final _ = tip;
    });
  }

  cv.Mat _toMaskMat(dynamic mask) {
    if (mask is List && mask.isNotEmpty && mask.first is List) {
      final int h = mask.length;
      final int w = (mask.first as List).length;
      final list = List<num>.filled(w * h, 0, growable: false);
      int k = 0;
      for (int y = 0; y < h; y++) {
        final row = mask[y] as List;
        for (int x = 0; x < w; x++) {
          final nv = (row[x] is num) ? (row[x] as num).toDouble() : 0.0;
          list[k++] = nv > 0.5 ? 255 : 0;
        }
      }
      return cv.Mat.fromList(h, w, cv.MatType.CV_8UC1, list);
    }
    if (mask is cv.Mat) {
      if (mask.type == cv.MatType.CV_8UC1) {
        final (double _, cv.Mat bin0) =
        cv.threshold(mask, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
        return bin0;
      }
      final cv.Mat gray = cv.cvtColor(mask, cv.COLOR_BGR2GRAY);
      final (double __, cv.Mat bin) =
      cv.threshold(gray, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
      return bin;
    }
    return cv.Mat.empty();
  }

  _EdgePoints _extractEdgePointsFromMask(cv.Mat bin) {
    final int W = bin.cols, H = bin.rows;
    final data = bin.data;

    final int yStart = (H * guideConfig.rowBandTop).floor();
    final int yEnd = (H * guideConfig.rowBandBot).ceil();

    final left = <_P>[];
    final right = <_P>[];
    final spans = <int>[];

    int totalRows = 0,
        dualRows = 0,
        hitLeftBorderRows = 0,
        hitRightBorderRows = 0;
    int sumX = 0, cntX = 0;

    for (int y = yStart; y < yEnd; y += guideConfig.rowStep) {
      totalRows++;
      final rowBase = y * W;

      int lx = -1, rx = -1;
      for (int x = 0; x < W; x++) {
        if (data[rowBase + x] > 0) {
          lx = x;
          break;
        }
      }
      if (lx == 0) hitLeftBorderRows++;

      for (int x = W - 1; x >= 0; x--) {
        if (data[rowBase + x] > 0) {
          rx = x;
          break;
        }
      }
      if (rx == W - 1) hitRightBorderRows++;

      if (lx >= 0 && rx >= 0 && rx >= lx) {
        dualRows++;
        left.add(_P(lx.toDouble(), y.toDouble()));
        right.add(_P(rx.toDouble(), y.toDouble()));
        spans.add(rx - lx);

        sumX += (lx + rx) * ((rx - lx + 1) ~/ 2);
        cntX += (rx - lx + 1);
      } else if (lx >= 0 && rx < 0) {
        left.add(_P(lx.toDouble(), y.toDouble()));
        sumX += lx;
        cntX += 1;
      } else if (rx >= 0 && lx < 0) {
        right.add(_P(rx.toDouble(), y.toDouble()));
        sumX += rx;
        cntX += 1;
      }
    }

    final double dualRowsRatio =
    (totalRows > 0) ? (dualRows / totalRows) : 0.0;
    spans.sort();
    final int medianSpan = spans.isEmpty ? 0 : spans[spans.length >> 1];
    final bool clippedLeft = hitLeftBorderRows >= 2;
    final bool clippedRight = hitRightBorderRows >= 2;
    final double cx = (cntX > 0) ? (sumX / cntX) : (W / 2.0);

    return _EdgePoints(
      left,
      right,
      clippedLeft: clippedLeft,
      clippedRight: clippedRight,
      dualRowsRatio: dualRowsRatio,
      medianSpan: medianSpan,
      cx: cx,
    );
  }

  (double, double, double, double) _fitLine(List<_P> pts) {
    double mx = 0, my = 0;
    for (final p in pts) {
      mx += p.x;
      my += p.y;
    }
    mx /= pts.length;
    my /= pts.length;

    double sxx = 0, syy = 0, sxy = 0;
    for (final p in pts) {
      final dx = p.x - mx;
      final dy = p.y - my;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }
    final double tmp =
    math.sqrt((sxx - syy) * (sxx - syy) + 4 * sxy * sxy);
    final double l1 = (sxx + syy + tmp) / 2.0;
    double vx = sxy, vy = l1 - sxx;
    final double norm = math.sqrt(vx * vx + vy * vy);
    if (norm > 1e-6) {
      vx /= norm;
      vy /= norm;
    } else {
      vx = 0.0;
      vy = 1.0;
    }
    return (vx, vy, mx, my);
  }

  (Offset, Offset) _intersectWithTopBottom(
      (double, double, double, double) line, Size s) {
    final (vx, vy, x0, y0) = line;
    final double H = s.height > 0 ? s.height : 1080.0;
    if (vy.abs() < 1e-6) {
      final double W = s.width > 0 ? s.width : 1920.0;
      final double tL = (-x0) / (vx == 0 ? 1e-6 : vx);
      final double tR = (W - x0) / (vx == 0 ? 1e-6 : vx);
      return (
      Offset(x0 + tL * vx, y0 + tL * vy),
      Offset(x0 + tR * vx, y0 + tR * vy),
      );
    } else {
      final double tTop = (0 - y0) / vy;
      final double tBot = (H - y0) / vy;
      return (
      Offset(x0 + tTop * vx, 0),
      Offset(x0 + tBot * vx, H),
      );
    }
  }

  double _lineVerticalAngleDeg(Offset a, Offset b) {
    final dx = (b.dx - a.dx).toDouble();
    final dy = (b.dy - a.dy).toDouble();
    final theta = math.atan2(dy, dx);
    final deg = 90.0 - (theta * 180.0 / math.pi);
    double ang = ((deg + 180.0) % 360.0) - 180.0;
    if (ang > 90.0) ang -= 180.0;
    if (ang < -90.0) ang += 180.0;
    return ang;
  }

  @override
  void initState() {
    super.initState();
    TTS.i.init(language: 'zh-TW', rate: 0.5, pitch: 1.0);

    _guiding = true;
    _stableCount = 0;
    _navigating = false;
    _emaInited = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TTS.i.speak('開始辨識，請將手機９０度垂直面對');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _guiding
          ? FloatingActionButton(
        onPressed: _stopAndExit,
        child: const Icon(Icons.stop),
      )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_guiding)
            YOLOView(
              modelPath: guideConfig.modelSeg,
              task: YOLOTask.segment,
              streamingConfig: YOLOStreamingConfig.throttled(
                maxFPS: 24,
                includeOriginalImage: true,
                includeMasks: true,
              ),
              onResult: _onResult,
            ),
        ],
      ),
    );
  }
}

class _P {
  final double x, y;
  const _P(this.x, this.y);
}

class _EdgePoints {
  final List<_P> left;
  final List<_P> right;
  final bool clippedLeft;
  final bool clippedRight;
  final double dualRowsRatio;
  final int medianSpan;
  final double cx;
  const _EdgePoints(
      this.left,
      this.right, {
        required this.clippedLeft,
        required this.clippedRight,
        required this.dualRowsRatio,
        required this.medianSpan,
        required this.cx,
      });
}
