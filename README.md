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

- `ext/Sources/FoundationModelMac/FoundationModelMac.swift` — talks to the `FoundationModels` framework and exposes a plain C ABI (`fmm_availability_check`, `fmm_generate`, `fmm_session_new`, `fmm_session_respond`, `fmm_session_free`) via Swift's `@c` attribute. The async model call is bridged to a synchronous C call here.
- `src/foundation_model.c` — mruby C glue. It declares the C ABI above and marshals values between it and Ruby.
- `mrblib/foundation_model.rb` — the public `FoundationModel` module.

At gem build time, `mrbgem.rake` runs `swift build -c release` to produce a static library and links it from the path `swift build --show-bin-path` reports.

## API

```ruby
# Send a prompt to the on-device model and return its reply as a String.
FoundationModel.generate(prompt)

# A session keeps the conversation: each reply sees the earlier turns.
session = FoundationModel::Session.new(instructions: "Answer in one short sentence.")
session.respond("My favorite color is green.")
session.respond("What is my favorite color?")

# Give up after timeout_ms; the generation is cancelled and the session stays usable.
session.respond(prompt, timeout_ms: 5000)
```

Errors:

| Class | Raised when |
|---|---|
| `FoundationModel::UnavailableError` | Apple Intelligence is not available (`generate`, `Session.new`) |
| `FoundationModel::GenerationError` (a `RuntimeError`) | the model call fails |
| `FoundationModel::TimeoutError` (a `GenerationError`) | `timeout_ms` elapses before the reply |

## Try it

The `example/` directory builds a single self-contained binary against upstream
[picoruby/picoruby](https://github.com/picoruby/picoruby) with the gem from this
checkout. The sample `app.rb`
is embedded into the binary (via the `picoruby-foundation-model-example` gem) and the Swift
glue is statically linked, so the result is one file with no script and no
in-tree dylib to ship alongside:

```sh
cd example
rake build   # clones picoruby (first run); builds example/build/host/bin/picoruby-foundation-model-example
rake run     # runs the binary (app.rb is baked in)
```

The binary depends only on macOS system pieces (the Swift runtime in
`/usr/lib/swift` and the `FoundationModels` framework), so it runs on any
macOS 26 machine with Apple Intelligence — copy it elsewhere and it still works.

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
