import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class Col implements ComponentInterface {
  /**
   * The amount to offset the column, in terms of how many columns it should shift to the end
   * of the total available.
   */
  offset?: string;
  /**
   * The amount to offset the column for xs screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  offsetXs?: string;
  /**
   * The amount to offset the column for sm screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  offsetSm?: string;
  /**
   * The amount to offset the column for md screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  offsetMd?: string;
  /**
   * The amount to offset the column for lg screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  offsetLg?: string;
  /**
   * The amount to offset the column for xl screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  offsetXl?: string;
  /**
   * The amount to pull the column, in terms of how many columns it should shift to the start of
   * the total available.
   */
  pull?: string;
  /**
   * The amount to pull the column for xs screens, in terms of how many columns it should shift
   * to the start of the total available.
   */
  pullXs?: string;
  /**
   * The amount to pull the column for sm screens, in terms of how many columns it should shift
   * to the start of the total available.
   */
  pullSm?: string;
  /**
   * The amount to pull the column for md screens, in terms of how many columns it should shift
   * to the start of the total available.
   */
  pullMd?: string;
  /**
   * The amount to pull the column for lg screens, in terms of how many columns it should shift
   * to the start of the total available.
   */
  pullLg?: string;
  /**
   * The amount to pull the column for xl screens, in terms of how many columns it should shift
   * to the start of the total available.
   */
  pullXl?: string;
  /**
   * The amount to push the column, in terms of how many columns it should shift to the end
   * of the total available.
   */
  push?: string;
  /**
   * The amount to push the column for xs screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  pushXs?: string;
  /**
   * The amount to push the column for sm screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  pushSm?: string;
  /**
   * The amount to push the column for md screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  pushMd?: string;
  /**
   * The amount to push the column for lg screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  pushLg?: string;
  /**
   * The amount to push the column for xl screens, in terms of how many columns it should shift
   * to the end of the total available.
   */
  pushXl?: string;
  /**
   * The size of the column, in terms of how many columns it should take up out of the total
   * available. If `"auto"` is passed, the column will be the size of its content.
   */
  size?: string;
  /**
   * The size of the column for xs screens, in terms of how many columns it should take up out
   * of the total available. If `"auto"` is passed, the column will be the size of its content.
   */
  sizeXs?: string;
  /**
   * The size of the column for sm screens, in terms of how many columns it should take up out
   * of the total available. If `"auto"` is passed, the column will be the size of its content.
   */
  sizeSm?: string;
  /**
   * The size of the column for md screens, in terms of how many columns it should take up out
   * of the total available. If `"auto"` is passed, the column will be the size of its content.
   */
  sizeMd?: string;
  /**
   * The size of the column for lg screens, in terms of how many columns it should take up out
   * of the total available. If `"auto"` is passed, the column will be the size of its content.
   */
  sizeLg?: string;
  /**
   * The size of the column for xl screens, in terms of how many columns it should take up out
   * of the total available. If `"auto"` is passed, the column will be the size of its content.
   */
  sizeXl?: string;
  onResize(): void;
  private getColumns;
  private calculateSize;
  private calculatePosition;
  private calculateOffset;
  private calculatePull;
  private calculatePush;
  render(): any;
}
