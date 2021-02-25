local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      name: { type: 'string' },
      age: { type: 'number' },
    },
    required: ['name'],
  },
};

Meta {
  age: 12,
}
