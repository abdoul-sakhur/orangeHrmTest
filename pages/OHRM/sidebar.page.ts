import { Page, Locator } from '@playwright/test';

export class Sidebar {
  readonly page: Page;
  readonly menuItems: Locator;
  readonly pimMenu: Locator;
  readonly leaveMenu: Locator;
  readonly timeMenu: Locator;
  readonly adminMenu: Locator;

  constructor(page: Page) {
    this.page      = page;
    // Tous les éléments du menu latéral
    this.menuItems = page.locator('nav.oxd-sidepanel li.oxd-main-menu-item');
    // Exemples de sous-sections
    this.pimMenu   = page.locator('.oxd-main-menu  li').nth(0);
    this.leaveMenu = page.locator('.oxd-main-menu  li').nth(1);
    this.timeMenu  = page.locator('.oxd-main-menu  li').nth(2);
    this.adminMenu = page.locator('.oxd-main-menu  li').nth(3);
  }

}
