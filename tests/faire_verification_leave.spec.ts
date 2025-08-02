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
        await fonction.cliquerSurElement(sidebar.adminMenu); // sidebar.pimMenu
    });


    test('Vérification des éléments principaux de la page Admin', async () => {

        
        // Vérifier la présence du bouton d'ajout d'utilisateur
        await expect(page.locator('.oxd-button--secondary').first()).toBeVisible();
        
        // Vérifier la présence du formulaire de recherche
        await expect(page.locator('.oxd-form').first()).toBeVisible();
        
        // Vérifier la présence du tableau des utilisateurs
        await expect(page.locator('.oxd-table').first()).toBeVisible();
    });

  
})