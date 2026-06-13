MRuby::Gem::Specification.new('picoruby-foundation-model-example') do |spec|
  spec.license = 'MIT'
  spec.author  = 'bash0C7'
  spec.summary = 'Single-binary example for picoruby-foundation-model (app.rb embedded)'

  spec.add_dependency 'mruby-compiler2'
  spec.add_dependency 'picoruby-mruby'
  spec.add_dependency 'mruby-io', gemdir: "#{MRUBY_ROOT}/mrbgems/picoruby-mruby/lib/mruby/mrbgems/mruby-io"
  # The app uses FoundationModel; declaring it fixes gem init order too.
  spec.add_dependency 'picoruby-foundation-model'

  # The app is just mrblib/app.rb. A gem's mrblib top-level code runs at VM init
  # (the standard gem build compiles it and runs it during mrb_open), so the app
  # executes when the binary starts — no script file at runtime, no explicit run
  # call in main. Simplest path for a one-shot app; if you need the task
  # scheduler or explicit run control, embed and run it from main instead (the
  # picoruby-bin-r2p2 technique).
  binname = 'picoruby-foundation-model-example'
  build.bins << binname

  src     = "#{dir}/tools/main/main.c"
  bin_obj = objfile(src.pathmap("#{build_dir}/tools/main/%n"))
  file bin_obj => ["#{MRUBY_ROOT}/include/picoruby.h", src] do
    cc.run bin_obj, src
  end

  file exefile("#{build.build_dir}/bin/#{binname}") => [bin_obj, build.libmruby_static] do |f|
    build.linker.run f.name, f.prerequisites
  end
end
