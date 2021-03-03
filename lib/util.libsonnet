{
  local this = self,

  get(o, keyPath, defaults=null):: (
    local nextKeyPath() = std.makeArray(std.length(keyPath) - 1, function(i) keyPath[i + 1]);
    local isNumber(s) = std.length(s) == std.length(std.filter(function(v) v >= '0' && v <= '9', std.stringChars(s)));

    if std.length(keyPath) == 0 then
      o
    else if std.isObject(o) then (
      if std.objectHasAll(o, keyPath[0]) then this.get(o[keyPath[0]], nextKeyPath(), defaults)
      else defaults
    )
    else if std.isArray(o) && isNumber(keyPath[0]) then (
      local idx = std.parseInt(keyPath[0]);
      if std.length(o) > idx then
        this.get(o[idx], nextKeyPath(), defaults)
    )
    else defaults
  ),

  fmod(value, multipleOf):: (
    if this.type(value) == 'integer' then std.mod(value, multipleOf)
    else
      local scale = if (1 / multipleOf) < 1 then 1 else 1 / multipleOf;
      local fixedValue = value * scale;
      local fixedMultipleOf = multipleOf * scale;
      fixedValue % fixedMultipleOf
  ),

  regexMatch(pattern, str):: (
    if std.objectHasAll(std, 'regexFullMatch')
    // https://github.com/google/jsonnet/pull/665
    then std.regexFullMatch(pattern, str)
    else
      std.native('regexMatch')(pattern, str)
  ),

  type(v):: (
    local t = std.type(v);
    if t == 'number' && std.length(std.split(std.toString(v), '.')) == 1 then 'integer'
    else t
  ),

  countChar(str):: (
    // fancyCount2 https://blog.jonnew.com/posts/poo-dot-length-equals-two

    local zwj = std.char(8205);  //  \u200D
    local fe00 = std.char(65024);  // \ufe00
    local fe0f = std.char(65039);  // \ufe0f
    //    local split = std.split(str, zwj);
    local split = std.objectValuesAll(
      std.foldl(
        function(ret, c) (
          if c == zwj then
            ret { idx: ret.idx + 1 }
          else (
            local idx = '' + ret.idx;
            ret { splits+: { [idx]: if std.objectHasAll(ret.splits, idx) then ret.splits[idx] + c else c } }
          )
        ),
        std.stringChars(str),
        {
          idx: 0,
          splits: {},
        }
      ).splits
    );

    std.foldl(
      (local foldl(count, s) = (
         count + std.length(
           std.filter((local filterEmoji(c) = !(c >= fe00 && c <= fe0f); filterEmoji), std.stringChars(s))
         )
       ); foldl),
      split,
      0
    ) / std.length(split)
  ),

  foldlWithIndex(func, arr, init):: (
    local aux(func, arr, running, idx) =
      if idx >= std.length(arr) then
        running
      else
        aux(func, arr, func(running, arr[idx], idx), idx + 1) tailstrict;
    aux(func, arr, init, 0)
  ),
}
