#!/usr/bin/env python3
"""App Studio – lokale Web-Oberfläche zum Anlegen/Bearbeiten der Loyalty-Apps.
Start:  python3 studio/server.py   ->  http://localhost:8787
Nur Python-Standardbibliothek (+ Pillow für Bild-Uploads, ist schon installiert)."""
import json, os, re, shutil, subprocess, sys, threading, time, uuid, mimetypes, io
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, unquote

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEN = os.path.join(ROOT, 'tenants'); DIST = os.path.join(ROOT, 'dist'); HERE = os.path.dirname(os.path.abspath(__file__))
PORT = int(os.environ.get('PORT', '8787')); HOST = os.environ.get('HOST', '127.0.0.1')
ID_RE = re.compile(r'^[a-z0-9][a-z0-9-]{1,40}$')
jobs = {}; job_lock = threading.Lock()  # alle Builds teilen sich ein Flutter-Projekt -> nacheinander

def tpath(tid, *p):
    if not ID_RE.match(tid): raise ValueError('ungültige Tenant-ID')
    return os.path.join(TEN, tid, *p)

def safe_rel(rel):
    rel = os.path.normpath(rel).replace('\\', '/')
    if rel.startswith('..') or rel.startswith('/'): raise ValueError('ungültiger Pfad')
    return rel

def new_tenant(tid, name):
    t = json.load(open(os.path.join(TEN, 'backstube-demo', 'tenant.json'), encoding='utf-8'))
    pkg = 'de.bartuan.loyalty.' + re.sub(r'[^a-z0-9]', '', tid)
    t.update(id=tid, packageId=pkg, appName=name, versionCode=1, versionName='1.0')
    t['brand'].update(name=name, wordmarkMain=name, wordmarkTop='', tagline='', iconText=name[:1].upper(), heroImage='', secondaryImage='', logo='')
    t['legal']['operator'] = name; t['sources'] = []
    t['home'] = {'hero': {'image': '', 'eyebrow': 'Nur in der App', 'title': 'Willkommen', 'subtitle': 'Sammle Punkte bei jedem Einkauf', 'cta': 'Coupons ansehen', 'couponId': ''},
                 'promo': {'title': 'Doppelte Punkte', 'body': 'Jeden Montag.', 'image': ''}, 'news': []}
    os.makedirs(tpath(tid, 'assets', 'img'))
    json.dump(t, open(tpath(tid, 'tenant.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    return t

def validate(t):
    errs = []
    if not re.match(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$', t.get('packageId', '')): errs.append('packageId muss wie de.firma.app aussehen (klein, mind. 3 Teile)')
    if not isinstance(t.get('versionCode'), int) or t['versionCode'] < 1: errs.append('versionCode muss eine ganze Zahl ≥ 1 sein')
    if not t.get('appName'): errs.append('App-Name fehlt')
    for k, v in t.get('brand', {}).get('colors', {}).items():
        if not re.match(r'^#[0-9A-Fa-f]{6}$', v): errs.append(f'Farbe {k}: {v} ist kein #RRGGBB')
    return errs

def run_job(kind, tid):
    jid = uuid.uuid4().hex[:8]; j = jobs[jid] = {'id': jid, 'kind': kind, 'tenant': tid, 'state': 'wartet', 'log': '', 'file': None, 'started': time.time()}
    script = {'apk': 'build_apk.sh', 'ios': 'export_ios.sh', 'shots': 'screenshots.sh'}[kind]
    def work():
        with job_lock:
            j['state'] = 'läuft'
            p = subprocess.Popen(['bash', os.path.join(ROOT, 'tools', script), tid], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            for line in p.stdout:
                if re.search(r'(?i)password|storepass|keypass', line): continue  # niemals Passwörter loggen
                j['log'] += line
            p.wait(); j['state'] = 'fertig' if p.returncode == 0 else 'fehler'
            m = re.search(r'(?:APK|ZIP): (\S+)', j['log'])
            if m and p.returncode == 0: j['file'] = os.path.basename(m.group(1))
    threading.Thread(target=work, daemon=True).start(); return j

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, code, body, ctype='application/json; charset=utf-8', extra=None):
        if not isinstance(body, (bytes, bytearray)): body = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code); self.send_header('Content-Type', ctype); self.send_header('Content-Length', str(len(body))); self.send_header('Cache-Control', 'no-store')
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.end_headers(); self.wfile.write(body)
    def file(self, path, download=False):
        if not os.path.isfile(path): return self.send(404, {'error': 'nicht gefunden'})
        extra = {'Content-Disposition': f'attachment; filename="{os.path.basename(path)}"'} if download else None
        self.send(200, open(path, 'rb').read(), mimetypes.guess_type(path)[0] or 'application/octet-stream', extra)
    def body(self): n = int(self.headers.get('Content-Length') or 0); return self.rfile.read(n) if n else b''
    def route(self, method):
        u = urlparse(self.path); p = [unquote(x) for x in u.path.strip('/').split('/') if x]; q = parse_qs(u.query)
        try:
            if method == 'GET' and not p: return self.file(os.path.join(HERE, 'index.html'))
            if p[:1] == ['fonts'] and method == 'GET': return self.file(os.path.join(ROOT, 'template', 'fonts', os.path.basename(p[1])))
            if p[:1] == ['asset'] and method == 'GET': return self.file(tpath(p[1], 'assets', safe_rel('/'.join(p[2:]))))
            if p[:1] == ['download'] and method == 'GET': return self.file(os.path.join(DIST, os.path.basename(p[1])), True)
            if p[:1] == ['shot'] and method == 'GET': return self.file(os.path.join(ROOT, 'screenshots', p[1], os.path.basename(p[2])))
            if p[:2] == ['api', 'fonts']: return self.send(200, sorted(os.listdir(os.path.join(ROOT, 'template', 'fonts'))))
            if p[:2] == ['api', 'jobs']:
                if len(p) == 2: return self.send(200, sorted(jobs.values(), key=lambda j: -j['started']))
                return self.send(200, jobs[p[2]])
            if p[:2] == ['api', 'tenants']:
                if len(p) == 2 and method == 'GET':
                    out = []
                    for d in sorted(os.listdir(TEN)):
                        f = os.path.join(TEN, d, 'tenant.json')
                        if os.path.isfile(f):
                            t = json.load(open(f, encoding='utf-8')); out.append({k: t.get(k) for k in ('id', 'appName', 'packageId', 'versionName', 'versionCode')} | {'primary': t['brand']['colors'].get('primary'), 'keystore': os.path.exists(os.path.join(ROOT, 'keystores', d + '.properties'))})
                    return self.send(200, out)
                if len(p) == 2 and method == 'POST':
                    d = json.loads(self.body()); tid = d.get('id', '').strip().lower()
                    if not ID_RE.match(tid): return self.send(400, {'error': 'ID nur a-z, 0-9 und -, 2–41 Zeichen'})
                    if os.path.exists(tpath(tid)): return self.send(400, {'error': 'ID existiert schon'})
                    return self.send(200, new_tenant(tid, d.get('name') or tid))
                tid = p[2]
                if len(p) == 3 and method == 'GET': return self.file(tpath(tid, 'tenant.json'))
                if len(p) == 3 and method == 'PUT':
                    t = json.loads(self.body()); t['id'] = tid; errs = validate(t)
                    if errs: return self.send(400, {'error': '; '.join(errs)})
                    json.dump(t, open(tpath(tid, 'tenant.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2); return self.send(200, {'ok': True})
                if len(p) == 4 and p[3] == 'assets' and method == 'GET':
                    base = tpath(tid, 'assets'); return self.send(200, sorted(os.path.relpath(os.path.join(r, f), base).replace('\\', '/') for r, _, fs in os.walk(base) for f in fs))
                if len(p) == 4 and p[3] == 'upload' and method == 'POST':
                    rel = safe_rel(q.get('path', [''])[0]); data = self.body()
                    if not re.match(r'^[\w./-]+\.(png|jpg|jpeg|webp)$', rel, re.I): return self.send(400, {'error': 'nur png/jpg/webp'})
                    from PIL import Image
                    im = Image.open(io.BytesIO(data)); dest = tpath(tid, 'assets', rel); os.makedirs(os.path.dirname(dest), exist_ok=True)
                    special = rel in ('icon.png', 'icon_foreground.png', 'logo.png')
                    if special:
                        im = im.convert('RGBA'); s = max(im.size); sq = Image.new('RGBA', (s, s), (0, 0, 0, 0)); sq.paste(im, ((s - im.width) // 2, (s - im.height) // 2))
                        im = sq.resize((1024, 1024) if rel != 'logo.png' else (min(s, 800),) * 2); im.save(dest)
                    else:
                        im.thumbnail((1600, 1600)); im = im.convert('RGB') if rel.lower().endswith(('jpg', 'jpeg')) else im; im.save(dest, quality=85)
                    return self.send(200, {'ok': True, 'path': rel})
                if len(p) == 4 and p[3] in ('build', 'ios', 'shots') and method == 'POST':
                    if not os.path.isfile(tpath(tid, 'tenant.json')): return self.send(404, {'error': 'Tenant fehlt'})
                    return self.send(200, run_job({'build': 'apk', 'ios': 'ios', 'shots': 'shots'}[p[3]], tid))
                if len(p) == 4 and p[3] == 'files':
                    fs = [f for f in sorted(os.listdir(DIST)) if f.startswith(tid + '-')] if os.path.isdir(DIST) else []
                    sh = sorted(os.listdir(os.path.join(ROOT, 'screenshots', tid))) if os.path.isdir(os.path.join(ROOT, 'screenshots', tid)) else []
                    return self.send(200, {'dist': fs, 'screenshots': sh})
            return self.send(404, {'error': 'unbekannt'})
        except (ValueError, KeyError, json.JSONDecodeError) as e: return self.send(400, {'error': str(e)})
        except Exception as e: return self.send(500, {'error': f'{type(e).__name__}: {e}'})
    def do_GET(self): self.route('GET')
    def do_POST(self): self.route('POST')
    def do_PUT(self): self.route('PUT')

if __name__ == '__main__':
    print(f'App Studio läuft: http://localhost:{PORT}  (Strg+C beendet)'); ThreadingHTTPServer((HOST, PORT), H).serve_forever()
