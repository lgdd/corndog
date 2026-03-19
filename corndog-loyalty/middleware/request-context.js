const { AsyncLocalStorage } = require('node:async_hooks');
const crypto = require('node:crypto');

const requestContext = new AsyncLocalStorage();

function requestContextMiddleware(req, _res, next) {
  const store = {
    requestId: req.headers['x-request-id'] || crypto.randomUUID(),
    startTime: Date.now(),
    customerTier: req.headers['x-customer-tier'] || 'bronze',
  };
  requestContext.run(store, next);
}

function getRequestContext() {
  return requestContext.getStore() || {};
}

module.exports = { requestContext, requestContextMiddleware, getRequestContext };
