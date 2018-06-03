#include <string.h>

#include "mpw-jni.h"
#include "mpw-util.h"

/** native int _scrypt(byte[] passwd, byte[] salt, int N, int r, int p, byte[] buf); */
JNIEXPORT jint JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1scrypt(JNIEnv *env, jobject obj,
        jbyteArray passwd, jbyteArray salt, jint N, jint r, jint p, jbyteArray buf) {

    jbyte *passwdBytes = (*env)->GetByteArrayElements( env, passwd, NULL );
    jbyte *saltBytes = (*env)->GetByteArrayElements( env, salt, NULL );
    const size_t keyLength = (*env)->GetArrayLength( env, buf );
    const uint8_t *key = mpw_kdf_scrypt( keyLength,
            (uint8_t *)passwdBytes, (size_t)(*env)->GetArrayLength( env, passwd ),
            (uint8_t *)saltBytes, (size_t)(*env)->GetArrayLength( env, salt ),
            (uint64_t)N, (uint32_t)r, (uint32_t)p );
    (*env)->ReleaseByteArrayElements( env, passwd, passwdBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, salt, saltBytes, JNI_ABORT );

    if (!key)
        return ERR;

    jbyte *bufBytes = (*env)->GetByteArrayElements( env, buf, NULL );
    memcpy( bufBytes, key, keyLength );
    (*env)->ReleaseByteArrayElements( env, buf, bufBytes, JNI_OK );
    mpw_free( &key, keyLength );

    return OK;
}
