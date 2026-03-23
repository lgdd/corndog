import { Injectable } from '@angular/core';
import { BehaviorSubject, map } from 'rxjs';
import { MenuItem } from './menu.service';

export interface CartItem {
  menuItem: MenuItem;
  quantity: number;
  sauces: string[];
}

@Injectable({ providedIn: 'root' })
export class CartService {
  private cartItems = new BehaviorSubject<CartItem[]>([]);

  cart$ = this.cartItems.asObservable();
  cartCount$ = this.cart$.pipe(
    map(items => items.reduce((sum, item) => sum + item.quantity, 0))
  );
  cartTotal$ = this.cart$.pipe(
    map(items => items.reduce((sum, item) => sum + (item.menuItem.price * item.quantity), 0))
  );

  addToCart(menuItem: MenuItem, sauces: string[] = []): void {
    const current = this.cartItems.value;
    const sauceKey = [...sauces].sort().join(',');
    const existing = current.find(item =>
      item.menuItem.id === menuItem.id &&
      [...item.sauces].sort().join(',') === sauceKey
    );

    if (existing) {
      existing.quantity += 1;
      this.cartItems.next([...current]);
    } else {
      this.cartItems.next([...current, { menuItem, quantity: 1, sauces }]);
    }
  }

  removeFromCart(menuItemId: number, sauces: string[] = []): void {
    const sauceKey = [...sauces].sort().join(',');
    const current = this.cartItems.value.filter(item =>
      !(item.menuItem.id === menuItemId && [...item.sauces].sort().join(',') === sauceKey)
    );
    this.cartItems.next(current);
  }

  updateQuantity(menuItemId: number, quantity: number, sauces: string[] = []): void {
    if (quantity <= 0) {
      this.removeFromCart(menuItemId, sauces);
      return;
    }
    const current = this.cartItems.value;
    const sauceKey = [...sauces].sort().join(',');
    const item = current.find(i =>
      i.menuItem.id === menuItemId && [...i.sauces].sort().join(',') === sauceKey
    );
    if (item) {
      item.quantity = quantity;
      this.cartItems.next([...current]);
    }
  }

  clearCart(): void {
    this.cartItems.next([]);
  }

  getItems(): CartItem[] {
    return this.cartItems.value;
  }
}
