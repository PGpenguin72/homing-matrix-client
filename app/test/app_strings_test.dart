// 多語言字串層（第五十七批）單元測試。
//
// 對應實作：`app/lib/l10n/app_strings.dart`（**零新依賴**的自建字串表：
// key ＝ 繁中原文，缺翻譯時自動回落原文）。
import 'package:flutter_test/flutter_test.dart';
import 'package:homing/l10n/app_strings.dart';

void main() {
  group('AppStrings（第五十七批）', () {
    tearDown(() {
      // 還原預設語言（避免影響同行程其他測試）。
      setAppLocale(AppLocale.zhTW);
    });

    test('預設語言為繁中 → 原樣回傳', () {
      expect(currentAppLocale, AppLocale.zhTW);
      expect(S.t('設定'), '設定');
    });

    test('切英文 → 有翻譯者回英文', () {
      setAppLocale(AppLocale.en);
      expect(currentAppLocale, AppLocale.en);
      expect(S.t('設定'), 'Settings');
      expect(S.t('顯示通知'), 'Show notifications');
    });

    test('切英文 → 查無翻譯者回落繁中原文（不顯示空字串）', () {
      setAppLocale(AppLocale.en);
      expect(S.t('這是尚未翻譯的字串'), '這是尚未翻譯的字串');
    });

    test('切回繁中 → 再次原樣回傳', () {
      setAppLocale(AppLocale.en);
      setAppLocale(AppLocale.zhTW);
      expect(S.t('設定'), '設定');
    });

    test('notifier 會通知變化（供上層重建 → 文字即時更新）', () {
      var notified = 0;
      void listener() => notified++;
      appLocaleNotifier.addListener(listener);
      addTearDown(() => appLocaleNotifier.removeListener(listener));
      setAppLocale(AppLocale.en);
      expect(notified, 1);
      setAppLocale(AppLocale.en); // 同一語言 → 不再通知
      expect(notified, 1);
    });
  });
}
