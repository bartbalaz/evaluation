# Definitions used by gnu default gnu tools
# These are the defintions 


#-----------------------------------------------------------------------------
# C compilation
#-----------------------------------------------------------------------------

CC = gcc


#-----------------------------------------------------------------------------
# C++ compilation
#-----------------------------------------------------------------------------

CPP = g++


#-----------------------------------------------------------------------------
# Static libraries
#-----------------------------------------------------------------------------

AR = ar

AR_FLAGS = rcs


#-----------------------------------------------------------------------------
# Static linking
#-----------------------------------------------------------------------------

ifndef LINK
LINK = g++
endif


#-----------------------------------------------------------------------------
# Dependencies
#-----------------------------------------------------------------------------

DEP_MAKER = gcc