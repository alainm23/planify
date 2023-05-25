/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { addEventListener, removeEventListener } from '../../helpers';
import { isFocused, relocateInput } from './common';
export const enableHideCaretOnScroll = (componentEl, inputEl, scrollEl) => {
  if (!scrollEl || !inputEl) {
    return () => {
      return;
    };
  }
  const scrollHideCaret = (shouldHideCaret) => {
    if (isFocused(inputEl)) {
      relocateInput(componentEl, inputEl, shouldHideCaret);
    }
  };
  const onBlur = () => relocateInput(componentEl, inputEl, false);
  const hideCaret = () => scrollHideCaret(true);
  const showCaret = () => scrollHideCaret(false);
  addEventListener(scrollEl, 'ionScrollStart', hideCaret);
  addEventListener(scrollEl, 'ionScrollEnd', showCaret);
  inputEl.addEventListener('blur', onBlur);
  return () => {
    removeEventListener(scrollEl, 'ionScrollStart', hideCaret);
    removeEventListener(scrollEl, 'ionScrollEnd', showCaret);
    inputEl.removeEventListener('blur', onBlur);
  };
};
