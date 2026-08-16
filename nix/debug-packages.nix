# Debug adapters and the embedded toolchain. codelldb and cpptools come
# from VS Code extension packages that don't expose their binaries on
# $out/bin by default (they're nested under share/vscode/extensions/...),
# so each gets a thin wrapper package that symlinks the real binary to a
# bare, PATH-resolvable name -- matching what debug.lua's kind modules
# expect (plain command names, not baked-in store paths that would go
# stale on every rebuild).
{ pkgs }:
let
  codelldb-bin = pkgs.runCommand "codelldb-bin" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $out/bin/codelldb
  '';

  opendebugad7-bin = pkgs.runCommand "opendebugad7-bin" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/OpenDebugAD7 $out/bin/OpenDebugAD7
  '';

  # nvim-dap-python needs a python with debugpy importable. Exposed under a
  # distinct name (not bare "python3") to avoid shadowing whatever Python
  # the rest of the system/PATH provides.
  debugpy-python = pkgs.runCommand "debugpy-python-bin" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.python3.withPackages (ps: [ ps.debugpy ])}/bin/python3 $out/bin/debugpy-python
  '';
in
with pkgs;
[
  codelldb-bin
  opendebugad7-bin
  debugpy-python

  gdb # native

  # arm-none-eabi-gdb, arm-none-eabi-gcc, etc. lib.lowPrio: both this and
  # gdb ship include/gdb/jit-reader.h, which conflicts in the profile;
  # neither copy matters to us (just a C header for GDB JIT-reader
  # plugins), so let gdb's win arbitrarily.
  (lib.lowPrio gcc-arm-embedded)

  openocd
]
