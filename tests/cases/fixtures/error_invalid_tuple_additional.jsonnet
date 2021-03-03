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
        additionalItems: {
          type: 'number',
        },
      },
    },
  },
};

Meta {
  tuple: ['s', 1, 'x'],
}
