import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'repository.dart';
import 'tenant.dart';

class Scope extends InheritedWidget {
  final Tenant tenant; final LoyaltyRepository repo;
  const Scope({super.key, required this.tenant, required this.repo, required super.child});
  static Scope of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Scope>()!;
  @override bool updateShouldNotify(Scope o) => o.tenant != tenant || o.repo != repo;
}
extension Ctx on BuildContext {
  Tenant get t => Scope.of(this).tenant;
  Brand get b => Scope.of(this).tenant.brand;
  LoyaltyRepository get repo => Scope.of(this).repo;
}

final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
String fmtDate(String iso) { final d = DateTime.tryParse(iso); return d == null ? iso : DateFormat('dd.MM.yyyy').format(d); }
String fmtTime(int ms) => DateFormat('dd.MM.yyyy · HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));
const dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

TextStyle display(double size, Color c) => TextStyle(fontFamily: 'Display', fontSize: size, height: 1.0, color: c);
TextStyle body(double size, Color c, [FontWeight w = FontWeight.w400]) => TextStyle(fontFamily: 'Body', fontSize: size, color: c, fontWeight: w, height: 1.3);

ThemeData buildTheme(Brand b) => ThemeData(
      useMaterial3: true, fontFamily: 'Body', scaffoldBackgroundColor: b.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: b.primary, primary: b.primary, onPrimary: b.onPrimary, secondary: b.accent,
          surface: b.surface, brightness: b.dark ? Brightness.dark : Brightness.light),
      checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? b.accent : null)),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: b.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: b.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: b.accent, width: 2)),
        labelStyle: body(16, b.muted), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20)),
    );

/// Asset image from the tenant folder; returns null widget-safe if empty.
Widget? assetImg(String name, {BoxFit fit = BoxFit.cover, double? w, double? h}) =>
    name.isEmpty ? null : Image.asset('${Tenant.base}$name', fit: fit, width: w, height: h, errorBuilder: (_, _, _) => const SizedBox());

class Eyebrow extends StatelessWidget { final String text; final Color? color;
  const Eyebrow(this.text, {super.key, this.color});
  @override Widget build(BuildContext c) => Text(text.toUpperCase(), style: body(12, color ?? c.b.muted, FontWeight.w600).copyWith(letterSpacing: 1.2)); }

class ScreenTitle extends StatelessWidget { final String eyebrow, title;
  const ScreenTitle(this.eyebrow, this.title, {super.key});
  @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow(eyebrow, color: c.b.accent), const SizedBox(height: 4),
        Text(c.b.dark ? title.toUpperCase() : title, style: display(34, c.b.text)),
      ])); }

class PrimaryButton extends StatelessWidget { final String text; final VoidCallback? onTap; final bool expand;
  const PrimaryButton(this.text, this.onTap, {super.key, this.expand = true});
  @override Widget build(BuildContext c) { final b = c.b;
    final btn = FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: b.primary, foregroundColor: b.onPrimary,
        disabledBackgroundColor: b.surfaceAlt, disabledForegroundColor: b.muted, minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(text.toUpperCase(), style: body(15, onTap == null ? b.muted : b.onPrimary, FontWeight.w700).copyWith(letterSpacing: 0.6)));
    return expand ? SizedBox(width: double.infinity, child: btn) : btn; } }

class SecondaryButton extends StatelessWidget { final String text; final VoidCallback? onTap; final bool expand;
  const SecondaryButton(this.text, this.onTap, {super.key, this.expand = true});
  @override Widget build(BuildContext c) { final b = c.b;
    final btn = OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: b.text, side: BorderSide(color: b.outline),
        minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(text, style: body(15, b.text, FontWeight.w600)));
    return expand ? SizedBox(width: double.infinity, child: btn) : btn; } }

class Panel extends StatelessWidget { final Widget child; final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override Widget build(BuildContext c) => Container(width: double.infinity, padding: padding,
      decoration: BoxDecoration(color: c.b.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.b.outline)), child: child); }

class PointsBar extends StatelessWidget { final double progress;
  const PointsBar(this.progress, {super.key});
  @override Widget build(BuildContext c) => ClipRRect(borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 10, color: c.b.accent, backgroundColor: c.b.surfaceAlt)); }

class Rule extends StatelessWidget { const Rule({super.key});
  @override Widget build(BuildContext c) => Divider(height: 1, thickness: 1, color: c.b.outline); }

class Tag extends StatelessWidget { final String text; final Color bg, fg;
  const Tag(this.text, this.bg, this.fg, {super.key});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)), child: Text(text, style: body(13, fg, FontWeight.w700))); }

class QrBox extends StatelessWidget { final String data; final double? size;
  const QrBox(this.data, {super.key, this.size});
  @override Widget build(BuildContext c) => QrImageView(data: data, size: size, padding: EdgeInsets.zero, backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF14100E)),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF14100E))); }

class BackRow extends StatelessWidget { final VoidCallback onBack;
  const BackRow(this.onBack, {super.key});
  @override Widget build(BuildContext c) => Align(alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.only(left: 6, top: 6), child: IconButton(onPressed: onBack, icon: Icon(Icons.arrow_back, color: c.b.text), tooltip: 'Zurück'))); }

/// Image header with fade into the background colour.
class HeroImage extends StatelessWidget { final String image; final double height; final Widget? child;
  const HeroImage(this.image, this.height, {super.key, this.child});
  @override Widget build(BuildContext c) { final b = c.b; final img = assetImg(image);
    return SizedBox(height: height, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
      if (img != null) ...[img, DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [b.bg.withValues(alpha: 0), b.bg.withValues(alpha: 0), b.bg], stops: const [0, .45, 1])))]
      else ColoredBox(color: b.primary),
      ?child,
    ])); } }

/// McD-style price: big euros, small raised cents ("8,50" -> 8 ⁵⁰ €). Other badges as-is.
class BigPrice extends StatelessWidget { final String text;
  const BigPrice(this.text, {super.key});
  @override Widget build(BuildContext c) { final p = c.b.primary;
    final m = RegExp(r'^(\d+),(\d{2})$').firstMatch(text.replaceAll('€', '').trim());
    if (m == null) return Text(text, style: display(34, p));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(m.group(1)!, style: display(44, p)),
      Padding(padding: const EdgeInsets.only(top: 3, left: 2), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.group(2)!, style: display(20, p)), Text('€', style: display(18, p))])),
    ]); } }

void toast(BuildContext c, String msg) => ScaffoldMessenger.of(c)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
