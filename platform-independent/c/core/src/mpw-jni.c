#include <string.h>

#include "java/com_lyndir_masterpassword_impl_MPAlgorithmV0.h"

#include "mpw-algorithm.h"
#include "mpw-util.h"

// TODO: We may need to zero the jbytes safely.

static JavaVM* _vm;
static jobject logger;

void mpw_log_app(LogLevel level, const char *format, ...) {
    JNIEnv *env;
    if ((*_vm)->GetEnv( _vm, (void **)&env, JNI_VERSION_1_6 ) != JNI_OK)
        return;

    va_list args;
    va_start( args, format );

    if (logger && (*env)->PushLocalFrame( env, 16 ) == OK) {
        jmethodID method = NULL;
        jclass Logger = (*env)->GetObjectClass( env, logger );
        if (level >= LogLevelTrace)
            method = (*env)->GetMethodID( env, Logger, "trace", "(Ljava/lang/String;)V" );
        else if (level == LogLevelDebug)
            method = (*env)->GetMethodID( env, Logger, "debug", "(Ljava/lang/String;)V" );
        else if (level == LogLevelInfo)
            method = (*env)->GetMethodID( env, Logger, "info", "(Ljava/lang/String;)V" );
        else if (level == LogLevelWarning)
            method = (*env)->GetMethodID( env, Logger, "warn", "(Ljava/lang/String;)V" );
        else if (level <= LogLevelError)
            method = (*env)->GetMethodID( env, Logger, "error", "(Ljava/lang/String;)V" );

        va_list _args;
        va_copy( _args, args );
        int length = vsnprintf( NULL, 0, format, _args );
        va_end( _args );

        if (length > 0) {
            size_t size = (size_t) (length + 1);
            char *message = malloc( size );
            va_copy( _args, args );
            if (message && (length = vsnprintf( message, size, format, _args )) > 0)
                (*env)->CallVoidMethod( env, logger, method, (*env)->NewStringUTF( env, message ) );
            va_end( _args );
            mpw_free( &message, (size_t)max( 0, length ) );
        }

        (*env)->PopLocalFrame( env, NULL );
    }
    else
        // Can't log via slf4j, fall back to cli logger.
        mpw_vlog_cli( level, format, args );

    va_end( args );
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

    return JNI_VERSION_1_6;
}

/* native int _masterKey(final String fullName, final byte[] masterPassword, final Version version) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1masterKey(JNIEnv *env, jobject obj,
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

/* native int _siteKey(final byte[] masterKey, final String siteName, final long siteCounter,
                       final MPKeyPurpose keyPurpose, @Nullable final String keyContext,  final Version version) */
JNIEXPORT jbyteArray JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteKey(JNIEnv *env, jobject obj,
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
                             final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                             final MPResultType resultType, @Nullable final String resultParam, final Version version) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteResult(JNIEnv *env, jobject obj,
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
                            final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            final MPResultType resultType, final String resultParam, final Version version) */
JNIEXPORT jstring JNICALL Java_com_lyndir_masterpassword_impl_MPAlgorithmV0__1siteState(JNIEnv *env, jobject obj,
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
