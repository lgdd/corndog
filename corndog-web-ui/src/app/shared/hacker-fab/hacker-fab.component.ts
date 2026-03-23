import { Component } from '@angular/core';
import { HackerModeService } from '../../services/hacker-mode.service';

@Component({
  selector: 'app-hacker-fab',
  templateUrl: './hacker-fab.component.html',
  styleUrls: ['./hacker-fab.component.css']
})
export class HackerFabComponent {
  hackerMode$ = this.hackerService.hackerMode$;

  constructor(private hackerService: HackerModeService) {}

  toggle(): void {
    this.hackerService.toggle();
  }

  togglePanel(): void {
    if (this.hackerService.isActive()) {
      this.hackerService.togglePanel();
    } else {
      this.hackerService.toggle();
      this.hackerService.togglePanel();
    }
  }
}
