import { Component } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
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
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.route.queryParams.subscribe(params => {
      if (params['prefill-instructions']) {
        this.specialInstructions = params['prefill-instructions'];
      }
    });
  }

  updateQuantity(ci: CartItem, quantity: number): void {
    this.cartService.updateQuantity(ci.menuItem.id, quantity, ci.sauces);
  }

  removeItem(ci: CartItem): void {
    this.cartService.removeFromCart(ci.menuItem.id, ci.sauces);
  }

  formatSauces(sauces: string[]): string {
    return sauces.map(s => s.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')).join(', ');
  }

  placeOrder(items: CartItem[], total: number): void {
    if (!this.customerName.trim() || items.length === 0) return;

    this.isSubmitting = true;
    const orderItems = items.map(ci => ({
      menuItemId: ci.menuItem.id,
      name: ci.menuItem.name,
      quantity: ci.quantity,
      price: ci.menuItem.price,
      sauces: ci.sauces
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
