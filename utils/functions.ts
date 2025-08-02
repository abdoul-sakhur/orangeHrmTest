import { Locator,Page } from "playwright/test";

export class FonctionDeTest{

constructor() {

}

public async surlignerSelecteur(selector:Locator){
    await selector.evaluate((element) => {
        element.style.background ='#B6F500';
        element.style.color      ='black';
        element.style.border     ='3px solid #FF4F0F';
    })
}


	public async cliquerSurElement(selector:Locator, random:any = 1) {
		await selector.waitFor({state:'visible'}); // Attendez que l'élément soit visible
		if (selector != undefined) {
			var bClick:boolean = true;
			if (bClick) {
				this.surlignerSelecteur(selector);               
				await selector.click();                
			}
		}else {
			throw new Error('TypeError : First argument is expected to be a Locator');
		}  
	}


}
