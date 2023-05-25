import type { MenuI } from '../../../components/menu/menu-interface';
import type { Animation } from '../../animation/animation-interface';
/**
 * Menu Push Type
 * The content slides over to reveal the menu underneath.
 * The menu itself also slides over to reveal its bad self.
 */
export declare const menuPushAnimation: (menu: MenuI) => Animation;
