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

  # Link the Swift dylib into the `picoruby` executable. picoruby-bin-picoruby's
  # exe link rule reads the build-level linker (not per-gem spec.linker), so we
  # register on build.linker here — that way consumers only need `conf.gem`, no
  # manual conf.linker step. rpath lets the dylib resolve at runtime.
  #
  # Constraint (macOS host experiment): the rpath points into the in-tree
  # ext/.build/release, so the built `picoruby` binary is not
  # relocatable/distributable as-is.
  lib_dir = "#{ext_dir}/.build/release"
  build.linker.flags     << "-L#{lib_dir}"
  build.linker.libraries << package
  build.linker.flags     << "-Wl,-rpath,#{lib_dir}"
end
