import { LoginPage }    from "../pages/OHRM/login.page";
import { test, expect, Page } from '@playwright/test';
import { Sidebar}       from "../pages/OHRM/sidebar.page";
import { AdminUserPage} from "../pages/OHRM/admin.page";
import {FonctionDeTest} from "../utils/functions.ts";

let page                 : Page;
let loginPage            : LoginPage;
let sidebar              : Sidebar;
let adminUserPage        : AdminUserPage;
let fonction             : FonctionDeTest;

test.beforeAll(async ({ browser }, ) => {
    page                 = await browser.newPage();
    loginPage            = new LoginPage(page);
    sidebar              = new Sidebar(page);
    adminUserPage        = new AdminUserPage(page);
    fonction             = new FonctionDeTest();
});

test.afterAll(async ({}) => {
    await page.close();
});

test.describe.serial('Faire une connexion', async () => {
    test('Ouverture URL : ohrm' , async() => {
        await page.goto('https://opensource-demo.orangehrmlive.com/');
    });

    test('Connexion', async () => {
        await loginPage.usernameInput.fill('Admin');
        await loginPage.passwordInput.fill('admin123');
        await fonction.cliquerSurElement(loginPage.loginButton); // loginPage.loginButton;
    });

    test('Affichage des menus', async () => {
        await fonction.cliquerSurElement(sidebar.pimMenu); // sidebar.pimMenu
    });

    test('Vérification des éléments principaux de la page PIM', async () => {
        // Vérifier la présence du header principal
        // await expect(page.locator('.oxd-topbar-header-breadcrumb h6')).toBeVisible();
        
        // Vérifier la présence du bouton d'ajout
        await expect(page.locator('.oxd-button--secondary').first()).toBeVisible();
        
        // Vérifier la présence du formulaire de recherche
        await expect(page.locator('.oxd-form').first()).toBeVisible();
        
        // Vérifier la présence du tableau des employés
        await expect(page.locator('.oxd-table').first()).toBeVisible();
    });

    test('Test du formulaire de recherche PIM', async () => {
        // Recherche par nom d'employé
        const employeeNameInput = page.locator('.oxd-autocomplete-text-input input').first();
        await employeeNameInput.fill('a');
        await page.waitForTimeout(1000); // Attendre les suggestions
        
        // Sélectionner le premier résultat s'il existe
        const firstSuggestion = page.locator('.oxd-autocomplete-option').first();
        if (await firstSuggestion.isVisible()) {
            await firstSuggestion.click();
        }
        
        // Cliquer sur le bouton de recherche
        await fonction.cliquerSurElement(page.locator('button[type="submit"]').first()); // page.locator('button[type="submit"]');
        await page.waitForLoadState('networkidle');
        
        // Vérifier que la table est toujours présente après la recherche
        await expect(page.locator('.oxd-table').first()).toBeVisible();
    });
})