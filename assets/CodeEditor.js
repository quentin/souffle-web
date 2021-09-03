
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
      mode: 'souffle',
      lineNumbers: true,
      value: this._editorValue
    });

    this._editor.on('changes', () => {
      this._editorValue = this._editor.getValue();
      this.dispatchEvent(new CustomEvent('editorChanged'));
    });
  }
})
