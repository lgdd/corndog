// Runtime environment config — overwritten by docker-entrypoint.sh at container start.
// During local dev (`ng serve`), these empty defaults cause RUM to skip initialization.
window.__env = {
  DD_APPLICATION_ID: '',
  DD_CLIENT_TOKEN: '',
  DD_SITE: '',
  DD_ENV: '',
  DD_VERSION: ''
};
