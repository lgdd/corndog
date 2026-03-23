import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { HackerModeService, HackerScenario } from '../../services/hacker-mode.service';

@Component({
  selector: 'app-hacker-panel',
  templateUrl: './hacker-panel.component.html',
  styleUrls: ['./hacker-panel.component.css']
})
export class HackerPanelComponent {
  panelOpen$ = this.hackerService.panelOpen$;
  activeScenario$ = this.hackerService.activeScenario$;
  scenarios = this.hackerService.scenarios;
  expandedId: string | null = null;
  copiedId: string | null = null;

  constructor(
    private hackerService: HackerModeService,
    private router: Router
  ) {}

  closePanel(): void {
    this.hackerService.togglePanel();
  }

  toggleScenario(scenario: HackerScenario): void {
    this.expandedId = this.expandedId === scenario.id ? null : scenario.id;
    this.hackerService.selectScenario(this.expandedId ? scenario : null);
  }

  tryIt(scenario: HackerScenario): void {
    if (!scenario.targetRoute) return;
    const queryParams: Record<string, string> = {};
    if (scenario.id === 'sqli' && scenario.payload) {
      queryParams['prefill'] = scenario.payload;
    } else if (scenario.id === 'xss' && scenario.payload) {
      queryParams['prefill-instructions'] = scenario.payload;
    } else if (scenario.id === 'cmdi-export' && scenario.payload) {
      queryParams['prefill-filename'] = scenario.payload;
    }
    this.router.navigate([scenario.targetRoute], { queryParams });
  }

  copyToClipboard(text: string, scenarioId: string): void {
    navigator.clipboard.writeText(text).then(() => {
      this.copiedId = scenarioId;
      setTimeout(() => this.copiedId = null, 2000);
    });
  }

  hasTryIt(scenario: HackerScenario): boolean {
    return !!scenario.targetRoute && !!scenario.payload;
  }
}
