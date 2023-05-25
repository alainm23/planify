/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { win } from '../window';
/**
 * Creates a controller that tracks and reacts to opening or closing the keyboard.
 *
 * @internal
 * @param keyboardChangeCallback A function to call when the keyboard opens or closes.
 */
export const createKeyboardController = (keyboardChangeCallback) => {
  let keyboardWillShowHandler;
  let keyboardWillHideHandler;
  let keyboardVisible;
  const init = () => {
    keyboardWillShowHandler = () => {
      keyboardVisible = true;
      if (keyboardChangeCallback)
        keyboardChangeCallback(true);
    };
    keyboardWillHideHandler = () => {
      keyboardVisible = false;
      if (keyboardChangeCallback)
        keyboardChangeCallback(false);
    };
    win === null || win === void 0 ? void 0 : win.addEventListener('keyboardWillShow', keyboardWillShowHandler);
    win === null || win === void 0 ? void 0 : win.addEventListener('keyboardWillHide', keyboardWillHideHandler);
  };
  const destroy = () => {
    win === null || win === void 0 ? void 0 : win.removeEventListener('keyboardWillShow', keyboardWillShowHandler);
    win === null || win === void 0 ? void 0 : win.removeEventListener('keyboardWillHide', keyboardWillHideHandler);
    keyboardWillShowHandler = keyboardWillHideHandler = undefined;
  };
  const isKeyboardVisible = () => keyboardVisible;
  init();
  return { init, destroy, isKeyboardVisible };
};
