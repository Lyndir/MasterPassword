#include "mpw-jni.h"

/** native int _scrypt(byte[] passwd, int passwdlen, byte[] salt, int saltlen, int N, int r, int p, byte[] buf, int buflen); */
JNIEXPORT jint JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1scrypt(JNIEnv *env, jobject obj,
        jbyteArray passwd, jint passwdlen, jbyteArray salt, jint saltlen, jint N, jint  r, jint p, jbyteArray buf, jint buflen) {

    return -2;
}
