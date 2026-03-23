export const environment = {
  production: false,
  apiUrl: '/api',
  keycloak: {
    url: '/auth',
    realm: 'corndog',
    clientId: 'corndog-web'
  },
  googleMapsApiKey: 'AIzaSyD3m0K3y_F4k3_V4lu3_N0T_R34L_8xQ2w',
  rum: {
    applicationId: '',
    clientToken: '',
    site: 'datadoghq.com',
    service: 'corndog-web-ui'
  }
};
