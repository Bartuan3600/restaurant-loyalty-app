import 'package:flutter/material.dart';
import 'repository.dart';
import 'tenant.dart';
import 'ui_common.dart';

// ---------------- Top bar ----------------
class BrandTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogo, onPoints;
  const BrandTopBar({super.key, required this.onLogo, required this.onPoints});
  @override Size get preferredSize => const Size.fromHeight(64);
  @override Widget build(BuildContext c) { final b = c.b; final t = c.t;
    return Container(color: b.surface, height: 64, padding: const EdgeInsets.symmetric(horizontal: 14), child: Stack(children: [
      Center(child: InkWell(key: const Key('logo'), borderRadius: BorderRadius.circular(8), onTap: onLogo, child: Padding(padding: const EdgeInsets.all(4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (t.brand.logo.isNotEmpty) Container(width: 44, height: 44, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: b.outline)),
              child: assetImg(t.brand.logo, fit: BoxFit.contain))
          else Text(t.brand.wordmarkMain, style: display(22, b.text)),
          const SizedBox(width: 6), Icon(Icons.location_on_outlined, color: b.primary, size: 24),
        ])))),
      Align(alignment: Alignment.centerRight, child: InkWell(key: const Key('pointsChip'), onTap: onPoints, borderRadius: BorderRadius.circular(10),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: b.text, width: 1.5), color: b.surface),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: b.primary, shape: BoxShape.circle)),
            const SizedBox(width: 7), Text('${c.repo.balance} ${t.pointsName}', style: body(16, b.text, FontWeight.w700)),
          ])))),
    ])); }
}

// ---------------- Onboarding ----------------
class OnboardingScreen extends StatefulWidget { final void Function(String, String, bool) onSignUp;
  const OnboardingScreen(this.onSignUp, {super.key});
  @override State<OnboardingScreen> createState() => _OnbState(); }
class _OnbState extends State<OnboardingScreen> {
  final name = TextEditingController(), email = TextEditingController(); bool privacy = false, marketing = true;
  bool get emailOk => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim());
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b;
    Widget check(bool v, ValueChanged<bool> on, String text, String key) => InkWell(key: Key(key), onTap: () => on(!v), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Checkbox(value: v, onChanged: (x) => on(x ?? false), side: BorderSide(color: b.muted, width: 2)),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(text, style: body(13, b.text))))])));
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeroImage(t.brand.heroImage, 340, child: Positioned(left: 20, bottom: 20, right: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (t.brand.wordmarkTop.isNotEmpty) Text(t.brand.wordmarkTop, style: body(12, b.accent, FontWeight.w600).copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 4), Text(b.dark ? t.brand.wordmarkMain.toUpperCase() : t.brand.wordmarkMain, style: display(44, b.text))]))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.brand.tagline, style: body(15, b.muted)), const SizedBox(height: 20),
        Text(b.dark ? 'SAMMELN. ESSEN. WIEDERHOLEN.' : 'Sammeln, genießen, wiederkommen.', style: display(28, b.text)), const SizedBox(height: 8),
        Text('${t.pointsPerEuro} ${t.pointsName} pro Euro. ${t.signupBonus} ${t.pointsName} gibt\'s direkt zur Anmeldung.', style: body(17, b.text)),
        const SizedBox(height: 20),
        TextField(key: const Key('name'), controller: name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Vorname'), style: body(16, b.text)),
        const SizedBox(height: 10),
        TextField(key: const Key('email'), controller: email, onChanged: (_) => setState(() {}), keyboardType: TextInputType.emailAddress, style: body(16, b.text),
            decoration: InputDecoration(labelText: 'E-Mail', errorText: email.text.isNotEmpty && !emailOk ? 'Bitte gültige E-Mail' : null)),
        const SizedBox(height: 12),
        check(privacy, (v) => setState(() => privacy = v), 'Ich akzeptiere die Datenschutzerklärung. ${t.privacyNote}', 'privacy'),
        check(marketing, (v) => setState(() => marketing = v), 'Push-Nachrichten zu Deals und Punkten erhalten (jederzeit abbestellbar).', 'marketing'),
        const SizedBox(height: 16),
        PrimaryButton('Mitglied werden', name.text.trim().isNotEmpty && emailOk && privacy ? () => widget.onSignUp(name.text, email.text, marketing) : null, key: const Key('signup')),
        const SizedBox(height: 10),
        Center(child: Text('Demo-App · Daten bleiben auf diesem Gerät', style: body(12, b.muted))), const SizedBox(height: 28),
      ])),
    ])); }
}

// ---------------- Home ----------------
class HomeScreen extends StatelessWidget { final VoidCallback onAllCoupons, onPromo; final void Function(String couponId) onCoupon;
  const HomeScreen({super.key, required this.onAllCoupons, required this.onCoupon, required this.onPromo});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final h = t.hero;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      AspectRatio(aspectRatio: 16 / 10.5, child: ColoredBox(color: Colors.white, child: Stack(fit: StackFit.expand, children: [
        ?assetImg(h?.image ?? t.brand.heroImage),
        Positioned(left: 18, top: 18, width: MediaQuery.sizeOf(c).width * .62, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if ((h?.eyebrow ?? '').isNotEmpty) Container(color: b.primary, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(h!.eyebrow.toUpperCase(), style: body(12, b.onPrimary, FontWeight.w600).copyWith(letterSpacing: 1.2))),
          const SizedBox(height: 8),
          Text(h?.title ?? t.brand.wordmarkMain, style: display(38, b.text)),
          if ((h?.subtitle ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(h!.subtitle, style: body(15, b.text, FontWeight.w600))],
        ])),
        Positioned(left: 16, bottom: 16, child: FilledButton(key: const Key('heroCta'),
          onPressed: () => (h?.couponId ?? '').isNotEmpty ? onCoupon(h!.couponId) : onAllCoupons(),
          style: FilledButton.styleFrom(backgroundColor: b.primary, foregroundColor: b.onPrimary, minimumSize: const Size(170, 50), elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(h?.cta.isNotEmpty == true ? h!.cta : 'Jetzt sichern', style: body(17, b.onPrimary, FontWeight.w700)))),
      ]))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), child: Text('Nur mit der App. Solange der Vorrat reicht.', style: body(13, b.muted))),
      if (t.promo != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Material(color: b.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: b.outline)), clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onPromo, child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 8, color: b.primary),
          if (t.promo!.image.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 10), child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: assetImg(t.promo!.image, w: 64, h: 64)))),
          Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t.promo!.title, style: body(17, b.text, FontWeight.w700)),
            if (t.promo!.body.isNotEmpty) Text(t.promo!.body, style: body(15, b.text))]))),
          Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.chevron_right, color: b.text)),
        ]))))),
      Padding(padding: const EdgeInsets.fromLTRB(18, 22, 6, 10), child: Row(children: [
        Expanded(child: Text('Coupons', style: display(30, b.text))),
        TextButton(onPressed: onAllCoupons, child: Row(children: [Text('Alles anzeigen', style: body(15, b.primary, FontWeight.w700)), const SizedBox(width: 4), Icon(Icons.arrow_forward, size: 18, color: b.primary)])),
      ])),
      SizedBox(height: 228, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: t.coupons.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) { final cp = t.coupons[i];
          return GestureDetector(key: Key('coupon_${cp.id}'), onTap: () => onCoupon(cp.id), child: SizedBox(width: 158, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 158, height: 158, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: b.outline)),
              child: Stack(children: [
                if (cp.image.isNotEmpty) Positioned.fill(child: Padding(padding: const EdgeInsets.fromLTRB(8, 30, 8, 6), child: assetImg(cp.image, fit: BoxFit.contain))),
                Positioned(left: 10, top: 6, child: BigPrice(cp.label)),
              ])),
            const SizedBox(height: 8),
            Text(cp.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(17, b.text, FontWeight.w500)),
            Text('Gültig bis ${fmtDate(cp.validTo)}', style: body(13, b.muted)),
          ]))); })),
      if (t.news.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(18, 28, 18, 12), child: Text("Was gibt's Neues", style: display(30, b.text))),
      for (final n in t.news) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Container(clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: b.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: b.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (n.image.isNotEmpty) AspectRatio(aspectRatio: 16 / 9, child: assetImg(n.image)),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.title, style: display(24, b.text)),
            if (n.body.isNotEmpty) ...[const SizedBox(height: 4), Text(n.body, style: body(15, b.muted))]])),
        ]))),
    ]); }
}

// ---------------- Menu ----------------
class MenuScreen extends StatefulWidget { const MenuScreen({super.key}); @override State<MenuScreen> createState() => _MenuState(); }
class _MenuState extends State<MenuScreen> { int cat = 0;
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b;
    if (t.menu.isEmpty) return const ScreenTitle('', 'Speisekarte');
    final items = t.menu[cat.clamp(0, t.menu.length - 1)].items;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTitle(t.brand.name, 'Speisekarte'),
      SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: t.menu.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8), itemBuilder: (_, i) { final sel = i == cat;
          return InkWell(borderRadius: BorderRadius.circular(20), onTap: () => setState(() => cat = i), child: Container(alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: sel ? b.primary : b.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? b.primary : b.outline)),
            child: Text(t.menu[i].category, style: body(16, sel ? b.onPrimary : b.text, FontWeight.w700)))); })),
      const SizedBox(height: 8),
      Expanded(child: ListView(key: ValueKey(cat), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), children: [
        for (final it in items) ...[
          Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(crossAxisAlignment: it.image.isNotEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
            if (it.image.isNotEmpty) ...[Container(width: 84, height: 84, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: b.outline)),
                child: assetImg(it.image, fit: BoxFit.contain)), const SizedBox(width: 14)],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(it.name, style: body(17, b.text, FontWeight.w600))),
                if (it.tag == 'veggie') ...[const SizedBox(width: 8), const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF6BBF59))]]),
              if (it.desc.isNotEmpty) Text(it.desc, style: body(13, b.muted)),
            ])),
            const SizedBox(width: 8),
            Text(euro.format(it.price) + (it.demoPrice ? '*' : ''), style: body(17, b.text, FontWeight.w600)),
          ])),
          const Rule(),
        ],
        const SizedBox(height: 14),
        Text('+ ${t.pointsPerEuro} ${t.pointsName} pro Euro auf alles.', style: body(15, b.accent)),
        if (t.menu.any((m) => m.items.any((i) => i.demoPrice))) Text('* Demo-Preis, nicht vom Laden bestätigt', style: body(13, b.muted)),
      ])),
    ]); }
}

// ---------------- My code ----------------
class MyCodeScreen extends StatelessWidget { final VoidCallback onRewards;
  const MyCodeScreen({super.key, required this.onRewards});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final cu = c.repo.customer!; final bal = c.repo.balance;
    final next = t.rewards.where((r) => r.points > bal).firstOrNull;
    final prev = t.rewards.where((r) => r.points <= bal).lastOrNull?.points ?? 0;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Text('Mein Code', style: display(34, b.text)), const SizedBox(height: 6),
      Text('An der Kasse zeigen – Punkte sammeln & Prämien einlösen', textAlign: TextAlign.center, style: body(15, b.muted)),
      const SizedBox(height: 18),
      AspectRatio(aspectRatio: 1, child: Container(padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: b.outline)),
          child: QrBox(Qr.member(t.id, cu.memberCode), key: const Key('memberQr')))),
      const SizedBox(height: 14),
      Text(cu.memberCode, key: const Key('memberCode'), style: display(32, b.text)),
      Text('Mitgliedsnummer · ${cu.name}', style: body(13, b.muted)), const SizedBox(height: 22),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$bal', key: const Key('balance'), style: display(48, b.primary)), const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(t.pointsName, style: body(17, b.text, FontWeight.w600)))]),
        const SizedBox(height: 8),
        PointsBar(next == null ? 1 : (bal - prev) / (next.points - prev).clamp(1, 1 << 30)), const SizedBox(height: 8),
        Text(next != null ? 'Noch ${next.points - bal} bis ${next.name}' : 'Alle Prämien freigeschaltet', style: body(15, b.text)),
        const SizedBox(height: 10), SecondaryButton('Prämien ansehen', onRewards),
      ])),
    ])); }
}

// ---------------- Rewards ----------------
class RewardsScreen extends StatelessWidget { const RewardsScreen({super.key});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final bal = c.repo.balance;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      ScreenTitle('Du hast $bal ${t.pointsName}', 'Prämien'),
      for (final r in t.rewards) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7), child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: b.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: bal >= r.points ? b.accent.withValues(alpha: .6) : b.outline)),
        child: Row(children: [
          SizedBox(width: 70, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.points}', style: display(34, bal >= r.points ? b.accent : b.muted)),
            const SizedBox(height: 4), Text(t.pointsName.toUpperCase(), style: body(11, b.muted, FontWeight.w600).copyWith(letterSpacing: 1.2))])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: body(17, b.text, FontWeight.w600)),
            Text(bal >= r.points ? r.desc : 'Noch ${r.points - bal} ${t.pointsName}', style: body(13, b.muted))])),
          if (bal >= r.points) FilledButton(key: Key('redeem_${r.id}'), onPressed: () async {
                final red = await c.repo.createRedemption(r.id);
                if (c.mounted) showDialog(context: c, builder: (_) => Scope(tenant: t, repo: c.repo, child: RedeemDialog(red.token)));
              }, style: FilledButton.styleFrom(backgroundColor: b.primary, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('EINLÖSEN', style: body(15, b.onPrimary, FontWeight.w700).copyWith(letterSpacing: .6)))
          else Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.lock_outline, color: b.muted)),
        ]))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Text('Der Einlöse-Code gilt ${t.redeemQrSeconds} Sekunden und nur einmal. ${t.pointsName} werden erst beim Scannen an der Kasse abgezogen.', style: body(13, b.muted))),
    ]); }
}

class RedeemDialog extends StatefulWidget { final String token; const RedeemDialog(this.token, {super.key}); @override State<RedeemDialog> createState() => _RedeemState(); }
class _RedeemState extends State<RedeemDialog> {
  @override void initState() { super.initState(); _tick(); }
  void _tick() => Future.delayed(const Duration(seconds: 1), () { if (mounted) { setState(() {}); _tick(); } });
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b;
    return ListenableBuilder(listenable: c.repo, builder: (c, _) {
      final r = c.repo.redemption(widget.token)!;
      final left = ((r.expiresAt - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 1 << 30);
      final done = r.status == 'REDEEMED'; final expired = !done && left <= 0;
      return Dialog(backgroundColor: b.surface, child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Eyebrow('Prämie einlösen', color: b.accent), const SizedBox(height: 4),
        Text(r.rewardName, style: display(28, b.text)), const SizedBox(height: 14),
        Container(width: 240, height: 240, alignment: Alignment.center, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: done ? const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF2E7D32)), Text('Eingelöst – guten Appetit!')])
              : expired ? const Text('Code abgelaufen') : QrBox(Qr.redeem(t.id, r.token), size: 224)),
        const SizedBox(height: 14),
        if (!done && !expired) ...[
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: left / t.redeemQrSeconds, minHeight: 6, color: b.accent, backgroundColor: b.surfaceAlt)),
          const SizedBox(height: 6), Text('Gültig noch $left s · Code ${r.token.substring(0, 8).toUpperCase()}', style: body(12, b.muted)),
        ],
        const SizedBox(height: 14), SecondaryButton(done ? 'Fertig' : 'Schließen', () => Navigator.pop(c)),
      ])));
    }); }
}

// ---------------- More ----------------
class MoreScreen extends StatelessWidget { final VoidCallback onStore, onDeals, onHistory, onSettings;
  const MoreScreen({super.key, required this.onStore, required this.onDeals, required this.onHistory, required this.onSettings});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b;
    final rows = [
      (Icons.storefront_outlined, t.locations.length > 1 ? 'Filialen & Öffnungszeiten' : 'Filiale & Öffnungszeiten', onStore),
      (Icons.local_offer_outlined, 'Coupons & Deals', onDeals),
      (Icons.receipt_long_outlined, 'Punkteverlauf & Nachrichten', onHistory),
      (Icons.settings_outlined, 'Einstellungen & Datenschutz', onSettings)];
    return ListView(children: [ScreenTitle(t.brand.name, 'Mehr'),
      for (final r in rows) ...[
        InkWell(onTap: r.$3, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), child: Row(children: [
          Icon(r.$1, color: b.primary), const SizedBox(width: 16), Expanded(child: Text(r.$2, style: body(17, b.text, FontWeight.w500))), Icon(Icons.chevron_right, color: b.muted)]))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Rule()),
      ]]); }
}

/// Bottom sheet to choose a branch for the map.
Future<Location?> pickLocation(BuildContext c) => showModalBottomSheet<Location>(context: c, backgroundColor: c.b.surface, builder: (_) {
  final b = c.b; final t = c.t;
  return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Route zu welcher Filiale?', style: display(26, b.text)), const SizedBox(height: 12),
    for (final l in t.locations) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.location_on_outlined, color: b.primary),
        title: Text(l.name, style: body(17, b.text, FontWeight.w600)), subtitle: Text('${l.street}, ${l.city}', style: body(13, b.muted)),
        trailing: Icon(Icons.directions_outlined, color: b.text), onTap: () => Navigator.pop(c, l)),
  ])));
});
