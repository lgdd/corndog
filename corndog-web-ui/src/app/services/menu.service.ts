import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ComboItem {
  menuItemId: number;
  role: string;
}

export interface MenuItem {
  id: number;
  name: string;
  description: string;
  price: number;
  emoji: string;
  category: string;
  imageUrl: string;
  availableSauces: string[];
  comboItems: ComboItem[] | null;
  sortOrder: number;
}

@Injectable({ providedIn: 'root' })
export class MenuService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getMenu(): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/menu`);
  }

  getMenuItem(id: number): Observable<MenuItem> {
    return this.http.get<MenuItem>(`${this.baseUrl}/menu/${id}`);
  }

  getMenuByCategory(category: string): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/menu`, {
      params: { category }
    });
  }
}
