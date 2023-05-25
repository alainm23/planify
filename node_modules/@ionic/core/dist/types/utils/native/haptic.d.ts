interface HapticImpactOptions {
  style: 'light' | 'medium' | 'heavy';
}
interface HapticNotificationOptions {
  style: 'success' | 'warning' | 'error';
}
/**
 * Check to see if the Haptic Plugin is available
 * @return Returns `true` or false if the plugin is available
 */
export declare const hapticAvailable: () => boolean;
/**
 * Trigger a selection changed haptic event. Good for one-time events
 * (not for gestures)
 */
export declare const hapticSelection: () => void;
/**
 * Tell the haptic engine that a gesture for a selection change is starting.
 */
export declare const hapticSelectionStart: () => void;
/**
 * Tell the haptic engine that a selection changed during a gesture.
 */
export declare const hapticSelectionChanged: () => void;
/**
 * Tell the haptic engine we are done with a gesture. This needs to be
 * called lest resources are not properly recycled.
 */
export declare const hapticSelectionEnd: () => void;
/**
 * Use this to indicate success/failure/warning to the user.
 * options should be of the type `{ type: 'success' }` (or `warning`/`error`)
 */
export declare const hapticNotification: (options: HapticNotificationOptions) => void;
/**
 * Use this to indicate success/failure/warning to the user.
 * options should be of the type `{ style: 'light' }` (or `medium`/`heavy`)
 */
export declare const hapticImpact: (options: HapticImpactOptions) => void;
export {};
