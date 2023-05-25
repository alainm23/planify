import type { ComponentInterface } from '../../stencil-public-runtime';
import type { ComponentRef, FrameworkDelegate } from '../../interface';
export declare class Tab implements ComponentInterface {
  private loaded;
  el: HTMLIonTabElement;
  /** @internal */
  active: boolean;
  /** @internal */
  delegate?: FrameworkDelegate;
  /**
   * A tab id must be provided for each `ion-tab`. It's used internally to reference
   * the selected tab or by the router to switch between them.
   */
  tab: string;
  /**
   * The component to display inside of the tab.
   */
  component?: ComponentRef;
  componentWillLoad(): Promise<void>;
  /** Set the active component for the tab */
  setActive(): Promise<void>;
  changeActive(isActive: boolean): void;
  private prepareLazyLoaded;
  render(): any;
}
