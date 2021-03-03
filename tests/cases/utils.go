package cases

import (
	"encoding/json"
	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/formatter"
	"github.com/onsi/gomega/matchers"
	"github.com/onsi/gomega/types"
	"os"
)

var libRoot = "../../"

func eval(raw string) (string, error) {
	vm := jsonnet.MakeVM()

	vm.Importer(&jsonnet.FileImporter{
		JPaths: []string{
			libRoot,
			"../fixtures",
		},
	})

	return vm.EvaluateAnonymousSnippet("main.jsonnet", raw)
}

func mustFormat(filename string) {
	if err := format(filename); err != nil {
		panic(err)
	}
}

func format(filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	result, err := formatter.Format(filename, string(data), formatter.DefaultOptions())
	if err != nil {
		return err
	}

	return os.WriteFile(filename, []byte(result), 0644)
}

func EqualJSON(expect string) types.GomegaMatcher {
	m := &equalJSONMatcher{}

	data, err := eval(expect)
	if err != nil {
		panic(err)
	}

	if err := json.Unmarshal([]byte(data), &m.Expected); err != nil {
		panic(err)
	}
	return m
}

type equalJSONMatcher struct {
	matchers.EqualMatcher
}

func (e equalJSONMatcher) Match(actual interface{}) (success bool, err error) {
	var data []byte

	switch v := actual.(type) {
	case string:
		data = []byte(v)
	case []byte:
		data = v
	}

	var v interface{}

	if err := json.Unmarshal(data, &v); err != nil {
		return false, err
	}

	return e.EqualMatcher.Match(v)
}
