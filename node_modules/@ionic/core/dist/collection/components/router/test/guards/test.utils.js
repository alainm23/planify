/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
/**
 * Selects a radio button from the radio group for configuring the
 * beforeEnter hook of the router.
 */
export const setBeforeEnterHook = async (page, type) => {
  await page.click(`ion-radio-group#beforeEnter ion-radio[value=${type}]`);
};
/**
 * Selects a radio button from the radio group for configuring the
 * beforeLeave hook of the router.
 */
export const setBeforeLeaveHook = async (page, type) => {
  await page.click(`ion-radio-group#beforeLeave ion-radio[value=${type}]`);
};
