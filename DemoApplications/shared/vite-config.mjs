export function createDemoConfig(demo, mode) {
  return {
    server: {
      host: '127.0.0.1', port: demo.port, strictPort: true,
      fs: { allow: ['..'] },
      proxy: mode === 'live' ? undefined : {
        '/api': { target: `http://127.0.0.1:${demo.mockPort}` },
      },
    },
  };
}
