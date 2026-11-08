MRuby::Gem::Specification.new('picoruby-foundation-model') do |spec|
  spec.license = 'MIT'
  spec.author  = 'bash0C7'
  spec.summary = 'Apple Intelligence (Foundation Models) for PicoRuby on macOS'

  # macOS host only. Build the Swift package to a static library;
  # src/foundation_model.c declares its C ABI itself.
  ext_dir = "#{dir}/ext"
  package = "FoundationModelMac"
  swift_build = ["swift", "build", "-c", "release", "--package-path", ext_dir]

  ok = system(*swift_build)
  raise "swift build failed for #{package}" unless ok

  # Statically link the Swift glue into the executable. picoruby-bin-picoruby's
  # exe link rule reads the build-level linker (not per-gem spec.linker), so we
  # register on build.linker here — consumers only need `conf.gem`, no manual
  # conf.linker step. Linking the .a folds our code into the binary, leaving no
  # in-tree dylib dependency; the only runtime deps are macOS system pieces
  # (the Swift runtime in /usr/lib/swift and the FoundationModels framework),
  # which the .a's LC_LINKER_OPTION autolink directives pull in. So the binary
  # is relocatable across macOS 26 + Apple Intelligence machines.
  lib_dir = IO.popen([*swift_build, "--show-bin-path"], &:read).strip
  raise "swift build --show-bin-path failed for #{package}" unless $?.success?
  build.linker.flags     << "-L#{lib_dir}"
  build.linker.libraries << package
  build.linker.flags     << "-L/usr/lib/swift"
  build.linker.flags     << "-Wl,-rpath,/usr/lib/swift"
end
