class Tools {
  static getKeyCode(event) {
    return event && (event.code || event.key || event.keyCode || event.detail && (event.detail.code || event.detail.key || event.detail.keyCode));
  }

  static preventDefault(event) {
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }
  }

  static normalizeSlideKey(code) {
    const slideMap = {
      ArrowDown: 'forward',
      Down: 'forward',
      40: 'forward',
      ArrowUp: 'backward',
      Up: 'backward',
      38: 'backward'
    };

    return slideMap[code] || '';
  }

  static getSlideEvent(event) {
    const code = Tools.getKeyCode(event);

    return {
      code,
      slide: Tools.normalizeSlideKey(code)
    };
  }
}

export default Tools;
