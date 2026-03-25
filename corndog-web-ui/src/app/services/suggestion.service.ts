import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface SuggestionResponse {
  item: string;
  suggestions: string[];
  model: string;
}

@Injectable({ providedIn: 'root' })
export class SuggestionService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getSuggestions(itemName: string): Observable<SuggestionResponse> {
    return this.http.get<SuggestionResponse>(`${this.baseUrl}/suggestions`, {
      params: { item: itemName }
    });
  }
}
