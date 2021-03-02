local util = import './util.libsonnet';

local schemaField = '__schema__';

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

local errMsgWithPath = function(errMsg, path='$') (
  if errMsg == '' then ''
  else if std.startsWith(errMsg, '`$') then errMsg
  else '`%s` %s' % [path, errMsg]
);

local validators = {
  local this = self,

  assertSchemaInteger(value, schema={}, path='$'):: (
    if std.type(value) != 'number' || std.length(std.split(std.toString(value), '.')) != 1 then
      'should be integer value'
    else
      ''
  ),

  assertSchemaConst(value, schema={}, path='$'):: (
    if schema.const != value then
      'should be const `%s`' % [schema.const]
    else
      ''
  ),

  assertSchemaEnum(value, schema={}, path='$'):: (
    if !std.member(schema.enum, value) then
      'should be one value of %s' % [schema.enum]
    else
      ''
  ),

  assertSchemaFieldValue(fieldValue, field, objectSchema={}, objectPath='$'):: (
    local propSchemaOrErr = (
      if std.objectHasAll(objectSchema, 'properties') then
        if std.objectHasAll(objectSchema.properties, field) then
          objectSchema.properties[field] { '$parent': objectSchema }
        else
          if !std.objectHasAll(objectSchema, 'additionalProperties') then
            errMsgWithPath('has additional field `%s` not needed' % [field], objectPath)
          else
            getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
      else
        getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
    );

    if std.isString(propSchemaOrErr) then
      propSchemaOrErr
    else
      this.assertSchema(
        fieldValue,
        propSchemaOrErr,
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
          concatErrMsg(errMsgs, errMsgWithPath('missing required field `%s`' % [field], path))
        else
          concatErrMsg(
            errMsgs,
            errMsgWithPath(
              this.assertSchemaFieldValue(
                value[field],
                field,
                schema,
                path,
              ),
              '%s.%s' % [path, field],
            )
          )
      ), allFields, '')
    )
  ,

  assertSchemaArray(value, schema={}, path='$'):: (
    if std.isArray(schema.items) then
      if std.length(schema.items) != std.length(value) && !std.objectHasAll(schema, 'additionalItems') then
        'should be a tuple with %s values' % [std.length(schema.items)]
      else
        util.foldlWithIndex(
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
              ),
            ),
          value,
          ''
        )
    else
      util.foldlWithIndex(
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
    errMsgWithPath(
      (
        if this.isObjectWithSchema(value) && !std.objectHasAll(schema, '$parent') then
          this.assertSchema(value, value[schemaField] { '$parent': '-' }, path)
        else if std.length(schema) == 0 then
          this.assertSchema(value, { type: std.type(value) }, path)
        else if std.objectHasAll(schema, 'oneOf') then
          this.assertSchemaOneOf(value, schema, path)
        else if schema.type == 'integer' then
          this.assertSchemaInteger(value, schema, path)
        else if schema.type != std.type(value) then
          'should be %s value' % [schema.type]
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
      path,
    )
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
