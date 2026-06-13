# picoruby-foundation-model

A PicoRuby mrbgem that exposes Apple Intelligence (the on-device [Foundation Models](https://developer.apple.com/documentation/foundationmodels) framework) to Ruby on macOS.

```ruby
puts FoundationModel.generate("Write a haiku about Ruby.")
```

## Requirements

- macOS 26 or later with Apple Intelligence enabled
- Swift 6.3 toolchain (`swift build`)
- A PicoRuby build targeting the full mruby VM (MicroRuby). mruby/c (femtoruby) is not supported.

## How it works

The gem is a thin three-layer bridge:

- `ext/Sources/FoundationModelMac/FoundationModelMac.swift` — talks to the `FoundationModels` framework and exposes a plain C ABI (`fmm_availability_check`, `fmm_generate`) via Swift's `@c` attribute. The async model call is bridged to a synchronous C call here.
- `src/foundation_model.c` — mruby C glue. Pure value marshalling between Ruby and the C ABI above.
- `mrblib/foundation_model.rb` — the public `FoundationModel` module.

At gem build time, `mrbgem.rake` runs `swift build -c release` to produce a dynamic library and emits the C ABI header that the C glue includes.

## API

```ruby
# Send a prompt to the on-device model and return its reply as a String.
# Raises FoundationModel::UnavailableError if Apple Intelligence is not available.
FoundationModel.generate(prompt)
```

## Try it

The `example/` directory builds a standalone host runtime against upstream
[picoruby/picoruby](https://github.com/picoruby/picoruby) and runs a sample:

```sh
cd example
rake build   # clones picoruby (first run) and builds into example/build
rake run     # runs example/app.rb on the built runtime
```

## Usage

Add the gem to your PicoRuby build configuration:

```ruby
conf.gem github: 'bash0C7/picoruby-foundation-model', branch: 'main'
```

That single line is all that is needed. The gem's `mrbgem.rake` builds the Swift
package and registers the dynamic library with the build linker itself, so no
manual `conf.linker` setup is required.

## License

MIT
