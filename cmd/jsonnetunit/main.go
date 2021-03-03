package main

import (
	"encoding/json"
	"fmt"
	"github.com/google/go-jsonnet"
	"os"
	"path/filepath"
	"sort"
	"strings"

	_ "embed"
)

//go:embed runsuites.libsonnet
var runsuites string

func main() {
	args := os.Args[1:]
	cwd, _ := os.Getwd()

	files := glob(filepath.Join(cwd, "*.libsonnet"))

	if len(args) > 0 {
		for i := range args {
			files = append(files, glob(filepath.Join(cwd, args[i]))...)
		}
	}

	for _, f := range filterTestFiles(files) {
		r, _ := filepath.Rel(cwd, f)

		fmt.Printf("=== RUN: %s\n", r)

		if err := RunTest(f); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
	}
}

func RunTest(testfile string) error {
	vm := jsonnet.MakeVM()

	for _, f := range NativeFuncs() {
		vm.NativeFunction(f)
	}

	snippets := fmt.Sprintf("(%s)(import '%s')", runsuites, testfile)

	ret, err := vm.EvaluateAnonymousSnippet("tests.libsonnet", snippets)
	if err != nil {
		return err
	}

	passed := make([]string, 0)

	if err := json.Unmarshal([]byte(ret), &passed); err != nil {
		return err
	}

	for i := range passed {
		fmt.Println(passed[i])
	}

	return err
}

func filterTestFiles(files []string) []string {
	s := map[string]bool{}

	for _, f := range files {
		if strings.HasSuffix(f, ".spec.libsonnet") {
			s[f] = true
		}
	}

	testFiles := make([]string, 0)

	for f := range s {
		testFiles = append(testFiles, f)
	}

	sort.Strings(testFiles)

	return testFiles
}

func glob(pat string) []string {
	files, err := filepath.Glob(pat)
	if err != nil {
		panic(err)
	}
	return files
}
