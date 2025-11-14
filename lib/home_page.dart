import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'crosswalk_guide_page.dart';
import 'traffic_light_detect.dart';
import 'options_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();

  @override
  void initState() {
    super.initState();
    // 首次啟動顯示歡迎面板
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarded_v1') ?? false;
    if (!seen) {
      final dontShow = await _showWelcomeSheet(context);
      // 若使用者沒取消打勾，也當作已看過
      if (dontShow) {
        await prefs.setBool('onboarded_v1', true);
      }
    }
  }

  void _onStartPressed() {
    if (guideConfig.useCrosswalkAssist) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CrosswalkGuidePage()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrafficLightPage(
            modelPath: guideConfig.modelLight,
            confThreshold: guideConfig.tlConfThreshold,
          ),
        ),
      );
    }
  }

  void _onOptionsPressed() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OptionsPage()))
        .then((_) => setState(() {}));
  }

  void _onTutorialPressed() => _showTutorial(context);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: null,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primaryContainer.withOpacity(0.65),
              color.surfaceVariant.withOpacity(0.50),
              color.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                child: _HomeCard(
                  onStart: _onStartPressed,
                  onOptions: _onOptionsPressed,
                  onTutorial: _onTutorialPressed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== 首次歡迎面板 =====
  Future<bool> _showWelcomeSheet(BuildContext context) async {
    bool dontShowAgain = true; // 預設勾選
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // 點外面可關閉
      builder: (ctx) {
        return Dialog(
          backgroundColor: color.surface,
          surfaceTintColor: color.surfaceTint,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85, // 最高佔 85% 高
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: StatefulBuilder(
                builder: (context, setSB) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // 視覺把手
                      Container(
                        width: 44, height: 5,
                        decoration: BoxDecoration(
                          color: color.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('歡迎使用',
                                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                '這是一款以相機協助過街的工具，會先引導你對準斑馬線，再進入紅綠燈辨識。',
                                style: text.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),


                              Text('使用介面介紹',
                                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w500)),
                              // 使用步驟
                              ListTile(
                                leading: const Icon(Icons.home_rounded),
                                title: const Text('首頁'),
                                subtitle: Text(
                                  '點「開始」即可啟動偵測流程。如需調整偵測靈敏度、左右反轉、相機解析度或不需要斑馬線輔助，請到「設定」',
                                  style: TextStyle(color: color.onSurfaceVariant),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.directions_walk),
                                title: const Text('斑馬線輔助'),
                                subtitle: Text(
                                  '將手機垂直９０度面對斑馬線後，依語音與畫面提示左右微調，畫面穩定置中後會自動跳轉到紅綠燈辨識。',
                                  style: TextStyle(color: color.onSurfaceVariant),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.traffic_rounded),
                                title: const Text('紅綠燈辨識'),
                                subtitle: Text(
                                  '持續保持手機垂直９０度,按「開始辨識」後進行３秒辨識，輸出紅綠燈辨識結果，若在「設定」關閉斑馬線輔助，將直接進入紅綠燈辨識。',
                                  style: TextStyle(color: color.onSurfaceVariant),
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),

                              // 注意事項
                              Text('注意事項',
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),

                              const _Bullet('在辨識過程中，請保持鏡頭穩定，並且手機垂直９０度（沒有垂直可能會引響辨識效率），並盡量讓斑馬線位於畫面中央。'),
                              const _Bullet('車流量過大的情況下會造成辨識結果有影響。'),
                              const _Bullet('如果不需要斑馬線辨識功能可以至設定關閉，會直接跳轉到紅綠燈辨識。'),
                              const _Bullet('若左右提示與實況相反，可到「設定」開啟左右反轉（flipLR）。'),
                              const _Bullet('辨識過程中有終止鈕，按下即可回到首頁'),

                              Text('免責聲明',
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              const _Bullet('此程式僅作為輔助功能，請注意自身安全，過馬路時仍以路況與行人號誌為準。'),
                              const _Bullet('使用本功能所產生之任何風險與損害，使用者自行承擔；開發者不負賠償或保證責任。'),
                              const _Bullet('請務必遵循行人號誌、路權規定與現場人員指示；緊急情況請以人員協助與官方資訊為準。'),

                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: dontShowAgain,
                                onChanged: (v) => setSB(() => dontShowAgain = v ?? true),
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('下次不再顯示'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 底部主按鈕
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('開始使用'),
                            onPressed: () => Navigator.pop(ctx, dontShowAgain),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }


  // ===== 使用教學（可隨時打開） =====
  void _showTutorial(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('首頁'),
              subtitle: Text(
                '點「開始」即可啟動偵測流程。若在「設定」關閉斑馬線輔助，將直接進入紅綠燈辨識。',
                style: TextStyle(color: color.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('斑馬線輔助'),
              subtitle: Text(
                '將手機垂直９０度面對斑馬線後,依語音與畫面提示左右微調，畫面穩定置中後會自動跳轉到紅綠燈辨識。',
                style: TextStyle(color: color.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.traffic_rounded),
              title: const Text('紅綠燈辨識'),
              subtitle: Text(
                '持續保持手機垂直９０度,按「開始辨識」後進行３秒辨識，輸出紅綠燈辨識結果。',
                style: TextStyle(color: color.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('了解了'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}

class _HomeCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onOptions;
  final VoidCallback onTutorial;

  const _HomeCard({
    required this.onStart,
    required this.onOptions,
    required this.onTutorial,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 8,
      shadowColor: color.primary.withOpacity(0.25),
      surfaceTintColor: color.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主按鈕
            _BigActionButton(
              icon: Icons.play_arrow_rounded,
              label: '開始',
              onPressed: onStart,
            ),
            const SizedBox(height: 12),
            // 次按鈕群
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('選項'),
                    onPressed: onOptions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('使用教學'),
                    onPressed: onTutorial,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          backgroundColor: color.primary,
          foregroundColor: color.onPrimary,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _StepTile({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(desc, style: TextStyle(color: color.onSurfaceVariant)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
