import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, cp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createServer } from 'node:net';
import { loadDemo, applySeed, readScenario } from './state.mjs';
import { normalizeRecords } from './api.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
for (const id of ['cosmic-archive', 'mathematical-minds', 'earth-observatory']) {
  test(`${id}: seeds persist and are served without restarting the mock server`, async () => {
    const directory = await mkdtemp(resolve(tmpdir(), 'science-demo-'));
    let server;
    try {
      for (const name of ['demo.json', 'fixtures.json']) await cp(resolve(root, id, name), resolve(directory, name));
      const context = await loadDemo(directory);
      const reservation = createServer();
      reservation.listen(0, '127.0.0.1');
      await once(reservation, 'listening');
      context.demo.mockPort = reservation.address().port;
      await new Promise(resolve => reservation.close(resolve));
      await writeFile(resolve(directory, 'demo.json'), JSON.stringify(context.demo));
      assert.equal((await readScenario(context)).scenario, context.demo.defaultScenario);
      assert.ok((await readScenario(context)).records.length > 0);
      await assert.rejects(applySeed(context, '../unknown'), /Choose a seed/);
      server = spawn(process.execPath, [fileURLToPath(new URL('./mock-server.mjs', import.meta.url))], { cwd: directory, stdio: ['ignore', 'pipe', 'pipe'] });
      const url = `http://127.0.0.1:${context.demo.mockPort}/api/records`;
      for (let attempt = 0; attempt < 50; attempt++) {
        try { if ((await fetch(url)).ok) break; } catch {}
        await new Promise(resolve => setTimeout(resolve, 30));
      }
      assert.equal((await (await fetch(url)).json()).scenario, context.demo.defaultScenario);
      for (const scenario of Object.keys(context.fixtures)) {
        await applySeed(context, scenario);
        const response = await fetch(url);
        assert.equal(response.status, 200);
        const result = await response.json();
        assert.equal(result.scenario, scenario);
        assert.deepEqual(result.records, context.fixtures[scenario]);
      }
      assert.equal((await fetch(`http://127.0.0.1:${context.demo.mockPort}/missing`)).status, 404);
    } finally {
      if (server && server.exitCode === null) {
        const exited = once(server, 'exit');
        server.kill('SIGTERM');
        await exited;
      }
      await rm(directory, { recursive: true, force: true });
    }
  });
}

test('public API response adapters preserve records and source links', () => {
  const nasa = normalizeRecords('cosmic-archive', { collection: { items: [{ data: [{ nasa_id: 'apollo', title: 'Moon', description: '<b>Surface</b>', date_created: '1969-07-20' }], links: [{ rel: 'preview', href: 'https://example.org/moon.jpg' }] }] } });
  assert.equal(nasa[0].description, 'Surface');
  assert.equal(nasa[0].image, 'https://example.org/moon.jpg');
  assert.match(nasa[0].url, /apollo$/);
  const books = normalizeRecords('mathematical-minds', { docs: [{ key: '/works/euler', title: 'Analysis', author_name: ['Euler'], first_publish_year: 1748, edition_count: 2 }] });
  assert.equal(books[0].subtitle, 'Euler');
  assert.equal(books[0].url, 'https://openlibrary.org/works/euler');
  const earth = normalizeRecords('earth-observatory', { features: [{ id: 'observation', properties: { place: 'Ocean', mag: 2.1, time: 0, url: 'https://earthquake.usgs.gov/example' }, geometry: { coordinates: [0, 0, 12.4] } }] });
  assert.equal(earth[0].magnitude, 2.1);
  assert.match(earth[0].description, /12.4/);
  assert.throws(() => normalizeRecords('cosmic-archive', {}), /unexpected response/);
  assert.deepEqual(normalizeRecords('earth-observatory', { features: [] }), []);
});
