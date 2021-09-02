
CodeMirror.defineSimpleMode("souffle", {
  start: [
    {regex: /"[^\"]+"/, token: "string" },
    {regex: /\.(?:decl)\b/, token: "keyword", next: "atom"},
    {regex: /\.(?:output)\b/, token:"keyword"},
    {regex: /\/\*/, token: "comment", next: "comment"},
    {regex: /\/\/.*/, token: "comment"},
    {regex: /[0-9]+/, token:"number"}
  ],

  atom: [
    {regex: /([a-zA-Z_?][a-zA-Z0-9]*)/,
      token: "variable-2"},
    {regex: /\(/, next: "args"}
  ],

  args: [
    {regex: /(?:number|symbol|unsigned|float)\b/, token: "type"},
    {regex: /\)/, next: "start"}
  ],

  comment: [
    {regex: /.*?\*\//, token: "comment", next: "start"},
    {regex: /.*/, token: "comment"}
  ]
});
