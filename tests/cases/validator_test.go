package cases

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"testing"

	. "github.com/onsi/gomega"
)

func TestValidator(t *testing.T) {
	mustFormat(filepath.Join(libRoot, "validator.libsonnet"))

	suites := []string{
		"draft2020-12/type.json",
	}

	for i := range suites {
		s := suites[i]

		t.Run(s, func(t *testing.T) {
			suites, err := LoadSuites(s)
			if err != nil {
				panic(err)
			}

			for _, s := range suites {
				s.Run(t)
			}
		})
	}
}

type Suite struct {
	Description string      `json:"description"`
	Schema      interface{} `json:"schema"`
	Tests       []struct {
		Description string      `json:"description"`
		Data        interface{} `json:"data"`
		Valid       bool        `json:"valid"`
	} `json:"tests"`
}

func (s *Suite) Run(t *testing.T) {
	for i := range s.Tests {
		test := s.Tests[i]

		t.Run(test.Description, func(t *testing.T) {
			tc := map[string]interface{}{
				"schema": s.Schema,
				"data":   test.Data,
			}

			d, _ := json.Marshal(tc)

			data, err := eval(fmt.Sprintf(
				`
local t = import 'validator.libsonnet';

local c = %s;

c + { err: t.validateBySchema(c.data, c.schema)}
	`, d))

			if err != nil {
				t.Log(err)
			}

			NewWithT(t).Expect(err).To(BeNil())

			var result struct {
				Schema   interface{} `json:"schema"`
				Data     interface{} `json:"data"`
				Err interface{} `json:"err"`
			}

			err = json.Unmarshal([]byte(data), &result)
			NewWithT(t).Expect(err).To(BeNil())

			if test.Valid {
				NewWithT(t).Expect(result.Err).To(BeNil(), data)
			} else {
				NewWithT(t).Expect(result.Err).NotTo(BeNil(), data)
			}
		})
	}
}

const suiteRoot = "https://raw.githubusercontent.com/json-schema-org/JSON-Schema-Test-Suite/master/tests/"

func LoadSuites(name string) ([]Suite, error) {
	filename := filepath.Join("suites/", name)

	data, err := os.ReadFile(filename)
	if err != nil {
		if os.IsNotExist(err) {
			resp, err := http.Get(suiteRoot + name)
			if err != nil {
				return nil, err
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				return nil, fmt.Errorf("sync failed from %s", resp.Request.URL)
			}

			data, err := io.ReadAll(resp.Body)
			if err != nil {
				return nil, err
			}

			if err := os.MkdirAll(filepath.Dir(filename), os.ModePerm); err != nil {
				return nil, err
			}

			if err := os.WriteFile(filename, data, os.ModePerm); err != nil {
				return nil, err
			}

			return LoadSuites(name)
		}
		return nil, err
	}

	cases := make([]Suite, 0)

	if err := json.Unmarshal(data, &cases); err != nil {
		return nil, err
	}

	return cases, nil
}
