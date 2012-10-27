# HOST PLATFORM DETECTION
ifeq "$(OS)" "Windows_NT"
   HOST_PLATFORM := win32
   WINDOWS_HOST := defined
else
ifeq "$(OSTYPE)" "FreeBSD"
# tocheck: temporarily using linux when on bsd
#   HOST_PLATFORM := bsd
#   BSD_HOST := defined
   HOST_PLATFORM := linux
   LINUX_HOST := defined
else
ifeq "$(shell uname)" "Darwin"
   HOST_PLATFORM := apple
   OSX_HOST := defined
else
   HOST_PLATFORM := linux
   LINUX_HOST := defined
endif
endif

UNAME_P := $(shell uname -p)
ifeq ($(UNAME_P),x86_64)
  HOST_ARCH = X64
else
ifneq ($(filter %86,$(UNAME_P)),)
  HOST_ARCH = X86
else
ifneq ($(filter arm%,$(UNAME_P)),)
  HOST_ARCH = ARM
endif
endif
endif
endif

# TARGET_PLATFORM
ifndef TARGET_PLATFORM
ifdef PLATFORM
   TARGET_PLATFORM := $(PLATFORM)
endif
endif
ifndef TARGET_PLATFORM
ifdef WINDOWS_HOST
   TARGET_PLATFORM := win32
else
ifdef OSX_HOST
   TARGET_PLATFORM := apple
else
ifdef BSD_HOST
   TARGET_PLATFORM := bsd
else
   TARGET_PLATFORM := linux
endif
endif
endif
endif
ifndef PLATFORM
   PLATFORM := $(TARGET_PLATFORM)
endif
ifeq "$(TARGET_PLATFORM)" "win32"
   WINDOWS_TARGET := defined
else
ifeq "$(TARGET_PLATFORM)" "apple"
   OSX_TARGET := defined
else
ifeq "$(TARGET_PLATFORM)" "bsd"
   BSD_TARGET := defined
else
   LINUX_TARGET := defined
endif
endif
endif

# DEBUG SUFFIX
ifdef DEBUG
DEBUG_SUFFIX := .debug
endif

ifdef COMPILER
ifneq "$(COMPILER)" "default"
COMPILER_SUFFIX := .$(COMPILER)
endif
endif

# MISC STRING TOOLS
empty :=
space := $(empty) $(empty)
escspace = $(subst $(space),\$(space),$(subst \$(space),$(space),$1))
hidspace = $(subst $(space),,$(subst \$(space),,$1))
shwspace = $(subst ,\$(space),$1)

# PATH SEPARATOR STRING TOOLS
ifdef WINDOWS_HOST
ifndef MSYSCON
   WIN_PS_TOOLS := defined
endif
endif
ifdef WIN_PS_TOOLS
   fixps = $(subst \,/,$(1))
   psep = $(subst \\,/,$(subst /,\,$(1)))
   PS := $(strip \)
else
   fixps = $(1)
   PS := $(strip /)
   psep = $(1)
endif

# PREFIXES AND EXTENSIONS
.SUFFIXES: .c .ec .sym .imp .bowl .o .a
EC := .ec
S := .sym
I := .imp
B := .bowl
C := .c
O := .o
A := .a
ifdef WINDOWS_TARGET
   E := .exe
ifeq "$(TARGET_TYPE)" "staticlib"
   LP := lib
else
   LP :=
endif
   SO := .dll
else
ifdef OSX_TARGET
   E :=
   LP := lib
   SO := .dylib
else
   E :=
   LP := lib
   SO := .so
endif
endif

# SUPER TOOLS
ifdef CCACHE
   CCACHE_COMPILE := ccache
ifdef DISTCC
   DISTCC_COMPILE := distcc
endif
else
ifdef DISTCC
   DISTCC_COMPILE := distcc
endif
endif

# SHELL COMMANDS
ifdef WINDOWS_HOST
ifndef MSYSCON
   WIN_SHELL_COMMANDS := defined
endif
endif
ifdef WIN_SHELL_COMMANDS
   echo = $(if $(1),echo $(1))
   cpq = $(if $(1),@cmd /c for %%I in ($(call psep,$(1))) do @copy /y %%I $(call psep,$(2)) > nul 2>&1)
   rmq = $(if $(1),-@del /f /q $(call psep,$(1)) > nul 2>&1)
   rmrq = $(if $(1),-@rmdir /q /s $(call psep,$(1)) > nul 2>&1)
   mkdirq = $(if $(1),-@mkdir $(call psep,$(1)) > nul 2>&1)
   rmdirq = $(if $(1),-@rmdir /q $(call psep,$(1)) > nul 2>&1)
else
   echo = $(if $(1),echo "$(1)")
   cpq = $(if $(1),@cp $(1) $(2))
   rmq = $(if $(1),-@rm -f $(1))
   rmrq = $(if $(1),-@rm -f -r $(1))
   mkdirq = $(if $(1),-@mkdir -p $(1))
   rmdirq = $(if $(1),-@rmdir $(1))
endif

# COMPILER OPTIONS
ifeq "$(TARGET_TYPE)" "sharedlib"
   ECSLIBOPT := -dynamiclib
else
ifeq "$(TARGET_TYPE)" "staticlib"
   ECSLIBOPT := -staticlib
else
   ECSLIBOPT :=
endif
endif
ifdef WINDOWS_TARGET
   FVISIBILITY :=
   FPIC :=
ifeq "$(TARGET_TYPE)" "executable"
   EXECUTABLE := $(CONSOLE)
else
   EXECUTABLE :=
endif
else
   FVISIBILITY := -fvisibility=hidden
   FPIC := -fPIC
   EXECUTABLE :=
endif
ifdef OSX
ifeq "$(TARGET_TYPE)" "sharedlib"
   INSTALLNAME := -install_name $(LP)$(MODULE)$(SO)
else
   INSTALLNAME :=
endif
else
   INSTALLNAME :=
endif

# LINKER OPTIONS
ifdef OSX
ifeq "$(TARGET_TYPE)" "sharedlib"
   SHAREDLIB := -dynamiclib -single_module -multiply_defined suppress
   LINKOPT :=
else
   SHAREDLIB :=
   LINKOPT :=
endif
ifeq "$(TARGET_TYPE)" "sharedlib"
   STRIPOPT := -x
else
   STRIPOPT := -u -r
endif
else
ifeq "$(TARGET_TYPE)" "sharedlib"
   SHAREDLIB := -shared
else
   SHAREDLIB :=
endif
   LINKOPT :=
   STRIPOPT := -x --strip-unneeded --remove-section=.comment --remove-section=.note
endif
ifdef WINDOWS_TARGET
   SODESTDIR := obj/$(TARGET_PLATFORM)/bin/
else
   SODESTDIR := obj/$(TARGET_PLATFORM)/lib/
endif

_L = $(if $(filter $(1),$(EXCLUDED_LIBS)),,-l$(1))

# DEBIAN
ifdef DEBIAN_PACKAGE
OFLAGS += $(LDFLAGS)
endif

# COMMON LIBRARIES DETECTION

ifdef WINDOWS_TARGET

ifdef OPENSSL_CONF
_OPENSSL_CONF = $(call hidspace,$(call fixps,$(OPENSSL_CONF)))
OPENSSL_INCLUDE_DIR = $(call shwspace,$(subst /bin/openssl.cfg,/include,$(_OPENSSL_CONF)))
OPENSSL_LIB_DIR = $(call shwspace,$(subst /bin/openssl.cfg,/lib,$(_OPENSSL_CONF)))
OPENSSL_BIN_DIR = $(call shwspace,$(subst /bin/openssl.cfg,/bin,$(_OPENSSL_CONF)))
else
# to avoid issues with empty -L/-I
OPENSSL_INCLUDE_DIR = .
OPENSSL_LIB_DIR = .
OPENSSL_BIN_DIR = .
endif

else

OFLAGS += -L/usr/lib/ec

endif
