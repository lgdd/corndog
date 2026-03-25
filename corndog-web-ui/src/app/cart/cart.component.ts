import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription, forkJoin, of } from 'rxjs';
import { switchMap, map, catchError } from 'rxjs/operators';
import { CartService, CartItem } from '../services/cart.service';
import { OrderService } from '../services/order.service';
import { LoyaltyService } from '../services/loyalty.service';
import { AuthService } from '../services/auth.service';
import { MenuService, MenuItem } from '../services/menu.service';
import { SuggestionService } from '../services/suggestion.service';

@Component({
  selector: 'app-cart',
  templateUrl: './cart.component.html',
  styleUrls: ['./cart.component.css']
})
export class CartComponent implements OnInit, OnDestroy {
  cart$ = this.cartService.cart$;
  cartTotal$ = this.cartService.cartTotal$;

  customerName = '';
  specialInstructions = '';
  isSubmitting = false;
  suggestions: MenuItem[] = [];

  private sub?: Subscription;

  constructor(
    private cartService: CartService,
    private orderService: OrderService,
    private loyaltyService: LoyaltyService,
    public auth: AuthService,
    private menuService: MenuService,
    private suggestionService: SuggestionService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.route.queryParams.subscribe(params => {
      if (params['prefill-instructions']) {
        this.specialInstructions = params['prefill-instructions'];
      }
    });
    if (this.auth.isLoggedIn()) {
      this.customerName = this.auth.getUsername();
    }
  }

  ngOnInit(): void {
    this.sub = this.cart$.pipe(
      switchMap(items => {
        if (items.length === 0) return of([]);
        const cartItemNames = new Set(items.map(ci => ci.menuItem.name));
        const firstItem = items[0].menuItem.name;
        return forkJoin([
          this.suggestionService.getSuggestions(firstItem).pipe(catchError(() => of({ item: firstItem, suggestions: [], model: 'error' }))),
          this.menuService.getMenu()
        ]).pipe(
          map(([res, menu]) => {
            const suggestedNames = res.suggestions || [];
            return menu
              .filter(m => suggestedNames.some(s => m.name.toLowerCase().includes(s.toLowerCase())))
              .filter(m => !cartItemNames.has(m.name))
              .slice(0, 3);
          })
        );
      })
    ).subscribe(suggestions => this.suggestions = suggestions);
  }

  ngOnDestroy(): void {
    this.sub?.unsubscribe();
  }

  addSuggestion(item: MenuItem): void {
    this.cartService.addToCart(item, []);
  }

  updateQuantity(ci: CartItem, quantity: number): void {
    this.cartService.updateQuantity(ci.menuItem.id, quantity, ci.sauces);
  }

  removeItem(ci: CartItem): void {
    this.cartService.removeFromCart(ci.menuItem.id, ci.sauces);
  }

  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    const emoji = img.nextElementSibling as HTMLElement;
    if (emoji) emoji.classList.remove('hidden');
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
        if (this.auth.isLoggedIn()) {
          this.loyaltyService.earnPoints(this.customerName, total).subscribe({
            next: (loyaltyResult) => {
              this.router.navigate(['/confirmation', order.id], {
                state: { loyaltyResult }
              });
            },
            error: () => {
              this.router.navigate(['/confirmation', order.id]);
            }
          });
        } else {
          this.router.navigate(['/confirmation', order.id]);
        }
      },
      error: () => {
        this.isSubmitting = false;
      }
    });
  }
}
