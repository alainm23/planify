interface HeaderIndex {
  el: HTMLIonHeaderElement;
  toolbars: ToolbarIndex[] | [];
}
interface ToolbarIndex {
  el: HTMLElement;
  background: HTMLElement;
  ionTitleEl: HTMLIonTitleElement | undefined;
  innerTitleEl: HTMLElement;
  ionButtonsEl: HTMLElement[] | [];
}
export declare const cloneElement: (tagName: string) => Element;
export declare const createHeaderIndex: (headerEl: HTMLElement | undefined) => HeaderIndex | undefined;
export declare const handleContentScroll: (scrollEl: HTMLElement, scrollHeaderIndex: HeaderIndex, contentEl: HTMLElement) => void;
export declare const setToolbarBackgroundOpacity: (headerEl: HTMLIonHeaderElement, opacity?: number) => void;
/**
 * If toolbars are intersecting, hide the scrollable toolbar content
 * and show the primary toolbar content. If the toolbars are not intersecting,
 * hide the primary toolbar content and show the scrollable toolbar content
 */
export declare const handleToolbarIntersection: (ev: any, mainHeaderIndex: HeaderIndex, scrollHeaderIndex: HeaderIndex, scrollEl: HTMLElement) => void;
export declare const setHeaderActive: (headerIndex: HeaderIndex, active?: boolean) => void;
export declare const scaleLargeTitles: (toolbars?: ToolbarIndex[], scale?: number, transition?: boolean) => void;
export declare const handleHeaderFade: (scrollEl: HTMLElement, baseEl: HTMLElement, condenseHeader: HTMLElement | null) => void;
export {};
