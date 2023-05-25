import type { ElementHandle, Locator } from '@playwright/test';
import type { E2EPage } from './';
export declare const dragElementBy: (el: Locator | ElementHandle<SVGElement | HTMLElement>, page: E2EPage, dragByX?: number, dragByY?: number, startXCoord?: number, startYCoord?: number) => Promise<void>;
/**
 * Drags an element by the given amount of pixels on the Y axis.
 * @param el The element to drag.
 * @param page The E2E Page object.
 * @param dragByY The amount of pixels to drag the element by.
 * @param startYCoord The Y coordinate to start the drag gesture at. Defaults to the center of the element.
 */
export declare const dragElementByYAxis: (el: Locator | ElementHandle<SVGElement | HTMLElement>, page: E2EPage, dragByY: number, startYCoord?: number) => Promise<void>;
