local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      labels: { type: 'object', additionalProperties: { type: 'string' } },
    },
  },
};

Meta {
  labels: {
    v: 1,
  },
}
