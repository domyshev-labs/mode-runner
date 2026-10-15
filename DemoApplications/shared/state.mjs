import { readFile, mkdir, rename, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

export async function loadDemo(directory = process.cwd()) {
  const demo = JSON.parse(await readFile(resolve(directory, 'demo.json'), 'utf8'));
  const fixtures = JSON.parse(await readFile(resolve(directory, 'fixtures.json'), 'utf8'));
  return { demo, fixtures, directory };
}

export async function readScenario({ demo, fixtures, directory }) {
  let scenario = demo.defaultScenario;
  try { scenario = JSON.parse(await readFile(resolve(directory, '.demo-state/seed.json'), 'utf8')).scenario; }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (!Object.hasOwn(fixtures, scenario)) throw new Error(`Unknown scenario: ${scenario}`);
  return { scenario, records: fixtures[scenario], updatedAt: new Date().toISOString() };
}

export async function applySeed({ demo, fixtures, directory }, scenario) {
  if (!Object.hasOwn(fixtures, scenario)) throw new Error(`Choose a seed: ${Object.keys(fixtures).join(', ')}`);
  const stateDirectory = resolve(directory, '.demo-state');
  await mkdir(stateDirectory, { recursive: true });
  const temporary = resolve(stateDirectory, `seed-${process.pid}.json`);
  await writeFile(temporary, JSON.stringify({ scenario }) + '\n');
  await rename(temporary, resolve(stateDirectory, 'seed.json'));
  console.log(`[seed] ${demo.title}: ${scenario} (${fixtures[scenario].length} records)`);
  console.log(`[seed] Refresh http://127.0.0.1:${demo.port} in Mock mode to see the dataset.`);
}
