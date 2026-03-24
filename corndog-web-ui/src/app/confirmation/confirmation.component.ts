import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { OrderService, Order } from '../services/order.service';
import { LoyaltyService, LoyaltyEarnResult } from '../services/loyalty.service';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-confirmation',
  templateUrl: './confirmation.component.html',
  styleUrls: ['./confirmation.component.css']
})
export class ConfirmationComponent implements OnInit {
  order: Order | null = null;
  loading = true;
  loyaltyResult: LoyaltyEarnResult | null = null;
  loyaltyLoading = false;

  constructor(
    private route: ActivatedRoute,
    private orderService: OrderService,
    private loyaltyService: LoyaltyService,
    private auth: AuthService
  ) {}

  ngOnInit(): void {
    const nav = history.state;
    if (nav?.loyaltyResult) {
      this.loyaltyResult = nav.loyaltyResult;
    }

    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.orderService.getOrder(id).subscribe({
      next: (order) => {
        this.order = order;
        this.loading = false;
        if (!this.loyaltyResult && order.customerName && this.auth.isLoggedIn()) {
          this.loyaltyLoading = true;
          this.loyaltyService.getPoints(order.customerName).subscribe({
            next: (points) => {
              this.loyaltyResult = {
                customer_name: points.customer_name,
                points: points.points,
                tier: points.tier,
                points_earned: Math.floor(order.totalPrice * 10),
                requestId: points.requestId
              };
              this.loyaltyLoading = false;
            },
            error: () => { this.loyaltyLoading = false; }
          });
        }
      },
      error: () => {
        this.loading = false;
      }
    });
  }
}
