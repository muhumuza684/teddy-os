const DB_NAME = 'TeddyOS';
const DB_VERSION = 3;
let db = null;

export function openDB() {
  return new Promise((resolve, reject) => {
    if (db) return resolve(db);
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = (e) => {
      const d = e.target.result;
      if (!d.objectStoreNames.contains('docs'))     d.createObjectStore('docs',     { keyPath: 'name' });
      if (!d.objectStoreNames.contains('events'))   d.createObjectStore('events',   { keyPath: 'id' });
      if (!d.objectStoreNames.contains('settings')) d.createObjectStore('settings', { keyPath: 'key' });
      if (!d.objectStoreNames.contains('notes'))    d.createObjectStore('notes',    { keyPath: 'id' });
      if (!d.objectStoreNames.contains('users'))    d.createObjectStore('users',    { keyPath: 'username' });
    };
    req.onsuccess = (e) => { db = e.target.result; resolve(db); };
    req.onerror = reject;
  });
}

export async function dbGet(store, key) {
  const d = await openDB();
  return new Promise((res) => {
    const tx = d.transaction(store, 'readonly');
    const r = tx.objectStore(store).get(key);
    r.onsuccess = () => res(r.result || null);
    r.onerror = () => res(null);
  });
}

export async function dbPut(store, obj) {
  const d = await openDB();
  return new Promise((res) => {
    const tx = d.transaction(store, 'readwrite');
    tx.objectStore(store).put(obj);
    tx.oncomplete = res;
    tx.onerror = res;
  });
}

export async function dbDel(store, key) {
  const d = await openDB();
  return new Promise((res) => {
    const tx = d.transaction(store, 'readwrite');
    tx.objectStore(store).delete(key);
    tx.oncomplete = res;
    tx.onerror = res;
  });
}

export async function dbAll(store) {
  const d = await openDB();
  return new Promise((res) => {
    const tx = d.transaction(store, 'readonly');
    const r = tx.objectStore(store).getAll();
    r.onsuccess = () => res(r.result || []);
    r.onerror = () => res([]);
  });
}
