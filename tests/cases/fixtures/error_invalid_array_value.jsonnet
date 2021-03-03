local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      array: { type: 'array', items: { type: 'number' } },
    },
  },
};

Meta {
  array: ['s', 1],
}
