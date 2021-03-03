local t = import 't.libsonnet';

local ObjectMeta = t.objectOf({
  name: t.string(),
  Namespace:: t.string(),
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
  spec:: NamespaceSpec,
});

{
  ObjectMeta:: ObjectMeta,
  Namespace:: Namespace,
  NamespaceSpec:: NamespaceSpec,
}
