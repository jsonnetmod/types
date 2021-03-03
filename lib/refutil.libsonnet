local schemafix = import './schemafix.libsonnet';

{
  local fieldPID = '__pid__',
  local fieldIDs = '$ids$',
  local fieldID = '$id',
  local fieldRef = '$ref',

  local this = self,

  pathJoin(base, path):: (
    if path == '' then base
    else if std.startsWith(path, 'http://') || std.startsWith(path, 'https://') then
      path
    else if path[0] == '#' || base == '' then (std.rstripChars(base, '#') + path)
    else (
      local parts = std.split(base, '/');
      std.join('/', std.makeArray(std.length(parts) - 1, function(i) parts[i]) + [path])
    )
  ),

  escapeKey(key):: std.foldl(function(key, replace) std.strReplace(key, replace[0], replace[1]), [
    ['%22', '"'],
    ['%25', '%'],
    ['~0', '~'],
    ['~1', '/'],
  ], key),

  withIDs(root):: (
    if std.isObject(root) && !std.objectHas(root, fieldIDs) then
      root { [fieldIDs]: this.resolveIDs(root) }
    else root
  ),

  resolveIDs(root, parent=''):: (
    local rootID = this.pathJoin(parent, if std.objectHasAll(root, fieldID) then root[fieldID] else '');

    (
      if rootID != '' then ({ [rootID]: root { [fieldID]: rootID } }) else {}
    )
    +
    (
      if std.objectHasAll(root, 'definitions') then
        std.foldl(function(ids, def) (
          local d = schemafix.fix(def);
          if std.isObject(d) && std.objectHasAll(d, fieldID)
          then this.resolveIDs(d, rootID)
          else {}
        ), std.objectValues(root.definitions), {})
      else {}
    )
  ),

  resolveRef(schema, root):: (
    local ref = schema[fieldRef];
    local refSchemaInDefs = this.resolveLocalRefs(ref, root);
    if refSchemaInDefs != null then { schema: refSchemaInDefs, root: root }
    else (
      local pid = if std.objectHasAll(schema, fieldPID) then schema[fieldPID] else this.getID(root);

      local parts = std.split(ref, '#');
      local path = this.pathJoin(pid, parts[0]);

      local resolvedRoot = (
        if path != '' && path != pid then this.remote(std.trace('' + schema, path), root) else root
      ) + (
        if std.objectHasAll(root, fieldIDs) then { [fieldIDs]: root[fieldIDs] } else {}
      );

      local keyPath = if std.length(parts) == 2 && parts[1] != '' then std.map(this.escapeKey, std.split(std.lstripChars(parts[1], '/'), '/')) else [];

      local refSchema = this.walk(
        resolvedRoot,
        keyPath,
        null,
        pid
      );

      if refSchema == null then error 'can not found ref %s %s' % [ref, resolvedRoot]
      else

        local pidPatch = if std.isObject(refSchema) && std.objectHasAll(refSchema, fieldPID) then { [fieldPID]: refSchema[fieldPID] } else {};

        if std.isObject(refSchema) && std.objectHasAll(refSchema, fieldRef) then
          this.resolveRef(refSchema, resolvedRoot + pidPatch)
        else
          {
            schema: refSchema,
            root: resolvedRoot + pidPatch,
          }
    )
  ),

  resolveLocalRefs(ref, root):: (
    if std.objectHasAll(root, fieldIDs) && std.objectHasAll(root[fieldIDs], ref) then
      root[fieldIDs][ref]
    else if std.objectHasAll(root, 'definitions') then
      std.foldl(
        function(r, d)
          if r != null then r
          else if std.isObject(d) && std.objectHasAll(d, fieldID) && d[fieldID] == ref then d
          else null,
        std.objectValuesAll(root.definitions),
        null
      )
  ),

  remote(id, root):: (
    if std.objectHasAll(root, fieldIDs) && std.objectHasAll(root[fieldIDs], id) then
      root[fieldIDs][id]
    else (
      std.native('parseJson')(std.native('fetch')(id))
    )
  ),

  getID(o):: if std.objectHasAll(o, fieldID) then o[fieldID] else '',

  withPID(s, parent):: if std.isObject(s) && !std.objectHasAll(s, fieldPID) then (
    local pid = this.pathJoin(
      if std.objectHasAll(parent, fieldPID) then parent[fieldPID] else this.getID(parent),
      this.getID(s),
    );
    s {
      [fieldPID]: pid,
    }
  ) else s,

  walk(schema, keyPath, defaults=null, pid=''):: (
    local o = schemafix.fix(schema);
    local nextKeyPath() = std.makeArray(std.length(keyPath) - 1, function(i) keyPath[i + 1]);
    local isNumber(s) = std.length(s) == std.length(std.filter(function(v) v >= '0' && v <= '9', std.stringChars(s)));

    if std.length(keyPath) == 0 then
      if std.isObject(o) && pid != '' then o { [fieldPID]: this.pathJoin(pid, this.getID(o)) } else o
    else if std.isObject(o) then (
      if std.objectHasAll(o, keyPath[0]) then
        this.walk(
          o[keyPath[0]],
          nextKeyPath(),
          defaults,
          this.pathJoin(pid, this.getID(o))
        )
      else
        defaults
    )
    else if std.isArray(o) && isNumber(keyPath[0]) then (
      local idx = std.parseInt(keyPath[0]);
      if std.length(o) > idx then
        this.walk(o[idx], nextKeyPath(), defaults, pid)
    )
    else defaults
  ),
}
