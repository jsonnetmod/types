package cases

import (
	. "github.com/onsi/gomega"
	"path/filepath"
	"testing"
)

func TestSchema(t *testing.T) {
	mustFormat(filepath.Join(libRoot, "schema.libsonnet"))

	data, err := eval(`
local t = import 'schema.libsonnet';

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
	namespace: Namespace
}
`)

	NewWithT(t).Expect(err).To(BeNil())
	NewWithT(t).Expect(data).To(EqualJSON(`
{
   "namespace": {
	  "apiVersion": "v1",
	  "kind": "Namespace"
   }
}
`))
}
