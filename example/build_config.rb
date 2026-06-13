# Host (POSIX) MicroRuby build that bundles picoruby-foundation-model.
# Driven by example/Rakefile, which clones upstream picoruby and sets
# MRUBY_CONFIG to this file and MRUBY_BUILD_DIR to example/build.
MRuby::Build.new do |conf|
  conf.toolchain :gcc

  # VM foundation defines for a POSIX (macOS) host. PICORB_ALLOC_ESTALLOC keeps
  # the allocator off the Linux-only <malloc.h> path.
  conf.cc.defines << "MRB_TICK_UNIT=4"
  conf.cc.defines << "MRB_TIMESLICE_TICK_COUNT=3"
  conf.cc.defines << "PICORB_ALLOC_ALIGN=8"
  conf.cc.defines << "PICORB_ALLOC_ESTALLOC"
  conf.cc.defines << "PICORB_PLATFORM_POSIX"
  conf.cc.defines << "MRB_INT64"
  conf.cc.defines << "MRB_NO_BOXING"
  conf.cc.defines << "MRB_UTF8_STRING"

  conf.picoruby   # select the full mruby VM (PICORB_VM_MRUBY)

  conf.gembox "mruby-posix"
  conf.gembox "minimum"
  conf.gembox "core"
  conf.gembox "stdlib"
  conf.gem core: "picoruby-bin-picoruby"   # provides the `picoruby <file.rb>` runner

  conf.gem github: 'bash0C7/picoruby-foundation-model', branch: 'main'
end
