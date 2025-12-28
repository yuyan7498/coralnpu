# Modification Log

I made these changes after reproducing the Docker+Bazel workflow on a Windows
host and capturing the failures that showed up in the container. The goal was
to make the README steps work without extra one-off fixes.

## What I observed

- Bazelisk could not download Bazel from releases.bazel.build because the TLS
  certificate was reported as expired.
- Bazel failed running the workspace status script because:
  - Git rejected the /workspace repo as a "dubious ownership" directory.
  - The script had CRLF line endings, so bash reported "$'\\r': command not found".
- The toolchain wrapper scripts under toolchain/wrappers were "fake symlinks"
  (one-line files) on Windows mounts, so the wrappers could not find driver.sh
  under Bazel's sandbox.
- riscv-tests used text-file placeholders for symlinks under
  third_party/riscv-tests/env, so the assembler saw literal path text instead of
  real headers/scripts. This broke with errors like "unknown pseudo-op: `..`".
- firtool.sh had CRLF line endings and failed under bash, so Chisel could not
  run firtool during Verilog generation.

## Why I changed these files

- I added BAZELISK_BASE_URL to Docker Compose so Bazelisk downloads from GitHub
  releases, which avoids the TLS issue seen with releases.bazel.build.
- I forced the workspace status command to run via bash so it can execute even
  when the script's executable bit is not preserved on Windows mounts.
- I updated the dev startup script to mark /workspace as a safe git directory
  on container entry, so workspace status does not fail.
- I added .gitattributes to enforce LF endings for shell scripts, linker
  scripts, assembly, and build files to prevent CRLF-related bash failures.
- I replaced Windows "symlink placeholder" files with real file contents to
  make toolchain wrappers and riscv-tests build reliably on Windows mounts.
- I fixed firtool.sh so it runs under bash in the container and reports a clear
  error if the firtool binary cannot be located.

## Files updated or added

- docker-compose.yml
- .bazelrc
- start_dev.bat
- .gitattributes
- toolchain/wrappers/ar
- toolchain/wrappers/clang
- toolchain/wrappers/cpp
- toolchain/wrappers/driver.sh
- toolchain/wrappers/g++
- toolchain/wrappers/gcc
- toolchain/wrappers/gcov
- toolchain/wrappers/ld
- toolchain/wrappers/nm
- toolchain/wrappers/objcopy
- toolchain/wrappers/objdump
- toolchain/wrappers/strip
- third_party/riscv-tests/env/p/link.ld
- third_party/riscv-tests/env/v/link.ld
- third_party/riscv-tests/env/v/riscv_test.h
- third_party/llvm-firtool/firtool.sh

## Notes for future runs

- With these changes, the README build and test commands should run without
  extra manual fixes when using Docker on Windows.
- If new CRLF or symlink placeholder issues appear, update .gitattributes or
  replace the placeholder files with real content, similar to the fixes above.
