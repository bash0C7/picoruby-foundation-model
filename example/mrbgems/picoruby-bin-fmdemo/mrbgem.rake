MRuby::Gem::Specification.new('picoruby-bin-fmdemo') do |spec|
  spec.license = 'MIT'
  spec.author  = 'bash0C7'
  spec.summary = 'Single-binary Apple Intelligence demo: app.rb embedded in mrblib'

  spec.add_dependency 'mruby-compiler2'
  spec.add_dependency 'picoruby-mruby'
  spec.add_dependency 'mruby-io', gemdir: "#{MRUBY_ROOT}/mrbgems/picoruby-mruby/lib/mruby/mrbgems/mruby-io"
  spec.add_dependency 'picoruby-foundation-model'

  binname = 'fmdemo'
  build.bins << binname

  src     = "#{dir}/tools/fmdemo/fmdemo.c"
  bin_obj = objfile(src.pathmap("#{build_dir}/tools/fmdemo/%n"))

  file bin_obj => ["#{MRUBY_ROOT}/include/picoruby.h", src] do
    cc.run bin_obj, src
  end

  file exefile("#{build.build_dir}/bin/#{binname}") => [bin_obj, build.libmruby_static] do |f|
    build.linker.run f.name, f.prerequisites
  end
end
