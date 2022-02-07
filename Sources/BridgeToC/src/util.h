/***********************************************************************
 * Copyright (c) 2013, 2014 Pieter Wuille                              *
 * Distributed under the MIT software license, see the accompanying    *
 * file COPYING or https://www.opensource.org/licenses/mit-license.php.*
 ***********************************************************************/

#ifndef SECP256K1_UTIL_H
#define SECP256K1_UTIL_H

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <limits.h>

/* Like assert(), but when VERIFY is defined, and side-effect safe. */
#if defined(COVERAGE)
#define VERIFY_CHECK(check)
#define VERIFY_SETUP(stmt)
#elif defined(VERIFY)
#define VERIFY_CHECK CHECK
#define VERIFY_SETUP(stmt) do { stmt; } while(0)
#else
#define VERIFY_CHECK(cond) do { (void)(cond); } while(0)
#define VERIFY_SETUP(stmt)
#endif

/* If SECP256K1_{LITTLE,BIG}_ENDIAN is not explicitly provided, infer from various other system macros. */
#if !defined(SECP256K1_LITTLE_ENDIAN) && !defined(SECP256K1_BIG_ENDIAN)
/* Inspired by https://github.com/rofl0r/endianness.h/blob/9853923246b065a3b52d2c43835f3819a62c7199/endianness.h#L52L73 */
# if (defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__) || \
     defined(_X86_) || defined(__x86_64__) || defined(__i386__) || \
     defined(__i486__) || defined(__i586__) || defined(__i686__) || \
     defined(__MIPSEL) || defined(_MIPSEL) || defined(MIPSEL) || \
     defined(__ARMEL__) || defined(__AARCH64EL__) || \
     (defined(__LITTLE_ENDIAN__) && __LITTLE_ENDIAN__ == 1) || \
     (defined(_LITTLE_ENDIAN) && _LITTLE_ENDIAN == 1) || \
     defined(_M_IX86) || defined(_M_AMD64) || defined(_M_ARM) /* MSVC */
#  define SECP256K1_LITTLE_ENDIAN
# endif
# if (defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__) || \
     defined(__MIPSEB) || defined(_MIPSEB) || defined(MIPSEB) || \
     defined(__MICROBLAZEEB__) || defined(__ARMEB__) || defined(__AARCH64EB__) || \
     (defined(__BIG_ENDIAN__) && __BIG_ENDIAN__ == 1) || \
     (defined(_BIG_ENDIAN) && _BIG_ENDIAN == 1)
#  define SECP256K1_BIG_ENDIAN
# endif
#endif
#if defined(SECP256K1_LITTLE_ENDIAN) == defined(SECP256K1_BIG_ENDIAN)
# error Please make sure that either SECP256K1_LITTLE_ENDIAN or SECP256K1_BIG_ENDIAN is set, see src/util.h.
#endif


/* Like assert(), but when VERIFY is defined, and side-effect safe. */
#if defined(COVERAGE)
#define VERIFY_CHECK(check)
#define VERIFY_SETUP(stmt)
#elif defined(VERIFY)
#define VERIFY_CHECK CHECK
#define VERIFY_SETUP(stmt) do { stmt; } while(0)
#else
#define VERIFY_CHECK(cond) do { (void)(cond); } while(0)
#define VERIFY_SETUP(stmt)
#endif


#endif /* SECP256K1_UTIL_H */
