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
        additionalItems: {
          type: 'number',
        },
      },
    },
  },
};

Meta {
  array: ['s', 1, 'x'],
}
