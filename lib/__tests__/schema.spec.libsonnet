local t = import '../schema.libsonnet';

local ObjectMeta = t.objectOf({
  name: t.string(),
  namespace:: t.string(),
  labels:: t.mapOf(t.string()),
  annotations:: t.mapOf(t.string()),
});

local NamespaceSpec = t.objectOf({
  finalizers:: t.arrayOf(t.string()),
});

local Namespace = t.objectOf({
  apiVersion: t.const('v1'),
  kind: t.const('Namespace'),
  metadata: ObjectMeta,
  spec: NamespaceSpec,
});

{
  test_SchemaDefaults():: {
    actual: Namespace,
    expect: {
      apiVersion: 'v1',
      kind: 'Namespace',
    },
  },
}
