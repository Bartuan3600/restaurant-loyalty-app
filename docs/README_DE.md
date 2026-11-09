# Loyalty-Apps (Flutter) + App Studio

Eine Codebasis für alle Treue-Apps (Android **und** iPhone). Jede App = ein Ordner in `tenants/<id>/`
(`tenant.json` + `assets/`). Format ist identisch zur alten Kotlin-Version.

## App Studio starten
```bash
cd restaurant-loyalty-app
./start_studio.sh
```
Dann im Browser **http://localhost:8787** öffnen.

Im App Studio kannst du:
- Apps **anlegen** (links unten) und alles bearbeiten: Name, Paket-ID, Version, Farben, Schriften, Logo/App-Icon hochladen,
  Startseite (großes Angebot, Aktions-Streifen, News), Filialen mit Öffnungszeiten, Speisekarte mit Preisen/Bildern, Coupons, Prämien, Push-Texte, Impressum.
- rechts die **Live-Vorschau** sehen (Start / Speisekarte / Prämien).
- **🤖 Android-APK bauen** → signierte APK in `dist/` (Download-Link erscheint). Beim ersten Build wird automatisch ein Keystore
  `keystores/<id>.jks` erzeugt – **unbedingt sichern**, ohne ihn kann die App nie mehr aktualisiert werden.
- **🍏 iOS-Projekt (ZIP)** → auf dem Mac weiter mit `MAC_ANLEITUNG.md`.
- **📸 Screenshots** → echte Flutter-Renderings aller Screens in `screenshots/<id>/`.

## Kommandozeile
```bash
tools/build_apk.sh <id>        # signierte APK -> dist/<id>-<version>.apk
tools/export_ios.sh <id>       # dist/<id>-ios-<version>.zip
tools/screenshots.sh <id>      # screenshots/<id>/*.png
python3 tools/apply_tenant.py <id>   # nur Tenant aktivieren (z. B. für flutter run)
```

## Updates ausliefern
Build-Nr. (`versionCode`) **immer erhöhen**, Paket-ID und Keystore **nie ändern** – sonst lässt Android das Update nicht zu.

## Aufbau
- `lib/src/tenant.dart` – liest `tenant.json`
- `lib/src/repository.dart` – `LoyaltyRepository` (Interface) + `LocalLoyaltyRepository` (Daten auf dem Gerät). Für echtes Backend später
  `SupabaseLoyaltyRepository` implementieren und in `lib/main.dart` tauschen – die Oberfläche bleibt gleich.
- `lib/src/screens_*.dart`, `lib/src/app.dart` – Oberfläche
- `tools/` – Build-Skripte, `studio/` – App Studio (Python, ohne Zusatzpakete außer Pillow)

## Grenzen
- iOS kann hier (Linux) nicht kompiliert werden → Mac + Xcode nötig.
- Push = lokale Benachrichtigungen (Demo). Echte Push-Kampagnen an alle Kunden brauchen Backend + FCM/APNs.
- Punkte liegen lokal auf dem Gerät – für mehrere Geräte/Kasse-Sync Backend (Supabase) anbinden.
