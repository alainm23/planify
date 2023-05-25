/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { m as menuController } from './index4.js';

// Given a menu, return whether or not the menu toggle should be visible
const updateVisibility = async (menu) => {
  const menuEl = await menuController.get(menu);
  return !!(menuEl && (await menuEl.isActive()));
};

export { updateVisibility as u };
