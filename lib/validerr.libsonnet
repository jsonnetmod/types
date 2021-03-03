local util = import './util.libsonnet';

{
  local this = self,
  local fieldValidErr = '__valid_err__',

  new(msg, ctx):: ctx { [fieldValidErr]:: true, msg: msg },

  check(valid, msg, ctx):: if !valid then this.new(msg, ctx),

  is(v):: std.isObject(v) && std.objectHasAll(v, fieldValidErr),

  valid(err):: err == null,

  merge(validErr, nextValidErr):: (
    if this.is(validErr) then
      validErr + (
        if this.is(nextValidErr) then { next: nextValidErr } else {}
      )
    else
      nextValidErr
  ),

  format(validErr):: (
    assert this.is(validErr) : 'format first parameter should be ValidErr';

    if std.objectHas(validErr, 'next') then
      if validErr.path == validErr.next.path then
        this.format(this.new((validErr.msg + ' or ' + validErr.next.msg), validErr))
      else
        this.format(validErr) + '\n' + this.format(validErr.next)
    else
      'should `%s` %s, got <%s> %s' % [validErr.path, validErr.msg, std.type(validErr.value), validErr.value]
  ),

  anyOf(rules)::
    local validateFuncs = (
      if std.isObject(rules) then
        std.objectValuesAll(rules)
      else if std.isArray(rules) then
        rules else
        error 'anyOf parameter should be object or array with func(): null | ValidErr'
    );

    util.foldlWithIndex(
      (local validateRule(validErr, validateFunc, i) = (
         if i > 0 && this.valid(validErr) then
           validErr
         else
           local nextValidErr = validateFunc();
           if nextValidErr == null then null
           else this.merge(validErr, nextValidErr)
       ); validateRule),
      validateFuncs,
      null,
    )
  ,

  oneOf(rules)::
    local validateFuncs = (
      if std.isObject(rules) then
        std.objectValuesAll(rules)
      else if std.isArray(rules) then
        rules else
        error 'oneOf parameter should be object or array with func(): null | ValidErr'
    );

    local errs = std.map(
      function(validateFunc) validateFunc(),
      validateFuncs,
    );

    local n = std.length(validateFuncs);
    local validLength = std.length(std.filter(this.valid, errs));

    if n > 1 && validLength == n then
      this.new('more than one rule valid', { path: '$', value: null })
    else if validLength == 1 then
      null
    else
      std.foldl(
        function(validErr, err) this.merge(validErr, err),
        errs,
        null,
      ),

  allOf(rules)::
    local validateFuncs = (
      if std.isObject(rules) then
        std.objectValuesAll(rules)
      else if std.isArray(rules) then
        rules else
        error 'allOf parameter should be object or array with func(): null | ValidErr'
    );

    std.foldl(
      (local validateRule(validErr, validateFunc) = this.merge(validErr, validateFunc()); validateRule),
      validateFuncs,
      null,
    ),
}
