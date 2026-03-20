import { Injectable } from '@angular/core';
import { CanActivate } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private auth: AuthService) {}

  async canActivate(): Promise<boolean> {
    if (this.auth.isLoggedIn()) {
      return true;
    }
    await this.auth.login();
    return false;
  }
}
