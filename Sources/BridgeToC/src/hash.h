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
void secp256k1_sha256_write(secp256k1_sha256 *hash, const void *data, size_t size);
void secp256k1_sha256_write_cache_state(secp256k1_sha256 *hash, const void *data, size_t size, void *state32out);
void secp256k1_sha256_finalize(secp256k1_sha256 *hash, void *out32);
void secp256k1_sha256_init_with_state(secp256k1_sha256 *sha, const void *data, size_t len);
void secp256k1_copy_hasher_state(secp256k1_sha256 *target, secp256k1_sha256 *source);

#endif /* SECP256K1_HASH_H */
