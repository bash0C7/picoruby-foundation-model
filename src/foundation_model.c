/* picoruby-foundation-model: mruby C glue for Apple Intelligence (Foundation Models).
 *
 * Thin marshalling only. The session lifecycle and the framework call live in
 * Swift (ext/Sources/FoundationModelMac/FoundationModelMac.swift), exposed as a
 * plain C ABI; each method here is a 1:1 marshal of one @c Swift function.
 *
 * picoruby's gem build compiles only top-level src/*.c, so the binding lives
 * directly here (no src/mruby/ split — this gem targets one VM). macOS host /
 * full mruby VM only; mruby/c (femtoruby) is unsupported. */
#if defined(PICORB_VM_MRUBY)

#include "mruby.h"
#include "mruby/presym.h"
#include "mruby/string.h"
#include "mruby/error.h"
#include <stdlib.h>
#include "FoundationModelMac-Swift.h"

/* Unavailability reason as a String, or nil when Apple Intelligence is ready. */
static mrb_value
mrb_fm_s_availability_reason(mrb_state *mrb, mrb_value klass)
{
  char *r = fmm_availability_check();
  if (!r) return mrb_nil_value();
  mrb_value s = mrb_str_new_cstr(mrb, r);
  free(r);
  return s;
}

/* Send the prompt to the on-device model and return its reply as a String. */
static mrb_value
mrb_fm_s_generate(mrb_state *mrb, mrb_value klass)
{
  const char *prompt;
  mrb_get_args(mrb, "z", &prompt);

  char *err = NULL;
  char *reply = fmm_generate(prompt, &err);
  if (err) {
    mrb_value m = mrb_str_new_cstr(mrb, err);
    free(err);
    mrb_raise(mrb, E_RUNTIME_ERROR, mrb_str_to_cstr(mrb, m));
  }
  if (!reply) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "fmm_generate returned NULL without error");
  }
  mrb_value result = mrb_str_new_cstr(mrb, reply);
  free(reply);
  return result;
}

void
mrb_picoruby_foundation_model_gem_init(mrb_state *mrb)
{
  struct RClass *module_FM = mrb_define_module_id(mrb, MRB_SYM(FoundationModel));
  mrb_define_class_method_id(mrb, module_FM, MRB_SYM(_availability_reason),
                             mrb_fm_s_availability_reason, MRB_ARGS_NONE());
  mrb_define_class_method_id(mrb, module_FM, MRB_SYM(_generate),
                             mrb_fm_s_generate, MRB_ARGS_REQ(1));
}

void
mrb_picoruby_foundation_model_gem_final(mrb_state *mrb)
{
}

#else
#error "picoruby-foundation-model targets the full mruby VM (MicroRuby) only; mruby/c (femtoruby) is not supported."
#endif
