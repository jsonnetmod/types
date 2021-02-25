local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      array: {
        type: 'array',
        items: [
          { type: 'string' },
          { type: 'number' },
        ],
      },
    },
  },
};

Meta {
  array: [1, 1],
}
