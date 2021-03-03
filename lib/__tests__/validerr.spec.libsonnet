local ValidErr = import '../validerr.libsonnet';

local err0 = ValidErr.new('err0', { value: '', path: '$' });
local err1 = ValidErr.new('err1', { value: '', path: '$' });

{
  '#oneOf()': {
    'should invalid':: {
      'when two rules valid'():: {
        expect: err0,
        actual: ValidErr.oneOf({
          _0():: err0,
          _1():: null,
          _2():: null,
        }),
      },
    },
    'should valid':: {
      'when empty rules'():: {
        expect: null,
        actual: ValidErr.oneOf({}),
      },
      'when one rule valid'():: {
        expect: null,
        actual: ValidErr.oneOf({
          _0():: err0,
          _1():: null,
          _2():: err1,
        }),
      },
    },
  },
  '#anyOf()': {
    'should invalid when all rule invalid'():: {
      expect: ValidErr.merge(err0, err1),
      actual: ValidErr.anyOf({
        _0():: err0,
        _1():: err1,
      }),
    },
    'should valid':: {
      'when empty rules'():: {
        expect: null,
        actual: ValidErr.anyOf({}),
      },
      'when one rule valid'():: {
        expect: null,
        actual: ValidErr.anyOf({
          _0():: err0,
          _1():: null,
          _2():: err1,
        }),
      },
      'when two rule invalid'():: {
        expect: null,
        actual: ValidErr.anyOf({
          _0():: null,
          _1():: err0,
          _2():: null,
        }),
      },
      'when all null'():: {
        expect: null,
        actual: ValidErr.anyOf({
          _0():: null,
          _1():: null,
          _2():: null,
        }),
      },
    },
  },

  '#allOf()': {
    'should valid when all valid'():: {
      expect: null,
      actual: ValidErr.allOf({
        _0():: null,
        _1():: null,
        _2():: null,
      }),
    },
    'should invalid when secound invalid'():: {
      expect: err1,
      actual: ValidErr.allOf({
        _0():: null,
        _2():: err1,
        _1():: null,
      }),
    },
    'should invalid with all errors when partial invalid'():: {
      expect: ValidErr.merge(err0, err1),
      actual: ValidErr.allOf({
        _0():: null,
        _1():: err0,
        _2():: err1,
      }),
    },
  },
}
