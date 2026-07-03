#include <errno.h>
#include <stddef.h>
#include <string.h>
#include <sys/sysctl.h>

static int write_string(const char *value, void *oldp, size_t *oldlenp) {
  const size_t needed = strlen(value) + 1;
  if (oldlenp == NULL) {
    errno = EINVAL;
    return -1;
  }
  if (oldp == NULL) {
    *oldlenp = needed;
    return 0;
  }
  if (*oldlenp < needed) {
    *oldlenp = needed;
    errno = ENOMEM;
    return -1;
  }
  memcpy(oldp, value, needed);
  *oldlenp = needed;
  return 0;
}

static int write_int(int value, void *oldp, size_t *oldlenp) {
  if (oldlenp == NULL) {
    errno = EINVAL;
    return -1;
  }
  if (oldp == NULL) {
    *oldlenp = sizeof(value);
    return 0;
  }
  if (*oldlenp < sizeof(value)) {
    *oldlenp = sizeof(value);
    errno = ENOMEM;
    return -1;
  }
  memcpy(oldp, &value, sizeof(value));
  *oldlenp = sizeof(value);
  return 0;
}

static int shim_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
  (void)newp;
  (void)newlen;

  if (name == NULL) {
    errno = EINVAL;
    return -1;
  }
  if (strcmp(name, "machdep.cpu.vendor") == 0) {
    return write_string("GenuineIntel", oldp, oldlenp);
  }
  if (strcmp(name, "machdep.cpu.brand_string") == 0) {
    return write_string("Intel(R) Core(TM) CPU", oldp, oldlenp);
  }
  if (strcmp(name, "machdep.cpu.features") == 0) {
    return write_string("FPU VME DE PSE TSC MSR PAE MCE CX8 APIC SEP MTRR PGE MCA CMOV PAT PSE36 CLFSH MMX FXSR SSE SSE2 SSSE3 SSE4.1 SSE4.2", oldp, oldlenp);
  }
  if (strcmp(name, "machdep.cpu.leaf7_features") == 0) {
    return write_string("", oldp, oldlenp);
  }
  if (strcmp(name, "hw.logicalcpu") == 0 || strcmp(name, "hw.physicalcpu") == 0) {
    return write_int(4, oldp, oldlenp);
  }

  errno = ENOENT;
  return -1;
}

struct interpose_entry {
  const void *replacement;
  const void *replacee;
};

__attribute__((used)) static const struct interpose_entry interposers[]
    __attribute__((section("__DATA,__interpose"))) = {
        {(const void *)shim_sysctlbyname, (const void *)sysctlbyname},
};
