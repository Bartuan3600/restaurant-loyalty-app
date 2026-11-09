import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notify.dart';
import 'repository.dart';
import 'screens_main.dart';
import 'screens_more.dart';
import 'tenant.dart';
import 'ui_common.dart';

enum TabId { home, menu, code, rewards, more }
enum Sheet { none, history, settings, staff, deals, store }
const _tabs = [
  (TabId.home, 'Start', Icons.home_outlined), (TabId.menu, 'Speisekarte', Icons.menu_book_outlined),
  (TabId.code, 'Mein Code', Icons.qr_code_2), (TabId.rewards, 'Prämien', Icons.redeem_outlined), (TabId.more, 'Mehr', Icons.menu)];

class LoyaltyApp extends StatelessWidget {
  final Tenant tenant; final LoyaltyRepository repo; final TabId initialTab; final Sheet initialOverlay;
  const LoyaltyApp({super.key, required this.tenant, required this.repo, this.initialTab = TabId.home, this.initialOverlay = Sheet.none});
  @override Widget build(BuildContext context) {
    final b = tenant.brand;
    SystemChrome.setSystemUIOverlayStyle((b.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: b.bg, systemNavigationBarColor: b.surface));
    return Scope(tenant: tenant, repo: repo, child: MaterialApp(title: tenant.appName, debugShowCheckedModeBanner: false, theme: buildTheme(b),
      builder: (c, child) => Scope(tenant: tenant, repo: repo, child: child!),
      home: Shell(initialTab: initialTab, initialOverlay: initialOverlay)));
  }
}

class Shell extends StatefulWidget { final TabId initialTab; final Sheet initialOverlay;
  const Shell({super.key, this.initialTab = TabId.home, this.initialOverlay = Sheet.none}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  late TabId tab = widget.initialTab; late Sheet overlay = widget.initialOverlay;

  Future<void> openMap(Location l) async {
    final q = Uri.encodeComponent('${context.t.brand.name}, ${l.street}, ${l.city}');
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'), mode: LaunchMode.externalApplication);
  }
  Future<void> onLogo() async {
    final locs = context.t.locations; if (locs.isEmpty) return;
    final l = locs.length > 1 ? await pickLocation(context) : locs.first; if (l != null) await openMap(l);
  }
  Future<void> push(String title, String body) async {
    final r = context.repo; await r.addInbox(title, body);
    if (r.customer?.marketing == true) await Notify.show(title, body);
  }

  @override Widget build(BuildContext c) => ListenableBuilder(listenable: c.repo, builder: (c, _) {
    final b = c.b; final repo = c.repo;
    if (repo.customer == null) {
      return Scaffold(body: OnboardingScreen((n, e, m) async { await repo.signUp(n, e, m); if (m) Notify.requestPermission(); setState(() { tab = TabId.home; overlay = Sheet.none; }); }));
    }
    void close() => setState(() => overlay = overlay == Sheet.staff ? Sheet.settings : Sheet.none);
    final Widget page = switch (overlay) {
      Sheet.history => HistoryScreen(onBack: close),
      Sheet.settings => SettingsScreen(onBack: close, onStaff: () => setState(() => overlay = Sheet.staff), onDeleted: () => setState(() => overlay = Sheet.none),
          onMarketing: (on) { repo.setMarketing(on); if (on) Notify.requestPermission(); }),
      Sheet.staff => StaffScreen(onBack: close, onPush: push),
      Sheet.deals => DealsScreen(onBack: close),
      Sheet.store => StoreScreen(onMap: openMap, onCall: (p) => launchUrl(Uri.parse('tel:${p.replaceAll(' ', '')}')), onBack: close),
      Sheet.none => switch (tab) {
        TabId.home => HomeScreen(onAllCoupons: () => setState(() => overlay = Sheet.deals), onPromo: () => setState(() => tab = TabId.code), onCoupon: (id) => showCoupon(c, id)),
        TabId.menu => const MenuScreen(),
        TabId.code => MyCodeScreen(onRewards: () => setState(() => tab = TabId.rewards)),
        TabId.rewards => const RewardsScreen(),
        TabId.more => MoreScreen(onStore: () => setState(() => overlay = Sheet.store), onDeals: () => setState(() => overlay = Sheet.deals),
            onHistory: () => setState(() => overlay = Sheet.history), onSettings: () => setState(() => overlay = Sheet.settings)),
      },
    };
    return PopScope(canPop: overlay == Sheet.none && tab == TabId.home, onPopInvokedWithResult: (did, _) { if (!did) setState(() { if (overlay != Sheet.none) { close(); } else { tab = TabId.home; } }); },
      child: Scaffold(backgroundColor: b.bg,
        appBar: overlay == Sheet.none ? PreferredSize(preferredSize: const Size.fromHeight(64), child: SafeArea(bottom: false, child: BrandTopBar(onLogo: onLogo, onPoints: () => setState(() => tab = TabId.code)))) : null,
        body: SafeArea(top: overlay != Sheet.none, bottom: false, child: page),
        bottomNavigationBar: overlay != Sheet.none ? null : NavigationBarTheme(
          data: NavigationBarThemeData(labelTextStyle: WidgetStateProperty.resolveWith((s) => body(12, s.contains(WidgetState.selected) ? b.text : b.muted, s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500))),
          child: NavigationBar(backgroundColor: b.surface, surfaceTintColor: Colors.transparent, indicatorColor: b.primary, height: 72,
            selectedIndex: _tabs.indexWhere((x) => x.$1 == tab), onDestinationSelected: (i) => setState(() => tab = _tabs[i].$1),
            destinations: [for (final x in _tabs) NavigationDestination(key: Key('tab_${x.$1.name}'), icon: Icon(x.$3, color: b.muted), selectedIcon: Icon(x.$3, color: b.onPrimary), label: x.$2)])),
      ));
  });
}
