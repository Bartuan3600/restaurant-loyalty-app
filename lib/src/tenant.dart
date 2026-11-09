import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color hex(String? s, [Color fb = Colors.black]) {
  if (s == null || s.isEmpty) return fb;
  var h = s.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? fb.toARGB32());
}

String _s(dynamic v) => v?.toString() ?? '';
List<T> _l<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    v is List ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList() : <T>[];

class Brand {
  final String name, wordmarkTop, wordmarkMain, tagline, iconText, heroImage, secondaryImage, logo;
  final bool dark;
  final Map<String, String> fonts;
  final Color primary, onPrimary, accent, onAccent, bg, surface, surfaceAlt, text, muted, outline;
  Brand(Map<String, dynamic> j)
      : name = _s(j['name']), wordmarkTop = _s(j['wordmarkTop']), wordmarkMain = _s(j['wordmarkMain']),
        tagline = _s(j['tagline']), iconText = _s(j['iconText']), heroImage = _s(j['heroImage']),
        secondaryImage = _s(j['secondaryImage']), logo = _s(j['logo']), dark = j['dark'] == true,
        fonts = Map<String, String>.from((j['fonts'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {}),
        primary = hex(j['colors']?['primary']), onPrimary = hex(j['colors']?['onPrimary'], Colors.white),
        accent = hex(j['colors']?['accent']), onAccent = hex(j['colors']?['onAccent'], Colors.white),
        bg = hex(j['colors']?['background'], Colors.white), surface = hex(j['colors']?['surface'], Colors.white),
        surfaceAlt = hex(j['colors']?['surfaceAlt'], const Color(0xFFF2F2F2)), text = hex(j['colors']?['text']),
        muted = hex(j['colors']?['muted'], Colors.grey), outline = hex(j['colors']?['outline'], const Color(0xFFE0E0E0));
}

class Hours { final int day; final String open, close; final bool closed;
  Hours(Map<String, dynamic> j) : day = (j['day'] as num?)?.toInt() ?? 1, open = _s(j['open']), close = _s(j['close']), closed = j['closed'] == true; }

class Location {
  final String name, street, city, phone; final double? lat, lng; final List<Hours> hours; final List<String> facts;
  Location(Map<String, dynamic> j)
      : name = _s(j['name']), street = _s(j['street']), city = _s(j['city']), phone = _s(j['phone']),
        lat = (j['lat'] as num?)?.toDouble(), lng = (j['lng'] as num?)?.toDouble(),
        hours = _l(j['hours'], Hours.new), facts = (j['facts'] as List?)?.map((e) => '$e').toList() ?? [];
}

class MenuItem { final String name, desc, image, tag; final double price; final bool demoPrice;
  MenuItem(Map<String, dynamic> j) : name = _s(j['name']), desc = _s(j['desc']), image = _s(j['image']), tag = _s(j['tag']),
        price = (j['price'] as num?)?.toDouble() ?? 0, demoPrice = j['demoPrice'] == true; }
class MenuCategory { final String category; final List<MenuItem> items;
  MenuCategory(Map<String, dynamic> j) : category = _s(j['category']), items = _l(j['items'], MenuItem.new); }
class Reward { final String id, name, desc; final int points;
  Reward(Map<String, dynamic> j) : id = _s(j['id']), name = _s(j['name']), desc = _s(j['desc']), points = (j['points'] as num?)?.toInt() ?? 0; }
class Coupon { final String id, title, desc, badge, validTo, image, price;
  Coupon(Map<String, dynamic> j) : id = _s(j['id']), title = _s(j['title']), desc = _s(j['desc']), badge = _s(j['badge']),
        validTo = _s(j['validTo']), image = _s(j['image']), price = _s(j['price']);
  String get label => price.isNotEmpty ? price : badge; }
class Msg { final String title, body, image;
  Msg(Map<String, dynamic> j) : title = _s(j['title']), body = _s(j['body']), image = _s(j['image']); }
class Hero { final String image, eyebrow, title, subtitle, cta, couponId;
  Hero(Map<String, dynamic> j) : image = _s(j['image']), eyebrow = _s(j['eyebrow']), title = _s(j['title']),
        subtitle = _s(j['subtitle']), cta = _s(j['cta']), couponId = _s(j['couponId']); }

class Tenant {
  final Map<String, dynamic> raw;
  final String id, packageId, appName, versionName, pointsName, staffPin, operator, privacyNote;
  final int pointsPerEuro, signupBonus, redeemQrSeconds;
  final Brand brand;
  final List<Location> locations; final List<MenuCategory> menu; final List<Reward> rewards;
  final List<Coupon> coupons; final List<Msg> campaigns, news; final List<String> sources;
  final Hero? hero; final Msg? promo;
  Tenant(this.raw)
      : id = _s(raw['id']), packageId = _s(raw['packageId']), appName = _s(raw['appName']), versionName = _s(raw['versionName']),
        pointsName = _s(raw['loyalty']?['pointsName']).isEmpty ? 'Punkte' : _s(raw['loyalty']?['pointsName']),
        pointsPerEuro = (raw['loyalty']?['pointsPerEuro'] as num?)?.toInt() ?? 1,
        signupBonus = (raw['loyalty']?['signupBonus'] as num?)?.toInt() ?? 0,
        redeemQrSeconds = (raw['loyalty']?['redeemQrSeconds'] as num?)?.toInt() ?? 60,
        staffPin = _s(raw['staff']?['pin']).isEmpty ? '1234' : _s(raw['staff']?['pin']),
        operator = _s(raw['legal']?['operator']), privacyNote = _s(raw['legal']?['privacyNote']),
        brand = Brand(Map<String, dynamic>.from(raw['brand'] ?? {})),
        locations = _l(raw['locations'], Location.new), menu = _l(raw['menu'], MenuCategory.new),
        rewards = _l(raw['rewards'], Reward.new)..sort((a, b) => a.points.compareTo(b.points)),
        coupons = _l(raw['coupons'], Coupon.new), campaigns = _l(raw['campaigns'], Msg.new),
        news = _l(raw['home']?['news'], Msg.new), sources = (raw['sources'] as List?)?.map((e) => '$e').toList() ?? [],
        hero = raw['home']?['hero'] is Map ? Hero(Map<String, dynamic>.from(raw['home']['hero'])) : null,
        promo = raw['home']?['promo'] is Map ? Msg(Map<String, dynamic>.from(raw['home']['promo'])) : null;

  static const base = 'assets/tenant/';
  static Future<Tenant> load() async => Tenant(jsonDecode(await rootBundle.loadString('${base}tenant.json')));

  /// Registers the tenant fonts as families "Display" and "Body".
  Future<void> loadFonts() async {
    Future<void> fam(String family, List<String?> files) async {
      final l = FontLoader(family);
      var any = false;
      for (final f in files.whereType<String>().toSet()) {
        try { l.addFont(rootBundle.load('$base$f')); any = true; } catch (_) {}
      }
      if (any) await l.load();
    }
    await fam('Display', [brand.fonts['display']]);
    await fam('Body', [brand.fonts['body'], brand.fonts['bodySemi'], brand.fonts['bodyBold']]);
  }
}
