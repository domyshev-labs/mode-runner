export function createDemoConfig(demo, mode) {
  const mock = mode !== 'live';
  const upstream = {
    'cosmic-archive': 'https://images-api.nasa.gov',
    'mathematical-minds': 'https://openlibrary.org',
    'earth-observatory': 'https://earthquake.usgs.gov',
  }[demo.id];
  return {
    server: {
      host: '127.0.0.1', port: demo.port, strictPort: true,
      fs: { allow: ['..'] },
      proxy: {
        '/api': mock ? {
          target: `http://127.0.0.1:${demo.mockPort}`,
        } : {
          target: upstream, changeOrigin: true,
          rewrite: path => path.replace(/^\/api/, ''),
          proxyTimeout: 15000,
        },
      },
    },
  };
}
