import { APP_INITIALIZER, NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { MenuComponent } from './menu/menu.component';
import { CartComponent } from './cart/cart.component';
import { ConfirmationComponent } from './confirmation/confirmation.component';
import { OrderHistoryComponent } from './order-history/order-history.component';
import { AdminComponent } from './admin/admin.component';
import { SafeHtmlPipe } from './shared/safe-html.pipe';
import { AuthService } from './services/auth.service';
import { RumService } from './services/rum.service';

function initializeRum(rum: RumService) {
  return () => rum.init();
}

function initializeKeycloak(auth: AuthService) {
  return () => auth.init();
}

@NgModule({
  declarations: [
    AppComponent,
    MenuComponent,
    CartComponent,
    ConfirmationComponent,
    OrderHistoryComponent,
    AdminComponent,
    SafeHtmlPipe
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeRum,
      multi: true,
      deps: [RumService]
    },
    {
      provide: APP_INITIALIZER,
      useFactory: initializeKeycloak,
      multi: true,
      deps: [AuthService]
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
