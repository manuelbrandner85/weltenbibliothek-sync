import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.weltenbibliothek.app',
  appName: 'Weltenbibliothek',
  webDir: 'dist',
  
  // Server configuration for production
  server: {
    // When deployed, use your Cloudflare Pages URL
    // url: 'https://weltenbibliothek.pages.dev',
    // cleartext: true
  },
  
  // Android specific configuration
  android: {
    backgroundColor: '#0f172a',
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: true
  },
  
  // Plugins configuration
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#0f172a',
      androidScaleType: 'CENTER_CROP',
      showSpinner: true,
      spinnerColor: '#6366f1'
    }
  }
};

export default config;
