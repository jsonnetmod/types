local Meta = {
  a: {
    b:: {
      c: {
        __schema__:: {
          type: 'object',
          properties: {
            d: { type: 'string' },
          },
        },
        d: 'string',
      },
    },
  },
};

Meta {
  a+: {
    b+:: {
      c+: {
        d: 1,
      },
    },
  },
}
