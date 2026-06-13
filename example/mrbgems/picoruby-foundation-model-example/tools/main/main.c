/* Single-binary entry point: open the VM and exit.
 *
 * picorb_vm_init() runs every gem's init, and a gem's mrblib top-level code
 * executes at init time. The app lives in this gem's mrblib/app.rb, so it runs
 * here — no script file at runtime, no explicit run call. The Apple Intelligence
 * binding is statically linked, so this is a self-contained binary. */
#include "picoruby.h"
#include <stdint.h>

#ifndef HEAP_SIZE
#define HEAP_SIZE (1024 * 6400 - 1)
#endif
static uint8_t vm_heap[HEAP_SIZE];

/* The runtime references this global VM handle (so does picorb_vm_init). */
mrb_state *global_mrb = NULL;

int
main(int argc, char **argv)
{
  mrb_state *vm = NULL;
  picorb_vm_init();   /* opens the VM and runs gem inits, including app.rb */
  /* picoruby's own runner leaves the VM open at exit (see picoruby.c cleanup);
   * the process is exiting anyway, so we do the same and skip mrb_close. */
  return 0;
}
