const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: process.env.LLM_ENDPOINT || 'http://localhost:5000',
      changeOrigin: true,
    })
  );
};