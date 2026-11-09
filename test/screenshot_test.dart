// Renders every main screen of the active tenant to screenshots/<tenant>/ (run: tools/screenshots.sh <id>).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_app/src/app.dart';
import 'package:loyalty_app/src/repository.dart';
import 'package:loyalty_app/src/tenant.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadFont(String family, String path) async { final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync()))); await l.load(); }

void main() {
  late Tenant t;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    t = await Tenant.load(); await t.loadFonts();
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? (throw 'Set FLUTTER_ROOT');
    await loadFont('MaterialIcons', '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });

  Future<LoyaltyRepository> repo({bool signedUp = true}) async {
    SharedPreferences.setMockInitialValues({});
    final r = LocalLoyaltyRepository(t); await r.init();
    if (signedUp) { final c = await r.signUp('Max', 'max@example.com', true); await r.creditPurchase(c.memberCode, 25.5); }
    return r;
  }

  Future<void> shot(WidgetTester tester, String name, Widget app, {Future<void> Function()? act}) async {
    tester.view.physicalSize = const Size(1080, 2340); tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app); await tester.pump();
    if (act != null) { await act(); }
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) { final w = e.widget as Image; await precacheImage(w.image, e); }
      });
      await tester.pump(const Duration(milliseconds: 400));
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../screenshots/${t.id}/$name.png'));
  }

  testWidgets('01 onboarding', (tt) async => shot(tt, '01_onboarding', LoyaltyApp(tenant: t, repo: await tt.runAsync(() => repo(signedUp: false)) as LoyaltyRepository)));
  for (final (n, tab) in [('02_home', TabId.home), ('03_menu', TabId.menu), ('03b_my_code', TabId.code), ('04_rewards', TabId.rewards), ('06b_more', TabId.more)]) {
    testWidgets(n, (tt) async => shot(tt, n, LoyaltyApp(tenant: t, repo: (await tt.runAsync(() => repo()))!, initialTab: tab)));
  }
  for (final (n, o) in [('06_deals', Sheet.deals), ('07_store', Sheet.store), ('08_history', Sheet.history), ('09_settings', Sheet.settings)]) {
    testWidgets(n, (tt) async => shot(tt, n, LoyaltyApp(tenant: t, repo: (await tt.runAsync(() => repo()))!, initialOverlay: o)));
  }
  testWidgets('05_redeem_qr', (tt) async {
    final r = (await tt.runAsync(() => repo()))!;
    await shot(tt, '05_redeem_qr', LoyaltyApp(tenant: t, repo: r, initialTab: TabId.rewards), act: () async {
      await tt.tap(find.byKey(Key('redeem_${t.rewards.first.id}'))); await tt.runAsync(() => Future.delayed(const Duration(milliseconds: 100))); await tt.pump(const Duration(milliseconds: 300));
    });
    await tt.pumpWidget(const SizedBox()); await tt.pump(const Duration(seconds: 61));
  });
  testWidgets('02b_home_scrolled', (tt) async {
    await shot(tt, '02b_home_scrolled', LoyaltyApp(tenant: t, repo: (await tt.runAsync(() => repo()))!), act: () async {
      await tt.drag(find.byType(ListView).first, const Offset(0, -700)); await tt.pump(); });
  });
}
