#include <string.h>

#include "mpw-jni.h"
#include "mpw-util.h"

/** native int _scrypt(byte[] passwd, int passwdlen, byte[] salt, int saltlen, int N, int r, int p, byte[] buf, int buflen); */
JNIEXPORT jint JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1scrypt(JNIEnv *env, jobject obj,
        jbyteArray passwd, jint passwdlen, jbyteArray salt, jint saltlen, jint N, jint r, jint p, jbyteArray buf, jint buflen) {

    jbyte *passwdBytes = (*env)->GetByteArrayElements( env, passwd, NULL );
    jbyte *saltBytes = (*env)->GetByteArrayElements( env, salt, NULL );
    const uint8_t *key = mpw_kdf_scrypt( (size_t)buflen, (uint8_t *)passwdBytes, (size_t)passwdlen, (uint8_t *)saltBytes, (size_t)saltlen,
            (uint64_t)N, (uint32_t)r, (uint32_t)p );
    (*env)->ReleaseByteArrayElements( env, passwd, passwdBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, salt, saltBytes, JNI_ABORT );

    if (!key)
        return ERR;

    memcpy( buf, key, buflen );
    return OK;
}
