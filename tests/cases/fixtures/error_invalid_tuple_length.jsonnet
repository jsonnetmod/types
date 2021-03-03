local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      tuple: {
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
  tuple: [1, 1, 'x'],
}
