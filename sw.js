// Service worker: rende l'app installabile e veloce da aprire.
// I dati NON vengono mai messi in cache: arrivano sempre freschi da Supabase.
const CACHE = 'registro-appuntamenti-1.3'; // stesso numero di VERSIONE in index.html
const ASSETS = ['./', './index.html', './config.js', './lib/supabase.js', './manifest.json', './icons/icon-192.png', './icons/icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) return; // Supabase e font: sempre dalla rete
  // Prima la rete (versione aggiornata), la copia salvata solo se manca la connessione
  e.respondWith(
    fetch(e.request).then(res => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
      return res;
    }).catch(() => caches.match(e.request).then(r => r || caches.match('./index.html')))
  );
});
