#include <string.h>

#include "mpw-jni.h"
#include "mpw-algorithm.h"
#include "mpw-util.h"

// TODO: We may need to zero the jbytes safely.

/* native int _masterKey(final String fullName, final byte[] masterPassword, final Version version) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1masterKey(JNIEnv *env, jobject obj,
        jstring fullName, jbyteArray masterPassword, jint algorithmVersion) {

    const char *fullNameString = (*env)->GetStringUTFChars( env, fullName, NULL );
    jbyte *masterPasswordString = (*env)->GetByteArrayElements( env, masterPassword, NULL );

    MPMasterKey masterKeyBytes = mpw_masterKey( fullNameString, (char *)masterPasswordString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseStringUTFChars( env, fullName, fullNameString );
    (*env)->ReleaseByteArrayElements( env, masterPassword, masterPasswordString, JNI_ABORT );

    if (!masterKeyBytes)
        return NULL;

    jbyteArray masterKey = (*env)->NewByteArray( env, (jsize)MPMasterKeySize );
    (*env)->SetByteArrayRegion( env, masterKey, 0, (jsize)MPMasterKeySize, (jbyte *)masterKeyBytes );
    mpw_free( &masterKeyBytes, MPMasterKeySize );

    return masterKey;
}

/* native int _siteKey(final byte[] masterKey, final String siteName, final long siteCounter,
                       final MPKeyPurpose keyPurpose, @Nullable final String keyContext,  final Version version) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteKey(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext, jint algorithmVersion) {

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    MPMasterKey siteKeyBytes = mpw_siteKey(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );

    if (!siteKeyBytes)
        return NULL;

    jbyteArray siteKey = (*env)->NewByteArray( env, (jsize)MPMasterKeySize );
    (*env)->SetByteArrayRegion( env, siteKey, 0, (jsize)MPMasterKeySize, (jbyte *)siteKeyBytes );
    mpw_free( &siteKeyBytes, MPSiteKeySize );

    return siteKey;
}

/* native String _siteResult(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                             final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                             final MPResultType resultType, @Nullable final String resultParam, final Version version) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteResult(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jbyteArray siteKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext,
        jint resultType, jstring resultParam, jint algorithmVersion) {

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    jbyte *siteKeyBytes = (*env)->GetByteArrayElements( env, siteKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    const char *resultParamString = resultParam? (*env)->GetStringUTFChars( env, resultParam, NULL ): NULL;
    const char *siteResultString = mpw_siteResult(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPResultType)resultType, resultParamString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, siteKey, siteKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );
    (*env)->ReleaseStringUTFChars( env, resultParam, resultParamString );

    if (!siteResultString)
        return NULL;

    jstring siteResult = (*env)->NewStringUTF( env, siteResultString );
    mpw_free_string( &siteResultString );

    return siteResult;
}

/* native String _siteState(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                            final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            final MPResultType resultType, final String resultParam, final Version version) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteState(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jbyteArray siteKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext,
        jint resultType, jstring resultParam, jint algorithmVersion) {

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    jbyte *siteKeyBytes = (*env)->GetByteArrayElements( env, siteKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    const char *resultParamString = (*env)->GetStringUTFChars( env, resultParam, NULL );
    const char *siteStateString = mpw_siteState(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPResultType)resultType, resultParamString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, siteKey, siteKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );
    (*env)->ReleaseStringUTFChars( env, resultParam, resultParamString );

    if (!siteStateString)
        return NULL;

    jstring siteState = (*env)->NewStringUTF( env, siteStateString );
    mpw_free_string( &siteStateString );

    return siteState;
}
