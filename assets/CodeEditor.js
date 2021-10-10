
const debounce = func => {
  let token;
  return function() {
    const later = () => {
      token = null;
      func.apply(null, arguments);
    };
    cancelIdleCallback(token);
    token = requestIdleCallback(later);
  };
};

customElements.define('code-editor', class extends HTMLElement {
  constructor() {
    super();
    this._value = this.editorValue || "";
    delete this.editorValue;
  }

  get editorValue() {
    return this._value
  }

  set editorValue(value) {
    if (value === null || this._value === value) return;
    this._value = value;
    if (!this._editor) return;
    this._editor.setValue(value);
  }

  connectedCallback() {
    if (this._editor) return;
    this._editor = CodeMirror(this, {
      lineNumbers: true,
      indentWithTabs: false,
      indentUnit: 4,
      indentWidth: 4,
      tabSize: 4,
      mode: 'souffle',
      theme: 'solarized dark',
      value: this._value
    });

    const runDispatch = debounce(() => {
      this._value = this._editor.getValue();
      const event = new Event("change")
      this.dispatchEvent(event);
    });

    this._editor.on('changes', runDispatch);

    requestAnimationFrame(() => {
      this._editor.refresh();
    });
  }
})
