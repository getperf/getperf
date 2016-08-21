﻿/* GLOBAL.H - RSAREF types and constants
 */

/* PROTOTYPES should be set to one if and only if the compiler supports
  function argument prototyping.
The following makes PROTOTYPES default to 0 if it has not already
  been defined with C compiler flags.
 */
 
#ifndef GETPERF_GLOBAL_H
#define GETPERF_GLOBAL_H

#ifndef PROTOTYPES
#define PROTOTYPES 0
#endif

#if defined(_WINDOWS)
typedef  unsigned short    uint16_t;        /* Unsigned 16 bit value type. */ 
typedef  unsigned long     uint32_t;        /* Unsigned 32 bit value type. */ 
#endif 

/* POINTER defines a generic pointer type */
typedef unsigned char *POINTER;

/* UINT2 defines a two byte word */
typedef uint16_t UINT2;

/* UINT4 defines a four byte word */
typedef uint32_t UINT4;

/* PROTO_LIST is defined depending on how PROTOTYPES is defined above.
If using PROTOTYPES, then PROTO_LIST returns the list, otherwise it
  returns an empty list.
 */
#if PROTOTYPES
#define PROTO_LIST(list) list
#else
#define PROTO_LIST(list) ()
#endif
#endif
