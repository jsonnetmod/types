local refutil = import './refutil.libsonnet';
local util = import './util.libsonnet';
local ValidErr = import './validerr.libsonnet';

local fieldSchema = '__schema__';

local validatorFor(value, path) = {
  local this = self,

  ref(schema, root):: (
    if std.objectHasAll(schema, '$ref') then (
      local ret = refutil.resolveRef(schema, root);
      this.validate(ret.schema, ret.root)
    )
  ),

  validate(s, originRoot):: (
    if s == null then
      error 'invalid schema %s' % [s]
    else if std.isBoolean(s) then
      if s then null
      else ValidErr.new('should not exists', { value: value, path: path, schema: s })
    else if std.isObject(s) then (
      local root = refutil.withIDs(originRoot);

      local schema = refutil.withPID(s, root);

      if std.objectHasAll(schema, '$ref') then
        this.ref(schema, root)
      else
        ValidErr.allOf({
          type(): this.type(schema, root),
          const(): this.const(schema, root),
          enum(): this.enum(schema, root),

          oneOf(): this.oneOf(schema, root),
          allOf(): this.allOf(schema, root),
          anyOf(): this.anyOf(schema, root),
          not(): this.not(schema, root),

          _if(): this._if(schema, root),

          number(): this.number(schema, root),
          string(): this.string(schema, root),

          minItems(): this.minItems(schema, root),
          maxItems(): this.maxItems(schema, root),
          uniqueItems(): this.uniqueItems(schema, root),
          contains(): this.contains(schema, root),

          array(): this.array(schema, root),

          required(): this.required(schema, root),
          minProperties(): this.minProperties(schema, root),
          maxProperties(): this.maxProperties(schema, root),

          object(): this.object(schema, root),
        })
    )


  ),

  string(schema, root):: (
    if std.isString(value) then
      ValidErr.allOf({
        pattern():: (
          local pattern = (
            if std.objectHasAll(schema, 'pattern') && std.isString(schema.pattern) then schema.pattern
          );
          if pattern != null then
            ValidErr.check(util.regexMatch(pattern, value), 'should match %s' % [pattern], { value: value, path: path, schema: schema })
        ),
        maxLength():: (
          local maxLength = (
            if std.objectHasAll(schema, 'maxLength') && std.isNumber(schema.maxLength) then schema.maxLength
          );

          if maxLength != null then
            ValidErr.check(util.countChar(value) <= maxLength, 'length should less or equal than %s' % [maxLength], { value: value, path: path, schema: schema })
        ),
        minLength():: (
          local minLength = (
            if std.objectHasAll(schema, 'minLength') && std.isNumber(schema.minLength) then schema.minLength
          );

          if minLength != null then
            ValidErr.check(util.countChar(value) >= minLength, 'length should large or equal than %s' % [minLength], { value: value, path: path, schema: schema })
        ),
      })
  ),

  number(schema, root):: (
    if std.isNumber(value) then
      ValidErr.allOf({
        multipleOf():: (
          local multipleOf = (
            if std.objectHasAll(schema, 'multipleOf') && std.isNumber(schema.multipleOf) && schema.multipleOf != 0 then schema.multipleOf else null
          );
          if multipleOf != null then
            if value > std.pow(2, 53) then
              ValidErr.check(false, 'too large value %s' % [value], { value: value, path: path, schema: schema })
            else
              ValidErr.check(util.fmod(value, multipleOf) == 0, 'should be multiple of %s' % [multipleOf], { value: value, path: path, schema: schema })
        ),
        exclusiveMinimum():: (
          local exclusiveMinimum = (
            if std.objectHasAll(schema, 'exclusiveMinimum') then
              if std.isNumber(schema.exclusiveMinimum) then schema.exclusiveMinimum
              else (
                if schema.exclusiveMinimum == true then if std.objectHasAll(schema, 'minimum') && std.isNumber(schema.minimum) then schema.minimum
              )
          );

          if exclusiveMinimum != null then
            ValidErr.check(value > exclusiveMinimum, 'should be large than %s' % [exclusiveMinimum], { value: value, path: path, schema: schema })
        ),
        minimum():: (
          local minimum = (
            if std.objectHasAll(schema, 'minimum') && std.isNumber(schema.minimum) then schema.minimum
          );

          if minimum != null then
            ValidErr.check(value >= minimum, 'should be large or equal than %s' % [minimum], { value: value, path: path, schema: schema })
        ),
        exclusiveMaximum():: (
          local exclusiveMaximum = (
            if std.objectHasAll(schema, 'exclusiveMaximum') then
              if std.isNumber(schema.exclusiveMaximum) then schema.exclusiveMaximum
              else (
                if schema.exclusiveMaximum == true then if std.objectHasAll(schema, 'maximum') && std.isNumber(schema.maximum) then schema.maximum
              )
          );
          if exclusiveMaximum != null then
            ValidErr.check(value < exclusiveMaximum, 'should be less than %s' % [exclusiveMaximum], { value: value, path: path, schema: schema })
        ),
        maximum():: (
          local maximum = (
            if std.objectHasAll(schema, 'maximum') && std.isNumber(schema.maximum) then schema.maximum
          );

          if maximum != null then
            ValidErr.check(value <= maximum, 'should be less or equal than %s' % [maximum], { value: value, path: path, schema: schema })
        ),
      })
  ),

  minItems(schema, root):: (
    if std.isArray(value) && std.objectHasAll(schema, 'minItems') && std.isNumber(schema.minItems) then
      ValidErr.check(std.length(value) >= schema.minItems, 'at least %s items' % [schema.minItems], { value: value, path: path, schema: schema })
  ),

  maxItems(schema, root):: (
    if std.isArray(value) && std.objectHasAll(schema, 'maxItems') && std.isNumber(schema.maxItems) then
      ValidErr.check(std.length(value) <= schema.maxItems, 'not large than %s items' % [schema.maxItems], { value: value, path: path, schema: schema })
  ),

  uniqueItems(schema, root):: (
    if std.isArray(value) && std.objectHasAll(schema, 'uniqueItems') && schema.uniqueItems then
      local sortAndUniq = std.uniq(std.sort(value, std.toString));
      ValidErr.check(std.length(sortAndUniq) == std.length(value), 'unique items', { value: value, path: path, schema: schema })
  ),

  contains(schema, root):: (
    if std.isArray(value) && std.objectHasAll(schema, 'contains') then
      local results = std.map(function(v) validatorFor(v, path).validate(refutil.withPID(schema.contains, schema), root), value);
      local n = std.length(std.filter(ValidErr.valid, results));

      if n > 0 then
        null
      else
        ValidErr.new('value match %s' % [schema.contains], { value: value, path: path, schema: schema })
  ),

  array(schema, root):: (
    if std.isArray(value) then (
      if std.objectHasAll(schema, 'items') then (
        if std.isArray(schema.items) then
          local tupleN = std.length(schema.items);

          ValidErr.allOf(
            std.makeArray(
              std.length(value),
              (local forEach(i) = (
                 local p = '%s[%s]' % [path, i];

                 if i < tupleN then
                   local validateTupleItem() = validatorFor(value[i], p).validate(
                     refutil.withPID(schema.items[i], schema),
                     root,
                   );
                   validateTupleItem
                 else
                   local validateTupleAddtionalItem() = validatorFor(value[i], p).validate(
                     if std.objectHasAll(schema, 'additionalItems') then refutil.withPID(schema.additionalItems, schema) else true,
                     root
                   );
                   validateTupleAddtionalItem
               ); forEach),
            )
          )
        else
          ValidErr.allOf(
            std.makeArray(
              std.length(value),
              (local forEach(i) = (
                 local p = '%s[%s]' % [path, i];
                 local validateArrayItem() = validatorFor(value[i], p).validate(refutil.withPID(schema.items, schema), root);
                 validateArrayItem
               ); forEach),
            )
          )
      )
    )
  ),

  object(schema, root):: (
    if std.isObject(value) then (
      local validateProp(field) = function() (
        if field == fieldSchema then
          null
        else
          local fieldPath = '%s.%s' % [path, field];
          local next = validatorFor(value[field], fieldPath);

          local dependency = (
            if std.objectHasAll(schema, 'dependencies') && std.objectHasAll(schema.dependencies, field) then
              schema.dependencies[field]
            else null
          );

          local dependencies() = (
            if dependency != null then
              if std.isArray(dependency) then
                // Property dependencies
                ValidErr.allOf(
                  std.map(
                    function(depField)
                      function()
                        if !std.objectHasAll(value, depField) then
                          ValidErr.new('missing dependency %s' % [depField], { value: value, path: fieldPath, schema: schema }),
                    dependency
                  )
                )
              else
                // Schema dependencies
                validatorFor(value, path).validate(refutil.withPID(dependency, schema), root)
          );

          local propSchema = (
            if std.objectHasAll(schema, 'properties') && std.objectHasAll(schema.properties, field) then
              schema.properties[field]
            else null
          );

          local patternPropSchemas = (
            if std.objectHasAll(schema, 'patternProperties') && std.isObject(schema.patternProperties) then
              std.filterMap(
                (local filterPattern(pattern) = util.regexMatch(pattern, field); filterPattern),
                (local mapPattern(pattern) = schema.patternProperties[pattern]; mapPattern),
                std.objectFieldsAll(schema.patternProperties),
              )
            else
              []
          );

          local isAdditionalProp = propSchema == null && std.length(patternPropSchemas) == 0;

          local additionalProperties() = (
            if isAdditionalProp && std.objectHasAll(schema, 'additionalProperties') then next.validate(refutil.withPID(schema.additionalProperties, schema), root)
          );

          local properties() = (
            if propSchema != null then
              next.validate(refutil.withPID(schema.properties[field], schema), root)
          );

          local patternProperties() = (
            if std.length(patternPropSchemas) > 0 then next.validate(refutil.withPID({ allOf: patternPropSchemas }, schema), root)
          );

          local propertyNames() = (
            if std.objectHasAll(schema, 'propertyNames') then validatorFor(field, '%s[%s]' % [path, field]).validate(refutil.withPID(schema.propertyNames, schema), root)
          );

          ValidErr.allOf([
            properties,
            dependencies,
            patternProperties,
            additionalProperties,
            propertyNames,
          ])
      );

      ValidErr.allOf(
        std.map(validateProp, std.objectFieldsAll(value))
      )
    )
  ),

  required(schema, root):: (
    if std.isObject(value) && std.objectHasAll(schema, 'required') && std.isArray(schema.required) then
      local validateRequired(field) = function() (
        ValidErr.check(std.objectHas(value, field), 'missing required field `%s`' % [field], { value: value, path: path, schema: schema })
      );
      ValidErr.allOf(std.map(validateRequired, schema.required))
  ),

  minProperties(schema, root):: (
    if std.isObject(value) && std.objectHasAll(schema, 'minProperties') && std.isNumber(schema.minProperties) then
      local n = std.length(std.objectFields(value));
      ValidErr.check(n >= schema.minProperties, 'min properties is %s' % schema.minProperties, { value: value, path: path, schema: schema })
  ),

  maxProperties(schema, root):: (
    if std.isObject(value) && std.objectHasAll(schema, 'maxProperties') && std.isNumber(schema.maxProperties) then
      local n = std.length(std.objectFields(value));
      ValidErr.check(n <= schema.maxProperties, 'max properties is %s' % schema.maxProperties, { value: value, path: path, schema: schema })
  ),

  oneOf(schema, root):: (
    if std.objectHasAll(schema, 'oneOf') && std.isArray(schema.oneOf) then
      ValidErr.oneOf(std.map(function(subSchema) function() this.validate(refutil.withPID(subSchema, schema), root), schema.oneOf))
  ),

  allOf(schema, root):: (
    if std.objectHasAll(schema, 'allOf') && std.isArray(schema.allOf) then
      ValidErr.allOf(std.map(function(subSchema) function() this.validate(refutil.withPID(subSchema, schema), root), schema.allOf))
  ),

  anyOf(schema, root):: (
    if std.objectHasAll(schema, 'anyOf') && std.isArray(schema.anyOf) then
      ValidErr.anyOf(std.map(function(subSchema) function() this.validate(refutil.withPID(subSchema, schema), root), schema.anyOf))
  ),

  not(schema, root):: (
    if std.objectHasAll(schema, 'not') then (
      if ValidErr.valid(this.validate(refutil.withPID(schema.not, schema), root)) then ValidErr.new('should not be %s' % [schema.not], { value: value, path: path, schema: schema })
    )
  ),

  _if(schema, root):: (
    local validateUseElse() = if std.objectHasAll(schema, 'else') then this.validate(refutil.withPID(schema['else'], schema), root);
    local validateUseThen() = if std.objectHasAll(schema, 'then') then this.validate(refutil.withPID(schema['then'], schema), root);

    if std.objectHasAll(schema, 'if') then
      if ValidErr.valid(this.validate(refutil.withPID(schema['if'], schema), root)) then (
        validateUseThen()
      )
      else validateUseElse()
  ),

  type(schema, root):: (
    if std.objectHasAll(schema, 'type') then
      ValidErr.allOf({
        typeIsSingleString():: (
          if std.isString(schema.type) then
            local t = util.type(value);
            ValidErr.check((t == 'integer' && schema.type == 'number') || t == schema.type, 'should be %s' % [schema.type], { value: value, path: path, schema: schema })
        ),
        typeIsArray():: if std.isArray(schema.type) then
          this.validate({ oneOf: std.map(function(t) { type: t }, schema.type) }, root),
      })
  ),

  const(schema, root):: (
    if std.objectHasAll(schema, 'const') then
      ValidErr.check(schema.const == value, 'should be equal %s' % [schema.const], { value: value, path: path, schema: schema })
  ),

  enum(schema, root):: (
    if std.objectHasAll(schema, 'enum') && std.isArray(schema.enum) then
      ValidErr.check(std.member(schema.enum, value), 'should be one of %s' % [schema.enum], { value: value, path: path, schema: schema })
  ),
};

{
  local this = self,

  isObjectWithSchema(value):: std.isObject(value) && std.objectHasAll(value, fieldSchema),

  validateBySchema(value, schema={}, path='$'):: (
    if this.isObjectWithSchema(value) && value[fieldSchema] != schema then
      this.validateBySchema(value, value[fieldSchema], path)
    else validatorFor(value, path).validate(schema, schema)
  ),

  validate(value, schema={}, path='$'):: (
    local err = this.validateBySchema(value, schema, path);
    if !ValidErr.vaild(err) then
      error ValidErr.format(err)
    else
      value
  ),
}
