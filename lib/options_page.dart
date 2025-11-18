import 'package:flutter/material.dart';
import 'config.dart';
import 'tts_service.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});
  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  static const _cameraChoices = ['720p', '1080p', '2160p'];

  @override
  Widget build(BuildContext context) {
    final segModelValue = kSegModelOptions.contains(guideConfig.modelSeg)
        ? guideConfig.modelSeg
        : kSegModelOptions.first;
    final lightModelValue = kLightModelOptions.contains(guideConfig.modelLight)
        ? guideConfig.modelLight
        : kLightModelOptions.first;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('斑馬線輔助'),
              subtitle: const Text('關閉：直接進入紅綠燈辨識'),
              value: guideConfig.useCrosswalkAssist,
              onChanged: (v) =>
                  setState(() => guideConfig.setUseCrosswalkAssist(v)),
            ),
          ),

          const SizedBox(height: 6),

          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('一般設定'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              const Text(
                '模型選擇',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              _dropdownTile(
                title: '斑馬線模型',
                value: segModelValue,
                items: kSegModelOptions,
                onChanged: (v) =>
                    setState(() => guideConfig.setModelSeg(v)),
                labelBuilder: _segModelLabel,
              ),

              _dropdownTile(
                title: '紅綠燈模型',
                value: lightModelValue,
                items: kLightModelOptions,
                onChanged: (v) =>
                    setState(() => guideConfig.setModelLight(v)),
                labelBuilder: _lightModelLabel,
              ),

              const Divider(),
              SwitchListTile(
                title: const Text('進入紅綠燈頁時語音提示'),
                value: guideConfig.tlSpeakOnEnter,
                onChanged: (v) =>
                    setState(() => guideConfig.setTlSpeakOnEnter(v)),
              ),
            ],
          ),


          ExpansionTile(
            title: const Text('斑馬線導引'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [

              _presetChips(
                label: '一鍵套用',
                values: const ['保守', '標準', '敏感'],
                onTap: (p) =>
                    setState(() => guideConfig.applyGuidePreset(p)),
              ),
              SwitchListTile(
                title: const Text('左右反轉（flipLR）'),
                subtitle: const Text('畫面左右顛倒時請開啟'),
                value: guideConfig.flipLR,
                onChanged: (v) => setState(() => guideConfig.setFlip(v)),
              ),
              _slider(
                label: '對準帶（facingBand）',
                help: '小於這個角度就算「已對準」',
                value: guideConfig.facingBand,
                min: 2,
                max: 10,
                divisions: 16,
                onChanged: (v) =>
                    setState(() => guideConfig.setFacingBand(v)),
              ),
              _intStepper(
                label: '連續對準幀數',
                value: guideConfig.requiredStable,
                min: 5,
                max: 60,
                step: 1,
                onChanged: (v) =>
                    setState(() => guideConfig.setRequiredStable(v)),
              ),
              const Divider(),
              const Text('畫面品質不好辨識條件',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _slider(
                label: '上方不掃比例（rowBandTop）',
                help: '越大＝越忽略畫面上方',
                value: guideConfig.rowBandTop,
                min: 0,
                max: 0.5,
                divisions: 50,
                onChanged: (v) =>
                    setState(() => guideConfig.setRowBandTop(v)),
              ),
              _slider(
                label: '下方不掃比例（rowBandBot）',
                help: '越小＝越忽略畫面下方',
                value: guideConfig.rowBandBot,
                min: 0.5,
                max: 1.0,
                divisions: 50,
                onChanged: (v) =>
                    setState(() => guideConfig.setRowBandBot(v)),
              ),
              _intStepper(
                label: '掃描步長（rowStep）',
                value: guideConfig.rowStep,
                min: 1,
                max: 8,
                step: 1,
                onChanged: (v) =>
                    setState(() => guideConfig.setRowStep(v)),
              ),
              _slider(
                label: '左右同時命中比例（minDualRowsRatio）',
                help: '同一列同時看到左右邊的最低比例',
                value: guideConfig.minDualRowsRatio,
                min: 0.1,
                max: 0.8,
                divisions: 70,
                onChanged: (v) =>
                    setState(() => guideConfig.setMinDualRowsRatio(v)),
              ),
              _slider(
                label: '跨度下限（minSpanRatio）',
                help: '左右距離占畫面寬度的最低比例',
                value: guideConfig.minSpanRatio,
                min: 0.05,
                max: 0.6,
                divisions: 55,
                onChanged: (v) =>
                    setState(() => guideConfig.setMinSpanRatio(v)),
              ),
              const Divider(),
              const Text('語音與平滑',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _intStepper(
                label: '語音間隔（毫秒）',
                value: guideConfig.sayCooldownMs,
                min: 500,
                max: 5000,
                step: 250,
                onChanged: (v) =>
                    setState(() => guideConfig.setSayCooldownMs(v)),
              ),
              _slider(
                label: '平滑強度（emaAlpha）',
                help: '越大越靈敏（抖動也較多）',
                value: guideConfig.emaAlpha,
                min: 0.05,
                max: 0.8,
                divisions: 75,
                onChanged: (v) =>
                    setState(() => guideConfig.setEmaAlpha(v)),
              ),
            ],
          ),


          ExpansionTile(
            title: const Text('紅綠燈偵測'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              _presetChips(
                label: '一鍵套用',
                values: const ['快速判斷', '標準', '穩健判斷'],
                onTap: (p) =>
                    setState(() => guideConfig.applyTrafficPreset(p)),
              ),
              _dropdownTile(
                title: '相機解析度（紅綠燈）',
                value: _cameraChoices.contains(guideConfig.tlCameraResolution)
                    ? guideConfig.tlCameraResolution
                    : _cameraChoices.first,
                items: _cameraChoices,
                onChanged: (v) =>
                    setState(() => guideConfig.setTlCameraResolution(v)),
              ),
              _intStepper(
                label: '最大 FPS（紅綠燈）',
                value: guideConfig.tlMaxFPS,
                min: 15,
                max: 120,
                step: 5,
                onChanged: (v) =>
                    setState(() => guideConfig.setTlMaxFps(v)),
              ),

              _slider(
                label: '信心門檻',
                help: '低於此分數就忽略',
                value: guideConfig.tlConfThreshold,
                min: 0.05,
                max: 0.95,
                divisions: 18,
                onChanged: (v) => setState(() =>
                    guideConfig.setTlConf(double.parse(v.toStringAsFixed(2)))),
              ),
              _intStepper(
                label: '投票秒數',
                value: guideConfig.tlVotingSeconds,
                min: 1,
                max: 10,
                step: 1,
                onChanged: (v) =>
                    setState(() => guideConfig.setTlVotingSeconds(v)),
              ),
              const Divider(),
              const Text('自動縮放（偵測時）',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _slider(
                label: '縮放下限',
                help: '最小倍率',
                value: guideConfig.tlZoomMin,
                min: 1.0,
                max: 4.0,
                divisions: 30,
                onChanged: (v) => setState(() => guideConfig
                    .setTlZoomMin(double.parse(v.toStringAsFixed(2)))),
              ),
              _slider(
                label: '縮放上限',
                help: '最大倍率',
                value: guideConfig.tlZoomMax,
                min: 1.0,
                max: 8.0,
                divisions: 70,
                onChanged: (v) => setState(() => guideConfig
                    .setTlZoomMax(double.parse(v.toStringAsFixed(2)))),
              ),
              _slider(
                label: '預設倍率',
                help: '開始偵測時回到此倍率',
                value: guideConfig.tlZoomReset,
                min: 1.0,
                max: 4.0,
                divisions: 30,
                onChanged: (v) => setState(() => guideConfig
                    .setTlZoomReset(double.parse(v.toStringAsFixed(2)))),
              ),
              _slider(
                label: '縮放步伐',
                help: '每次調整的幅度',
                value: guideConfig.tlZoomStep,
                min: 0.05,
                max: 0.6,
                divisions: 55,
                onChanged: (v) => setState(() => guideConfig
                    .setTlZoomStep(double.parse(v.toStringAsFixed(2)))),
              ),
              _intStepper(
                label: '縮放頻率（毫秒）',
                value: guideConfig.tlZoomIntervalMs,
                min: 50,
                max: 1000,
                step: 50,
                onChanged: (v) =>
                    setState(() => guideConfig.setTlZoomIntervalMs(v)),
              ),
            ],
          ),
        ],
      ),


      bottomSheet: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await guideConfig.resetToDefaults();
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已重設為預設值')),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('重設為預設值'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      TTS.i.speak('這是語音提示的測試'),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('試播語音'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _segModelLabel(String file) {
    switch (file) {
      case 'Cross_Road_960.tflite':
        return '高性能（960×960）';
      case 'Cross_Road_640.tflite':
        return '中性能（640×640）';
      default:
        return file;
    }
  }

  String _lightModelLabel(String file) {
    switch (file) {
      case 'pedestrian-signal-lights_960.tflite':
        return '高性能（960×960）';
      case 'pedestrian-signal-lights_640.tflite':
        return '中性能（640×640）';
      default:
        return file;
    }
  }


  Widget _presetChips({
    required String label,
    required List<String> values,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final v in values)
              ActionChip(
                label: Text(v),
                onPressed: () => onTap(v),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String)? labelBuilder,
  }) {
    final lb = labelBuilder ?? (s) => s;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((e) =>
            DropdownMenuItem(value: e, child: Text(lb(e))))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }


  Widget _slider({
    required String label,
    required String help,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold))),
              Text(value.toStringAsFixed(3)),
            ]),
            const SizedBox(height: 4),
            Text(
              help,
              style:
              TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              min: min,
              max: max,
              divisions: divisions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _intStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label：$value',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: '減少 $label',
              onPressed: value - step >= min ? () => onChanged(value - step) : null,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '增加 $label',
              onPressed: value + step <= max ? () => onChanged(value + step) : null,
            ),
          ],
        ),
      ),
    );
  }
}
