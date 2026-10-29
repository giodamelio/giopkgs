{
  runCommandCC,
  writeText,
  go,
  jq,
  microsandbox,
}:
# Loading the FFI library and resolving the runtime pair needs no /dev/kvm, so
# this exercises the whole Go -> C ABI -> Rust SDK path a Go service takes,
# short of booting a VM.
let
  inherit (microsandbox) runtimeEnv;

  main = writeText "main.go" ''
    package main

    import (
    	"encoding/json"
    	"fmt"
    	"os"

    	microsandbox "github.com/superradcompany/microsandbox/sdk/go"
    )

    func main() {
    	version, err := microsandbox.RuntimeVersion()
    	if err != nil {
    		fmt.Fprintln(os.Stderr, "RuntimeVersion:", err)
    		os.Exit(1)
    	}
    	runtime, err := microsandbox.ResolveRuntime(microsandbox.RuntimeConfig{})
    	if err != nil {
    		fmt.Fprintln(os.Stderr, "ResolveRuntime:", err)
    		os.Exit(1)
    	}
    	json.NewEncoder(os.Stdout).Encode(map[string]any{"version": version, "runtime": runtime})
    }
  '';
in
  runCommandCC "microsandbox-go-ffi-test" {
    nativeBuildInputs = [go jq];
    env = runtimeEnv;
  } ''
    export HOME=$PWD GOCACHE=$PWD/gocache GOPROXY=off GOFLAGS=-mod=mod
    export MSB_HOME=$PWD/msb-home

    mkdir smoke && cd smoke
    cp ${main} main.go
    cat > go.mod <<EOF
    module smoke

    go 1.22

    require github.com/superradcompany/microsandbox/sdk/go v0.0.0
    replace github.com/superradcompany/microsandbox/sdk/go => ${microsandbox.src}/sdk/go
    EOF
    go build -tags microsandbox_ffi_path -o smoke .

    ./smoke > result.json
    cat result.json

    jq -e --arg v ${microsandbox.version} --arg msb "$MSB_PATH" --arg fw "$MSB_LIBKRUNFW_PATH" '
      .version == $v and .runtime.msb_path == $msb and .runtime.libkrunfw_path == $fw
    ' result.json

    touch $out
  ''
