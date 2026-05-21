// Tiny static file server for the Claude Preview sandbox.
// `python3 -m http.server` is blocked by the sandbox (PermissionError on
// os.getcwd at module import); Node has no such restriction.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const port = Number(process.env.PORT || 8092);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.mjs':  'application/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.webp': 'image/webp',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico':  'image/x-icon',
  '.mid':  'audio/midi',
  '.midi': 'audio/midi',
};

http.createServer((req, res) => {
  try {
    const url = new URL(req.url, `http://localhost:${port}`);
    let rel = decodeURIComponent(url.pathname);
    if (rel.endsWith('/')) rel += 'index.html';
    const full = path.resolve(root, '.' + rel);
    if (!full.startsWith(root)) { res.writeHead(403).end('forbidden'); return; }
    fs.readFile(full, (err, data) => {
      if (err) { res.writeHead(404).end('not found: ' + rel); return; }
      const ext = path.extname(full).toLowerCase();
      res.writeHead(200, { 'Content-Type': TYPES[ext] || 'application/octet-stream' });
      res.end(data);
    });
  } catch (e) {
    res.writeHead(500).end(String(e));
  }
}).listen(port, () => {
  console.log(`drumrot static server on http://localhost:${port}/  root=${root}`);
});
