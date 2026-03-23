import { Injectable } from '@angular/core';
import { datadogRum } from '@datadog/browser-rum';
import { environment } from '../../environments/environment';

declare global {
  interface Window {
    __env?: {
      DD_APPLICATION_ID?: string;
      DD_CLIENT_TOKEN?: string;
      DD_SITE?: string;
      DD_ENV?: string;
      DD_VERSION?: string;
    };
  }
}

@Injectable({ providedIn: 'root' })
export class RumService {
  init(): void {
    const env = window.__env ?? {};
    const applicationId = env.DD_APPLICATION_ID || environment.rum.applicationId;
    const clientToken = env.DD_CLIENT_TOKEN || environment.rum.clientToken;

    if (!applicationId || !clientToken) {
      console.warn('[RUM] DD_APPLICATION_ID or DD_CLIENT_TOKEN not set — RUM disabled');
      return;
    }

    datadogRum.init({
      applicationId,
      clientToken,
      site: env.DD_SITE || environment.rum.site,
      service: environment.rum.service,
      env: env.DD_ENV || 'dev',
      version: env.DD_VERSION || '1.0.0',
      sessionSampleRate: 100,
      sessionReplaySampleRate: 100,
      trackUserInteractions: true,
      trackResources: true,
      trackLongTasks: true,
      defaultPrivacyLevel: 'mask-user-input',
      traceSampleRate: 100,
      allowedTracingUrls: [
        { match: /\/api\//, propagatorTypes: ['datadog', 'tracecontext'] }
      ]
    });
  }

  setUser(user: { id: string; email?: string; name?: string }): void {
    datadogRum.setUser(user);
  }

  clearUser(): void {
    datadogRum.clearUser();
  }
}
