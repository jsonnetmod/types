local util = import './util.libsonnet';

local ValidErr = {
  local this = self,
  local fieldValidErr = '__valid_err__',

  new(msg, value, path):: { [fieldValidErr]:: true, msg: msg, path: path, value: value },

  is(v):: std.isObject(v) && std.objectHasAll(v, fieldValidErr),

  merge(validErr, nextValidErr):: (
    if this.is(validErr) then
      validErr + (if this.is(nextValidErr) then { next: nextValidErr } else {})
    else
      nextValidErr
  ),

  format(validErr):: (
    assert this.is(validErr) : 'format first parameter should be ValidErr';

    if std.objectHas(validErr, 'next') then
      if validErr.path == validErr.next.path then
        this.format(this.new((validErr.msg + ' or ' + validErr.next.msg), validErr.value, validErr.path))
      else
        this.format(validErr) + '\n' + this.format(validErr.next)
    else
      '`%s` %s, got <%s> %s' % [validErr.path, validErr.msg, std.type(validErr.value), validErr.value]
  ),
};

{
  local this = self,

  fieldSchema: '__schema__',

  getAdditionalSchema(schema, key, defaultSchema):: (
    if std.objectHasAll(schema, key) && std.isObject(schema[key]) then
      schema[key] { '$parent': schema }
    else
      defaultSchema
  ),

  validateBySchemaEnum(value, schema={}, path='$'):: (
    if !std.member(schema.enum, value) then
      ValidErr.new('should be one value of %s' % [schema.enum], value, path)
  ),

  validateBySchemaNull(value, schema={}, path='$'):: (
    if value != null then
      ValidErr.new('should be null', value, path)
  ),

  validateBySchemaInteger(value, schema={}, path='$'):: (
    if std.type(value) != 'number' || std.length(std.split(std.toString(value), '.')) != 1 then
      ValidErr.new('should be integer', value, path)
  ),

  validateBySchemaString(value, schema={}, path='$'):: (
    if std.type(value) != 'string' then
      ValidErr.new('should be string', value, path)
  ),

  validateBySchemaNumber(value, schema={}, path='$'):: (
    if std.type(value) != 'number' then
      ValidErr.new('should be number', value, path)
  ),

  validateBySchemaBoolean(value, schema={}, path='$'):: (
    if std.type(value) != 'boolean' then
      ValidErr.new('should be boolean', value, path)
  ),

  validateBySchemaObject(value, schema={}, path='$')::
    (
      if std.type(value) != 'object' then
        ValidErr.new('should be object', value, path)
      else
        local validateBySchemaFieldValue = function(fieldValue, field, objectSchema={}, objectPath='$') (
          local propSchemaOrErr = (
            if std.objectHasAll(objectSchema, 'properties') then
              if std.objectHasAll(objectSchema.properties, field) then
                objectSchema.properties[field] { '$parent': objectSchema }
              else
                if !std.objectHasAll(objectSchema, 'additionalProperties') then
                  ValidErr.new('field `%s` is not needed' % [field], fieldValue, objectPath)
                else
                  this.getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
            else
              this.getAdditionalSchema(objectSchema, 'additionalProperties', { type: std.type(fieldValue) })
          );

          if ValidErr.is(propSchemaOrErr) then
            propSchemaOrErr
          else
            this.validateBySchema(
              fieldValue,
              propSchemaOrErr,
              '%s.%s' % [objectPath, field]
            )
        );

        local fieldSet = (
          {
            [field]: true
            for field in std.objectFieldsAll(value)
            if field != this.fieldSchema
          }
          +
          {
            [requiredField]: true
            for requiredField in if std.objectHasAll(schema, 'required') then schema.required else []
          }
        );

        local allFields = std.objectFields(fieldSet);

        std.foldl(function(validErr, field) (
          if !std.objectHasAll(value, field) then
            ValidErr.merge(validErr, ValidErr.new('missing required field `%s`' % [field], value, path))
          else
            ValidErr.merge(
              validErr,
              validateBySchemaFieldValue(
                value[field],
                field,
                schema,
                path,
              ),
            )
        ), allFields, null)
    ),

  validateBySchemaArray(value, schema={}, path='$'):: (
    if std.type(value) != 'array' then
      ValidErr.new('should be object', value, path)
    else if std.objectHas(schema, 'items') then
      if std.isArray(schema.items) then
        if std.length(schema.items) != std.length(value) && !std.objectHasAll(schema, 'additionalItems') then
          ValidErr.new('should be a tuple with %s values' % [std.length(schema.items)], value, path)
        else
          util.foldlWithIndex(
            function(validErr, itemValue, idx)
              ValidErr.merge(
                validErr,
                this.validateBySchema(
                  itemValue,
                  if idx < std.length(schema.items) then
                    schema.items[idx] { '$parent': schema }
                  else
                    this.getAdditionalSchema(schema, 'additionalItems', { type: std.type(itemValue) }),
                  '%s[%s]' % [path, idx],
                ),
              ),
            value,
            null
          )
      else
        util.foldlWithIndex(
          function(validErr, itemValue, idx)
            ValidErr.merge(
              validErr,
              this.validateBySchema(
                itemValue,
                schema.items { '$parent': schema },
                '%s[%s]' % [path, idx],
              )
            ),
          value,
          null
        )
  ),

  validateBySchemaOneOf(value, schema={}, path='$'):: (
    local validErrs = std.map(
      function(schema) this.validateBySchema(value, schema, path),
      schema.oneOf,
    );

    local valids = std.filter(function(validErr) validErr == null, validErrs);

    if std.length(valids) > 0 then
      null
    else
      std.foldl(function(validErr, nextValidErr) ValidErr.merge(validErr, nextValidErr), validErrs, null)
  ),

  isObjectWithSchema(value):: std.isObject(value) && std.objectHasAll(value, this.fieldSchema),

  isSchemaType(schema, type, specialFields=[])::
    if std.objectHasAll(schema, 'type') then
      schema.type == type
    else std.foldl(
      function(exists, field)
        if exists then exists else std.objectHasAll(schema, field),
      specialFields,
      false,
    ),

  validateBySchema(value, schema={}, path='$'):: (
    if this.isObjectWithSchema(value) && !std.objectHasAll(schema, '$parent') then
      this.validateBySchema(value, value[this.fieldSchema] { '$parent': '-' }, path)
    else if std.length(schema) == 0 then
      this.validateBySchema(value, { type: std.type(value) }, path)
    else if std.objectHasAll(schema, 'type') && std.isArray(schema.type) then
      // { type: [t] } equals { oneOf: [{ type: t }]}
      this.validateBySchema(value, { oneOf: std.map(function(t) { type: t }, schema.type) }, path)
    else if std.objectHasAll(schema, 'const') then
      // { const: v } equals { enum: [v] }
      this.validateBySchemaEnum(value, schema { enum: [schema.const] }, path)
    else if std.objectHasAll(schema, 'oneOf') then
      this.validateBySchemaOneOf(value, schema, path)
    else if std.objectHasAll(schema, 'enum') then
      this.validateBySchemaEnum(value, schema, path)
    else if this.isSchemaType(schema, 'null') then
      this.validateBySchemaNull(value, schema, path)
    else if this.isSchemaType(schema, 'boolean') then
      this.validateBySchemaBoolean(value, schema, path)
    else if this.isSchemaType(schema, 'integer') then
      this.validateBySchemaInteger(value, schema, path)
    else if this.isSchemaType(schema, 'number', [
      'multipleOf',
      'maximum',
      'exclusiveMaximum',
      'minimum',
      'exclusiveMinimum',
    ]) then
      this.validateBySchemaNumber(value, schema, path)
    else if this.isSchemaType(schema, 'string', [
      'pattern',
      'maxLength',
      'minLength',
    ]) then
      this.validateBySchemaString(value, schema, path)
    else if this.isSchemaType(schema, 'array', [
      'additionalItems',
      'contains',
      'maxItems',
      'minItems',
      'uniqueItems',
      'maxContains',
      'minContains',
    ]) then
      this.validateBySchemaArray(value, schema, path)
    else if this.isSchemaType(schema, 'object', [
      'propertyNames',
      'properties',
      'patternProperties',
      'additionalProperties',
      'maxProperties',
      'maxProperties',
      'required',
      'dependentRequired',
    ]) then
      this.validateBySchemaObject(value, schema, path)
    else
      null
  ),

  validate(value, schema={}, path='$'):: (
    local validErr = this.validateBySchema(value, schema, path);
    if ValidErr.is(validErr) then
      error ValidErr.format(validErr)
    else
      value
  ),
}
