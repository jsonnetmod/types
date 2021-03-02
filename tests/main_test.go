package tests_test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/formatter"
)

func Test(t *testing.T) {
	_ = format("../schema.libsonnet")
	_ = format("../validate.libsonnet")

	files, err := filepath.Glob("./fixtures/*.jsonnet")
	if err != nil {
		t.Fatal(err)
	}

	for i := range files {
		f := files[i]
		base := filepath.Base(f)
		name := base[0 : len(base)-len(filepath.Ext(f))]

		_ = format(f)

		t.Run(name, func(t *testing.T) {
			ret, err := eval(f)

			if strings.HasPrefix(base, "error_") {
				if err == nil {
					t.Logf(ret)
					t.Fatal(name)
				} else {
					fmt.Println(err.Error())

					if !strings.HasPrefix(err.Error(), "RUNTIME ERROR: `$") {
						t.Fatal(err)
					}
				}
			} else {
				if err != nil {
					t.Fatal(err, name)
				} else {
					t.Logf(ret)
				}
			}
		})
	}
}

func eval(file string) (string, error) {
	vm := jsonnet.MakeVM()

	vm.Importer(&jsonnet.FileImporter{
		JPaths: []string{
			"..",
			".",
		},
	})

	raw := fmt.Sprintf(`
local t = import 't.libsonnet'; 
t.validate(import '%s')
`, file)

	return vm.EvaluateAnonymousSnippet("", raw)
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
