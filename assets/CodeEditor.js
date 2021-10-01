
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
    this._editorValue = "-- If you see this, the Elm code didn't set the value."
  }

  get editorValue() {
    return this._editorValue
  }

  set editorValue(value) {
    if (this._editorValue === value) return;
    this._editorValue = value;
    if (!this._editor) return;
    this._editor.setValue(value);
  }

  connectedCallback() {
    this._editor = CodeMirror(this, {
      indentUnit: 4,
      indentWidth: 4,
      tabSize: 4,
      indentWithTabs: false,
      mode: 'souffle',
      lineNumbers: true,
      theme: 'solarized dark',
      value: this._editorValue
    });

    const runDispatch = debounce(() => {
      this._editorValue = this._editor.getValue();
      this.dispatchEvent(new CustomEvent('editorChanged'));
    });

    this._editor.on('changes', runDispatch);
  }
})
