/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import{w as l}from"./p-4de71892.js";const o=o=>{let e,i,r;const d=()=>{e=()=>{r=!0,o&&o(!0)},i=()=>{r=!1,o&&o(!1)},null==l||l.addEventListener("keyboardWillShow",e),null==l||l.addEventListener("keyboardWillHide",i)};return d(),{init:d,destroy:()=>{null==l||l.removeEventListener("keyboardWillShow",e),null==l||l.removeEventListener("keyboardWillHide",i),e=i=void 0},isKeyboardVisible:()=>r}};export{o as c}