/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
'use strict';

const gestureController = require('./gesture-controller-e2865472.js');

const addEventListener = (el, // TODO(FW-2832): type
eventName, callback, opts) => {
  // use event listener options when supported
  // otherwise it's just a boolean for the "capture" arg
  const listenerOpts = supportsPassive(el)
    ? {
      capture: !!opts.capture,
      passive: !!opts.passive,
    }
    : !!opts.capture;
  let add;
  let remove;
  if (el['__zone_symbol__addEventListener']) {
    add = '__zone_symbol__addEventListener';
    remove = '__zone_symbol__removeEventListener';
  }
  else {
    add = 'addEventListener';
    remove = 'removeEventListener';
  }
  el[add](eventName, callback, listenerOpts);
  return () => {
    el[remove](eventName, callback, listenerOpts);
  };
};
const supportsPassive = (node) => {
  if (_sPassive === undefined) {
    try {
      const opts = Object.defineProperty({}, 'passive', {
        get: () => {
          _sPassive = true;
        },
      });
      node.addEventListener('optsTest', () => {
        return;
      }, opts);
    }
    catch (e) {
      _sPassive = false;
    }
  }
  return !!_sPassive;
};
let _sPassive;

const MOUSE_WAIT = 2000;
// TODO(FW-2832): types
const createPointerEvents = (el, pointerDown, pointerMove, pointerUp, options) => {
  let rmTouchStart;
  let rmTouchMove;
  let rmTouchEnd;
  let rmTouchCancel;
  let rmMouseStart;
  let rmMouseMove;
  let rmMouseUp;
  let lastTouchEvent = 0;
  const handleTouchStart = (ev) => {
    lastTouchEvent = Date.now() + MOUSE_WAIT;
    if (!pointerDown(ev)) {
      return;
    }
    if (!rmTouchMove && pointerMove) {
      rmTouchMove = addEventListener(el, 'touchmove', pointerMove, options);
    }
    /**
     * Events are dispatched on the element that is tapped and bubble up to
     * the reference element in the gesture. In the event that the element this
     * event was first dispatched on is removed from the DOM, the event will no
     * longer bubble up to our reference element. This leaves the gesture in an
     * unusable state. To account for this, the touchend and touchcancel listeners
     * should be added to the event target so that they still fire even if the target
     * is removed from the DOM.
     */
    if (!rmTouchEnd) {
      rmTouchEnd = addEventListener(ev.target, 'touchend', handleTouchEnd, options);
    }
    if (!rmTouchCancel) {
      rmTouchCancel = addEventListener(ev.target, 'touchcancel', handleTouchEnd, options);
    }
  };
  const handleMouseDown = (ev) => {
    if (lastTouchEvent > Date.now()) {
      return;
    }
    if (!pointerDown(ev)) {
      return;
    }
    if (!rmMouseMove && pointerMove) {
      rmMouseMove = addEventListener(getDocument(el), 'mousemove', pointerMove, options);
    }
    if (!rmMouseUp) {
      rmMouseUp = addEventListener(getDocument(el), 'mouseup', handleMouseUp, options);
    }
  };
  const handleTouchEnd = (ev) => {
    stopTouch();
    if (pointerUp) {
      pointerUp(ev);
    }
  };
  const handleMouseUp = (ev) => {
    stopMouse();
    if (pointerUp) {
      pointerUp(ev);
    }
  };
  const stopTouch = () => {
    if (rmTouchMove) {
      rmTouchMove();
    }
    if (rmTouchEnd) {
      rmTouchEnd();
    }
    if (rmTouchCancel) {
      rmTouchCancel();
    }
    rmTouchMove = rmTouchEnd = rmTouchCancel = undefined;
  };
  const stopMouse = () => {
    if (rmMouseMove) {
      rmMouseMove();
    }
    if (rmMouseUp) {
      rmMouseUp();
    }
    rmMouseMove = rmMouseUp = undefined;
  };
  const stop = () => {
    stopTouch();
    stopMouse();
  };
  const enable = (isEnabled = true) => {
    if (!isEnabled) {
      if (rmTouchStart) {
        rmTouchStart();
      }
      if (rmMouseStart) {
        rmMouseStart();
      }
      rmTouchStart = rmMouseStart = undefined;
      stop();
    }
    else {
      if (!rmTouchStart) {
        rmTouchStart = addEventListener(el, 'touchstart', handleTouchStart, options);
      }
      if (!rmMouseStart) {
        rmMouseStart = addEventListener(el, 'mousedown', handleMouseDown, options);
      }
    }
  };
  const destroy = () => {
    enable(false);
    pointerUp = pointerMove = pointerDown = undefined;
  };
  return {
    enable,
    stop,
    destroy,
  };
};
const getDocument = (node) => {
  return node instanceof Document ? node : node.ownerDocument;
};

const createPanRecognizer = (direction, thresh, maxAngle) => {
  const radians = maxAngle * (Math.PI / 180);
  const isDirX = direction === 'x';
  const maxCosine = Math.cos(radians);
  const threshold = thresh * thresh;
  let startX = 0;
  let startY = 0;
  let dirty = false;
  let isPan = 0;
  return {
    start(x, y) {
      startX = x;
      startY = y;
      isPan = 0;
      dirty = true;
    },
    detect(x, y) {
      if (!dirty) {
        return false;
      }
      const deltaX = x - startX;
      const deltaY = y - startY;
      const distance = deltaX * deltaX + deltaY * deltaY;
      if (distance < threshold) {
        return false;
      }
      const hypotenuse = Math.sqrt(distance);
      const cosine = (isDirX ? deltaX : deltaY) / hypotenuse;
      if (cosine > maxCosine) {
        isPan = 1;
      }
      else if (cosine < -maxCosine) {
        isPan = -1;
      }
      else {
        isPan = 0;
      }
      dirty = false;
      return true;
    },
    isGesture() {
      return isPan !== 0;
    },
    getDirection() {
      return isPan;
    },
  };
};

// TODO(FW-2832): types
const createGesture = (config) => {
  let hasCapturedPan = false;
  let hasStartedPan = false;
  let hasFiredStart = true;
  let isMoveQueued = false;
  const finalConfig = Object.assign({ disableScroll: false, direction: 'x', gesturePriority: 0, passive: true, maxAngle: 40, threshold: 10 }, config);
  const canStart = finalConfig.canStart;
  const onWillStart = finalConfig.onWillStart;
  const onStart = finalConfig.onStart;
  const onEnd = finalConfig.onEnd;
  const notCaptured = finalConfig.notCaptured;
  const onMove = finalConfig.onMove;
  const threshold = finalConfig.threshold;
  const passive = finalConfig.passive;
  const blurOnStart = finalConfig.blurOnStart;
  const detail = {
    type: 'pan',
    startX: 0,
    startY: 0,
    startTime: 0,
    currentX: 0,
    currentY: 0,
    velocityX: 0,
    velocityY: 0,
    deltaX: 0,
    deltaY: 0,
    currentTime: 0,
    event: undefined,
    data: undefined,
  };
  const pan = createPanRecognizer(finalConfig.direction, finalConfig.threshold, finalConfig.maxAngle);
  const gesture = gestureController.GESTURE_CONTROLLER.createGesture({
    name: config.gestureName,
    priority: config.gesturePriority,
    disableScroll: config.disableScroll,
  });
  const pointerDown = (ev) => {
    const timeStamp = now(ev);
    if (hasStartedPan || !hasFiredStart) {
      return false;
    }
    updateDetail(ev, detail);
    detail.startX = detail.currentX;
    detail.startY = detail.currentY;
    detail.startTime = detail.currentTime = timeStamp;
    detail.velocityX = detail.velocityY = detail.deltaX = detail.deltaY = 0;
    detail.event = ev;
    // Check if gesture can start
    if (canStart && canStart(detail) === false) {
      return false;
    }
    // Release fallback
    gesture.release();
    // Start gesture
    if (!gesture.start()) {
      return false;
    }
    hasStartedPan = true;
    if (threshold === 0) {
      return tryToCapturePan();
    }
    pan.start(detail.startX, detail.startY);
    return true;
  };
  const pointerMove = (ev) => {
    // fast path, if gesture is currently captured
    // do minimum job to get user-land even dispatched
    if (hasCapturedPan) {
      if (!isMoveQueued && hasFiredStart) {
        isMoveQueued = true;
        calcGestureData(detail, ev);
        requestAnimationFrame(fireOnMove);
      }
      return;
    }
    // gesture is currently being detected
    calcGestureData(detail, ev);
    if (pan.detect(detail.currentX, detail.currentY)) {
      if (!pan.isGesture() || !tryToCapturePan()) {
        abortGesture();
      }
    }
  };
  const fireOnMove = () => {
    // Since fireOnMove is called inside a RAF, onEnd() might be called,
    // we must double check hasCapturedPan
    if (!hasCapturedPan) {
      return;
    }
    isMoveQueued = false;
    if (onMove) {
      onMove(detail);
    }
  };
  const tryToCapturePan = () => {
    if (!gesture.capture()) {
      return false;
    }
    hasCapturedPan = true;
    hasFiredStart = false;
    // reset start position since the real user-land event starts here
    // If the pan detector threshold is big, not resetting the start position
    // will cause a jump in the animation equal to the detector threshold.
    // the array of positions used to calculate the gesture velocity does not
    // need to be cleaned, more points in the positions array always results in a
    // more accurate value of the velocity.
    detail.startX = detail.currentX;
    detail.startY = detail.currentY;
    detail.startTime = detail.currentTime;
    if (onWillStart) {
      onWillStart(detail).then(fireOnStart);
    }
    else {
      fireOnStart();
    }
    return true;
  };
  const blurActiveElement = () => {
    if (typeof document !== 'undefined') {
      const activeElement = document.activeElement;
      if (activeElement === null || activeElement === void 0 ? void 0 : activeElement.blur) {
        activeElement.blur();
      }
    }
  };
  const fireOnStart = () => {
    if (blurOnStart) {
      blurActiveElement();
    }
    if (onStart) {
      onStart(detail);
    }
    hasFiredStart = true;
  };
  const reset = () => {
    hasCapturedPan = false;
    hasStartedPan = false;
    isMoveQueued = false;
    hasFiredStart = true;
    gesture.release();
  };
  // END *************************
  const pointerUp = (ev) => {
    const tmpHasCaptured = hasCapturedPan;
    const tmpHasFiredStart = hasFiredStart;
    reset();
    if (!tmpHasFiredStart) {
      return;
    }
    calcGestureData(detail, ev);
    // Try to capture press
    if (tmpHasCaptured) {
      if (onEnd) {
        onEnd(detail);
      }
      return;
    }
    // Not captured any event
    if (notCaptured) {
      notCaptured(detail);
    }
  };
  const pointerEvents = createPointerEvents(finalConfig.el, pointerDown, pointerMove, pointerUp, {
    capture: false,
    passive,
  });
  const abortGesture = () => {
    reset();
    pointerEvents.stop();
    if (notCaptured) {
      notCaptured(detail);
    }
  };
  return {
    enable(enable = true) {
      if (!enable) {
        if (hasCapturedPan) {
          pointerUp(undefined);
        }
        reset();
      }
      pointerEvents.enable(enable);
    },
    destroy() {
      gesture.destroy();
      pointerEvents.destroy();
    },
  };
};
const calcGestureData = (detail, ev) => {
  if (!ev) {
    return;
  }
  const prevX = detail.currentX;
  const prevY = detail.currentY;
  const prevT = detail.currentTime;
  updateDetail(ev, detail);
  const currentX = detail.currentX;
  const currentY = detail.currentY;
  const timestamp = (detail.currentTime = now(ev));
  const timeDelta = timestamp - prevT;
  if (timeDelta > 0 && timeDelta < 100) {
    const velocityX = (currentX - prevX) / timeDelta;
    const velocityY = (currentY - prevY) / timeDelta;
    detail.velocityX = velocityX * 0.7 + detail.velocityX * 0.3;
    detail.velocityY = velocityY * 0.7 + detail.velocityY * 0.3;
  }
  detail.deltaX = currentX - detail.startX;
  detail.deltaY = currentY - detail.startY;
  detail.event = ev;
};
const updateDetail = (ev, detail) => {
  // get X coordinates for either a mouse click
  // or a touch depending on the given event
  let x = 0;
  let y = 0;
  if (ev) {
    const changedTouches = ev.changedTouches;
    if (changedTouches && changedTouches.length > 0) {
      const touch = changedTouches[0];
      x = touch.clientX;
      y = touch.clientY;
    }
    else if (ev.pageX !== undefined) {
      x = ev.pageX;
      y = ev.pageY;
    }
  }
  detail.currentX = x;
  detail.currentY = y;
};
const now = (ev) => {
  return ev.timeStamp || Date.now();
};

exports.GESTURE_CONTROLLER = gestureController.GESTURE_CONTROLLER;
exports.createGesture = createGesture;
