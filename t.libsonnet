local schemaField = '__schema__';

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

local mayUseSchemaFromField = function(value, schema) (
  if std.isObject(value) && std.objectHasAll(value, schemaField) then
    value[schemaField]
  else
    schema
);


local additionalSchema = function(schema, key, defaultSchema) (
  if std.objectHasAll(schema, key) && std.isObject(schema[key]) then
    schema[key]
  else
    defaultSchema
);


local walkAndCheck = function(value, schema, path='$') (
  if schema.type != std.type(value) then
    error '`%s` should be %s value, but got %s value' % [path, schema.type, std.type(value)]
  else if schema.type == 'object' then (
    local walkField = function(fieldValue, field) (
      walkAndCheck(
        fieldValue,
        mayUseSchemaFromField(
          fieldValue,
          if std.objectHasAll(schema, 'properties') then
            if std.objectHasAll(schema.properties, field) then
              schema.properties[field]
            else
              if !std.objectHasAll(schema, 'additionalProperties') then
                error '`%s has invalid field `%s`' % [path, field]
              else
                additionalSchema(schema, 'additionalProperties', { type: std.type(fieldValue) })
          else
            additionalSchema(schema, 'additionalProperties', { type: std.type(fieldValue) }),
        ),
        '%s.%s' % [path, field]
      )
    );

    (
      if std.objectHasAll(schema, 'required') then
        {
          [field]: (
            if !std.objectHas(value, field) then
              error '`%s` missing required field `%s`' % [path, field]
            else
              walkField(value[field], field)
          )
          for field in schema.required
        }
      else
        {}
    )
    +
    ({
       [field]: walkField(value[field], field)
       for field in std.objectFields(value)
       if field != schemaField
     })
  )
  else if schema.type == 'array' then
    if std.isArray(schema.items) then
      if std.length(schema.items) != std.length(value) && !std.objectHasAll(schema, 'additionalItems') then
        error '`%s` should be a tuple type with size %s, but got size `%s`' % [path, std.length(schema.items), std.length(value)]
      else
        std.mapWithIndex(
          function(idx, itemValue)
            walkAndCheck(itemValue,
                         mayUseSchemaFromField(
                           itemValue,
                           if idx < std.length(schema.items) then
                             schema.items[idx]
                           else
                             additionalSchema(schema, 'additionalItems', { type: std.type(itemValue) })
                         ),
                         '%s[%s]' % [path, idx]),
          value
        )
    else
      std.mapWithIndex(function(idx, itemValue) walkAndCheck(itemValue, mayUseSchemaFromField(itemValue, schema.items), '%s[%s]' % [path, idx]), value)
  else if std.objectHasAll(schema, 'enum') then
    if !std.member(schema.enum, value) then
      error error '`%s` should be one value of %s, but got `%s`' % [path, schema.enum, value]
    else
      value
  else
    value
);

local validate = function(value) (
  if !std.isObject(value) then
    error 'validate only support object value'
  else
    if std.objectHasAll(value, schemaField) then
      walkAndCheck(value, value[schemaField])
    else
      walkAndCheck(value, { type: 'object' })
);

local normalizeSchema = function(schemaOrSchemaType) (
  if std.objectHasAll(schemaOrSchemaType, schemaField) then
    normalizeSchema(schemaOrSchemaType[schemaField])
  else if !std.isObject(schemaOrSchemaType) then
    error 'schema must be an object type'
  else if !std.objectHasAll(schemaOrSchemaType, 'type') then
    error 'schema must have field `type`'
  else
    schemaOrSchemaType
);

local typeOf = function(schema) { [schemaField]: schema } + getDefaultsFromSchema(schema);

{
  local this = self,

  validate:: validate,

  typeOf:: typeOf,

  const(c):: typeOf({
    type: std.type(c),
    const: c,
    default: c,
  }),

  enum(values):: typeOf({
    type: std.type(values[0]),
    enum: values,
    default: values[0],
  }),

  string():: typeOf({ type: 'string' }),

  number():: typeOf({ type: 'number' }),

  boolean():: typeOf({ type: 'boolean' }),

  tupleOf(itemSchemas):: typeOf(
    if !std.isArray(itemSchemas) then
      error 'itemSchemas must be an array'
    else
      {
        type: 'array',
        items: std.map(function(itemSchema) normalizeSchema(itemSchema), itemSchemas),
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
