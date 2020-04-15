#include <string.h>

#include "java/com_lyndir_masterpassword_MPAlgorithm_Version.h"

#include "mpw-algorithm.h"
#include "mpw-util.h"

// TODO: We may need to zero the jbytes safely.

static JavaVM* _vm;
static jobject logger;

MPLogSink mpw_log_sink_jni;
bool mpw_log_sink_jni(const MPLogEvent *record) {
    bool sunk = false;

    JNIEnv *env;
    if ((*_vm)->GetEnv( _vm, (void **)&env, JNI_VERSION_1_6 ) != JNI_OK)
        return sunk;

    if (logger && (*env)->PushLocalFrame( env, 16 ) == OK) {
        jmethodID method = NULL;
        jclass Logger = (*env)->GetObjectClass( env, logger );
        switch (record->level) {
            case LogLevelTrace:
                method = (*env)->GetMethodID( env, Logger, "trace", "(Ljava/lang/String;)V" );
                break;
            case LogLevelDebug:
                method = (*env)->GetMethodID( env, Logger, "debug", "(Ljava/lang/String;)V" );
                break;
            case LogLevelInfo:
                method = (*env)->GetMethodID( env, Logger, "info", "(Ljava/lang/String;)V" );
                break;
            case LogLevelWarning:
                method = (*env)->GetMethodID( env, Logger, "warn", "(Ljava/lang/String;)V" );
                break;
            case LogLevelError:
            case LogLevelFatal:
                method = (*env)->GetMethodID( env, Logger, "error", "(Ljava/lang/String;)V" );
                break;
        }

        if (method && record->message) {
            // TODO: log file, line & function as markers?
            (*env)->CallVoidMethod( env, logger, method, (*env)->NewStringUTF( env, record->message ) );
            sunk = true;
        }

        (*env)->PopLocalFrame( env, NULL );
    }

    return sunk;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    JNIEnv *env;
    if ((*vm)->GetEnv( _vm = vm, (void **)&env, JNI_VERSION_1_6 ) != JNI_OK)
        return -1;

    jclass LoggerFactory = (*env)->FindClass( env, "org/slf4j/LoggerFactory" );
    jmethodID method = (*env)->GetStaticMethodID( env, LoggerFactory, "getLogger", "(Ljava/lang/String;)Lorg/slf4j/Logger;" );
    jstring name = (*env)->NewStringUTF( env, "com.lyndir.masterpassword.algorithm" );
    if (LoggerFactory && method && name)
        logger = (*env)->NewGlobalRef( env, (*env)->CallStaticObjectMethod( env, LoggerFactory, method, name ) );
    else
        wrn( "Couldn't initialize JNI logger." );

    jclass Logger = (*env)->GetObjectClass( env, logger );
    if ((*env)->CallBooleanMethod( env, logger, (*env)->GetMethodID( env, Logger, "isTraceEnabled", "()Z" ) ))
        mpw_verbosity = LogLevelTrace;
    else if ((*env)->CallBooleanMethod( env, logger, (*env)->GetMethodID( env, Logger, "isDebugEnabled", "()Z" ) ))
        mpw_verbosity = LogLevelDebug;
    else if ((*env)->CallBooleanMethod( env, logger, (*env)->GetMethodID( env, Logger, "isInfoEnabled", "()Z" ) ))
        mpw_verbosity = LogLevelInfo;
    else if ((*env)->CallBooleanMethod( env, logger, (*env)->GetMethodID( env, Logger, "isWarnEnabled", "()Z" ) ))
        mpw_verbosity = LogLevelWarning;
    else if ((*env)->CallBooleanMethod( env, logger, (*env)->GetMethodID( env, Logger, "isErrorEnabled", "()Z" ) ))
        mpw_verbosity = LogLevelError;
    else
        mpw_verbosity = LogLevelFatal;

    mpw_log_sink_register( &mpw_log_sink_jni );

    return JNI_VERSION_1_6;
}

/* native byte[] _masterKey(final String fullName, final byte[] masterPassword, final int algorithmVersion) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_MPAlgorithm_00024Version__1masterKey(JNIEnv *env, jobject obj,
        jstring fullName, jbyteArray masterPassword, jint algorithmVersion) {

    if (!fullName || !masterPassword)
        return NULL;

    const char *fullNameString = (*env)->GetStringUTFChars( env, fullName, NULL );
    jbyte *masterPasswordString = (*env)->GetByteArrayElements( env, masterPassword, NULL );

    MPMasterKey masterKeyBytes = mpw_master_key( fullNameString, (char *)masterPasswordString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseStringUTFChars( env, fullName, fullNameString );
    (*env)->ReleaseByteArrayElements( env, masterPassword, masterPasswordString, JNI_ABORT );

    if (!masterKeyBytes)
        return NULL;

    jbyteArray masterKey = (*env)->NewByteArray( env, (jsize)MPMasterKeySize );
    (*env)->SetByteArrayRegion( env, masterKey, 0, (jsize)MPMasterKeySize, (jbyte *)masterKeyBytes );
    mpw_free( &masterKeyBytes, MPMasterKeySize );

    return masterKey;
}

/* native byte[] _siteKey(final byte[] masterKey, final String siteName, final long siteCounter,
                          final int keyPurpose, @Nullable final String keyContext, final int version) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_MPAlgorithm_00024Version__1siteKey(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext, jint algorithmVersion) {

    if (!masterKey || !siteName)
        return NULL;

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    MPMasterKey siteKeyBytes = mpw_site_key(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    if (keyContext)
        (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );

    if (!siteKeyBytes)
        return NULL;

    jbyteArray siteKey = (*env)->NewByteArray( env, (jsize)MPMasterKeySize );
    (*env)->SetByteArrayRegion( env, siteKey, 0, (jsize)MPMasterKeySize, (jbyte *)siteKeyBytes );
    mpw_free( &siteKeyBytes, MPSiteKeySize );

    return siteKey;
}

/* native String _siteResult(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                             final int keyPurpose, @Nullable final String keyContext,
                             final int resultType, @Nullable final String resultParam, final int algorithmVersion) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_MPAlgorithm_00024Version__1siteResult(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jbyteArray siteKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext,
        jint resultType, jstring resultParam, jint algorithmVersion) {

    if (!masterKey || !siteKey || !siteName)
        return NULL;

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    jbyte *siteKeyBytes = (*env)->GetByteArrayElements( env, siteKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    const char *resultParamString = resultParam? (*env)->GetStringUTFChars( env, resultParam, NULL ): NULL;
    const char *siteResultString = mpw_site_result(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPResultType)resultType, resultParamString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, siteKey, siteKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    if (keyContext)
        (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );
    if (resultParam)
        (*env)->ReleaseStringUTFChars( env, resultParam, resultParamString );

    if (!siteResultString)
        return NULL;

    jstring siteResult = (*env)->NewStringUTF( env, siteResultString );
    mpw_free_string( &siteResultString );

    return siteResult;
}

/* native String _siteState(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                            final int keyPurpose, @Nullable final String keyContext,
                            final int resultType, final String resultParam, final int algorithmVersion) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_MPAlgorithm_00024Version__1siteState(JNIEnv *env, jobject obj,
        jbyteArray masterKey, jbyteArray siteKey, jstring siteName, jlong siteCounter, jint keyPurpose, jstring keyContext,
        jint resultType, jstring resultParam, jint algorithmVersion) {

    if (!masterKey || !siteKey || !siteName || !resultParam)
        return NULL;

    jbyte *masterKeyBytes = (*env)->GetByteArrayElements( env, masterKey, NULL );
    jbyte *siteKeyBytes = (*env)->GetByteArrayElements( env, siteKey, NULL );
    const char *siteNameString = (*env)->GetStringUTFChars( env, siteName, NULL );
    const char *keyContextString = keyContext? (*env)->GetStringUTFChars( env, keyContext, NULL ): NULL;
    const char *resultParamString = (*env)->GetStringUTFChars( env, resultParam, NULL );
    const char *siteStateString = mpw_site_state(
            (MPMasterKey)masterKeyBytes, siteNameString, (MPCounterValue)siteCounter,
            (MPKeyPurpose)keyPurpose, keyContextString, (MPResultType)resultType, resultParamString, (MPAlgorithmVersion)algorithmVersion );
    (*env)->ReleaseByteArrayElements( env, masterKey, masterKeyBytes, JNI_ABORT );
    (*env)->ReleaseByteArrayElements( env, siteKey, siteKeyBytes, JNI_ABORT );
    (*env)->ReleaseStringUTFChars( env, siteName, siteNameString );
    if (keyContextString)
        (*env)->ReleaseStringUTFChars( env, keyContext, keyContextString );
    if (resultParam)
        (*env)->ReleaseStringUTFChars( env, resultParam, resultParamString );

    if (!siteStateString)
        return NULL;

    jstring siteState = (*env)->NewStringUTF( env, siteStateString );
    mpw_free_string( &siteStateString );

    return siteState;
}
