# HOST PLATFORM DETECTION
ifeq ($(OS),Windows_NT)
   HOST_PLATFORM := win32
   WINDOWS_HOST := defined
else
 _UNAME := $(shell uname)
 UNAME_P := $(shell uname -p)
 ifeq ($(_UNAME),FreeBSD)
 # Using Linux platform for Unix OSes for now
 #   HOST_PLATFORM := bsd
    BSD_HOST := defined
    HOST_PLATFORM := linux
    LINUX_HOST := defined
 else
  ifeq ($(_UNAME),Darwin)
     HOST_PLATFORM := apple
     OSX_HOST := defined
  else
     HOST_PLATFORM := linux
     LINUX_HOST := defined
  endif
 endif
 HOST_ARCH := $(UNAME_P)
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
#ifdef BSD_HOST
#   TARGET_PLATFORM := bsd
#else
   TARGET_PLATFORM := linux
ifdef BSD_HOST
   BSD_TARGET := defined
endif
#endif
endif
endif
endif
ifndef PLATFORM
   PLATFORM := $(TARGET_PLATFORM)
endif
ifeq ($(TARGET_PLATFORM),win32)
   WINDOWS_TARGET := defined
else
ifeq ($(TARGET_PLATFORM),apple)
   OSX_TARGET := defined
else
#ifeq ($(TARGET_PLATFORM),bsd)
#   BSD_TARGET := defined
#else
   LINUX_TARGET := defined
#endif
endif
endif

# CROSS_TARGET
ifneq ($(TARGET_PLATFORM),$(HOST_PLATFORM))
   CROSS_TARGET := defined
endif

# TARGET_TYPE
ifeq ($(TARGET_TYPE),staticlib)
   STATIC_LIBRARY_TARGET := defined
else
ifeq ($(TARGET_TYPE),sharedlib)
   SHARED_LIBRARY_TARGET := defined
else
ifeq ($(TARGET_TYPE),executable)
   EXECUTABLE_TARGET := defined
endif
endif
endif

ifeq ($(GCC_PREFIX),i586-mingw32msvc-)
export ARCH
ARCH := x32
endif

ifeq ($(GCC_PREFIX),i686-w64-mingw32-)
export ARCH
ARCH := x32
endif

# Accept different things for ARCH but standardize on x32/x64
# This will be used for object directories
ifdef ARCH
 ifeq ($(ARCH),32)
  override ARCH := x32
 endif
 ifeq ($(ARCH),x86)
  override ARCH := x32
 endif
 ifeq ($(ARCH),i386)
  override ARCH := x32
 endif
 ifeq ($(ARCH),i686)
  override ARCH := x32
 endif
 ifeq ($(ARCH),64)
  override ARCH := x64
 endif
 ifeq ($(ARCH),amd64)
  override ARCH := x64
 endif
 ifeq ($(ARCH),x86_64)
  override ARCH := x64
 endif

 # Set ARCH_FLAGS only if ARCH is set
 ifeq ($(ARCH),x64)
  TARGET_ARCH := x86_64
  ARCH_FLAGS := -m64
 endif
 ifeq ($(ARCH),x32)
  TARGET_ARCH := i386
  ARCH_FLAGS := -m32
 endif

 ARCH_SUFFIX := .$(ARCH)

 ifdef LINUX_TARGET
  TARGET_ARCH := $(TARGET_ARCH)-linux-gnu
 endif

endif

# On Windows/32 bit systems, pass -m32 as TDM-GCC packaged with the installer produces 64 bit executables by default
# Disable this if your compiler does not accept -m32
ifndef ARCH
 ifeq ($(HOST_PLATFORM),win32)
  ifeq ($(TARGET_PLATFORM),win32)
   ifndef ProgramFiles(x86)
    ARCH := x32
    TARGET_ARCH := i386
    ARCH_FLAGS := -m32
   endif
  endif
 endif
endif

# DEBUG SUFFIX
ifdef DEBUG
DEBUG_SUFFIX := .debug
endif

# COMPILER SUFFIX
COMPILER_SUFFIX = $(ARCH_SUFFIX)
ifdef COMPILER
ifneq ($(COMPILER),default)
COMPILER_SUFFIX = .$(COMPILER)$(ARCH_SUFFIX)
endif
endif

# STRING TOOLS
empty :=
esc := $(empty)$(empty)
space := $(empty) $(empty)
comma := ,
quote := "
slash := $(empty)/$(empty)
backslash := $(empty)\$(empty)
escspace = $(subst $(space),$(backslash)$(space),$(subst $(backslash)$(space),$(space),$(1)))
hidspace = $(subst $(space),$(esc),$(subst $(backslash)$(space),$(esc),$(1)))
shwspace = $(subst $(esc),$(backslash)$(space),$(1))
unescp_all = $(subst $(esc),$(backslash),$(subst $(backslash),,$(subst $(backslash)$(backslash),$(esc),$(1))))
path = $(call fp_encode,$(1))

# HIDDEN SPACE STRING TOOLS
temporaty_token := _+;:;+_:;+;:_:+;+:_
hidden_space := $(empty)$(empty)
hs_hide = $(subst $(space),$(hidden_space),$(1))
hs_unhide = $(subst $(hidden_space),$(space),$(1))
hs_escape = $(subst $(hidden_space),$(backslash)$(space),$(1))
hs_process = $(subst $(space),$(hidden_space),$(subst $(backslash)$(space),$(hidden_space),$(1)))
hs_quote_all = $(foreach item,$(1),"$(call hs_unhide,$(item))")
hs_quote_each = $(foreach item,$(1),$(if $(findstring $(esc),$(item)),"$(call hs_unhide,$(item))",$(item)))



list_match_dir = $(foreach path,$(2),$(if $(filter-out $(1),$(dir $(path))),,$(path)))
list_match_sufx_dir = $(foreach path,$(3),$(if $(filter-out $(2),$(dir $(path))),,$(if $(filter-out $(1),$(suffix $(path))),,$(path))))
list_src_to_obj = $(addprefix $(OBJ),$(patsubst %$(1),%$(2),$(notdir $(3))))

list_match_src_dir_objs = $(patsubst %.c,%$(O),$(foreach path,$(2),$(if $(filter-out $(srcdir)$(1),$(dir $(path))),,$(OBJ)$(notdir $(path)))))


# MATH TOOLS
ifdef WIN_SHELL_COMMANDS
   # todo: see if we can't use a common function for escaping
   escape_chars_for_cmd = $(subst %,^%,$(subst <,^<,$(subst >,^>,$(subst &,^&,$(subst |,^|,$(subst ^,^^,$(1)))))))
   math = $(shell CMD /C "SET /A $(call escape_chars_for_cmd,$(1)"))
else
   math = $(shell $(1))
endif

ifdef _______HEAD
# FILE PATH TOOLS
fp_encode = $(call hidspace,$(call fp_unquote,$(1)))
#fp_encode = $(subst $(space),$(esc),$(subst $(backslash)$(space),$(esc),$(1))) old encode? same code?
fp_decode = $(call shwspace,$(1))
fp_unquote = $(subst $(quote),,$(1))
fp_opt_quotes = $(if $(findstring $(space),$(1)),"$(1)",$(1))
fp_no_parent_dir = $(foreach item,$(1),$(if $(findstring ..,$(item)),,$(item)))

# EACH PATH FUNCTIONS -- FILE PATH FUNCTIONS TO BE USED WITH FOREACH AND _PATH VARIABLE NAME
# i.e.: $(foreach _path,$(1),$(ep_wildcard))
ep_decode_syspath_quote = $(call fp_opt_quotes,$(call sys_path,$(call unescp_all,$(call fp_decode,$(_path)))))
ep_wildcard = $(if $(wildcard $(call fp_decode,$(_path))),$(_path),)
ep_unwildcard = $(if $(wildcard $(call fp_decode,$(_path))),,$(_path))

# PATH LISTS FUNCTIONS
pl_decode = $(foreach _path,$(1),$(ep_decode_syspath_quote))
pl_wildcard = $(foreach _path,$(1),$(ep_wildcard))
pl_unwildcard = $(foreach _path,$(1),$(ep_unwildcard))
pl_wildcard_some = $(if $(1),$(if $(subst $(space),,$(call pl_wildcard,$(1))),some,),)
pl_unwildcard_some = $(if $(1),$(if $(subst $(space),,$(call pl_unwildcard,$(1))),some,),)


# FILE SYSTEM TOOLS
# hs_ls doc
#     usage: $(hs_ls) | $(hs_ls_dir) | $(hs_ls_files)
#     result:
#      -      for hs_ls: a list of files and directories in the current dir
#                        i.e.: fileA dir1/ fileB fileC dir2/ dir3/
#      -  for hs_ls_dir: a list of directories in the current dir
#                        i.e.: dir1 dir2 dir3
#      - for hs_ls_file: a list of files in the current dir
#                        i.e.: fileA fileB fileC
#     notes:
#      - hs_ls* functions work in current dir, you can't specify a directory
#      - hs_ls* functions do not report hidden files and directories because wildcard doesn't
#        you would never get such a list: .fileA .dir1/
hs_ls = $(subst $(temporaty_token),$(space),$(subst ./,,$(call hs_hide,$(subst $(space)./,$(temporaty_token),$(wildcard ./*/)))))
hs_ls_dir = $(subst /,,$(foreach item,$(hs_ls),$(if $(findstring /,$(item)),$(item),)))
hs_ls_file = $(foreach item,$(hs_ls),$(if $(findstring /,$(item)),,$(item)))
# find_parent_dir_with_file usage: $(call find_parent_dir_with_file,<file-name>,<start-dir>,<max-depth>)
find_parent_dir_with_file = $(if $(wildcard $(2)$(1)),$(2),$(if $(3),$(if $(subst 0,,$(3)),$(call find_parent_dir_with_file,$(1),$(2)../,$(call math,$(3)-1)),),))

# CONTROL FLOW TOOLS
# hs_crossloop usage: $(call hs_crossloop,<list>,<command_function>)
#                     hs_crossloop will call <command_function> with the item as first parameter ($(1))
hs_crossloop = $(call hs_unsafe_crossloop,$(call fp_no_parent_dir,$(1)),$(2))

# PATH SEPARATOR STRING TOOLS
ifdef WINDOWS_HOST
   ifneq ($(TERM),cygwin)
      ifndef MSYSCON
         WIN_PS_TOOLS := defined
      endif
   endif
endif
slash_path = $(subst $(backslash),$(slash),$(1))
ifdef WIN_PS_TOOLS
   psep := $(backslash)
   sys_path = $(subst $(backslash)$(backslash),$(slash),$(subst $(slash),$(backslash),$(1)))
   quote_path = "$(call sys_path,$(call unescp_all,$(1)))"
   each_path_quote = $(if $(findstring $(esc),$(_path)),"$(call unescp_all,$(call shwspace,$(_path)))",$(call unescp_all,$(_path)))
   sys_path_list = $(foreach _path,$(1),$(each_path_quote))
endif
# find_parent_dir_with_file usage: $(call find_parent_dir_with_file,<file-name>,<start-dir>,<max-depth>)
find_parent_dir_with_file = $(if $(wildcard $(2)$(1)),$(2),$(if $(3),$(if $(subst 0,,$(3)),$(call find_parent_dir_with_file,$(1),$(2)../,$(call math,$(3)-1)),),))

# TOOLS DOC
#
#     Function Name                    Description
#
#
#     va_*                             Basic Variables (No Parameters)
#
#     va_empty                            Empty Variable
#
#     va_numbers                          List of Numbers from 0 to 9
#
#
#     ch_*                             Characters (Single or Multiple, No Parameters)
#
#                                         Slash Chars
#
#     ch_slash                               Forward Slash
#     ch_backslash                           Backward Slash
#
#                                         Space Chars
#
#     ch_lit_space                           Literal Space
#     ch_enc_space                           Encoded Space
#     ch_esc_space                           Escaped Space
#
#                                         Special Chars
#
#     ch_enc_token                           Single Char Swap Token
#
#     ch_tmp_token                           Temporary Token
#                                               note: a non clashing temporary token used to
#                                                     do string manipulations
#
#     st_*                             String Functions
#
#     st_space_esc_enc(string)            Substitute Escaped Space By Encoded Space
#     st_space_lit_enc(string)            Substitute Literal Space By Encoded Space
#     st_space_enc_lit(string)            Substitute Encoded Space By Literal Space
#     st_space_enc_esc(string)            Substitute Encoded Space By Escaped Space
#     st_slash_bac_frw(string)            Substitute Backward Slash By Forward Slash
#     st_unquote(string)                  Remove Double Quotes Around String
#                                            i.e.: "my str" -> my str
#                                            i.e.: "my "special" str" -> my "special" str
#     st_quote(string[, force])           Add Double Quotes Around String
#                                            i.e.:  ->
#                                            i.e.: "" ->
#                                            i.e.: my -> my
#                                            i.e.: my str -> "my str"
#                                            i.e.: "my" -> my
#                                            i.e.: "my str" -> "my str"
#                                          when forcing...
#                                            i.e.:  -> ""
#                                            i.e.: "" -> ""
#                                            i.e.: my -> "my"
#                                            i.e.: my str -> "my str"
#                                            i.e.: "my" -> "my"
#                                            i.e.: "my str" -> "my str"
#
#     st_unescp_all                       todo... remove all \ chars that are used to escape special chars, etc?
#
#     st_spc_numbers(string)
#     st_has_numbers(string)
#     st_is_number(string)
#
#
#     li_*                             List Functions
#
#     li_reverse(list)                 Reverse List
#
#     li_split_path(path)              split path into it's parts, return as a list
#
#     fp_*                             File System Path Functions
#
#     fp_enc                              Encode File System Path
#                                            function: take a single path potentialy provided by the user and encode it in strict internal format usable in lists
#                                                      it should have no problem taking a string that is already encoded
#                                            i.e.: C:\path to\some dir or file -> C:/path~to/some~dir~or~file
#                                            i.e.: C:/my/ path/ -> C:/my~path/
#                                            i.e.: "C:/path/" -> C:/path/
#                                            i.e.: C:/my~path/ -> C:/my~path/
#                                            note: ~ represents ch_enc_space
#                                            tofix: need to unescape all other possible escaped chars before calling st_slash_bac_frw
#
#
#     fp_dec_xxxxxxxx                     Decode File System Path For Xxxxxxxx Use
#
#     fp_dec_esc(enc-path)                Decode File System Path For Escaped Space Use
#
#     fp_sys                              make a sys path from an encoded path
#
#     fp_quote                            get a quoted path from a path (which might be encoded) provided by make
#
#
#     pl_*                             File System Path List Functions
#
#     pl_ls                               Get Path List of Entries in Current Directory
#                                            result: a list of files and directories in the current dir
#                                               i.e.: fileA dir1/ fileB fileC dir2/ dir3/
#     pl_ls_dir                           Get Path List of Directories in Current Directory
#                                            result: a list of directories in the current dir
#                                               i.e.: dir1 dir2 dir3
#     pl_ls_files                         Get Path List of Files in Current Directory
#                                            result: a list of files in the current dir
#                                               i.e.: fileA fileB fileC
#                                            usage: $(pl_ls) | $(pl_ls_dir) | $(pl_ls_files)
#                                            notes:
#                                             - pl_ls* functions return a list of paths (with encoded spaces)
#                                             - pl_ls* functions work in current dir, you can't specify a directory
#                                             - pl_ls* functions do not report hidden files and directories because wildcard doesn't
#                                               you would never get such a list: .fileA .dir1/
#
#     pl_no_parent(path-list)             Remove Any Parent Path from Path List
#
#     pl_dec_quote(path-list[, force])    Add Double Quotes Around Each Path from Path List and Decode Escaped Space to Literal
#
#     pl_call_on_each(path-list, func)    Call Arbitrary Function on Each Path from Path List
#                                            usage: $(call pl_call_on_each,<list>,<command_function>)
#                                            desc: pl_call_on_each will call <command_function> with the item as first parameter ($(1))
#
#
#
#     pl_wildcard(path-list)              Call Wildcard on Each Path from Path List
#
#     pl_sys_quote(path-list)             convert to a list of quoted sys paths
#
#
#     ex_*                             Extra Miscellaneous Functions
#
#
#     note: all these variables and functions are usable from makefiles that include crossplatform.mk
#
#


va_empty :=
va_numbers := 0 1 2 3 4 5 6 7 8 9


ch_slash := $(va_empty)/$(va_empty)
ch_backslash := $(va_empty)\$(va_empty)
ch_lit_space := $(va_empty) $(va_empty)
ch_enc_space := $(va_empty)$(va_empty)
ch_esc_space := $(ch_backslash)$(ch_lit_space)
ch_enc_token := $(ch_enc_space)
ch_tmp_token := _+;:;+_:;+;:_:+;+:_


# backward compatibility
quote_path = $(call fp_quote,$(1))
# these are a bit old, keep their names or rename them? (st_*)
escspace = $(subst $(ch_lit_space),$(ch_backslash)$(ch_lit_space),$(subst $(ch_backslash)$(ch_lit_space),$(ch_lit_space),$(1)))
hidspace = $(subst $(ch_lit_space),$(ch_enc_space),$(subst $(ch_backslash)$(ch_lit_space),$(ch_enc_space),$(1)))
shwspace = $(subst $(ch_enc_space),$(ch_backslash)$(ch_lit_space),$(1))


# CHANGES TO OLD TOOLS -- MUST UPDATE THIS COMMIT

# following old hidspace function -- hidspace = $(subst $(space),$(esc),$(subst $(backslash)$(space),$(esc),$(1)))
hidescspace = $(subst $(backslash)$(space),$(esc),$(1))
# following old shwspace function -- shwspace = $(subst $(esc),$(backslash)$(space),$(1))
shwspacequoted = $(subst $(esc),"$(space)",$(subst \$(space),$(esc),$(1)))
# following old unescp_all function -- unescp_all = $(subst $(esc),$(backslash),$(subst $(backslash),,$(subst $(backslash)$(backslash),$(esc),$(1))))
for_list = $(call sys_path,$(call unescp_all,$(call shwspacequoted,$(subst $(space),$(comma),$(subst $(space)$(space),$(space),$(call hidescspace,$(1)))))))
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))
ifdef WIN_PS_TOOLS
# replacing old sys_path function -- sys_path = $(subst $(backslash)$(backslash),$(slash),$(subst $(slash),$(backslash),$(1)))
   esc_ampersand = $(subst &,^&,$(subst ^&,&,$(1)))
   sys_path = $(call esc_ampersand,$(subst $(backslash)$(backslash),$(slash),$(subst $(slash),$(backslash),$(1))))
   each_quote_path = $(call quote_path,$(path))
endif
# following old quote_path function -- quote_path = "$(call sys_path,$(call unescp_all,$(1)))"
#   each_path_quote = $(if $(findstring $(esc),$(path)),"$(call sys_path,$(call unescp_all,$(call shwspace,$(path))))",$(call sys_path,$(call unescp_all,$(path))))
# following old each_path_quote function -- each_path_quote = $(if $(findstring $(esc),$(path)),"$(call unescp_all,$(call shwspace,$(path)))",$(call unescp_all,$(path)))
#   sys_path_list


st_space_esc_enc = $(subst $(ch_esc_space),$(ch_enc_space),$(1))
st_space_esc_lit = $(subst $(ch_esc_space),$(ch_lit_space),$(1))
st_space_lit_enc = $(subst $(ch_lit_space),$(ch_enc_space),$(1))
st_space_enc_lit = $(subst $(ch_enc_space),$(ch_lit_space),$(1))
st_space_enc_esc = $(subst $(ch_enc_space),$(ch_esc_space),$(1))
st_slash_bac_frw = $(subst $(ch_backslash),$(ch_slash),$(1))
st_unquote = $(subst $(ch_tmp_token),,$(call _st_unquote_head,$(call _st_unquote_tail,$(1))))
   _st_unquote_head = $(subst $(ch_tmp_token)",,$(ch_tmp_token)$(1))
   _st_unquote_tail = $(subst "$(ch_tmp_token),,$(1)$(ch_tmp_token))
st_quote = $(if $(if $(2),$(2),$(findstring $(ch_lit_space),$(1))),$(subst $(ch_tmp_token),,$(call _st_quote_head,$(call _st_quote_tail,$(1)))),$(call st_unquote,$(1)))
   _st_quote_head = $(subst $(ch_tmp_token)"",",$(ch_tmp_token)"$(1))
   _st_quote_tail = $(subst ""$(ch_tmp_token),",$(1)"$(ch_tmp_token))
st_unescp_all = $(subst $(ch_enc_token),$(ch_backslash),$(subst $(ch_backslash),,$(subst $(ch_backslash)$(ch_backslash),$(ch_enc_token),$(1))))
st_spc_numbers = $(subst 0,$(ch_lit_space)0$(ch_lit_space),$(subst 1,$(ch_lit_space)1$(ch_lit_space),$(subst 2,$(ch_lit_space)2$(ch_lit_space),$(subst 3,$(ch_lit_space)3$(ch_lit_space),$(subst 4,$(ch_lit_space)4$(ch_lit_space),$(subst 5,$(ch_lit_space)5$(ch_lit_space),$(subst 6,$(ch_lit_space)6$(ch_lit_space),$(subst 7,$(ch_lit_space)7$(ch_lit_space),$(subst 8,$(ch_lit_space)8$(ch_lit_space),$(subst 9,$(ch_lit_space)9$(ch_lit_space),$(1)))))))))))
st_has_numbers = $(if $(filter $(va_numbers),$(call st_spc_numbers,$(1))),$(1),)
st_is_number = $(if $(filter-out $(va_numbers),$(call st_spc_numbers,$(1))),,$(1))


li_reverse = $(if $(1),$(call li_reverse,$(strip $(wordlist 2,$(words $(1)),$(1))))) $(firstword $(1))
li_split_path = $(strip $(subst $(ch_slash),$(ch_lit_space),$(subst $(ch_backslash),$(ch_lit_space),$(1))))

# for fp_enc -- first decode literal in case of already encoded and then encode...
# check if this (fp_encode) is useful from a new note commit (3d417858d823376a7679978a22d52cd2a4adfd5a) on top of the old crossplatform.mk
# also see 'path' function above which makes use of fp_encode for a simple alias to wrote more readable $(call path,MY/PATH/) instead of fp_encode
# fp_encode = $(subst $(space),$(esc),$(subst $(backslash)$(space),$(esc),$(1)))
fp_enc = $(call st_slash_bac_frw,$(call st_space_lit_enc,$(call st_space_esc_lit,$(1))))
fp_dec_esc = $(call st_space_enc_esc,$(1))
#fp_dec_sys = $(call fp_quote,$(call st_unescp_all,$(1)))
fp_dec_sys = $(call st_quote,$(call fp_sys,$(call st_space_enc_lit,$(1))))
fp_wildcard = $(wildcard $(call fp_sys,$(call fp_dec_esc,$(1))))

fp_san_esc = $(call fp_dec_esc,$(call fp_enc,$(1)))
fp_san_sys = $(call fp_dec_esc,$(call fp_enc,$(1)))

# todo: see that each_path_wildcard = $(addprefix ./,$(wildcard $(path))) change for linux isn't lost
ifdef WIN_SHELL_COMMANDS
   fp_sys = $(subst $(ch_backslash)$(ch_backslash),$(ch_slash),$(subst $(ch_slash),$(ch_backslash),$(1)))
   fp_quote = "$(call fp_sys,$(call st_unescp_all,$(1)))"
else
   fp_sys = $(1)
   fp_quote = $(1)
endif


pl_ls = $(subst $(ch_tmp_token),$(ch_lit_space),$(subst ./,,$(call st_space_lit_enc,$(subst $(ch_lit_space)./,$(ch_tmp_token),$(wildcard ./*/)))))
pl_ls_dir = $(subst /,,$(foreach item,$(pl_ls),$(if $(findstring /,$(item)),$(item),)))
pl_ls_file = $(foreach item,$(pl_ls),$(if $(findstring /,$(item)),,$(item)))

pl_no_parent = $(foreach item,$(1),$(if $(findstring ..,$(item)),,$(item)))
pl_dec_quote = $(foreach item,$(1),$(if $(if $(2),$(2),$(findstring $(ch_enc_space),$(item))),"$(call st_space_enc_lit,$(item))",$(item)))

pl_call_on_each = $(call _pl_call_on_each_raw,$(call pl_no_parent,$(1)),$(2))

ifdef WIN_SHELL_COMMANDS
      _pl_call_on_each_raw = ${if $(1),${if $(2),@cmd /c "for %%I in (${call pl_dec_quote,$(1)}) do ${call $(2),%%I}",},}
   pl_wildcard = $(foreach item,$(1),$(wildcard $(call fp_dec_esc,$(item))))
   pl_sys_quote = $(foreach path,$(1),$(_pl_sys_quote_each))
      _pl_sys_quote_each = $(if $(findstring $(ch_enc_space),$(path)),"$(call st_unescp_all,$(call fp_dec_esc,$(path)))",$(call st_unescp_all,$(path)))
else
      _pl_call_on_each_raw = ${if $(1),${if $(2),for item in ${call pl_dec_quote,$(1)}; do ${call $(2),"$$item"}; done,},}
   pl_wildcard = $(foreach item,$(1),$(wildcard $(item)))
   pl_sys_quote = $(1)
endif

# cdmake = $(if $(if $(filter-out clean,$(filter-out cleantarget,$(filter-out realclean,$(2)))),$(if $(wildcard $(1)),do,),do),cd $(1) && $(_MAKE)$(if $(srcdir), srcdir=..\$(srcdir)$(1)\ -f ..\$(srcdir)$(1)\Makefile,)$(if $(2), $(2),),)
cdmake = $(if $(if $(find clean,$(2)),$(if $(wildcard $(1)),do,),do),cd $(1) && $(_MAKE)$(if $(srcdir), srcdir=../$(srcdir)$(1)/ -f ..\\$(srcdir)$(1)\\Makefile,)$(if $(2), $(2),),)
# cdmake = cd $(1) && $(_MAKE)$(if $(srcdir), srcdir=..\$(srcdir)$(1)\ -f ..\$(srcdir)$(1)\Makefile,)$(if $(2), $(2),)

# SHELL COMMANDS
ifdef WINDOWS_HOST
   ifneq ($(TERM),cygwin)
      ifndef MSYSCON
         WIN_SHELL_COMMANDS := defined
      endif
   endif
endif
ifdef V
   export V
endif
ifneq ($(V),1)
   SILENT_IS_ON := defined
endif
ifeq ($(D),1)
   DEBUG_IS_ON := defined
endif
addtolistfile = $(if $(1),@$(call echo,$(1)) >> $(2),)
ifdef WIN_SHELL_COMMANDS
   cd = @cd
   nullerror = 2>NUL
   echo = $(if $(1),echo $(1),echo.)
   cat = $(if $(1),type $(1))
   touch = $(if $(1),@cmd /c "for %%I in ($(call fp_sys,$(1))) do @(cd %%~pI && type nul >> %%~nxI && copy /by %%~nxI+,, > nul 2>&1 && cd %%cd%%)")
# 996-related would suggest cp and cpr should use for_list instead of sys_path or fp_sys in the list of files / dirs to be copied
# 996-related would suggest rm and rmr use $(foreach path,$(1),$(each_quote_path)) $(call sys_path,$(1) around the list of files to delete
   cp = $(if $(1),@cmd /c "for %%I in ($(call fp_sys,$(1))) do copy /by %%I $(call fp_dec_sys,$(2))"$(if $(SILENT_IS_ON), > nul,))
   cpr = $(if $(1),xcopy /y /i /e$(if $(SILENT_IS_ON), /q,) $(call fp_sys,$(call pl_sys_quote,$(1))) $(call fp_dec_sys,$(2))$(if $(SILENT_IS_ON), > nul,))
ifdef _______HEAD
   rm = $(if $(call pl_wildcard_some,$(1)),-del /f$(if $(SILENT_IS_ON), /q,) $(call fp_sys,$(call pl_sys_quote,$(call pl_wildcard,$(1))))$(if $(SILENT_IS_ON), > nul,),)
   rmr = $(if $(call pl_wildcard_some,$(1)),-rmdir /s /q $(call fp_sys,$(call pl_wildcard,$(1)))$(if $(SILENT_IS_ON), > nul,),)
   mkdir = $(if $(call pl_unwildcard_some,$(1)),-mkdir $(call pl_decode,$(call pl_unwildcard,$(1)))$(if $(SILENT_IS_ON), > nul,),)
   rmdir = $(if $(call pl_wildcard_some,$(1)),-rmdir /q $(call pl_decode,$(call pl_wildcard,$(1)))$(if $(SILENT_IS_ON), > nul,),)
   hs_unsafe_crossloop = ${if $(1),${if $(2),@cmd /c "for %%I in (${call hs_quote_each,$(1)}) do ${call $(2),%%I}",},}
endif
   rm = $(if $(call wildcard_check,$(1)),-del /f$(if $(SILENT_IS_ON), /q,) $(call fp_sys,$(call pl_sys_quote,$(call wildcard_list,$(1))))$(if $(SILENT_IS_ON), > nul,),)
   rmr = $(if $(call wildcard_check,$(1)),-rmdir /s /q $(call fp_sys,$(call wildcard_list,$(1)))$(if $(SILENT_IS_ON), > nul,),)
   mkdir = $(if $(call unwildcard_check,$(1)),-mkdir $(call fp_sys,$(call unwildcard_list,$(1)))$(if $(SILENT_IS_ON), > nul,),)
   rmdir = $(if $(call wildcard_check,$(1)),-rmdir /q $(call fp_sys,$(call wildcard_list,$(1)))$(if $(SILENT_IS_ON), > nul,),)
else
   cd = cd
   nullerror = 2>/dev/null
   echo = $(if $(1),echo "$(1)",echo)
   cat = $(if $(1),cat $(1))
   touch = $(if $(1),touch $(1))
   cp = $(if $(1),cp -P$(if $(SILENT_IS_ON),,v) $(1) $(2))
   cpr = $(if $(1),cp -PR$(if $(SILENT_IS_ON),,v) $(1) $(2))
ifdef _______HEAD
   rm = $(if $(call pl_wildcard_some,$(1)),-rm -f$(if $(SILENT_IS_ON),,v) $(call pl_wildcard,$(1)),)
   rmr = $(if $(call pl_wildcard_some,$(1)),-rm -fr$(if $(SILENT_IS_ON),,v) $(call pl_wildcard,$(1)),)
   mkdir = $(if $(call pl_unwildcard_some,$(1)),-mkdir -p$(if $(SILENT_IS_ON),,v) $(call pl_unwildcard,$(1)),)
   rmdir = $(if $(call pl_wildcard_some,$(1)),-rmdir$(if $(SILENT_IS_ON),, -v) $(call pl_wildcard,$(1)),)
   hs_unsafe_crossloop = ${if $(1),${if $(2),for item in ${call hs_quote_each,$(1)}; do ${call $(2),"$$item"}; done,},}
endif
   rm = $(if $(call wildcard_check,$(1)),-rm -f$(if $(SILENT_IS_ON),,v) $(call wildcard_list,$(1)),)
   rmr = $(if $(call wildcard_check,$(1)),-rm -fr$(if $(SILENT_IS_ON),,v) $(call wildcard_list,$(1)),)
   mkdir = $(if $(call unwildcard_check,$(1)),-mkdir -p$(if $(SILENT_IS_ON),,v) $(call unwildcard_list,$(1)),)
   rmdir = $(if $(call wildcard_check,$(1)),-rmdir$(if $(SILENT_IS_ON),, -v) $(call wildcard_list,$(1)),)
endif

locationversion = $(call fp_dev_esc,$(call _lv_dirwalker,$(call li_reverse,$(subst $(ch_lit_space)$(ch_lit_space),$(ch_lit_space),$(call li_split_path,$(call fp_enc,$(1)))))))
   _lv_issimplever = $(if $(call st_is_number,$(firstword $(call st_spc_numbers,$(subst .,,$(1))))),$(1),)
   _lv_isversionver = $(if $(call _lv_issimplever,$(1:v%=%)),$(1),$(if $(call _lv_issimplever,$(1:ver%=%)),$(1),$(if $(call _lv_issimplever,$(1:version%=%)),$(1),)))
   _lv_isreleasever = $(if $(call _lv_issimplever,$(1:r%=%)),$(1),$(if $(call _lv_issimplever,$(1:rel%=%)),$(1),$(if $(call _lv_issimplever,$(1:release%=%)),$(1),)))
   _lv_isbuildver = $(if $(call _lv_issimplever,$(1:b%=%)),$(1),$(if $(call _lv_issimplever,$(1:bld%=%)),$(1),$(if $(call _lv_issimplever,$(1:build%=%)),$(1),)))
   _lv_iscomplexver = $(if $(call _lv_isversionver,$(1)),$(1),$(if $(call _lv_isreleasever,$(1)),$(1),$(if $(call _lv_isbuildver,$(1)),$(1),)))
   _lv_isver = $(if $(call _lv_issimplever,$(1)),$(1),$(if $(call _lv_iscomplexver,$(1)),$(1),))
   _lv_possibleverorver = $(if $(findstring -,$(1)),$(if $(call st_has_numbers,$(1)),$(1),),$(if $(call _lv_isver,$(1)),$(1),))
   _lv_termslistfromdir = $(strip $(subst -,$(ch_lit_space),$(1)))
   _lv_verfromtermlist = $(if $(1)$(2),$(if $(1),$(1)$(if $(2),-,),)$(call _lv_verfromtermlist,$(firstword $(2)),$(wordlist 2,$(words $(2)),$(2))),)
   _lv_termwalker = $(if $(firstword $(1)),$(if $(call _lv_isver,$(firstword $(1))),$(call _lv_verfromtermlist,,$(1)),$(call _lv_termwalker,$(wordlist 2,$(words $(1)),$(1)))),)
   _lv_version = $(if $(call _lv_possibleverorver,$(1)),$(call _lv_termwalker,$(call _lv_termslistfromdir,$(1))),)
   _lv_dirwalker = $(if $(firstword $(1)),$(if $(call _lv_version,$(firstword $(1))),$(call _lv_version,$(firstword $(1))),$(call _lv_dirwalker,$(wordlist 2,$(words $(1)),$(1)))),)

# SOURCE CODE REPOSITORY VERSION
ifndef REPOSITORY_VER
   # TODO: support other VCS
   ifndef GIT_REPOSITORY
      ifndef GIT
         GIT := git
      endif
      ifeq ($(shell $(GIT) --version $(nullerror)),)
         export GIT_NA := $(GIT)NotAvailable
      else
         ifneq ($(shell $(GIT) log -n 1 --format="%%%%" $(nullerror)),)
            export GIT_REPOSITORY := yes
            export REPOSITORY_VER := $(shell $(GIT) describe --tags --dirty="-d" --always)
         endif
      endif
   endif
   ifndef REPOSITORY_VER
      DIR_VER := $(call locationversion,$(CURDIR))
      ifneq ($(DIR_VER),)
         export REPOSITORY_VER := $(DIR_VER)
      endif
   endif
   ifndef REPOSITORY_VER
      export REPOSITORY_VER := unknown
   endif
endif

# PREFIXES AND EXTENSIONS
EC := .ec
S := .sym
I := .imp
B := .bowl
C := .c
ifndef O
O := .o
endif
A := .a
E := $(if $(WINDOWS_TARGET),.exe,)
SO := $(if $(WINDOWS_TARGET),.dll,$(if $(OSX_TARGET),.dylib,.so))
LP := $(if $(WINDOWS_TARGET),$(if $(STATIC_LIBRARY_TARGET),lib,),lib)
HOST_E := $(if $(WINDOWS_HOST),.exe,)
HOST_SO := $(if $(WINDOWS_HOST),.dll,$(if $(OSX_HOST),.dylib,.so))
HOST_LP := $(if $(WINDOWS_HOST),$(if $(STATIC_LIBRARY_TARGET),lib,),lib)
.SUFFIXES: .c .ec .sym .imp .bowl $(O) $(A)

# TARGET VERSION
VER := $(if $(LINUX_TARGET),$(if $(LINUX_HOST),$(if $(VERSION),.$(VERSION),),),)

# SUPER TOOLS
ifdef CCACHE
   CCACHE_COMPILE := ccache$(ch_lit_space)
ifdef DISTCC
   DISTCC_COMPILE := distcc$(ch_lit_space)
endif
else
ifdef DISTCC
   DISTCC_COMPILE := distcc$(ch_lit_space)
endif
endif

_CPP = $(if $(findstring $(ch_lit_space),$(CPP)),"$(CPP)",$(CPP))

_SYSROOT = $(if $(SYSROOT),$(ch_lit_space)--sysroot=$(SYSROOT),)

_MAKE = $(call st_quote,$(MAKE))

# COMPILER OPTIONS
ECSLIBOPT := $(if $(STATIC_LIBRARY_TARGET),-staticlib,$(if $(SHARED_LIBRARY_TARGET),-dynamiclib,))
FVISIBILITY := $(if $(WINDOWS_TARGET),,-fvisibility=hidden)
FPIC := $(if $(WINDOWS_TARGET),,-fPIC)
EXECUTABLE := $(if $(WINDOWS_TARGET),$(if $(EXECUTABLE_TARGET),$(CONSOLE),),)
INSTALLNAME := $(if $(OSX_TARGET),$(if $(SHARED_LIBRARY_TARGET),-install_name $(LP)$(MODULE)$(SO),),)

# LINKER OPTIONS
SHAREDLIB := $(if $(SHARED_LIBRARY_TARGET),$(if $(OSX_TARGET),-dynamiclib -single_module -multiply_defined suppress,-shared),)
LINKOPT :=
STRIPOPT := $(if $(OSX_TARGET),$(if $(SHARED_LIBRARY_TARGET),-x, -u -r), -x --strip-unneeded --remove-section=.comment --remove-section=.note)
HOST_SODESTDIR := $(if $(WINDOWS_HOST),obj/$(HOST_PLATFORM)$(COMPILER_SUFFIX)$(DEBUG_SUFFIX)/bin/,obj/$(HOST_PLATFORM)$(COMPILER_SUFFIX)$(DEBUG_SUFFIX)/lib/)
SODESTDIR := $(if $(WINDOWS_TARGET),obj/$(TARGET_PLATFORM)$(COMPILER_SUFFIX)$(DEBUG_SUFFIX)/bin/,obj/$(TARGET_PLATFORM)$(COMPILER_SUFFIX)$(DEBUG_SUFFIX)/lib/)

# EXCLUDED_LIBS TOOL
_L = $(if $(filter $(1),$(EXCLUDED_LIBS)),,-l$(1))

# DEBIAN
ifdef DEBIAN_PACKAGE
CFLAGS += $(CPPFLAGS)
endif

ifdef DEBUG
CFLAGS += -D_DEBUG
endif

# COMMON LIBRARIES DETECTION
ifdef WINDOWS_TARGET
 ifdef OPENSSL_CONF
  _OPENSSL_CONF = $(call fp_enc,$(call slash_path,$(OPENSSL_CONF)))
  OPENSSL_INCLUDE_DIR = $(call fp_dec_esc,$(subst /bin/openssl.cfg,/include,$(_OPENSSL_CONF)))
  OPENSSL_LIB_DIR = $(call fp_dec_esc,$(subst /bin/openssl.cfg,/lib,$(_OPENSSL_CONF)))
  OPENSSL_BIN_DIR = $(call fp_dec_esc,$(subst /bin/openssl.cfg,/bin,$(_OPENSSL_CONF)))
 endif
endif

str_issimplever = $(if $(call isanumber,$(firstword $(call spacenumbers,$(subst .,,$(1))))),$(1),)
str_isversionver = $(if $(call str_issimplever,$(1:v%=%)),$(1),$(if $(call str_issimplever,$(1:ver%=%)),$(1),$(if $(call str_issimplever,$(1:version%=%)),$(1),)))
str_isreleasever = $(if $(call str_issimplever,$(1:r%=%)),$(1),$(if $(call str_issimplever,$(1:rel%=%)),$(1),$(if $(call str_issimplever,$(1:release%=%)),$(1),)))
str_isbuildver = $(if $(call str_issimplever,$(1:b%=%)),$(1),$(if $(call str_issimplever,$(1:bld%=%)),$(1),$(if $(call str_issimplever,$(1:build%=%)),$(1),)))
str_iscomplexver = $(if $(call str_isversionver,$(1)),$(1),$(if $(call str_isreleasever,$(1)),$(1),$(if $(call str_isbuildver,$(1)),$(1),)))
str_isver = $(if $(call str_issimplever,$(1)),$(1),$(if $(call str_iscomplexver,$(1)),$(1),))

dot := .

digits := 0 1 2 3 4 5 6 7 8 9
dotits := $(digits) $(dot)
uppers := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
lowers := a b c d e f g h i j k l m n o p q r s t u v w x y z
alphas := $(uppers) $(lowers)
alnums := $(digits) $(alphas)

true := T
false := $(empty)

despace = $(subst $(space),$(empty),$(1))
singlespace = $(subst $(space)$(space),$(space),$(1))
match = $(if $(and $(2),$(if $(filter-out $(1),$(2)),,$(true))),$(true),)
setcheck = $(call match,$(1),$(call despace,$(2)))
eachfind = $(call despace,$(foreach X,$(1),$(findstring $X,$(2))))
eachsubst = $(eval x__=$(2))$(if $(foreach X,$(1),$(eval x__=$(subst $X,$(space)$X$(space),$(x__)))),$(x__),$(x__))
eachtest = $(eval each_ret__=$(empty))$(if $(foreach X,$(2),$(info $X --> $(call $(1),$X))$(if $(each_ret__),,$(if $(call $(1),$X),$(eval each_ret__=$X),))),$(each_ret__),$(each_ret__))
eachtestfmt = $(call eachtest,$(1),$(2))$(if $(3),$(call $(3),$(each_ret__)),$(each_ret__))
spacedigits = $(strip $(call singlespace,$(call eachsubst,$(digits),$(1))))
spacedotits = $(strip $(call singlespace,$(call eachsubst,$(dotits),$(1))))
spaceuppers = $(strip $(call singlespace,$(call eachsubst,$(uppers),$(1))))
spacelowers = $(strip $(call singlespace,$(call eachsubst,$(lowers),$(1))))
spacealphas = $(strip $(call singlespace,$(call eachsubst,$(alphas),$(1))))
spacealnums = $(strip $(call singlespace,$(call eachsubst,$(alnums),$(1))))

#filterdotits = $(filter $(dotits),$(1))

#, spaceuppers, etc: is there a way to use foreach to do recursive substitutions and avoid the spacenumbers mess

#hasnumsanddot = $(if $(or $(or $(or $(or $(findstring 0,$(1)),$(findstring 1,$(1))),$(or $(findstring 2,$(1)),$(findstring 3,$(1)))),$(or $(or $(findstring 4,$(1)),$(findstring 5,$(1))),$(or $(findstring 6,$(1)),$(findstring 7,$(1))))),$(or $(findstring 8,$(1)),$(findstring 9,$(1)))),$(1),)
hasnumsanddot = $(if $(and $(findstring .,$(1)),$(call hasnumbersnew,$(1))),$(1),)
hasnumbersnew = $(if $(or $(or $(or $(or $(findstring 0,$(1)),$(findstring 1,$(1))),$(or $(findstring 2,$(1)),$(findstring 3,$(1)))),$(or $(or $(findstring 4,$(1)),$(findstring 5,$(1))),$(or $(findstring 6,$(1)),$(findstring 7,$(1))))),$(or $(findstring 8,$(1)),$(findstring 9,$(1)))),$(1),)

hasnumbersbest = $(if $(foreach X,$(digits),$(findstring $X,$(1))),$(1),)
#hasdigits = $(if $(foreach X,$(digits),$(findstring $X,$(1))),$(1),)

hasanyofdigits = $(if $(call eachfind,$(digits),$(1)),$(1),)
hasanyofdotits = $(if $(call eachfind,$(dotits),$(1)),$(1),)
hasanyofuppers = $(if $(call eachfind,$(uppers),$(1)),$(1),)
hasanyoflowers = $(if $(call eachfind,$(lowers),$(1)),$(1),)
hasanyofalphas = $(if $(call eachfind,$(alphas),$(1)),$(1),)
hasanyofalnums = $(if $(call eachfind,$(alnums),$(1)),$(1),)

hasditanddot = $(if $(and $(findstring $(dot),$(1)),$(call hasanyofdigits,$(1))),$(true),)

setconcat := $(digits) $(dot)

# test suite
ok = $(space)ok$(space)$(eval ok__=$(ok__)$(space)K)
fail = $(space)fail$(space)$(eval fail__=$(fail__)$(space)!)

# ts: test something
ts__ = $(if $(1),$(ok),$(fail))
ects__ = $(eval SUT_PREREQ_$(1)=$(SUT_PREREQ_$(1))$(space)$(2))$(call echo,   test $(3): $(if $(4),$(ok),$(fail)))
# te: test empty
te__ = $(if $(1),$(fail),$(ok))

#suite-all: ;
#	@$(call echo )$(call test-sets)

# ta: test add
ta__ = $(eval tests__=$(tests__)$(space)$(1))

sutt-all = $(call tst-sets)$(call suit-spacers)

tst-sets = $(call ta__,test-sets)$(call ts__,$(and $(call setcheck,0123456789,$(digits)),$(and $(call setcheck,0123456789.,$(dotits)),$(and $(call setcheck,ABCDEFGHIJKLMNOPQRSTUVWXYZ,$(uppers)),$(and $(call setcheck,abcdefghijklmnopqrstuvwxyz,$(lowers)),$(and $(call setcheck,ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,$(alphas)),$(call setcheck,0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,$(alnums))))))))

#test-sets: ;
#tst-debug = $(call setcheck,0123456789,$(digits))

sut-%: $(SUT_PREREQ_%);
	@$(call echo,SUT_PREREQ_$* = $(SUT_PREREQ_$*))
	@$(call echo,$*:)

suitesummary = $(info )$(info )$(info $(words $(fail__)) test(s) failed)$(info $(words $(ok__)) test(s) succeeded)$(info )$(info )$(info $(if $(fail__),FAILLURE!,SUCCESS!!))$(info )

info-suit-all: ; $(info )$(info all tests suite:)$(info )
suit-all: info-suit-all | tests-sets tests-spacers;
	@$(call suitesummary)

info-suit-sets: ; $(info )$(info sets suite:)$(info )
tests-sets: info-suit-sets | test-set-digits test-set-dotits test-set-uppers test-set-lowers test-set-alphas test-set-alnums;
suit-sets: tests-sets;
	@$(call suitesummary)
#	@$(call echo,$(if $(fail__),$(words $(fail__)) test(s) failed.,SUCCESS!! no tests failed))

test-set-digits: ; @$(call ects__,sets,test-set-digits,digits set,$(call setcheck,0123456789,$(digits)))
test-set-dotits: ; @$(call ects__,sets,test-set-dotits,dotits set,$(call setcheck,0123456789.,$(dotits)))
test-set-uppers: ; @$(call ects__,sets,test-set-uppers,uppers set,$(call setcheck,ABCDEFGHIJKLMNOPQRSTUVWXYZ,$(uppers)))
test-set-lowers: ; @$(call ects__,sets,test-set-lowers,lowers set,$(call setcheck,abcdefghijklmnopqrstuvwxyz,$(lowers)))
test-set-alphas: ; @$(call ects__,sets,test-set-alnums,alphas set,$(call setcheck,ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,$(alphas)))
test-set-alnums: ; @$(call ects__,sets,test-set-alnums,alnums set,$(call setcheck,0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,$(alnums)))

info-suit-spacers: ; $(info )$(info spacers suite:)$(info )
tests-spacers: info-suit-spacers | test-spacer-digits test-spacer-dotits test-spacer-uppers test-spacer-lowers test-spacer-alphas test-spacer-alnums;
suit-spacers: tests-spacers;
	@$(call echo,$(if $(fail__),$(words $(fail__)) test(s) failed.,SUCCESS!! no tests failed))

test-spacer-digits: ; @$(call ects__,sets,test-set-alnums,digits set,$(call spacercheck,$(spacers-tst-r1),$(call spacedigits,$(spacers-tst-val))))
test-spacer-dotits: ; @$(call ects__,sets,test-set-alnums,dotits set,$(call spacercheck,$(spacers-tst-r2),$(call spacedotits,$(spacers-tst-val))))
test-spacer-uppers: ; @$(call ects__,sets,test-set-alnums,uppers set,$(call spacercheck,$(spacers-tst-r3),$(call spaceuppers,$(spacers-tst-val))))
test-spacer-lowers: ; @$(call ects__,sets,test-set-alnums,lowers set,$(call spacercheck,$(spacers-tst-r4),$(call spacelowers,$(spacers-tst-val))))
test-spacer-alphas: ; @$(call ects__,sets,test-set-alnums,alphas set,$(call spacercheck,$(spacers-tst-r5),$(call spacealphas,$(spacers-tst-val))))
test-spacer-alnums: ; @$(call ects__,sets,test-set-alnums,alnums set,$(call spacercheck,$(spacers-tst-r6),$(call spacealnums,$(spacers-tst-val))))


eachfindx = $(call despace,$(foreach X,$(1),$(findstring $X,$(2))))
tst-eachfind = $(call eachfindx,$(digits),skd33fd2)

spacers-tst-val := sd..D..31SFks3dfj398sdfSDFI3SD2dFdHdd980jf39.kfSD3FDdfq3.f890ik0jb
spacers-tst-r1 := sd..D..!3!1!SFks!3!dfj!3!9!8!sdfSDFI!3!SD!2!dFdHdd!9!8!0!jf!3!9!.kfSD!3!FDdfq!3!.f!8!9!0!ik!0!jb
spacers-tst-r2 := sd!.!.!D!.!.!3!1!SFks!3!dfj!3!9!8!sdfSDFI!3!SD!2!dFdHdd!9!8!0!jf!3!9!.!kfSD!3!FDdfq!3!.!f!8!9!0!ik!0!jb
spacers-tst-r3 := sd..!D!..31!S!F!ks3dfj398sdf!S!D!F!I!3!S!D!2d!F!d!H!dd980jf39.kf!S!D!3!F!D!dfq3.f890ik0jb
spacers-tst-r4 := s!d!..D..31SF!k!s!3!d!f!j!398!s!d!f!SDFI3SD2!d!F!d!H!d!d!980!j!f!39.!k!f!SD3FD!d!f!q!3.!f!890!i!k!0!j!b
spacers-tst-r5 := s!d!..!D!..31!S!F!k!s!3!d!f!j!398!s!d!f!S!D!F!I!3!S!D!2!d!F!d!H!d!d!980!j!f!39.!k!f!S!D!3!F!D!d!f!q!3.!f!890!i!k!0!j!b
spacers-tst-r6 := s!d!..!D!..!3!1!S!F!k!s!3!d!f!j!3!9!8!s!d!f!S!D!F!I!3!S!D!2!d!F!d!H!d!d!9!8!0!j!f!3!9!.!k!f!S!D!3!F!D!d!f!q!3!.!f!8!9!0!i!k!0!j!b
#spacercheck = $(call match,$(1),$(subst $(space),!,$(strip $(call singlespace,$(2)))))
spacercheck = $(call match,$(1),$(subst $(space),!,$(2)))

suit-spacers = $(call tst-spacer1)$(call tst-spacer2)$(call tst-spacer3)$(call tst-spacer4)$(call tst-spacer5)$(call tst-spacer6)
tst-spacer1 = $(call ts__,$(call spacercheck,$(spacers-tst-r1),$(call spacedigits,$(spacers-tst-val))))
tst-spacer2 = $(call ts__,$(call spacercheck,$(spacers-tst-r2),$(call spacedotits,$(spacers-tst-val))))
tst-spacer3 = $(call ts__,$(call spacercheck,$(spacers-tst-r3),$(call spaceuppers,$(spacers-tst-val))))
tst-spacer4 = $(call ts__,$(call spacercheck,$(spacers-tst-r4),$(call spacelowers,$(spacers-tst-val))))
tst-spacer5 = $(call ts__,$(call spacercheck,$(spacers-tst-r5),$(call spacealphas,$(spacers-tst-val))))
tst-spacer6 = $(call ts__,$(call spacercheck,$(spacers-tst-r6),$(call spacealnums,$(spacers-tst-val))))

tst-hasnumbersnewold = $(call te__,$(filter-out 0123456789,$(call hasnumbersnew,0)$(call hasnumbersnew,1)$(call hasnumbersnew,2)$(call hasnumbersnew,3)$(call hasnumbersnew,4)$(call hasnumbersnew,5)$(call hasnumbersnew,6)$(call hasnumbersnew,7)$(call hasnumbersnew,8)$(call hasnumbersnew,9)))
tst-hasnumsanddotold = $(call ts__,$(filter-out 0.1.2.3.4.5.6.7.8.9.,$(call hasnumsanddot,0.)$(call hasnumsanddot,1.)$(call hasnumsanddot,2.)$(call hasnumsanddot,3.)$(call hasnumsanddot,4.)$(call hasnumsanddot,5.)$(call hasnumsanddot,6.)$(call hasnumsanddot,7.)$(call hasnumsanddot,8.)$(call hasnumsanddot,9.)))

#tst-hasnumbersnew = $(call ts__,$(filter-out 0123456789,$(foreach X,digits,$(call hasnumbersnew,$X))))
tst-hasnumbersnew = $(foreach X,digits,$(call hasnumbersnew,$X))
tst-hasnumbersbest = $(call ts__,$(call setcheck,0123456789,$(foreach X,$(digits),$(call hasnumbersbest,$X))))
tst-hasdigits = $(call ts__,$(call setcheck,0123456789,$(foreach X,$(digits),$(call hasdigits,$X))))
#tst-hasnumbersbest = $(foreach X,$(digits),$(call hasnumbersbest,$X))
#tst-hasnumbersbest = $(call match,)

tst-all = $(foreach X,$(tests__),$(call $X))

test-all: $(TARGETS);
	@$(call echo,tests__ = $(tests__))
	@$(call echo,all done?)

#str_ismajminver = $(if $(and $(call isanumber,$(word 1,$(subst .,$(space),$(1)))),$(call isanumber,$(word 2,$(subst .,$(space),$(1))))))$(1),)
ismajminver = $(info ismajminver($(1)))$(if $(and $(call isanumber,$(word 1,$(1))),$(and $(call match,$(dot),$(word 2,$(1)))),$(call isanumber,$(word 3,$(1)))),,)
ismajminverx = $(info ismajminverx($(1)))$(call isanumber,$(word 1,$(1)))
verparsenew = $(subst $(dot),$(space)$(dot)$(space),$(call despace,$(filter $(dotits),$(call spacedotits,$(1)))))
comb = $(call ismajminver,$(call verparsenew,$(1)))
xcomb = $(call ismajminverx,$(call verparsenew,$(1)))
getver = $(if $(call hasditanddot,$(word 1,$(1))),$(word 1,$(1)),$(wordlist 2,$(words $(1)),$(1)))
getver0 = $(info 1($(1)) 2($(2)))$(if $(and $(1)$(2),$(call hasditanddot,$(1))),aaa$(1),bbb$(call gitver0,$(word 2,$(2)),$(wordlist 2,$(words $(2)),$(2))))
gvr = $(eval gvr_r__=)$(if $(foreach X,$(1),$(if $(gvr_r__),,$(if $(call hasditanddot,$X),$(eval gvr_r__=$X),))),$(gvr_r__),$(gvr_r__))
gvr2 = $(call eachtest,hasditanddot,$(1),hasditanddot)
gvr3 = $(call eachtest,verparsenew,$(1),verparsenew)
gvr4 = $(call eachtest,ismajminver,$(1),ismajminver)
gvr5 = $(call eachtest,comb,$(1),comb)
getver1 = $(if $(call hasditanddot,$(word 1,$(1))),$(word 1,$(1)),$(call gitver1,$(wordlist 2,$(words $(1)),$(1))))
wl = start$(wordlist 2,$(words $(1)),$(1))end
__each = $(call eachfind,$(digits),$(1))
__hasa = $(call hasanyofdigits,$(1))
__ditd = $(call hasditanddot,$(1))
str_getversion = $(if $(1),$(if $(and $(call hasditanddot,$(word 1,$(1))),$(call ismajminver,$(call verparsenew,$(word 1,$(1))))),$(word 1,$(1)),$(call str_getversion,$(wordlist 2,$(words $(1)),$(1)))),)

ifndef OPENSSL_VERSION
   ifndef OPENSSL
      OPENSSL := openssl
   endif
   ifeq ($(shell $(OPENSSL) version $(nullerror)),)
      export OPENSSL_NA := $(OPENSSL)NotAvailable
   else
		SSL_VER_OUTPUT := $(shell $(OPENSSL) version)
		SSLw1 = $(word 1,$(SSL_VER_OUTPUT))
		SSLw2 = $(word 2,$(SSL_VER_OUTPUT))
		SSLw3 = $(word 3,$(SSL_VER_OUTPUT))
		SSLe1 = $(call __each,$(SSLw1))
		SSLe2 = $(call __each,$(SSLw2))
		SSLe3 = $(call __each,$(SSLw3))
		SSLh1 = $(call __hasa,$(SSLw1))
		SSLh2 = $(call __hasa,$(SSLw2))
		SSLh3 = $(call __hasa,$(SSLw3))
		SSLd1 = $(call __ditd,$(SSLw1))
		SSLd2 = $(call __ditd,$(SSLw2))
		SSLd3 = $(call __ditd,$(SSLw3))
		SSLv1 = $(call getver,$(SSLw1))
		SSLv2 = $(call getver,$(SSLw2))
		SSLv3 = $(call getver,$(SSLw3))
		SSLa1 = $(call verparsenew,$(SSLw1))
		SSLa2 = $(call verparsenew,$(SSLw2))
		SSLa3 = $(call verparsenew,$(SSLw3))
		SSLb1 = $(call comb,$(SSLw1))
		SSLb2 = $(call comb,$(SSLw2))
		SSLb3 = $(call comb,$(SSLw3))
		#,$(and $(call match,$(dot),$(word 2,$(1)))),$(call isanumber,$(word 3,$(1)))
		SSLc1 = $(call xcomb,$(SSLw1))
		SSLc2 = $(call xcomb,$(SSLw2))
		SSLc3 = $(call xcomb,$(SSLw3))
#		SSLv2 = $(call verparsenew,$(SSL_VER_OUTPUT))
		SSLrA = $(call wl,$(SSL_VER_OUTPUT))
		SSLrB = $(call getver0,,$(SSL_VER_OUTPUT))
		SSLrC = $(call getver1,$(SSL_VER_OUTPUT))
		SSLrD = $(call gvr,$(SSL_VER_OUTPUT))
		SSLrE = $(call gvr2,$(SSL_VER_OUTPUT))
		SSLrF = $(call gvr3,$(SSL_VER_OUTPUT))
		SSLrG = $(call gvr4,$(SSL_VER_OUTPUT))
		SSLrH = $(call gvr5,$(SSL_VER_OUTPUT))
		SSL_VER = $(call str_getversion,$(SSL_VER_OUTPUT))
      ifneq ($(SSL_VER),)
         export OPENSSL_VERSION := $(SSL_VER)
      endif
   endif
endif
ifndef OPENSSL_VERSION
   export OPENSSL_VERSION := unknown
endif

.DEFAULT_GOAL := all

cplm-print-%: ; $(info $* = $($*))

cplm-vars-%: ; $(foreach X,$(sort $(.VARIABLES)),$(if $(findstring $*,$X),$(info $X = $($X)),))

all-vars: ; $(foreach X,$(.VARIABLES),$(info $X = $($X)))

all-vars-sort: ; $(foreach X,$(sort $(.VARIABLES)),$(info $X = $($X)))
