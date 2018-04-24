To build a release distribution:

STORE_PW=$(mpw masterpassword.keystore) KEY_PW=$(mpw masterpassword-android) gradle assembleRelease

Note:

 - At the time of writing, Android does not build with JDK 9+.  As such, the above command must be ran with JAVA_HOME pointing to JDK 7-8.
