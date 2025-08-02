import { Page, Locator, expect } from '@playwright/test';

export class AdminUserPage {
  public readonly page            : Page;
  public readonly addButton       : Locator;
  public readonly userRoleDropdown: Locator;
  public readonly statusDropdown  : Locator;
  public readonly searchButton    : Locator;
  public readonly resultRows      : Locator;

  constructor(page: Page) {
    this.page             = page;
    this.addButton        = page.locator('button:has-text("Add")');
    this.userRoleDropdown = page.locator('i.oxd-icon.bi-caret-down-fill').nth(0);
    this.statusDropdown   = page.locator('i.oxd-icon.bi-caret-down-fill').nth(1);
    this.searchButton     = page.locator('button:has-text("Search")');
    this.resultRows       = page.locator('div.oxd-table-body div.oxd-table-card');
  }
}