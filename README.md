# Types

ALPHA VERSION, APIs may changes.

A [jsonnet](https://jsonnet.org/) validation follow [json schema](https://json-schema.org/) .

## Rule

When hidden field `__schema__` with json schema exists, will validate the object

```jsonnet
local t = import 'github.com/jsonnetmod/types/t.libsonnet';

local Meta = {
  __schema__:: {
    type: 'object',
    properties: {
      name: { type: 'string' },
      age: { type: 'string' },
    },
    required: ['name']
  },
};

// or with build helper
local Meta = t.objectOf({
  name: t.string(),
  age:: t.number(), // hidden means not required
});

t.validate(Meta {
  name: 1,  // should throw error like `$.name` should be a string value
  age: 18,
})
```

## JSON-Schema-Test-Suite Covers 

* [x] draft7
* [x] draft6
* [ ] draft4
* [ ] draft3


## Known Issues

* `$ref` with remote url need native functions:
    * `fetch(url): string` to fetch remote json schema raw data
    * `parseJson(json data): {} | []` to parse json schema from raw data

* `pattern` && `patternProperties` native function:
    * `regexMatch(regex, str: string): bool` in custom jsonnet vm