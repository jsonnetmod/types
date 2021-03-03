local check(name, case) = (
  assert std.isObject(case) : 'invalid case %s' % [name];
  assert std.objectHasAll(case, 'expect') : '%s case should have expect' % [name];
  assert std.objectHasAll(case, 'actual') : '%s case should have actual' % [name];

  local expect = if std.isFunction(case.expect) then case.expect else (local shouldEqual(actual) = case.expect == actual; shouldEqual);

  assert (
    expect(case.actual)
  ) : '\n\t--- FAIL: %s\n\t%s\nactual: %s\n' % [
    name,
    if std.objectHasAll(case, 'msg') then case.msg else '',
    case.actual,
  ];
  '\t--- PASS: %s' % [name]
);

local flattenSuites(suites, parent='') = (
  local testname(field) = std.foldl(
    function(s, c) s + (
      if c == ' ' then '_'
      else c
    ),
    std.stringChars(std.stripChars(if parent == '' then field else parent + '_' + field, ' ')),
    ''
  );

  std.foldl(
    function(final, field)
      local fullname = testname(field);

      final + (
        if std.isFunction(suites[field]) then
          { [fullname]:: suites[field] }
        else if std.isObject(suites[field]) then
          flattenSuites(suites[field], fullname + if std.objectHas(suites, field) then '__' else '')
        else {}
      ),
    std.objectFieldsAll(suites),
    {}
  )
);

function(suites) (
  local allSuites = flattenSuites(suites);
  std.foldl(
    function(passed, name) (
      assert std.isFunction(allSuites[name]) : 'case should be function: %s' % [name];
      passed + [check(name, allSuites[name]())]
    ),
    std.objectFieldsAll(allSuites),
    [],
  )
)
