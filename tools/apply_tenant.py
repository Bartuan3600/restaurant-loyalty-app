#!/usr/bin/env python3
"""Activate one tenant in the Flutter project (Android + iOS).
Usage: tools/apply_tenant.py <tenant-id>
- copies tenants/<id>/tenant.json + assets + fonts to assets/tenant/
- Android: android/tenant.properties (package, version, name, keystore), launcher icons
- iOS: bundle id, display name, camera text, AppIcon set"""
import json, os, re, shutil, sys, plistlib
from PIL import Image, ImageDraw, ImageFont
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tid = sys.argv[1]
tdir = os.path.join(ROOT, 'tenants', tid)
t = json.load(open(os.path.join(tdir, 'tenant.json'), encoding='utf-8'))
b = t['brand']; c = b['colors']; src = os.path.join(tdir, 'assets')

# 1. Flutter assets
out = os.path.join(ROOT, 'assets', 'tenant'); shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
for f in os.listdir(os.path.join(ROOT, 'template', 'fonts')): shutil.copy(os.path.join(ROOT, 'template', 'fonts', f), out)
if os.path.isdir(src):
    for f in os.listdir(src):
        sp = os.path.join(src, f)
        (shutil.copytree if os.path.isdir(sp) else shutil.copy)(sp, os.path.join(out, f))
shutil.copy(os.path.join(tdir, 'tenant.json'), out)
# pubspec must list every asset folder
dirs = sorted({os.path.relpath(r, ROOT) + '/' for r, _, fs in os.walk(out) if fs})
ps = open(os.path.join(ROOT, 'pubspec.yaml')).read()
block = '  assets:\n' + ''.join(f'    - {d}\n' for d in dirs)
ps = re.sub(r'  assets:\n(    - .*\n)*', block, ps)
open(os.path.join(ROOT, 'pubspec.yaml'), 'w').write(ps)

# 2. Icons
def base_icon(size):
    p = os.path.join(src, 'icon.png')
    if os.path.exists(p): return Image.open(p).convert('RGBA').resize((size, size), Image.LANCZOS)
    im = Image.new('RGBA', (size, size), c['primary']); d = ImageDraw.Draw(im)
    font = ImageFont.truetype(os.path.join(out, b['fonts']['display']), int(size * 0.5))
    txt = b.get('iconText') or b['name'][:1]
    x0, y0, x1, y1 = d.textbbox((0, 0), txt, font=font)
    d.text(((size - (x1 - x0)) / 2 - x0, (size - (y1 - y0)) / 2 - y0), txt, font=font, fill=c['onPrimary'])
    bar = int(size * 0.07); d.rectangle([0, size - bar, size, size], fill=c['accent'])
    return im
big = base_icon(1024)
res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
for dens, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    d = os.path.join(res, f'mipmap-{dens}'); os.makedirs(d, exist_ok=True)
    for f in os.listdir(d): os.remove(os.path.join(d, f))
    sq = big.resize((px, px), Image.LANCZOS)
    for name, shape in (('ic_launcher', 'r'), ('ic_launcher_round', 'c')):
        m = Image.new('L', (px, px), 0); dr = ImageDraw.Draw(m)
        dr.rounded_rectangle([0, 0, px - 1, px - 1], int(px * .18), fill=255) if shape == 'r' else dr.ellipse([0, 0, px - 1, px - 1], fill=255)
        o = Image.new('RGBA', (px, px), (0, 0, 0, 0)); o.paste(sq, (0, 0), m); o.save(os.path.join(d, name + '.png'))
ad = os.path.join(res, 'mipmap-anydpi-v26'); shutil.rmtree(ad, ignore_errors=True)
vals = os.path.join(res, 'values'); os.makedirs(vals, exist_ok=True)
fg = os.path.join(src, 'icon_foreground.png')
bgc = b.get('iconBackground', '#FFFFFF')
open(os.path.join(vals, 'tenant_colors.xml'), 'w').write(f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n  <color name="ic_launcher_bg">{bgc}</color>\n</resources>\n')
if os.path.exists(fg):
    f = Image.open(fg).convert('RGBA')
    for dens, px in {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}.items():
        f.resize((px, px), Image.LANCZOS).save(os.path.join(res, f'mipmap-{dens}', 'ic_launcher_foreground.png'))
    os.makedirs(ad)
    for n in ('ic_launcher', 'ic_launcher_round'):
        open(os.path.join(ad, n + '.xml'), 'w').write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n  <background android:drawable="@color/ic_launcher_bg"/>\n  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
# iOS icon: no transparency allowed
ios_set = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset'); shutil.rmtree(ios_set, ignore_errors=True); os.makedirs(ios_set)
flat = Image.new('RGB', (1024, 1024), bgc); flat.paste(big, (0, 0), big); flat.save(os.path.join(ios_set, 'icon-1024.png'))
json.dump({'images': [{'filename': 'icon-1024.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, open(os.path.join(ios_set, 'Contents.json'), 'w'), indent=2)
# launch screen background colour not needed (white default)

# 3. Android properties
ks = os.path.join(ROOT, 'keystores', tid + '.properties')
open(os.path.join(ROOT, 'android', 'tenant.properties'), 'w').write(
    f"packageId={t['packageId']}\nversionCode={t['versionCode']}\nversionName={t['versionName']}\nappName={t['appName']}\nkeystoreProperties={ks}\n")

# 4. iOS
pbx = os.path.join(ROOT, 'ios', 'Runner.xcodeproj', 'project.pbxproj'); s = open(pbx).read()
bid = t.get('iosBundleId') or t['packageId']
s = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*RunnerTests;', f'PRODUCT_BUNDLE_IDENTIFIER = {bid}.RunnerTests;', s)
s = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*RunnerTests)[^;]*;', f'PRODUCT_BUNDLE_IDENTIFIER = {bid};', s)
s = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.5;', s)
open(pbx, 'w').write(s)
pl = os.path.join(ROOT, 'ios', 'Runner', 'Info.plist'); d = plistlib.load(open(pl, 'rb'))
d['CFBundleDisplayName'] = t['appName']; d['CFBundleName'] = t['appName'][:15]
d['NSCameraUsageDescription'] = 'Die Kamera wird nur zum Scannen von QR-Codes an der Kasse genutzt.'
d['LSApplicationQueriesSchemes'] = ['tel', 'https', 'comgooglemaps', 'maps']
d['UIStatusBarStyle'] = 'UIStatusBarStyleLightContent' if b.get('dark') else 'UIStatusBarStyleDarkContent'
plistlib.dump(d, open(pl, 'wb'))
pod = os.path.join(ROOT, 'ios', 'Podfile')
if os.path.exists(pod):
    p = open(pod).read(); p = re.sub(r"^#?\s*platform :ios.*$", "platform :ios, '15.5'", p, flags=re.M); open(pod, 'w').write(p)
print(f"Tenant aktiv: {tid} ({t['appName']}, {t['packageId']} v{t['versionName']}/{t['versionCode']})")
