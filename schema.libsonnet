local v = import './validate.libsonnet';

local getDefaultsFromSchema = function(schema) (
  if std.objectHasAll(schema, 'properties') then (
    {
      [name]: schema.properties[name].default
      for name in std.objectFieldsAll(schema.properties)
      if std.objectHasAll(schema.properties[name], 'default')
    }
    +
    {
      [name]: getDefaultsFromSchema(schema.properties[name])
      for name in std.objectFieldsAll(schema.properties)
      if std.objectHasAll(schema.properties[name], 'type') && schema.properties[name].type == 'object'
    }
  )
  else {}
);

local normalizeSchema = function(schemaOrSchemaType) (
  if std.objectHasAll(schemaOrSchemaType, v.schemaField) then
    normalizeSchema(schemaOrSchemaType[v.schemaField])
  else if !std.isObject(schemaOrSchemaType) then
    error 'schema must be an object type'
  else if !std.objectHasAll(schemaOrSchemaType, 'type') then
    error 'schema must have field `type`'
  else
    schemaOrSchemaType
);

local typeOf = function(schema) { [v.schemaField]:: schema } + getDefaultsFromSchema(schema);


{
  local this = self,

  typeOf:: typeOf,

  any():: {},

  const(c):: typeOf({
    type: std.type(c),
    const: c,
    default: c,
  }),

  enum(values):: (
    if !std.isArray(values) then
      error 'enum(values), values should be a arrry error'
    else if std.length(values) == 0 then
      error 'enum(values), values should contain at least one item'
    else
      typeOf({
        type: std.type(values[0]),
        enum: values,
        default: values[0],
      })
  ),

  string():: typeOf({ type: 'string' }),

  number():: typeOf({ type: 'number' }),

  integer():: typeOf({ type: 'integer' }),

  boolean():: typeOf({ type: 'boolean' }),

  tupleOf(itemSchemas):: typeOf(
    if !std.isArray(itemSchemas) then
      error 'tupleOf(itemSchemas), itemSchemas must be an array'
    else
      {
        type: 'array',
        items: std.map(function(itemSchema) normalizeSchema(itemSchema), itemSchemas),
      }
  ),

  oneOf(schemas):: typeOf(
    if !std.isArray(schemas) then
      error 'oneOf(schemas), schemas must be an array'
    else
      {
        oneOf: std.map(function(s) normalizeSchema(s), schemas),
      }
  ),

  arrayOf(itemSchema):: typeOf({
    type: 'array',
    items: normalizeSchema(itemSchema),
  }),


  objectOf(properties, additionalSchema=false):: typeOf({
    type: 'object',
    properties: {
      [name]: normalizeSchema(properties[name])
      for name in std.objectFieldsAll(properties)
    },
    required: std.objectFields(properties),
  } + (
    if (std.isObject(additionalSchema)) then
      normalizeSchema(additionalSchema)
    else
      if additionalSchema then
        { additionalProperties: additionalSchema }
      else
        {}
  )),

  mapOf(valueSchema, propertyNames=this.string()):: typeOf({
    type: 'object',
    additionalProperties: normalizeSchema(valueSchema),
    propertyNames: normalizeSchema(propertyNames),
  }),
}
