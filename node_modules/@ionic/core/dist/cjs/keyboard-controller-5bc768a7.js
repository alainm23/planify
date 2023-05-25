/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
'use strict';

const index = require('./index-823295fd.js');

/**
 * Creates a controller that tracks and reacts to opening or closing the keyboard.
 *
 * @internal
 * @param keyboardChangeCallback A function to call when the keyboard opens or closes.
 */
const createKeyboardController = (keyboardChangeCallback) => {
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
    index.win === null || index.win === void 0 ? void 0 : index.win.addEventListener('keyboardWillShow', keyboardWillShowHandler);
    index.win === null || index.win === void 0 ? void 0 : index.win.addEventListener('keyboardWillHide', keyboardWillHideHandler);
  };
  const destroy = () => {
    index.win === null || index.win === void 0 ? void 0 : index.win.removeEventListener('keyboardWillShow', keyboardWillShowHandler);
    index.win === null || index.win === void 0 ? void 0 : index.win.removeEventListener('keyboardWillHide', keyboardWillHideHandler);
    keyboardWillShowHandler = keyboardWillHideHandler = undefined;
  };
  const isKeyboardVisible = () => keyboardVisible;
  init();
  return { init, destroy, isKeyboardVisible };
};

exports.createKeyboardController = createKeyboardController;
