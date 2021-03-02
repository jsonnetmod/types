local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      type: { type: 'string', enum: ['A', 'B'] },
    },
  },
};

Meta {
  type: 'C',
}
