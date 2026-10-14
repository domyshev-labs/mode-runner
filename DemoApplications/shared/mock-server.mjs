import { createServer } from 'node:http';
import { loadDemo, readScenario } from './state.mjs';

const context = await loadDemo();
const server = createServer(async (request, response) => {
  console.log(`[mock] ${request.method} ${request.url}`);
  response.setHeader('Content-Type', 'application/json');
  response.setHeader('Cache-Control', 'no-store');
  if (request.method !== 'GET' || !['/api/records', '/health'].includes(request.url)) {
    response.writeHead(404).end(JSON.stringify({ error: 'Not found' }));
    return;
  }
  try {
    response.end(JSON.stringify(await readScenario(context)));
  } catch (error) {
    console.error(`[mock] ${error.message}`);
    response.writeHead(500).end(JSON.stringify({ error: 'Unable to read the seeded dataset' }));
  }
});
server.on('error', error => { console.error(`[mock] ${error.message}`); process.exitCode = 1; });
server.listen(context.demo.mockPort, '127.0.0.1', () => {
  console.log(`[mock] ${context.demo.title}: http://127.0.0.1:${context.demo.mockPort}/api/records`);
});
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => {
  console.log(`[mock] Stopping ${context.demo.title}`);
  server.close();
  server.closeAllConnections();
});
