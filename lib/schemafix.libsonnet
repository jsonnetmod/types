{
  local this = self,

  omit(o, keys):: { [n]: o[n] for n in std.objectFields(o) if !std.member(keys, n) },

  fix(s):: (
    if std.isObject(s) then
      if std.objectHasAll(s, 'disallow') then
        local fixDisallow(disallow) = if std.isString(disallow) then { type: disallow } else disallow;
        { not: if std.isArray(s.disallow) then { anyOf: std.map(fixDisallow, s.disallow) } else fixDisallow(s.disallow) } + this.omit(s, 'not')
      else if std.objectHasAll(s, 'divisibleBy') then
        { multipleOf: s.divisibleBy } + this.omit(s, 'divisibleBy')
      else if std.objectHasAll(s, 'id') then
        { '$id': s.id } + this.omit(s, 'id')
      else if std.objectHasAll(s, 'extends') then
        local base = this.omit(s, ['definitions', 'extends']);
        {
          allOf: if std.isArray(s.extends) then s.extends + [base] else [s.extends, base],
          definitions: if std.objectHas(s, 'definitions') then s.definitions else {},
        }
      else if std.objectHasAll(s, 'properties') && !std.objectHasAll(s, 'required') then
        s { required: std.filter(function(name) std.isObject(s.properties[name]) && std.objectHasAll(s.properties[name], 'required') && s.properties[name].required == true, std.objectFieldsAll(s.properties)) }
      else s
    else s
  ),
}
