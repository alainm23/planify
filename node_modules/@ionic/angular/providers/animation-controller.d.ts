import { Animation } from '@ionic/core';
import * as i0 from "@angular/core";
export declare class AnimationController {
    /**
     * Create a new animation
     */
    create(animationId?: string): Animation;
    /**
     * EXPERIMENTAL
     *
     * Given a progression and a cubic bezier function,
     * this utility returns the time value(s) at which the
     * cubic bezier reaches the given time progression.
     *
     * If the cubic bezier never reaches the progression
     * the result will be an empty array.
     *
     * This is most useful for switching between easing curves
     * when doing a gesture animation (i.e. going from linear easing
     * during a drag, to another easing when `progressEnd` is called)
     */
    easingTime(p0: number[], p1: number[], p2: number[], p3: number[], progression: number): number[];
    static ɵfac: i0.ɵɵFactoryDeclaration<AnimationController, never>;
    static ɵprov: i0.ɵɵInjectableDeclaration<AnimationController>;
}
