package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func NativeFuncs() []*jsonnet.NativeFunction {
	return []*jsonnet.NativeFunction{
		{
			Name:   "fetch",
			Params: ast.Identifiers{"url"},
			Func: func(args []interface{}) (res interface{}, err error) {
				data, err := fetch(args[0].(string))
				if err != nil {
					return nil, err
				}
				return string(data), nil
			},
		},
		{
			Name:   "parseJson",
			Params: ast.Identifiers{"json"},
			Func: func(dataString []interface{}) (interface{}, error) {
				data := []byte(dataString[0].(string))
				var contents interface{}
				err := json.Unmarshal(data, &contents)
				return contents, err
			},
		},
		{
			Name:   "regexMatch",
			Params: ast.Identifiers{"regex", "str"},
			Func: func(args []interface{}) (interface{}, error) {
				pattern := args[0].(string)
				str := args[1].(string)
				return regexp.MatchString(pattern, str)
			},
		},
		{
			Name:   "importDir",
			Params: ast.Identifiers{"thisFile", "glob"},
			Func: func(args []interface{}) (interface{}, error) {
				file := args[0].(string)
				relDir := args[1].(string)

				files, err := filepath.Glob(filepath.Join(filepath.Dir(file), relDir))
				if err != nil {
					return nil, err
				}

				contents := map[string]interface{}{}

				for _, f := range files {
					data, err := os.ReadFile(f)
					if err != nil {
						return nil, err
					}
					contents[filepath.Base(f)] = string(data)
				}

				return contents, nil
			},
		},
	}
}

const cacheRoot = "./.cache"

func fetch(url string) ([]byte, error) {
	filename := filepath.Join(cacheRoot, base64.StdEncoding.EncodeToString([]byte(url)))

	data, err := os.ReadFile(filename)
	if err != nil {
		if os.IsNotExist(err) {
			data, err := get(url)
			if err != nil {
				return nil, err
			}

			_ = os.MkdirAll(cacheRoot, os.ModePerm)
			if err := os.WriteFile(filename, data, os.ModePerm); err != nil {
				return nil, err
			}
			return data, nil
		}
	}

	return data, nil
}

func get(uri string) ([]byte, error) {
	localFake := "http://localhost:1234/"

	if strings.HasPrefix(uri, localFake) {
		return os.ReadFile(filepath.Join("JSON-Schema-Test-Suite/remotes", strings.TrimPrefix(uri, localFake)))
	}

	resp, err := http.Get(uri)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		return io.ReadAll(resp.Body)
	}
	return nil, fmt.Errorf("fetch from %s failed with %s", uri, resp.Status)
}
