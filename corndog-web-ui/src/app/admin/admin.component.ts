import { Component, OnInit } from '@angular/core';
import { OrderService, Order } from '../services/order.service';

// TODO: fix before production — add route guard with authentication
@Component({
  selector: 'app-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent implements OnInit {
  orders: Order[] = [];
  exportFilename = 'orders_export.csv';
  exportMessage = '';
  loading = true;

  constructor(private orderService: OrderService) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading = true;
    this.orderService.getAllOrders().subscribe({
      next: (orders) => {
        this.orders = orders;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      }
    });
  }

  exportOrders(): void {
    this.orderService.exportOrders(this.exportFilename).subscribe({
      next: (result) => {
        this.exportMessage = result.message;
        setTimeout(() => this.exportMessage = '', 3000);
      },
      error: () => {
        this.exportMessage = 'Export failed';
      }
    });
  }
}
