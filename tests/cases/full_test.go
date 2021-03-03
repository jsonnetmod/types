package cases

import (
	"fmt"
	"path/filepath"
	"strings"
	"testing"
)

func Test(t *testing.T) {
	files, err := filepath.Glob("./fixtures/*.jsonnet")
	if err != nil {
		t.Fatal(err)
	}

	for i := range files {
		f := files[i]
		base := filepath.Base(f)
		name := base[0 : len(base)-len(filepath.Ext(f))]

		mustFormat(f)

		t.Run(name, func(t *testing.T) {
			ret, err := eval(
				fmt.Sprintf(`
local t = import 't.libsonnet'; 
t.validate(import '%s')
`, f))

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
