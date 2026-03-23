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
  filteredItems: MenuItem[] = [];
  categories = ['all', 'corndogs', 'sides', 'drinks', 'combos'];
  categoryLabels: Record<string, string> = {
    all: 'All', corndogs: 'Corndogs', sides: 'Sides', drinks: 'Drinks', combos: 'Combos'
  };
  activeCategory = 'all';
  addedItemId: number | null = null;
  selectedSauces: Map<number, string[]> = new Map();

  constructor(
    private menuService: MenuService,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.menuService.getMenu().subscribe(items => {
      this.menuItems = items;
      this.applyFilter();
    });
  }

  filterByCategory(category: string): void {
    this.activeCategory = category;
    this.applyFilter();
  }

  private applyFilter(): void {
    if (this.activeCategory === 'all') {
      this.filteredItems = this.menuItems;
    } else {
      this.filteredItems = this.menuItems.filter(i => i.category === this.activeCategory);
    }
  }

  getItemsByCategory(category: string): MenuItem[] {
    return this.menuItems.filter(i => i.category === category);
  }

  get activeCategories(): string[] {
    if (this.activeCategory === 'all') {
      return this.categories.filter(c => c !== 'all' && this.getItemsByCategory(c).length > 0);
    }
    return [this.activeCategory];
  }

  toggleSauce(itemId: number, sauce: string): void {
    const current = this.selectedSauces.get(itemId) || [];
    const index = current.indexOf(sauce);
    if (index >= 0) {
      current.splice(index, 1);
    } else {
      current.push(sauce);
    }
    this.selectedSauces.set(itemId, [...current]);
  }

  isSauceSelected(itemId: number, sauce: string): boolean {
    return (this.selectedSauces.get(itemId) || []).includes(sauce);
  }

  getAvailableSauces(item: MenuItem): string[] {
    if (!item.availableSauces) return [];
    if (typeof item.availableSauces === 'string') {
      try { return JSON.parse(item.availableSauces); } catch { return []; }
    }
    return item.availableSauces;
  }

  getComboItems(item: MenuItem): any[] {
    if (!item.comboItems) return [];
    if (typeof item.comboItems === 'string') {
      try { return JSON.parse(item.comboItems); } catch { return []; }
    }
    return item.comboItems;
  }

  getComboSavings(item: MenuItem): number {
    const comboItems = this.getComboItems(item);
    if (comboItems.length === 0) return 0;
    const individualTotal = comboItems.reduce((sum: number, ci: any) => {
      const menuItem = this.menuItems.find(m => m.id === ci.menuItemId);
      return sum + (menuItem ? menuItem.price : 0);
    }, 0);
    return Math.max(0, individualTotal - item.price);
  }

  getComboItemName(menuItemId: number): string {
    const item = this.menuItems.find(m => m.id === menuItemId);
    return item ? item.name : '';
  }

  formatSauceName(sauce: string): string {
    return sauce.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
  }

  getGradientClass(item: MenuItem): string {
    return 'gradient-' + item.category;
  }

  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    const emoji = img.parentElement?.querySelector('.menu-emoji') as HTMLElement;
    if (emoji) emoji.classList.remove('hidden');
  }

  addToCart(item: MenuItem): void {
    const sauces = this.selectedSauces.get(item.id) || [];
    this.cartService.addToCart(item, sauces);
    this.addedItemId = item.id;
    setTimeout(() => this.addedItemId = null, 1200);
  }
}
