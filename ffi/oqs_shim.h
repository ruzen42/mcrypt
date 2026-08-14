#ifndef MCRYPT_OQS_SHIM_H
#define MCRYPT_OQS_SHIM_H

#include <stddef.h>
#include <stdint.h>

#define MCRYPT_SIG_ALG "Dilithium3"

size_t mcrypt_sig_public_key_len(void);
size_t mcrypt_sig_secret_key_len(void);
size_t mcrypt_sig_max_signature_len(void);

int mcrypt_sig_keypair(uint8_t *public_key, uint8_t *secret_key);

int mcrypt_sig_sign(uint8_t *signature, size_t *signature_len,
                    const uint8_t *message, size_t message_len,
                    const uint8_t *secret_key);

int mcrypt_sig_verify(const uint8_t *message, size_t message_len,
                      const uint8_t *signature, size_t signature_len,
                      const uint8_t *public_key);

#endif /* MCRYPT_OQS_SHIM_H */
