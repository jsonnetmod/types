local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      type: { type: 'string', const: 'A' },
    },
  },
};

Meta {
  labels: {
    type: 'C',
  },
}