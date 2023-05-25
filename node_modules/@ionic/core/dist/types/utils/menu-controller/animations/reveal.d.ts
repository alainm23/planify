import type { MenuI } from '../../../components/menu/menu-interface';
import type { Animation } from '../../animation/animation-interface';
/**
 * Menu Reveal Type
 * The content slides over to reveal the menu underneath.
 * The menu itself, which is under the content, does not move.
 */
export declare const menuRevealAnimation: (menu: MenuI) => Animation;
