import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'repository.dart';
import 'tenant.dart';
import 'ui_common.dart';

// ---------------- Deals ----------------
class DealsScreen extends StatelessWidget { final VoidCallback? onBack; final String? openCoupon;
  const DealsScreen({super.key, this.onBack, this.openCoupon});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final uses = c.repo.couponUses;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      if (onBack != null) BackRow(onBack!), const ScreenTitle('Nur für Mitglieder', 'Coupons & Deals'),
      for (final cp in t.coupons) Builder(builder: (_) {
        final use = uses.where((u) => u.couponId == cp.id).firstOrNull;
        final exp = DateTime.tryParse(cp.validTo); final expired = exp != null && exp.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        final usable = use?.usedAt == null && !expired;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7), child: Container(
          decoration: BoxDecoration(color: b.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: b.outline)), clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (cp.image.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(12, 12, 0, 12), child: Align(alignment: Alignment.topCenter, child: Container(width: 112, height: 112, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: b.outline)),
              child: Stack(children: [Positioned.fill(child: Padding(padding: const EdgeInsets.all(6), child: assetImg(cp.image, fit: BoxFit.contain))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: b.primary, borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10))),
                    child: Text(cp.label, style: display(18, b.onPrimary)))]))))
            else Container(width: 96, color: usable ? b.primary : b.surfaceAlt, alignment: Alignment.center,
                child: Text(cp.badge, textAlign: TextAlign.center, style: display(28, usable ? b.onPrimary : b.muted))),
            Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cp.title, style: body(17, b.text, FontWeight.w600)), Text(cp.desc, style: body(13, b.muted)), const SizedBox(height: 6),
              Text(use?.usedAt != null ? 'Genutzt am ${fmtTime(use!.usedAt!)}' : expired ? 'Abgelaufen' : 'Gültig bis ${fmtDate(cp.validTo)}',
                  style: body(13, usable ? b.accent : b.muted, FontWeight.w600)),
              if (usable) ...[const SizedBox(height: 8), SecondaryButton(use == null ? 'Aktivieren' : 'Code zeigen', () => showCoupon(c, cp.id), expand: false)],
            ]))),
          ]))));
      }),
    ]); }
}

Future<void> showCoupon(BuildContext c, String id) async {
  final t = c.t; final repo = c.repo; final cp = t.coupons.where((x) => x.id == id).firstOrNull; if (cp == null || repo.customer == null) return;
  await repo.activateCoupon(id);
  if (!c.mounted) return;
  await showDialog(context: c, builder: (_) => Scope(tenant: t, repo: repo, child: ListenableBuilder(listenable: repo, builder: (c, _) {
    final b = c.b; final used = repo.couponUses.where((u) => u.couponId == id).firstOrNull?.usedAt != null;
    return AlertDialog(backgroundColor: b.surface, title: Text(cp.title, style: display(26, b.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 220, height: 220, padding: const EdgeInsets.all(8), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: used ? const Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF2E7D32)) : QrBox(Qr.coupon(t.id, cp.id, repo.customer!.memberCode), size: 204)),
        const SizedBox(height: 10), Text(used ? 'Deal eingelöst' : 'An der Kasse scannen lassen', style: body(14, b.muted)),
        if (!used) Text(cp.desc, textAlign: TextAlign.center, style: body(13, b.text)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Schließen', style: body(15, b.text, FontWeight.w600)))]);
  })));
}

// ---------------- Store ----------------
class StoreScreen extends StatelessWidget { final void Function(Location) onMap; final void Function(String) onCall; final VoidCallback? onBack;
  const StoreScreen({super.key, required this.onMap, required this.onCall, this.onBack});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final today = DateTime.now().weekday;
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      if (onBack != null) BackRow(onBack!),
      HeroImage(t.brand.secondaryImage.isNotEmpty ? t.brand.secondaryImage : t.brand.heroImage, 220),
      ScreenTitle(t.brand.name, t.locations.length > 1 ? 'Filialen' : 'Filiale'),
      for (final (i, l) in t.locations.indexed) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (i > 0) ...[const SizedBox(height: 18), const Rule(), const SizedBox(height: 18)],
        Eyebrow(l.name, color: b.primary), const SizedBox(height: 2),
        Text(l.street, style: body(22, b.text, FontWeight.w600)), Text(l.city, style: body(16, b.muted)), const SizedBox(height: 14),
        Row(children: [Expanded(child: PrimaryButton('Route', () => onMap(l))),
          if (l.phone.isNotEmpty) ...[const SizedBox(width: 10), Expanded(child: SecondaryButton('Anrufen', () => onCall(l.phone)))]]),
        if (l.facts.isNotEmpty) ...[const SizedBox(height: 16), Wrap(spacing: 6, runSpacing: 6, children: [for (final f in l.facts) Tag(f, b.surfaceAlt, b.text)])],
        const SizedBox(height: 18), Eyebrow('Öffnungszeiten', color: b.accent), const SizedBox(height: 4),
        for (final h in [...l.hours]..sort((a, z) => a.day.compareTo(z.day))) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
          Expanded(child: Text(dayNames[(h.day - 1).clamp(0, 6)], style: body(15, b.text, h.day == today ? FontWeight.w700 : FontWeight.w400))),
          Text(h.closed ? 'geschlossen' : '${h.open} – ${h.close}', style: body(15, b.text, h.day == today ? FontWeight.w700 : FontWeight.w400))])),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0), child: Text('An Feiertagen können die Zeiten abweichen.', style: body(13, b.muted))),
    ]); }
}

// ---------------- History ----------------
class HistoryScreen extends StatelessWidget { final VoidCallback onBack; const HistoryScreen({super.key, required this.onBack});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final r = c.repo;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      BackRow(onBack), ScreenTitle(t.pointsName, 'Verlauf'),
      for (final x in r.history) ...[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(children: [
          Icon(x.type == 'PURCHASE' ? Icons.shopping_bag_outlined : x.type == 'REDEEM' ? Icons.redeem_outlined : Icons.star_outline, color: b.muted), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.label, style: body(15, b.text, FontWeight.w600)), Text(fmtTime(x.createdAt), style: body(12, b.muted))])),
          Text('${x.delta > 0 ? '+' : '−'}${x.delta.abs()}', style: body(17, x.delta > 0 ? b.accent : b.text, FontWeight.w700))])),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Rule())],
      if (r.inbox.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 4), child: Eyebrow('Nachrichten', color: b.accent)),
        for (final m in r.inbox) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title, style: body(15, b.text, FontWeight.w600)), Text(m.body, style: body(13, b.muted)), Text(fmtTime(m.createdAt), style: body(11, b.muted))]))],
    ]); }
}

// ---------------- Settings ----------------
class SettingsScreen extends StatelessWidget { final VoidCallback onBack, onStaff, onDeleted; final ValueChanged<bool> onMarketing;
  const SettingsScreen({super.key, required this.onBack, required this.onStaff, required this.onDeleted, required this.onMarketing});
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b; final r = c.repo; final cu = r.customer!;
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      BackRow(onBack), const ScreenTitle('Konto', 'Einstellungen'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cu.name, style: body(18, b.text, FontWeight.w700)), Text(cu.email, style: body(14, b.muted)), Text('Mitglied seit ${fmtTime(cu.createdAt)}', style: body(12, b.muted))])),
        const SizedBox(height: 12),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: cu.marketing, onChanged: onMarketing, activeThumbColor: b.accent,
            title: Text('Push-Nachrichten', style: body(16, b.text, FontWeight.w600)), subtitle: Text('Deals, Aktionen und Punkte-Hinweise', style: body(13, b.muted))),
        const Rule(), const SizedBox(height: 18), Eyebrow('Datenschutz (DSGVO)', color: b.accent), const SizedBox(height: 6),
        Text(t.privacyNote, style: body(14, b.text)), const SizedBox(height: 4), Text('Verantwortlich: ${t.operator}', style: body(12, b.muted)),
        const SizedBox(height: 14),
        SecondaryButton('Meine Daten exportieren (JSON)', () async { await Clipboard.setData(ClipboardData(text: r.exportJson())); if (c.mounted) toast(c, 'Export in die Zwischenablage kopiert'); }),
        const SizedBox(height: 10),
        SecondaryButton('Konto & alle Daten löschen', () async {
          final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(title: const Text('Wirklich löschen?'), content: const Text('Punkte, Verlauf und Coupons werden auf diesem Gerät gelöscht.'),
              actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Abbrechen')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Löschen'))]));
          if (ok == true) { await r.deleteEverything(); onDeleted(); } }),
        const SizedBox(height: 26), const Rule(), const SizedBox(height: 18),
        Eyebrow('Für Mitarbeiter', color: b.muted), const SizedBox(height: 8),
        SecondaryButton('Kassenmodus öffnen', onStaff, key: const Key('staffMode')),
        const SizedBox(height: 22),
        if (t.sources.isNotEmpty) ...[Eyebrow('Quellen & Hinweise'), const SizedBox(height: 4), for (final s in t.sources) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('· $s', style: body(11, b.muted)))],
        const SizedBox(height: 8), Text('${t.appName} · Version ${t.versionName}', style: body(11, b.muted)),
      ])),
    ]); }
}

// ---------------- Staff / cashier mode ----------------
class StaffScreen extends StatefulWidget { final VoidCallback onBack; final void Function(String, String) onPush;
  const StaffScreen({super.key, required this.onBack, required this.onPush}); @override State<StaffScreen> createState() => _StaffState(); }
class _StaffState extends State<StaffScreen> {
  bool unlocked = false; final pin = TextEditingController(), code = TextEditingController(), amount = TextEditingController(); StaffResult? res;
  Future<void> handle(String raw) async {
    final r = context.repo; final t = context.t; final p = Qr.parse(raw);
    StaffResult out;
    if (p == null) { out = const StaffResult(false, 'Kein Kunden-Code'); }
    else if (p[1] != t.id) { out = const StaffResult(false, 'Code gehört zu einem anderen Laden'); }
    else if (p[2] == 'M') { code.text = p[3]; out = StaffResult(true, 'Mitglied ${p[3]}', 'Betrag eingeben und gutschreiben'); }
    else if (p[2] == 'R') { out = await r.validateRedemption(p[3]); }
    else if (p[2] == 'C' && p.length >= 5) { out = await r.validateCoupon(p[3], p[4]); }
    else { out = const StaffResult(false, 'Unbekannter Code'); }
    setState(() => res = out);
  }
  Future<void> scan() async {
    final raw = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
    if (raw != null) await handle(raw);
  }
  @override Widget build(BuildContext c) { final t = c.t; final b = c.b;
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      BackRow(widget.onBack), ScreenTitle(t.brand.name, 'Kassenmodus'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: !unlocked
        ? Column(children: [
            TextField(key: const Key('pin'), controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mitarbeiter-PIN')),
            const SizedBox(height: 12),
            PrimaryButton('Entsperren', () { if (pin.text == t.staffPin) { setState(() => unlocked = true); } else { toast(c, 'Falsche PIN'); } }),
            const SizedBox(height: 8), Text('Demo-PIN: ${t.staffPin}', style: body(12, b.muted))])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PrimaryButton('QR-Code scannen', scan, key: const Key('scan')), const SizedBox(height: 14),
            if (res != null) Container(width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: res!.ok ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(res!.title, style: body(18, const Color(0xFF14100E), FontWeight.w700)),
                if (res!.detail.isNotEmpty) Text(res!.detail, style: body(14, const Color(0xFF3A3A3A)))])),
            Eyebrow('Einkauf gutschreiben', color: b.accent), const SizedBox(height: 8),
            TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Mitgliedsnummer')),
            const SizedBox(height: 10),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Betrag in €')),
            const SizedBox(height: 10),
            SecondaryButton('Punkte gutschreiben', () async {
              final v = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
              final out = await c.repo.creditPurchase(code.text, v); setState(() { res = out; if (out.ok) amount.clear(); }); }),
            const SizedBox(height: 24), Eyebrow('Push-Aktion senden (Demo, lokal)', color: b.accent), const SizedBox(height: 8),
            for (final m in t.campaigns) Padding(padding: const EdgeInsets.only(bottom: 8), child: SecondaryButton(m.title, () { widget.onPush(m.title, m.body); toast(c, 'Gesendet: ${m.title}'); })),
          ])),
    ]); }
}

class ScanPage extends StatefulWidget { const ScanPage({super.key}); @override State<ScanPage> createState() => _ScanState(); }
class _ScanState extends State<ScanPage> { bool done = false;
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Kunden-QR scannen')),
    body: Stack(children: [
      MobileScanner(onDetect: (cap) { final v = cap.barcodes.firstOrNull?.rawValue; if (v != null && !done) { done = true; HapticFeedback.mediumImpact(); Navigator.pop(c, v); } }),
      Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)))),
      const Positioned(left: 0, right: 0, bottom: 40, child: Text('QR-Code in den Rahmen halten', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16))),
    ]));
}
