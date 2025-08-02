import { Page, Locator, expect } from '@playwright/test';

export class LoginPage {
  public readonly page              : Page;
  public readonly usernameInput     : Locator;
  public readonly passwordInput     : Locator;
  public readonly loginButton       : Locator;
  public readonly errorMessage      : Locator;
  public readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page               = page;
    this.usernameInput      = page.locator('input[name="username"]');
    this.passwordInput      = page.locator('input[name="password"]');
    this.loginButton        = page.locator('button[type="submit"]');
    this.errorMessage       = page.locator('.oxd-alert-content-text'); // message "Invalid credentials" :contentReference[oaicite:0]{index=0}
    this.forgotPasswordLink = page.locator('div.orangehrm-login-forgot p');
  }

}
