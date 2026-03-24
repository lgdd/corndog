import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { LoyaltyService, LoyaltyPoints } from '../services/loyalty.service';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-loyalty',
  templateUrl: './loyalty.component.html',
  styleUrls: ['./loyalty.component.css']
})
export class LoyaltyComponent implements OnInit {
  loyaltyInfo: LoyaltyPoints | null = null;
  loading = true;
  redeemAmount: number | null = null;
  redeemMessage = '';
  redeemError = false;
  cardUrl: SafeResourceUrl | null = null;
  cardCustomer = '';

  constructor(
    private loyaltyService: LoyaltyService,
    public auth: AuthService,
    private sanitizer: DomSanitizer,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.loadPoints();
  }

  loadPoints(): void {
    const username = this.auth.getUsername();
    this.loading = true;

    // If prefill-xss query param is present, use it as the card customer (XSS demo)
    const xssPayload = this.route.snapshot.queryParamMap.get('prefill-xss');
    this.cardCustomer = xssPayload || username;

    this.cardUrl = this.sanitizer.bypassSecurityTrustResourceUrl(
      `/api/loyalty/card?customer=${this.cardCustomer}`
    );

    this.loyaltyService.getPoints(username).subscribe({
      next: (info) => {
        this.loyaltyInfo = info;
        this.loading = false;
      },
      error: () => {
        this.loyaltyInfo = null;
        this.loading = false;
      }
    });
  }

  redeemPoints(): void {
    if (!this.redeemAmount || this.redeemAmount <= 0) return;
    const username = this.auth.getUsername();
    this.loyaltyService.redeemPoints(username, this.redeemAmount).subscribe({
      next: (result) => {
        this.redeemMessage = `Redeemed ${result.points_redeemed} points! New balance: ${result.points}`;
        this.redeemError = false;
        this.redeemAmount = null;
        this.loadPoints();
        setTimeout(() => this.redeemMessage = '', 4000);
      },
      error: (err) => {
        this.redeemMessage = err.error?.error || 'Redemption failed';
        this.redeemError = true;
        setTimeout(() => this.redeemMessage = '', 4000);
      }
    });
  }
}
