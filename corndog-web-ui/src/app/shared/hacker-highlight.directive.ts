import { Directive, ElementRef, Input, OnDestroy, OnInit } from '@angular/core';
import { Subscription, combineLatest } from 'rxjs';
import { HackerModeService } from '../services/hacker-mode.service';

@Directive({
  selector: '[appHackerHighlight]'
})
export class HackerHighlightDirective implements OnInit, OnDestroy {
  @Input('appHackerHighlight') scenarioId = '';
  private sub?: Subscription;

  constructor(
    private el: ElementRef,
    private hackerService: HackerModeService
  ) {}

  ngOnInit(): void {
    this.sub = combineLatest([
      this.hackerService.hackerMode$,
      this.hackerService.activeScenario$
    ]).subscribe(([active, scenario]) => {
      const highlight = active && scenario?.id === this.scenarioId;
      if (highlight) {
        this.el.nativeElement.style.boxShadow = '0 0 0 2px #00ff41, 0 0 16px rgba(0, 255, 65, 0.3)';
        this.el.nativeElement.style.transition = 'box-shadow 0.3s ease';
      } else {
        this.el.nativeElement.style.boxShadow = '';
      }
    });
  }

  ngOnDestroy(): void {
    this.sub?.unsubscribe();
  }
}
