#-----------------------------------------------------------------------------
# Rules file
#-----------------------------------------------------------------------------

first: all

#-----------------------------------------------------------------------------
# Recursion magic
#
#   Targets that we want to be recursive must be listed in RECURS_TARGETS
#----------------------------------------------------------------------------
$(RECURS_TARGETS) : % : 
	@SUB="$(SUBDIRS)"; for dir in $$SUB; do \
            cd $$dir || exit $$?; \
            $(MAKE) $* || exit $$?;\
	    cd $(PWD); \
	done

#-----------------------------------------------------------------------------
# All
#-----------------------------------------------------------------------------

all: libraries executables

#-----------------------------------------------------------------------------
# Clean
#-----------------------------------------------------------------------------
clean : clean_bak

clean_bak:
	rm -f *~


#-----------------------------------------------------------------------------
# Assembly
#-----------------------------------------------------------------------------

_AS_SOURCES := $(filter %.S,$(SOURCES))

_AS_OBJECTS := $(patsubst %.S,$(OBJ_DIR)/%.o,$(_AS_SOURCES))

objects : $(_AS_OBJECTS)

_OBJECTS += $(_AS_OBJECTS)

$(_AS_OBJECTS) : $(OBJ_DIR)/%.o : %.S
	@if test ! -d $(@D); then mkdir -p $(@D); fi;
	${AS} ${AS_FLAGS} -c -o $@ $<

clean : clean_as_obj

clean_as_obj:
	rm -f $(_AS_OBJECTS)

#-----------------------------------------------------------------------------
# C compilation
#-----------------------------------------------------------------------------

_C_SOURCES := $(filter %.c,$(SOURCES))

_C_OBJECTS := $(patsubst %.c,$(OBJ_DIR)/%.o,$(_C_SOURCES))

objects : $(_C_OBJECTS)

_OBJECTS += $(_C_OBJECTS)

$(_C_OBJECTS) : $(OBJ_DIR)/%.o : %.c
	@if test ! -d $(@D); then mkdir -p $(@D); fi;
	${CC} ${C_FLAGS} -c -o $@ $<

clean : clean_c_obj

clean_c_obj:
	rm -f $(_C_OBJECTS)

#-----------------------------------------------------------------------------
# C++ compilation
#-----------------------------------------------------------------------------

_CPP_SOURCES := $(filter %.cpp,$(SOURCES))

_CPP_OBJECTS := $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(_CPP_SOURCES))

objects : $(_CPP_OBJECTS)

_OBJECTS += $(_CPP_OBJECTS)

$(_CPP_OBJECTS) : $(OBJ_DIR)/%.o : %.cpp
	@if test ! -d $(OBJ_DIR); then mkdir -p $(OBJ_DIR); fi; 
	${CPP} ${CPP_FLAGS} -c -o $@ $<

clean : clean_cpp_obj

clean_cpp_obj:
	rm -f $(_CPP_OBJECTS)

#-----------------------------------------------------------------------------
# Header dependencies
#-----------------------------------------------------------------------------
ifneq ($(findstring clean,$(MAKECMDGOALS)),clean)

-include $(OBJ_DIR)/$(DEP_PREFIX)_hfiles.dep 

ifneq ($(strip $(_C_SOURCES) $(_CPP_SOURCES)),) 

$(OBJ_DIR)/$(DEP_PREFIX)_hfiles.dep : $(_C_SOURCES) $(_CPP_SOURCES)
	@if test ! -d $(OBJ_DIR); then mkdir -p $(OBJ_DIR); fi; 
	@echo Rebuilding header dependencies... 
	@$(DEP_MAKER) $(DEP_FLAGS) -M $(_C_SOURCES) $(_CPP_SOURCES) | sed -e 's@ /[^ ]*@ @g' -e '/^[ ]*\\/ d' | sed -e 's@\(.*\.o\)@$(OBJ_DIR)/\1@g' > $@ 
endif 

endif

clean: clean_dep

clean_dep:
	rm -f $(OBJ_DIR)/*.dep


#-----------------------------------------------------------------------------
# Static libraries
#-----------------------------------------------------------------------------
_LIBRARY := $(patsubst %,$(LIB_DIR)/lib%.a,$(LIBRARY))

libraries : $(_LIBRARY)

$(_LIBRARY) : $(_OBJECTS)
	@if test ! -d $(LIB_DIR); then mkdir -p $(LIB_DIR); fi;
	$(AR) $(AR_FLAGS) $@ $(_OBJECTS)

clean : clean_lib

ifdef _LIBRARY
clean_lib:
	rm -f $(_LIBRARY)
else
clean_lib:
endif


#-----------------------------------------------------------------------------
# Related libraries build
# The EXEC_LIBS variable must be reset in order to prevent undesired 
# recursion, we have to force make to try to build the library in order
# to ensure it is uptodate 
#-----------------------------------------------------------------------------
$(REQ_LIBS): FORCE
	@$(MAKE) -C $(BLD_ROOT)/$(patsubst lib%.a,%,$(@F)) EXEC_LIBS=
	
FORCE:

#-----------------------------------------------------------------------------
# Static linking
#-----------------------------------------------------------------------------

_EXECUTABLE := $(patsubst %,$(BIN_DIR)/%,$(EXECUTABLE))

_EXEC_LIBS := $(patsubst %,-l%,$(EXEC_LIBS))

_EXEC_LIB_FILES := $(filter-out $patsubst( %,\
                   $(LIB_DIR)/lib%.a,$(EXEC_LIBS_NO_DEPENDENCY)),\
                   $(patsubst %,$(LIB_DIR)/lib%.a,$(EXEC_LIBS)))


executables: $(_EXECUTABLE)

$(_EXECUTABLE) : $(_OBJECTS) $(_EXEC_LIB_FILES) 
	@if test ! -d $(BIN_DIR); then mkdir -p $(BIN_DIR); fi;
	$(LINK) $(LINK_FLAGS) $(_OBJECTS) $(_EXEC_LIBS) $(SYS_LIBS) -o $@ 

clean: clean_exec

clean_exec:
	rm -rf $(_EXECUTABLE)



#-----------------------------------------------------------------------------
# Rules for other tools
#-----------------------------------------------------------------------------

-include $(patsubst %,$(BLD_ROOT)/makefiles/tools/%Rules.mk,$(TOOLS))

