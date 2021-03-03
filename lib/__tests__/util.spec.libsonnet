local util = import '../util.libsonnet';


{
  '#get()': {
    local o = { a: { b: { c: 1 } } },
    gotValue():: {
      expect: 1,
      actual: util.get(o, ['a', 'b', 'c']),
    },
    gotObject():: {
      expect: { c: 1 },
      actual: util.get(o, ['a', 'b']),
    },
    gotNull():: {
      expect: null,
      actual: util.get(o, ['a', 'b', 'd']),
    },
  },

  '#countChar()': {
    simpleString():: {
      expect: 5,
      actual: util.countChar('hello'),
    },
    emoji():: {
      expect: 2,
      actual: util.countChar('💩💩'),
    },
    zwjEmoji():: {
      expect: 1,
      actual: util.countChar('👩‍❤️‍💋‍👩'),
    },
    zero():: {
      expect: 0,
      actual: util.countChar('︀️'),
    },
  },
  '#regexMatch()': {
    case_0(): {
      actual: util.regexMatch('h(?P<mid>.*)o', 'hello'),
      expect: true,
    },
    case_1(): {
      actual: util.regexMatch('f.o', 'fxo'),
      expect: true,
    },
  },
  '#type()': {
    integer():: {
      actual: util.type(1),
      expect: 'integer',
    },
    number():: {
      actual: util.type(1.01),
      expect: 'number',
    },
    'null'():: {
      actual: util.type(null),
      expect: 'null',
    },
    boolean():: {
      actual: util.type(true),
      expect: 'boolean',
    },
    object():: {
      actual: util.type({}),
      expect: 'object',
    },
    array():: {
      actual: util.type([]),
      expect: 'array',
    },
    string():: {
      actual: util.type(''),
      expect: 'string',
    },
  },
}
