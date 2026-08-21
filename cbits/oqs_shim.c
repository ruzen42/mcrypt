#include "oqs_shim.h"
#include <oqs/oqs.h>

static OQS_SIG 
*open_sig(void) 
{
    return OQS_SIG_new(MCRYPT_SIG_ALG); /* wrapper for MCRYPT_SIG_ALG macros */
}

size_t
mcrypt_sig_public_key_len(void) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return 0;
    int n = sig->length_public_key;
    OQS_SIG_free(sig);
    return n;
}

size_t
mcrypt_sig_secret_key_len(void) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return 0;
    int n = sig->length_secret_key;
    OQS_SIG_free(sig);
    return n;
}

size_t
mcrypt_sig_max_signature_len(void) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return 0;
    int n = sig->length_signature;
    OQS_SIG_free(sig);
    return n;
}

int 
mcrypt_sig_keypair(uint8_t *public_key, uint8_t *secret_key) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return -1;
    OQS_STATUS rc = OQS_SIG_keypair(sig, public_key, secret_key);
    OQS_SIG_free(sig);
    return rc == OQS_SUCCESS ? 0 : -1;
}

int 
mcrypt_sig_sign(uint8_t *signature, 
                size_t *signature_len,
                const uint8_t *message, 
                size_t message_len,
                const uint8_t *secret_key) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return -1;
    OQS_STATUS rc = OQS_SIG_sign(sig, signature, signature_len,
                                  message, message_len, secret_key);
    OQS_SIG_free(sig);
    return rc == OQS_SUCCESS ? 0 : -1;
}

int 
mcrypt_sig_verify(const uint8_t *message, 
                  size_t message_len,
                  const uint8_t *signature, 
                  size_t signature_len,
                  const uint8_t *public_key) 
{
    OQS_SIG *sig = open_sig(); /* not effective, in future, change it to handler style */
    if (!sig) return -1;
    OQS_STATUS rc = OQS_SIG_verify(sig, message, message_len,
                                    signature, signature_len, public_key);
    OQS_SIG_free(sig);
    return rc == OQS_SUCCESS ? 0 : -1;
}
