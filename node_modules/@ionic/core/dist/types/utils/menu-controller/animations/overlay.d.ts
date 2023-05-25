import type { MenuI } from '../../../components/menu/menu-interface';
import type { Animation } from '../../animation/animation-interface';
/**
 * Menu Overlay Type
 * The menu slides over the content. The content
 * itself, which is under the menu, does not move.
 */
export declare const menuOverlayAnimation: (menu: MenuI) => Animation;
