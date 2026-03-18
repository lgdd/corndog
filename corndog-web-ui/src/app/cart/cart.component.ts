import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { CartService, CartItem } from '../services/cart.service';
import { OrderService } from '../services/order.service';

@Component({
  selector: 'app-cart',
  templateUrl: './cart.component.html',
  styleUrls: ['./cart.component.css']
})
export class CartComponent {
  cart$ = this.cartService.cart$;
  cartTotal$ = this.cartService.cartTotal$;

  customerName = '';
  specialInstructions = '';
  isSubmitting = false;

  constructor(
    private cartService: CartService,
    private orderService: OrderService,
    private router: Router
  ) {}

  updateQuantity(menuItemId: number, quantity: number): void {
    this.cartService.updateQuantity(menuItemId, quantity);
  }

  removeItem(menuItemId: number): void {
    this.cartService.removeFromCart(menuItemId);
  }

  placeOrder(items: CartItem[], total: number): void {
    if (!this.customerName.trim() || items.length === 0) return;

    this.isSubmitting = true;
    const orderItems = items.map(ci => ({
      menuItemId: ci.menuItem.id,
      name: ci.menuItem.name,
      quantity: ci.quantity,
      price: ci.menuItem.price
    }));

    this.orderService.placeOrder({
      customerName: this.customerName,
      items: orderItems,
      specialInstructions: this.specialInstructions,
      totalPrice: total
    }).subscribe({
      next: (order) => {
        this.cartService.clearCart();
        this.router.navigate(['/confirmation', order.id]);
      },
      error: () => {
        this.isSubmitting = false;
      }
    });
  }
}
