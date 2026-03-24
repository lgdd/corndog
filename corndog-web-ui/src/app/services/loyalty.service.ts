import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface LoyaltyPoints {
  customer_name: string;
  points: number;
  tier: string;
  updated_at: string;
  requestId: string;
}

export interface LoyaltyEarnResult {
  customer_name: string;
  points: number;
  tier: string;
  points_earned: number;
  requestId: string;
}

export interface LoyaltyRedeemResult {
  customer_name: string;
  points: number;
  tier: string;
  points_redeemed: number;
  requestId: string;
}

@Injectable({ providedIn: 'root' })
export class LoyaltyService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getPoints(customer: string): Observable<LoyaltyPoints> {
    return this.http.get<LoyaltyPoints>(`${this.baseUrl}/loyalty/points`, {
      params: { customer }
    });
  }

  earnPoints(customerName: string, orderTotal: number): Observable<LoyaltyEarnResult> {
    return this.http.post<LoyaltyEarnResult>(`${this.baseUrl}/loyalty/earn`, {
      customerName, orderTotal
    });
  }

  redeemPoints(customerName: string, points: number): Observable<LoyaltyRedeemResult> {
    return this.http.post<LoyaltyRedeemResult>(`${this.baseUrl}/loyalty/redeem`, {
      customerName, points
    });
  }
}
