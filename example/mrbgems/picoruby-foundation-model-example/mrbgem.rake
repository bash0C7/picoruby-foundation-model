MRuby::Gem::Specification.new('picoruby-foundation-model-example') do |spec|
  spec.license = 'MIT'
  spec.author  = 'bash0C7'
  spec.summary = 'Single-binary example for picoruby-foundation-model (app.rb embedded)'

  spec.add_dependency 'mruby-compiler2'
  spec.add_dependency 'picoruby-mruby'
  spec.add_dependency 'mruby-io', gemdir: "#{MRUBY_ROOT}/mrbgems/picoruby-mruby/lib/mruby/mrbgems/mruby-io"
  # The app uses FoundationModel; declaring it fixes gem init order too.
  spec.add_dependency 'picoruby-foundation-model'

  # Compile app.rb to a C array `app[]` and link it into the binary, so the app
  # is embedded (no script file at runtime). This is the picoruby-bin-r2p2
  # embedding technique; main.c runs the array with mrb_load_irep.
  app_dir = "#{build_dir}/tools/mrblib"
  build.cc.include_paths << app_dir
  directory app_dir
  app_rb  = "#{dir}/tools/mrblib/app.rb"
  app_src = "#{app_dir}/app.c"
  file app_src => [app_dir, app_rb] do |t|
    File.open(t.name, "w") { |f| mrbc.run f, app_rb, "app", cdump: false }
  end
  app_obj = objfile(app_src.pathmap("#{app_dir}/%n"))
  build.libmruby_objs << app_obj

  binname = 'picoruby-foundation-model-example'
  build.bins << binname

  src     = "#{dir}/tools/main/main.c"
  bin_obj = objfile(src.pathmap("#{build_dir}/tools/main/%n"))
  file bin_obj => ["#{MRUBY_ROOT}/include/picoruby.h", app_src, src] do
    cc.run bin_obj, src
  end

  file exefile("#{build.build_dir}/bin/#{binname}") => [bin_obj, build.libmruby_static] do |f|
    build.linker.run f.name, f.prerequisites
  end
end
