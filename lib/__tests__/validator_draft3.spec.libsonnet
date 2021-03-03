local createSuites = (import './jsonschemasuite.libsonnet').createSuites;

local cases = std.native('importDir')(std.thisFile, '../../JSON-Schema-Test-Suite/tests/draft3/*.json');


local createSuitesFromJSON(data) = createSuites(std.native('parseJson')(data));

{
  [name]: createSuitesFromJSON(cases[name])
  for name in std.objectFieldsAll(cases)
}
