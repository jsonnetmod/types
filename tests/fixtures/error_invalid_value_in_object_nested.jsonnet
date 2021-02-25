local Meta = {
  a: {
    b: {
      c: {
        __schema__:: {
          type: 'object',
          properties: {
            d: { type: 'string' },
          },
        },
      },
    },
  },
};

Meta {
  a+: {
    b+: {
      c+: {
        d: 1,
      },
    },
  },
}
