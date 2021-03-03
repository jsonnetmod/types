local t = import '../validator.libsonnet';

{
  createSuites(suites):: (
    std.foldl(
      function(suites, s) suites {
        [s.description]: std.foldl(
          function(cases, c) cases {
            [c.description]::
              if c.valid then
                function() {
                  expect: null,
                  actual: t.validateBySchema(c.data, s.schema),
                  msg: '%s\nshould valid \ndata: <%s> %s\nschema: %s' % [c.description, std.type(c.data), c.data, s.schema],
                }
              else
                function() {
                  expect: function(v) v != null,
                  actual: t.validateBySchema(c.data, s.schema),
                  msg: '%s\nshould invalid \ndata: <%s> %s\nschema: %s' % [c.description, std.type(c.data), c.data, s.schema],
                },
          },
          s.tests,
          {}
        ),
      },
      suites,
      {}
    )
  ),
}
