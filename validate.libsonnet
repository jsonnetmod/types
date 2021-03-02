local schemaField = '__schema__';

local additionalSchema = function(schema, key, defaultSchema) (
  if std.objectHasAll(schema, key) && std.isObject(schema[key]) then
    schema[key] { '$parent': schema }
  else
    defaultSchema
);

local validators = {
  local this = self,

  validateConst(value, schema={}, path='$'):: (
    if schema.const != value then
      error error '`%s` should be const %s, but got `%s`' % [path, schema.const, value]
    else
      value
  ),

  validateEnum(value, schema={}, path='$'):: (
    if !std.member(schema.enum, value) then
      error error '`%s` should be one value of %s, but got `%s`' % [path, schema.enum, value]
    else
      value
  ),

  validateFieldValue(fieldValue, field, objectSchema={}, objectPath='$'):: (
    local propSchema = (
      if std.objectHasAll(objectSchema, 'properties') then
        if std.objectHasAll(objectSchema.properties, field) then
          objectSchema.properties[field] { '$parent': objectSchema }
        else
          if !std.objectHasAll(objectSchema, 'additionalProperties') then
            error '`%s has invalid field `%s`' % [objectPath, field]
          else
            additionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
      else
        additionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
    );

    this.validate(
      fieldValue,
      propSchema,
      '%s.%s' % [objectPath, field]
    )
  ),

  validateObject(value, schema={}, path='$')::
    (
      local fieldSet = (
        {
          [field]: true
          for field in std.objectFields(value)
        }
        +
        {
          [requiredField]: true
          for requiredField in if std.objectHasAll(schema, 'required') then schema.required else []
        }
      );

      local fields = std.objectFields(fieldSet);

      value
      {
        __hidden_fields__::: {
          [field]: this.validateFieldValue(value[field], field, schema, path)
          for field in std.objectFieldsAll(value)
          if field != schemaField && !std.member(fields, field)
        },
      }
      +
      {
        [field]: this.validateFieldValue(
          (
            if !std.objectHas(value, field) then
              error '`%s` missing required field `%s`' % [path, field]
            else
              value[field]
          ),
          field,
          schema,
          path,
        )
        for field in fields
        if field != schemaField
      }
    )
  ,

  validateArray(value, schema={}, path='$'):: (
    if std.isArray(schema.items) then
      if std.length(schema.items) != std.length(value) && !std.objectHasAll(schema, 'additionalItems') then
        error '`%s` should be a tuple type with size %s, but got size `%s`' % [path, std.length(schema.items), std.length(value)]
      else
        std.mapWithIndex(
          function(idx, itemValue)
            this.validate(
              itemValue,
              if idx < std.length(schema.items) then
                schema.items[idx] { '$parent': schema }
              else
                additionalSchema(schema, 'additionalItems', { type: std.type(itemValue) }),
              '%s[%s]' % [path, idx],
            ),
          value
        )
    else
      std.mapWithIndex(
        function(idx, itemValue)
          this.validate(
            itemValue,
            schema.items { '$parent': schema },
            '%s[%s]' % [path, idx],
          ), value
      )
  ),

  isObjectWithSchema(value):: std.isObject(value) && std.objectHasAll(value, schemaField),

  validate(value, schema={}, path='$')::
    if this.isObjectWithSchema(value) && !std.objectHasAll(schema, '$parent') then
      this.validate(value, value[schemaField] { '$parent': '-' }, path)
    else if !std.objectHasAll(schema, 'type') then
      this.validate(value, { type: std.type(value) }, path)
    else if schema.type != std.type(value) then
      error '`%s` should be %s value, but got %s value' % [path, schema.type, std.type(value)]
    else if std.objectHasAll(schema, 'const') then
      this.validateConst(value, schema, path)
    else if std.objectHasAll(schema, 'enum') then
      this.validateEnum(value, schema, path)
    else if schema.type == 'object' then
      this.validateObject(value, schema, path)
    else if schema.type == 'array' then
      this.validateArray(value, schema, path)
    else
      value,
};

{
  schemaField: schemaField,
  validate: validators.validate,
}
