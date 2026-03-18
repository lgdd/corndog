import { Component, OnInit } from '@angular/core';
import { MenuService, MenuItem } from '../services/menu.service';
import { CartService } from '../services/cart.service';

@Component({
  selector: 'app-menu',
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit {
  menuItems: MenuItem[] = [];
  addedItemId: number | null = null;

  constructor(
    private menuService: MenuService,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.menuService.getMenu().subscribe(items => {
      this.menuItems = items;
    });
  }

  addToCart(item: MenuItem): void {
    this.cartService.addToCart(item);
    this.addedItemId = item.id;
    setTimeout(() => this.addedItemId = null, 1200);
  }
}
