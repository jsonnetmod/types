local schemaField = '__schema__';

local foldlWithIndex = function(func, arr, init) (
  local aux(func, arr, running, idx) =
    if idx >= std.length(arr) then
      running
    else
      aux(func, arr, func(running, arr[idx], idx), idx + 1) tailstrict;
  aux(func, arr, init, 0)
);

local getAdditionalSchema = function(schema, key, defaultSchema) (
  if std.objectHasAll(schema, key) && std.isObject(schema[key]) then
    schema[key] { '$parent': schema }
  else
    defaultSchema
);

local concatErrMsg = function(prev, next, split='\n') (
  if prev != '' && next != '' then
    '%s%s%s' % [prev, split, next]
  else
    '%s%s' % [prev, next]
);

local validators = {
  local this = self,

  assertSchemaInteger(value, schema={}, path='$'):: (
    if std.type(value) != 'number' || std.length(std.split(std.toString(value), '.')) != 1 then
      '`%s` should be integer value, but got `%s`' % [path, value]
    else
      ''
  ),

  assertSchemaConst(value, schema={}, path='$'):: (
    if schema.const != value then
      '`%s` should be const %s, but got `%s`' % [path, schema.const, value]
    else
      ''
  ),

  assertSchemaEnum(value, schema={}, path='$'):: (
    if !std.member(schema.enum, value) then
      '`%s` should be one value of %s, but got `%s`' % [path, schema.enum, value]
    else
      ''
  ),

  assertSchemaFieldValue(fieldValue, field, objectSchema={}, objectPath='$'):: (
    local propSchema = (
      if std.objectHasAll(objectSchema, 'properties') then
        if std.objectHasAll(objectSchema.properties, field) then
          objectSchema.properties[field] { '$parent': objectSchema }
        else
          if !std.objectHasAll(objectSchema, 'additionalProperties') then
            error '`%s has invalid field `%s`' % [objectPath, field]
          else
            getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
      else
        getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
    );

    this.assertSchema(
      fieldValue,
      propSchema,
      '%s.%s' % [objectPath, field]
    )
  ),

  assertSchemaObject(value, schema={}, path='$')::
    (
      local fieldSet = (
        {
          [field]: true
          for field in std.objectFieldsAll(value)
          if field != schemaField
        }
        +
        {
          [requiredField]: true
          for requiredField in if std.objectHasAll(schema, 'required') then schema.required else []
        }
      );

      local allFields = std.objectFields(fieldSet);

      std.foldl(function(errMsgs, field) (
        if !std.objectHasAll(value, field) then
          concatErrMsg(errMsgs, '`%s` missing required field `%s`' % [path, field])
        else
          concatErrMsg(
            errMsgs,
            this.assertSchemaFieldValue(
              value[field],
              field,
              schema,
              path,
            )
          )
      ), allFields, '')
    )
  ,

  assertSchemaArray(value, schema={}, path='$'):: (
    if std.isArray(schema.items) then
      if std.length(schema.items) != std.length(value) && !std.objectHasAll(schema, 'additionalItems') then
        '`%s` should be a tuple type with size %s, but got size `%s`' % [path, std.length(schema.items), std.length(value)]
      else
        foldlWithIndex(
          function(errMsgs, itemValue, idx)
            concatErrMsg(
              errMsgs,
              this.assertSchema(
                itemValue,
                if idx < std.length(schema.items) then
                  schema.items[idx] { '$parent': schema }
                else
                  getAdditionalSchema(schema, 'additionalItems', { type: std.type(itemValue) }),
                '%s[%s]' % [path, idx],
              )
            ),
          value,
          ''
        )
    else
      foldlWithIndex(
        function(errMsgs, itemValue, idx)
          concatErrMsg(
            errMsgs,
            this.assertSchema(
              itemValue,
              schema.items { '$parent': schema },
              '%s[%s]' % [path, idx],
            )
          ),
        value,
        ''
      )
  ),

  assertSchemaOneOf(value, schema={}, path='$'):: (
    std.foldl(
      function(errMsgs, schema) (
        local errMsg = this.assertSchema(
          value,
          schema,
          path,
        );
        if errMsg == '' then ''
        else concatErrMsg(errMsgs, errMsg, ' or ')
      )
      ,
      schema.oneOf,
      ''
    )
  ),

  isObjectWithSchema(value):: std.isObject(value) && std.objectHasAll(value, schemaField),

  assertSchema(value, schema={}, path='$'):: (
    if this.isObjectWithSchema(value) && !std.objectHasAll(schema, '$parent') then
      this.assertSchema(value, value[schemaField] { '$parent': '-' }, path)
    else if std.length(schema) == 0 then
      this.assertSchema(value, { type: std.type(value) }, path)
    else if std.objectHasAll(schema, 'oneOf') then
      this.assertSchemaOneOf(value, schema, path)
    else if schema.type == 'integer' then
      this.assertSchemaInteger(value, schema, path)
    else if schema.type != std.type(value) then
      '`%s` should be %s value, but got %s value' % [path, schema.type, std.type(value)]
    else if std.objectHasAll(schema, 'const') then
      this.assertSchemaConst(value, schema, path)
    else if std.objectHasAll(schema, 'enum') then
      this.assertSchemaEnum(value, schema, path)
    else if schema.type == 'object' then
      this.assertSchemaObject(value, schema, path)
    else if schema.type == 'array' then
      this.assertSchemaArray(value, schema, path)
    else
      ''
  ),

  validate(value, schema={}, path='$'):: (
    local errMsg = this.assertSchema(value, schema, path);
    if errMsg != '' then
      error errMsg
    else
      value
  ),
};

{
  schemaField: schemaField,
  validate: validators.validate,
}
