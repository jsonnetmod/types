local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      some: {
        oneOf: [
          { type: 'integer' },
          { type: 'string' },
        ],
      },
    },
  },
};

Meta {
  some: 1.1,
}
