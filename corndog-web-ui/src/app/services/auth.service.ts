import { Injectable } from '@angular/core';
import Keycloak from 'keycloak-js';
import { environment } from '../../environments/environment';
import { RumService } from './rum.service';

// keycloak-js 26.x requires crypto.randomUUID() for state/nonce generation
// and crypto.subtle for PKCE. Both are unavailable in insecure contexts
// (plain HTTP to a non-localhost host, e.g. EC2 via IP). Polyfill
// randomUUID so Keycloak login works over HTTP for demo purposes.
if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'undefined') {
  crypto.randomUUID = () => {
    const bytes = new Uint8Array(16);
    crypto.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const h = [...bytes].map(b => b.toString(16).padStart(2, '0')).join('');
    return `${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20)}` as `${string}-${string}-${string}-${string}-${string}`;
  };
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private keycloak: Keycloak;

  constructor(private rum: RumService) {
    this.keycloak = new Keycloak({
      url: environment.keycloak.url,
      realm: environment.keycloak.realm,
      clientId: environment.keycloak.clientId
    });
  }

  init(): Promise<boolean> {
    const isSecure = window.isSecureContext;
    return this.keycloak.init({
      onLoad: 'check-sso',
      silentCheckSsoRedirectUri: isSecure
        ? window.location.origin + '/assets/silent-check-sso.html'
        : undefined,
      checkLoginIframe: false,
      pkceMethod: isSecure ? 'S256' : false
    }).then(authenticated => {
      if (authenticated) {
        this.syncRumUser();
      }
      return authenticated;
    });
  }

  login(): Promise<void> {
    return this.keycloak.login();
  }

  logout(): Promise<void> {
    this.rum.clearUser();
    return this.keycloak.logout({ redirectUri: window.location.origin });
  }

  isLoggedIn(): boolean {
    return !!this.keycloak.authenticated;
  }

  getUsername(): string {
    return this.keycloak.tokenParsed?.['preferred_username'] ?? '';
  }

  getToken(): string | undefined {
    return this.keycloak.token;
  }

  private syncRumUser(): void {
    const token = this.keycloak.tokenParsed;
    if (!token) return;
    this.rum.setUser({
      id: token['sub'] ?? '',
      email: token['email'],
      name: token['preferred_username']
    });
  }
}
