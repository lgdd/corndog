import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface OrderItem {
  menuItemId: number;
  name: string;
  quantity: number;
  price: number;
  sauces?: string[];
}

export interface Order {
  id: number;
  customerName: string;
  items: OrderItem[];
  specialInstructions: string;
  totalPrice: number;
  createdAt: string;
}

export interface OrderRequest {
  customerName: string;
  items: OrderItem[];
  specialInstructions: string;
  totalPrice: number;
}

@Injectable({ providedIn: 'root' })
export class OrderService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  placeOrder(order: OrderRequest): Observable<Order> {
    return this.http.post<Order>(`${this.baseUrl}/orders`, order);
  }

  getOrder(id: number): Observable<Order> {
    return this.http.get<Order>(`${this.baseUrl}/orders/${id}`);
  }

  searchOrders(query: string): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.baseUrl}/orders/search`, {
      params: { q: query }
    });
  }

  getReceipt(orderId: number, format: string = 'txt'): Observable<any> {
    return this.http.get(`${this.baseUrl}/orders/${orderId}/receipt`, {
      params: { format }
    });
  }

  getAllOrders(): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.baseUrl}/admin/orders`);
  }

  exportOrders(filename: string): Observable<any> {
    return this.http.post(`${this.baseUrl}/admin/export`, { filename });
  }
}
