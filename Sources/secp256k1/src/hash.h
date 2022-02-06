/***********************************************************************
 * Copyright (c) 2014 Pieter Wuille                                    *
 * Distributed under the MIT software license, see the accompanying    *
 * file COPYING or https://www.opensource.org/licenses/mit-license.php.*
 ***********************************************************************/

#ifndef SECP256K1_HASH_H
#define SECP256K1_HASH_H

#include <stdlib.h>
#include <stdint.h>

typedef struct {
    uint32_t s[8];
    uint32_t buf[16]; /* In big endian */
    size_t bytes;
} secp256k1_sha256;

void secp256k1_sha256_initialize(secp256k1_sha256 *hash);

void secp256k1_sha256_write(secp256k1_sha256 *hash, const unsigned char *data, size_t size);

void secp256k1_sha256_finalize(secp256k1_sha256 *hash, unsigned char *out32);

/* Initializes SHA256 with fixed midstate. */
void secp256k1_sha256_initialize_with_fixed_midstate(secp256k1_sha256 *sha, const unsigned char *data, size_t size);

#endif /* SECP256K1_HASH_H */
