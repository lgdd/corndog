import { Component } from '@angular/core';
import { CartService } from './services/cart.service';
import { AuthService } from './services/auth.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  cartCount$ = this.cartService.cartCount$;

  constructor(
    private cartService: CartService,
    public auth: AuthService
  ) {}

  login(): void {
    this.auth.login();
  }

  logout(): void {
    this.auth.logout();
  }
}
