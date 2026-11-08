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
#include "mruby/data.h"
#include "mruby/class.h"
#include <stdint.h>
#include <stdlib.h>

char *fmm_availability_check(void);
char *fmm_generate(const char *prompt, char **error_out);
void *fmm_session_new(const char *instructions);
void fmm_session_free(void *handle);
int32_t fmm_session_respond(void *handle, const char *prompt, int64_t timeout_ms, char **text_out);

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

static struct RClass *
fm_error_class(mrb_state *mrb, mrb_sym name)
{
  return mrb_class_get_under_id(mrb, mrb_module_get_id(mrb, MRB_SYM(FoundationModel)), name);
}

static void
fm_raise_with(mrb_state *mrb, struct RClass *klass, char *msg)
{
  mrb_value m = mrb_str_new_cstr(mrb, msg);
  free(msg);
  mrb_exc_raise(mrb, mrb_exc_new_str(mrb, klass, m));
}

/* Send the prompt to the on-device model and return its reply as a String. */
static mrb_value
mrb_fm_s_generate(mrb_state *mrb, mrb_value klass)
{
  const char *prompt;
  mrb_get_args(mrb, "z", &prompt);

  char *err = NULL;
  char *reply = fmm_generate(prompt, &err);
  if (err) fm_raise_with(mrb, fm_error_class(mrb, MRB_SYM(GenerationError)), err);
  mrb_value result = mrb_str_new_cstr(mrb, reply);
  free(reply);
  return result;
}

static void
fm_session_free(mrb_state *mrb, void *handle)
{
  if (handle) fmm_session_free(handle);
}

static const struct mrb_data_type fm_session_type = { "FoundationModel::Session", fm_session_free };

static mrb_value
mrb_fm_session_open(mrb_state *mrb, mrb_value self)
{
  const char *instructions;
  mrb_get_args(mrb, "z!", &instructions);
  void *old = DATA_PTR(self);
  if (old) fmm_session_free(old);
  mrb_data_init(self, fmm_session_new(instructions), &fm_session_type);
  return self;
}

static mrb_value
mrb_fm_session_respond(mrb_state *mrb, mrb_value self)
{
  const char *prompt;
  mrb_int timeout_ms;
  mrb_get_args(mrb, "zi", &prompt, &timeout_ms);
  void *handle = mrb_data_get_ptr(mrb, self, &fm_session_type);
  if (!handle) mrb_raise(mrb, E_RUNTIME_ERROR, "session is not open");

  char *text = NULL;
  int32_t status = fmm_session_respond(handle, prompt, (int64_t)timeout_ms, &text);
  if (status == 2) {
    mrb_raisef(mrb, fm_error_class(mrb, MRB_SYM(TimeoutError)), "no reply within %i ms", timeout_ms);
  }
  if (status != 0) fm_raise_with(mrb, fm_error_class(mrb, MRB_SYM(GenerationError)), text);
  mrb_value result = mrb_str_new_cstr(mrb, text);
  free(text);
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

  struct RClass *class_Session = mrb_define_class_under_id(mrb, module_FM, MRB_SYM(Session), mrb->object_class);
  MRB_SET_INSTANCE_TT(class_Session, MRB_TT_CDATA);
  mrb_define_method_id(mrb, class_Session, MRB_SYM(_open), mrb_fm_session_open, MRB_ARGS_REQ(1));
  mrb_define_method_id(mrb, class_Session, MRB_SYM(_respond), mrb_fm_session_respond, MRB_ARGS_REQ(2));
}

void
mrb_picoruby_foundation_model_gem_final(mrb_state *mrb)
{
}

#else
#error "picoruby-foundation-model targets the full mruby VM (MicroRuby) only; mruby/c (femtoruby) is not supported."
#endif
