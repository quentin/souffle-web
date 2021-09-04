
CodeMirror.defineSimpleMode("souffle", {
  start: [
    // string
    {regex: /"[^\"]+"/, token: "string" },
    // declaration
    {regex: /\.(?:decl)\b/, token: "keyword", next: "atom"},
    // output
    {regex: /\.(?:output|input|functor|type|printsize|pragma|plan)\b/, token:"keyword"},
    // comment block
    {regex: /\/\*/, token: "comment", next: "comment"},
    //
    {regex: /#\w+/, token: "meta"},
    // number
    {regex: /[0-9]+/, token:"number"},
    // types
    {regex: /(?:symbol|number|unsigned|float)\b/, token:"type"},
    // identifier
    {regex: /([a-zA-Z_?][a-zA-Z0-9]*)/, token:"variable"},
    // :-
    {regex: /:\-/, token: "keyword"},
    // operator
    {regex: /[+\-*=<>!\/:%]/, token:"operator"}
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
  ],

  meta : {
    lineComment: "//"
  }
});
