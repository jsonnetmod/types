local refutil = import '../refutil.libsonnet';


{
  pathJoin: {
    join():: {
      expect: 'http://localhost:1234/baseUriChangeFolder/folderInteger.json',
      actual: refutil.pathJoin('http://localhost:1234/baseUriChangeFolder/', 'folderInteger.json'),
    },
  },
  resolveIDs: {
    tree():: {
      local s = {
        '$id': 'http://localhost:1234/tree',
        description: 'tree of nodes',
        type: 'object',
        properties: {
          meta: { type: 'string' },
          nodes: {
            type: 'array',
            items: { '$ref': 'node' },
          },
        },
        required: ['meta', 'nodes'],
        definitions: {
          node: {
            '$id': 'http://localhost:1234/node',
            description: 'node',
            type: 'object',
            properties: {
              value: { type: 'number' },
              subtree: { '$ref': 'tree' },
            },
            required: ['value'],
          },
        },
      },
      expect: {
        'http://localhost:1234/node': s.definitions.node,
        'http://localhost:1234/tree': s,
      },
      actual: refutil.resolveIDs(s),
    },

    nested():: {
      local s = {
        '$id': 'http://localhost:1234/root',
        allOf: [{
          '$ref': 'http://localhost:1234/nested.json#foo',
        }],
        definitions: {
          A: {
            '$id': 'nested.json',
            definitions: {
              B: {
                '$id': '#foo',
                type: 'integer',
              },
            },
          },
        },
      },

      expect: {
        'http://localhost:1234/nested.json': s.definitions.A { '$id': 'http://localhost:1234/nested.json' },
        'http://localhost:1234/nested.json#foo': s.definitions.A.definitions.B { '$id': 'http://localhost:1234/nested.json#foo' },
        'http://localhost:1234/root': s,
      },
      actual: refutil.resolveIDs(s),
    },
  },

  '#resolveRef': {
    indep():: {
      local s = {
        allOf: [{
          '$ref': '#foo',
        }],
        definitions: {
          A: {
            '$id': '#foo',
            type: 'integer',
          },
        },
      },
      expect: 'integer',
      actual: refutil.resolveRef({ '$ref': '#foo' }, s).schema.type,
    },

    scope_change_defs1():: {
      local s = {
        '$id': 'http://localhost:1234/scope_change_defs1.json',
        type: 'object',
        properties: {
          list: { '$ref': '#/definitions/baz/items' },
        },
        definitions: {
          baz: {
            '$id': 'baseUriChangeFolder/',
            type: 'array',
            items: { '$ref': 'folderInteger.json' },
          },
        },
      },

      expect: 'integer',
      actual: refutil.resolveRef(s.properties.list, s).schema.type,
    },

    scope_change_defs2():: {
      local s = {
        '$id': 'http://localhost:1234/scope_change_defs2.json',
        type: 'object',
        properties: {
          list: { '$ref': '#/definitions/baz/definitions/bar/items' },
        },
        definitions: {
          baz: {
            '$id': 'baseUriChangeFolderInSubschema/',
            definitions: {
              bar: {
                type: 'array',
                items: { '$ref': 'folderInteger.json' },
              },
            },
          },
        },
      },

      expect: 'integer',
      actual: refutil.resolveRef(s.properties.list, s).schema.type,
    },
  },
}
