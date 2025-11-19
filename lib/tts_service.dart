import 'package:flutter_tts/flutter_tts.dart';

class TTS {
  TTS._();
  static final TTS i = TTS._();

  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  String _lastSpoken = '';
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init({
    String language = 'zh-TW',
    double rate = 0.5,     // 0.0 ~ 1.0
    double pitch = 1.0,    // 0.5 ~ 2.0
    bool awaitFinish = true,
  }) async {
    if (_inited) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.awaitSpeakCompletion(awaitFinish);

    // iOS：讓語音播放時壓低其他音訊（可選）
    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.duckOthers],
      );
    } catch (_) {}

    _inited = true;
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_inited) await init();
    if (interrupt) {
      try { await _tts.stop(); } catch (_) {}
    }
    await _tts.speak(text);
  }

  Future<void> speakIfChanged(
      String text, {
        Duration minGap = const Duration(seconds: 2),
      }) async {
    if (!_inited) await init();
    final now = DateTime.now();
    if (_lastSpoken == text && now.difference(_lastAt) < minGap) return;
    _lastSpoken = text;
    _lastAt = now;
    try { await _tts.stop(); } catch (_) {}
    await _tts.speak(text);
  }

  Future<void> stop() async {
    try { await _tts.stop(); } catch (_) {}
  }

  Future<void> setLanguage(String lang) async => _tts.setLanguage(lang);
  Future<void> setRate(double rate) async => _tts.setSpeechRate(rate);
  Future<void> setPitch(double pitch) async => _tts.setPitch(pitch);

  String speechForTrafficLabel(String? label) {
    final l = (label ?? '').toLowerCase();
    if (l.contains('green'))  return '綠燈，請通行';
    if (l.contains('red'))    return '紅燈，請停';
    if (l.contains('yellow') || l.contains('amber')) return '黃燈，請注意';
    return '沒有辨識到紅綠燈，請再試一次';
  }
}
