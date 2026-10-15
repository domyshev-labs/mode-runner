import { applySeed, loadDemo } from './state.mjs';
try {
  await applySeed(await loadDemo(), process.argv[2]);
} catch (error) {
  console.error(`[seed] ${error.message}`);
  process.exitCode = 1;
}
