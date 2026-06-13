MRuby::Gem::Specification.new('picoruby-foundation-model') do |spec|
  spec.license = 'MIT'
  spec.author  = 'bash0C7'
  spec.summary = 'Apple Intelligence (Foundation Models) for PicoRuby on macOS'

  # macOS host only. Build the Swift package to a dynamic library and emit the
  # C ABI header that src/foundation_model.c includes.
  ext_dir = "#{dir}/ext"
  package = "FoundationModelMac"
  header  = "#{ext_dir}/#{package}-Swift.h"

  ok = system(
    "swift", "build", "-c", "release", "--package-path", ext_dir,
    "-Xswiftc", "-emit-clang-header-path", "-Xswiftc", header
  )
  raise "swift build failed for #{package}" unless ok

  # C binding needs the generated header.
  spec.cc.include_paths << ext_dir

  # NOTE: linking the Swift dylib into the `picoruby` executable must be done in
  # your build configuration's conf.linker — per-gem spec.linker.* does not reach
  # the executable link step.
  #
  # Constraints (macOS host experiment): `swift build` runs at spec-eval time on
  # every rake invocation (incremental, usually a no-op); the runtime rpath
  # points into the in-tree ext/.build/release, so the built `picoruby` binary
  # is not relocatable/distributable as-is.
end
