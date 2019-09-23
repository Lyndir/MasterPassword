To build a release distribution:

Desktop:

    STORE_PW=$(mpw masterpassword.keystore) KEY_PW_DESKTOP=$(mpw masterpassword-desktop) gradle --no-daemon clean masterpassword-gui:shadowJar

Android:

    STORE_PW=$(mpw masterpassword.keystore) KEY_PW_ANDROID=$(mpw masterpassword-android) gradle --no-daemon clean masterpassword-android:assembleRelease


Note:

 - At the time of writing, Android does not build with JDK 9+.  As such, the above command must be ran with JAVA_HOME pointing to JDK 7-8.
 - The release keystores are not included in the repository.  They are maintained by Maarten Billemont (lhunath@lyndir.com).
