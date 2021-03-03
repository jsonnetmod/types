{
  local this = self,

  fieldSchema:: '__schema__',

  normalizeSchema(schemaOrSchemaType):: (
    assert std.isObject(schemaOrSchemaType) : 'normalizeSchema first parameter should be object, got <%s> %s' % [std.type(schemaOrSchemaType), schemaOrSchemaType];

    if std.objectHasAll(schemaOrSchemaType, this.fieldSchema) then
      this.normalizeSchema(schemaOrSchemaType[this.fieldSchema])
    else if std.objectHasAll(schemaOrSchemaType, 'type') then
      schemaOrSchemaType
    else
      {}
  ),

  isRequiredField(field, schema):: (
    std.isObject(schema) && std.objectHasAll(schema, 'required') && std.member(schema.required, field)
  ),

  getDefaultsFromSchema(schema):: (
    assert std.isObject(schema) : 'getDefaultsFromSchema first parameter should be object, got <%s> %s' % [std.type(schema), schema];

    if std.objectHasAll(schema, 'properties') then
      std.foldl(
        function(defaults, field) (
          local propDefault = this.getDefaultsFromSchema(schema.properties[field]);
          if propDefault == null then
            defaults
          else
            if std.isObject(propDefault) && std.length(propDefault) == 0 && this.isRequiredField(field, schema) then
              defaults
            else defaults { [field]: propDefault }
        ),
        std.objectFieldsAll(schema.properties),
        {},
      )
    else if std.objectHasAll(schema, 'default') then schema.default
    else null
  ),

  fromSchema(schema):: (
    ({ [this.fieldSchema]:: schema })
    + (
      local defaults = this.getDefaultsFromSchema(schema);
      if std.isObject(defaults) then defaults
      else {}
    )
  ),

  any():: this.fromSchema({}),

  const(c):: this.fromSchema({
    type: std.type(c),
    const: c,
    default: c,
  }),

  enum(values):: (
    assert std.isArray(values) : 'enum first parameter should be a array, got %s' % [std.type(values)];
    assert std.length(values) : 'enum first parameter should at least one value, got %s' % [std.lenght(values)];

    this.fromSchema({
      type: std.type(values[0]),
      enum: values,
      default: values[0],
    })
  ),

  string():: this.fromSchema({ type: 'string' }),

  number():: this.fromSchema({ type: 'number' }),

  integer():: this.fromSchema({ type: 'integer' }),

  boolean():: this.fromSchema({ type: 'boolean' }),

  tupleOf(itemSchemas):: this.fromSchema(
    if !std.isArray(itemSchemas) then
      error 'tupleOf(itemSchemas), itemSchemas must be an array'
    else
      { type: 'array', items: std.map(function(itemSchema) this.normalizeSchema(itemSchema), itemSchemas) }
  ),

  oneOf(schemas):: this.fromSchema(
    assert std.isArray(schemas) : 'oneOf first parameter should be a array, got %s' % [std.type(schemas)];
    { oneOf: std.map(function(s) this.normalizeSchema(s), schemas) }
  ),

  arrayOf(itemSchema):: this.fromSchema({
    type: 'array',
    items: this.normalizeSchema(itemSchema),
  }),

  objectOf(properties, additionalSchema=false):: this.fromSchema(
    (
      {
        type: 'object',
        properties: {
          [name]: this.normalizeSchema(properties[name])
          for name in std.objectFieldsAll(properties)
        },
        required: std.objectFields(properties),
      }
    )
    +
    (
      if additionalSchema then { additionalProperties: this.normalizeSchema(additionalSchema) }
      else {}
    ),
  ),

  mapOf(valueSchema, propertyNames=this.string()):: this.fromSchema({
    type: 'object',
    additionalProperties: this.normalizeSchema(valueSchema),
    propertyNames: this.normalizeSchema(propertyNames),
  }),
}
