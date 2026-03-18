import { Component } from '@angular/core';
import { OrderService, Order } from '../services/order.service';

@Component({
  selector: 'app-order-history',
  templateUrl: './order-history.component.html',
  styleUrls: ['./order-history.component.css']
})
export class OrderHistoryComponent {
  searchQuery = '';
  orders: Order[] = [];
  searched = false;
  loading = false;

  constructor(private orderService: OrderService) {}

  search(): void {
    if (!this.searchQuery.trim()) return;
    this.loading = true;
    this.orderService.searchOrders(this.searchQuery).subscribe({
      next: (orders) => {
        this.orders = orders;
        this.searched = true;
        this.loading = false;
      },
      error: () => {
        this.orders = [];
        this.searched = true;
        this.loading = false;
      }
    });
  }
}
