const { getRequestContext, requestContextMiddleware } = require('../middleware/request-context');

describe('request-context middleware', () => {
  test('provides requestId in context', (done) => {
    const req = { headers: {} };
    const res = {};
    const next = () => {
      const ctx = getRequestContext();
      expect(ctx.requestId).toBeDefined();
      expect(ctx.startTime).toBeDefined();
      expect(ctx.customerTier).toBe('bronze');
      done();
    };
    requestContextMiddleware(req, res, next);
  });

  test('uses x-request-id header when provided', (done) => {
    const req = { headers: { 'x-request-id': 'test-123' } };
    const res = {};
    const next = () => {
      const ctx = getRequestContext();
      expect(ctx.requestId).toBe('test-123');
      done();
    };
    requestContextMiddleware(req, res, next);
  });

  test('returns empty object outside of context', () => {
    const ctx = getRequestContext();
    expect(ctx).toEqual({});
  });
});
