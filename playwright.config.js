const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: 'tests',
  timeout: 30000,
  expect: {
    timeout: 5000
  },
 reporter: [
    ['html', { 
      outputFolder: 'C:/ProgramData/Jenkins/.jenkins/workspace/recuperer_repository_github/playwright-report/',
      open: 'never',
      host: '0.0.0.0',
      port: 9323
    }]
  ],
  use: {
    headless: true,
    browserName: 'chromium',
        screenshot: 'only-on-failure',  // <--- capture auto en cas d'échec
    // video: 'retain-on-failure',     // (optionnel) conserve vidéo en cas d'échec
    // trace: 'on-first-retry'         // (optionnel) trace à la 2e tentative
  },
});