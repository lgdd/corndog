import { Injectable } from '@angular/core';
import Keycloak from 'keycloak-js';
import { environment } from '../../environments/environment';
import { RumService } from './rum.service';

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
    // PKCE (S256) and silent-check-sso require the Web Crypto API, which is
    // only available in secure contexts (HTTPS). Disable both over plain HTTP
    // so Keycloak auth still works for the demo.
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
