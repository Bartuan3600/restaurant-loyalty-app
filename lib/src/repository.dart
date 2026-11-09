import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tenant.dart';

/// QR format (identical to the Kotlin app): LOY1|<tenant>|<kind>|<value>[|<extra>]
class Qr {
  static String member(String t, String code) => 'LOY1|$t|M|$code';
  static String redeem(String t, String token) => 'LOY1|$t|R|$token';
  static String coupon(String t, String id, String code) => 'LOY1|$t|C|$id|$code';
  static List<String>? parse(String raw) { final p = raw.trim().split('|'); return p.length >= 4 && p[0] == 'LOY1' ? p : null; }
}

class Customer {
  final String id, name, email, memberCode; final bool marketing; final int createdAt;
  Customer(this.id, this.name, this.email, this.memberCode, this.marketing, this.createdAt);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'memberCode': memberCode, 'marketing': marketing, 'createdAt': createdAt};
  factory Customer.fromJson(Map j) => Customer(j['id'], j['name'], j['email'], j['memberCode'], j['marketing'] == true, j['createdAt']);
  Customer copyWith({bool? marketing}) => Customer(id, name, email, memberCode, marketing ?? this.marketing, createdAt);
}
class PointTx { final int delta, createdAt; final String type, label;
  PointTx(this.delta, this.type, this.label, this.createdAt);
  Map toJson() => {'delta': delta, 'type': type, 'label': label, 'createdAt': createdAt};
  factory PointTx.fromJson(Map j) => PointTx(j['delta'], j['type'], j['label'], j['createdAt']); }
class Redemption { final String token, rewardId, rewardName; final int points, createdAt, expiresAt; String status; int? redeemedAt;
  Redemption(this.token, this.rewardId, this.rewardName, this.points, this.createdAt, this.expiresAt, this.status, [this.redeemedAt]);
  Map toJson() => {'token': token, 'rewardId': rewardId, 'rewardName': rewardName, 'points': points, 'createdAt': createdAt, 'expiresAt': expiresAt, 'status': status, 'redeemedAt': redeemedAt};
  factory Redemption.fromJson(Map j) => Redemption(j['token'], j['rewardId'], j['rewardName'], j['points'], j['createdAt'], j['expiresAt'], j['status'], j['redeemedAt']); }
class CouponUse { final String couponId; final int activatedAt; int? usedAt;
  CouponUse(this.couponId, this.activatedAt, [this.usedAt]);
  Map toJson() => {'couponId': couponId, 'activatedAt': activatedAt, 'usedAt': usedAt};
  factory CouponUse.fromJson(Map j) => CouponUse(j['couponId'], j['activatedAt'], j['usedAt']); }
class InboxMessage { final String title, body; final int createdAt;
  InboxMessage(this.title, this.body, this.createdAt);
  Map toJson() => {'title': title, 'body': body, 'createdAt': createdAt};
  factory InboxMessage.fromJson(Map j) => InboxMessage(j['title'], j['body'], j['createdAt']); }

class StaffResult { final bool ok; final String title, detail; const StaffResult(this.ok, this.title, [this.detail = '']); }

/// Backend boundary. The demo uses [LocalLoyaltyRepository] (on-device). For production implement this
/// against Supabase (Postgres + RLS + Edge Functions) – the UI only talks to this interface.
abstract class LoyaltyRepository extends ChangeNotifier {
  Customer? get customer;
  int get balance;
  List<PointTx> get history;
  List<CouponUse> get couponUses;
  List<InboxMessage> get inbox;
  Redemption? redemption(String token);
  Future<void> init();
  Future<Customer> signUp(String name, String email, bool marketing);
  Future<void> setMarketing(bool on);
  Future<Redemption> createRedemption(String rewardId);
  Future<void> activateCoupon(String couponId);
  Future<void> addInbox(String title, String body);
  // staff side (production: Edge Function with staff JWT)
  Future<StaffResult> creditPurchase(String memberCode, double amountEuro);
  Future<StaffResult> validateRedemption(String token);
  Future<StaffResult> validateCoupon(String couponId, String memberCode);
  // GDPR
  String exportJson();
  Future<void> deleteEverything();
}

class LocalLoyaltyRepository extends LoyaltyRepository {
  final Tenant t; final int Function() now; final _rnd = Random.secure();
  LocalLoyaltyRepository(this.t, {int Function()? now}) : now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  SharedPreferences? _p;
  Customer? _c; List<PointTx> _tx = []; List<Redemption> _red = []; List<CouponUse> _cu = []; List<InboxMessage> _inbox = [];
  String get _key => 'loyalty_${t.id}';

  @override Customer? get customer => _c;
  @override int get balance => _tx.fold(0, (s, x) => s + x.delta);
  @override List<PointTx> get history => _tx.reversed.toList();
  @override List<CouponUse> get couponUses => _cu;
  @override List<InboxMessage> get inbox => _inbox.reversed.toList();
  @override Redemption? redemption(String token) => _red.where((r) => r.token == token).firstOrNull;

  @override Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final s = _p!.getString(_key);
    if (s != null) {
      final j = jsonDecode(s);
      _c = j['customer'] == null ? null : Customer.fromJson(j['customer']);
      _tx = [for (final x in j['tx'] ?? []) PointTx.fromJson(x)];
      _red = [for (final x in j['red'] ?? []) Redemption.fromJson(x)];
      _cu = [for (final x in j['cu'] ?? []) CouponUse.fromJson(x)];
      _inbox = [for (final x in j['inbox'] ?? []) InboxMessage.fromJson(x)];
    }
    notifyListeners();
  }
  Future<void> _save() async {
    notifyListeners();
    await _p?.setString(_key, jsonEncode({'customer': _c?.toJson(), 'tx': _tx, 'red': _red, 'cu': _cu, 'inbox': _inbox}));
  }
  String _memberCode() { const a = 'ACDEFGHJKLMNPQRSTUVWXYZ2345679'; final s = List.generate(8, (_) => a[_rnd.nextInt(a.length)]).join(); return '${s.substring(0, 4)}-${s.substring(4)}'; }

  @override Future<Customer> signUp(String name, String email, bool marketing) async {
    final id = List.generate(16, (_) => _rnd.nextInt(16).toRadixString(16)).join();
    _c = Customer(id, name.trim(), email.trim(), _memberCode(), marketing, now());
    _tx = []; if (t.signupBonus > 0) _tx.add(PointTx(t.signupBonus, 'BONUS', 'Willkommensbonus', now()));
    await _save(); return _c!;
  }
  @override Future<void> setMarketing(bool on) async { if (_c != null) { _c = _c!.copyWith(marketing: on); await _save(); } }
  @override Future<Redemption> createRedemption(String rewardId) async {
    if (_c == null) throw StateError('Kein Konto');
    final r = t.rewards.firstWhere((e) => e.id == rewardId, orElse: () => throw ArgumentError('Unbekannte Prämie'));
    if (balance < r.points) throw StateError('Nicht genug ${t.pointsName}');
    final token = List.generate(16, (_) => _rnd.nextInt(16).toRadixString(16)).join();
    final red = Redemption(token, r.id, r.name, r.points, now(), now() + t.redeemQrSeconds * 1000, 'PENDING');
    _red.add(red); await _save(); return red;
  }
  @override Future<void> activateCoupon(String couponId) async {
    if (_c == null || _cu.any((u) => u.couponId == couponId)) return;
    _cu.add(CouponUse(couponId, now())); await _save();
  }
  @override Future<void> addInbox(String title, String body) async { _inbox.add(InboxMessage(title, body, now())); await _save(); }

  @override Future<StaffResult> creditPurchase(String memberCode, double amountEuro) async {
    final c = _c;
    if (c == null || c.memberCode != memberCode.toUpperCase().trim()) return StaffResult(false, 'Mitglied $memberCode nicht gefunden');
    if (amountEuro <= 0 || amountEuro > 500) return const StaffResult(false, 'Betrag muss zwischen 0,01 und 500 € liegen');
    final pts = (amountEuro * t.pointsPerEuro).floor();
    _tx.add(PointTx(pts, 'PURCHASE', 'Einkauf ${amountEuro.toStringAsFixed(2).replaceAll('.', ',')} €', now())); await _save();
    return StaffResult(true, '+$pts ${t.pointsName}', '${c.name} · neuer Stand $balance');
  }
  @override Future<StaffResult> validateRedemption(String token) async {
    final r = redemption(token);
    if (r == null) return const StaffResult(false, 'Unbekannter Code');
    if (r.status == 'REDEEMED') return const StaffResult(false, 'Schon eingelöst');
    if (now() > r.expiresAt) { r.status = 'EXPIRED'; await _save(); return const StaffResult(false, 'Code abgelaufen – Gast soll neu erzeugen'); }
    if (balance < r.points) return const StaffResult(false, 'Nicht genug Punkte');
    _tx.add(PointTx(-r.points, 'REDEEM', r.rewardName, now())); r.status = 'REDEEMED'; r.redeemedAt = now(); await _save();
    return StaffResult(true, '${r.rewardName} ausgeben', '−${r.points} ${t.pointsName} abgebucht');
  }
  @override Future<StaffResult> validateCoupon(String couponId, String memberCode) async {
    if (_c == null || _c!.memberCode != memberCode) return const StaffResult(false, 'Mitglied nicht gefunden');
    final cp = t.coupons.where((c) => c.id == couponId).firstOrNull;
    if (cp == null) return const StaffResult(false, 'Unbekannter Deal');
    final u = _cu.where((x) => x.couponId == couponId).firstOrNull;
    if (u?.usedAt != null) return const StaffResult(false, 'Deal schon genutzt');
    if (u == null) { _cu.add(CouponUse(couponId, now(), now())); } else { u.usedAt = now(); }
    await _save(); return StaffResult(true, 'Deal gültig', '${cp.title} · ${cp.badge}');
  }
  @override String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.fromMillisecondsSinceEpoch(now()).toUtc().toIso8601String(), 'controller': t.operator,
        if (_c != null) ...{'profile': _c!.toJson(), 'pointTransactions': _tx, 'redemptions': _red, 'coupons': _cu, 'balance': balance},
      });
  @override Future<void> deleteEverything() async { _c = null; _tx = []; _red = []; _cu = []; _inbox = []; await _p?.remove(_key); notifyListeners(); }
}
