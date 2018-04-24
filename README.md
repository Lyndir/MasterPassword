[![Travis CI](http://img.shields.io/travis-ci/Lyndir/MasterPassword.png)](https://travis-ci.org/Lyndir/MasterPassword)
[![Join the chat at https://gitter.im/lyndir/MasterPassword](https://badges.gitter.im/lyndir/MasterPassword.svg)](https://gitter.im/lyndir/MasterPassword?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![license](https://img.shields.io/github/license/lyndir/masterpassword.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)




# [Master Password •••|](http://masterpasswordapp.com)

Master Password is a completely new way of thinking about passwords.

It consists of an algorithm that implements the core idea and applications for various platforms making the alogirthm available to users on a variety of devices and platforms.

To skip the intro and go straight to the information on how to use the code, [click here](#source-code).

Master Password is available for [📲 iOS](https://itunes.apple.com/app/id510296984), [🖥 macOS](https://ssl.masterpasswordapp.com/masterpassword-mac.zip), [📲 Android](https://ssl.masterpasswordapp.com/masterpassword-android.apk), [🖥 Desktop](https://ssl.masterpasswordapp.com/masterpassword-gui.jar), and [⌨ Console](https://ssl.masterpasswordapp.com/masterpassword-cli.tar.gz).

Master Password is also available from the following package managers: [macOS: Homebrew](https://brew.sh/) (`brew install mpw`).
Get in touch if you are interested in adding Master Password to any other package managers.

There are many reasons for using Master Password instead of an ordinary password manager, read below for the details, but if you want my personal favourites, they would be:

 - I don't need to worry about keeping backups of my countless authentication credentials.
 - I don't need to worry that when I travel, I might not have access to my passwords vault.
 - I don't need to trust an external party, proprietary code or a service to be online and stay online.
 - If I feel at risk of my device being stolen or confiscated, I can set a fake master password, delete my user or wipe it worry-free.

We also have a [Frequently Asked Questions](#faq).



## What is a password?

Ah, the "password".  Somehow, passwords have become the default solution to authentication across the web.  We've long since accepted this as the way things are, but let's stop to think for a moment about what passwords actually are:

A password is a secret that is known only to the party providing a service and the party that should be allowed access to this service.

Simple enough - a secret that you know and your website knows but nobody else, thereby guaranteeing that you and only you have access to your account on this website.  Unfortunately, in practice, the ubiquitous use of passwords has us completely overwhelmed.  And the only way we can cope with that is by finding ways of making the problem manageable.



## What's the problem?

Coming up with a secret password is pretty easy.  Say you're organizing a secret meeting and will only let people in if they know the password at the door.  You tell those you trust, the password for tonight's meeting is "purple oranges with a smile".

The problem we have in our daily lives, however, is the fact that we need secret passwords for almost everything now.  A password for our email, twitter, 9gag, facebook, imgur, amazon, ebay, paypal, bank, reddit, etc.  And every time we want to use a new site, we need another one.  The problem now becomes clear: passwords are meant to be remembered and recalled with ease when needed, but this becomes impossible when we have secrets for every distinct activity in our lives.

We cannot recall passwords the way we are expected to when there are too many.



## Coping

Life gives us no advice on how to deal with this problem.  So we find our own ways:

 - We use a single personal secret for all our websites, thereby violating the secrecy of these passwords (eg. you've given your email secret to twitter).
 - We use simple variations of a personal secret or pattern, thereby trivializing the complexity of these passwords (eg. google98, twitter98; reversals, eg. 8991elgoog)
 - We use external means of remembering passwords, thereby increasing the risk of loss (both loss of access when we lose the tool and theft when a thief finds our tool)

These coping mechanisms come in various forms, and they all have down-sides, because at the root of each of these lies an undeniable truth:

Our passwords are no longer true to the original definition.



## Master Password's approach

The theory behind Master Password starts with accepting that it is impossible to keep track of passwords for all your accounts.  Instead, we return to the core premise of the password: a secret phrase that you can remember easily, all by yourself.

Master Password solves this problem by letting you remember one and only one password.  You use this password with Master Password only.  Master Password then gives you access to any website or service you want by creating a website-specific key for it.

1. You sign into Master Password using your one password.
2. You ask Master Password for the key to enter your website, eg. twitter.
3. You log into twitter using your username and the key from Master Password.

Master Password is *not* a password manager.  It does not store your website passwords.  Therefore, there is zero risk of you losing your website passwords (or them falling in the wrong hands).  Master Password simply uses your one password and the name of the site to generate a site-specific secret.



## Benefits

 - You don't need to think up a new strong password every time you make a new account - Master Password gives you the key for it.
 - You don't need to try remembering a password you created two years ago for that one account - Master Password just gives you the key for it.
 - You don't need to worry about getting into that account you made at work after you come home because you don't have your office passwords with you - Master Password is availale everywhere, even offline.
 - You don't need to try to keep password lists in sync or stored somewhere easily accessible - Master Password keys can be created anywhere.
 - You don't need to worry what you'll do if your computer dies or you need to log into your bank while you're in the airport transit zone - your Master Password keys are always available, even when starting empty.
 - You don't need to worry about your password manager website getting hacked, your phone getting duplicated, somebody taking a picture of your passwords book - Master Password stores no secrets.



## How does it work?

The details of how Master Password works [are available here](http://masterpasswordapp.com/algorithm.html).

In short:

    master-key = SCRYPT( user-name, master-password )
    site-key = HMAC-SHA-256( site-name . site-counter, master-key )
    site-password = PW-TEMPLATE( site-key, site-template )

Master Password can derive the `site-password` in an entirely stateless manner.  It is therefore better defined as a calculator than a manager.  It is the user's responsibility to remember the inputs: `user-name`, `master-password`, `site-name`, `site-counter` and `site-template`.

We standardize `user-name` as your full name, `site-name` as the domain name of the site, `site-counter` to `1` (unless you explicitly increment it) and `site-template` to `Long Password`; as a result the only token the user really needs to remember actively is `master-password`.



## FAQ

 1. If I lose my master password and need to set a new one, will I need to change all of my site passwords?

Yes.  If your master password is compromised, it is only sensible for you to change all of your site passwords.  Just like if you lose the keys in your pocket, you'll have to change all the locks they open.  Master Password effectively enforces this security practice.

 2. But what if I just forget my master password or I just want to change it to something else?

Sorry, still yes.  Your master password is the secret component to your Master Password identity.  If it changes, your identity changes.  I wholly encourage you to think very carefully about what makes for a really memorable and good master password before just diving in with something lazy.  A short phrase works great, eg. `banana coloured duckling`.

 3. Doesn't this mean an attacker can reverse my master password from any of my site passwords?

Technically, yes.  Practically, no.

You could argue that site passwords are "breadcrumbs" of your master password, but the same argument would suggest encrypted messages are breadcrumbs to the encryption key.  Encryption works because it is computationally unfeasible to "guess" the encryption key that made the encrypted message, just like Master Password works because it is computationally unfeasible to "guess" your master password that made the site password.

 4. The second step is just a HMAC-SHA-256, doesn't that make the SCRYPT completely pointless?

No.  They are used for different reasons and one is not weaker than the other.

HMAC-SHA-256 is much faster to compute than SCRYPT, which leads some people to think "all an attacker needs to do is brute-force the SHA and ignore the SCRYPT".  The reality is that the HMAC-SHA-256 guards a 64-byte authentication key (the `master-key`) which makes the search space for brute-forcing the HMAC wildly too large to compute.
The `master-password` on the other hand, is only a simple phrase, which means its search space is much smaller.  This is why it is guarded by a much tougher SCRYPT operation.

 5. I have another question.

Please don't hesitate to [get in touch](#support), we're more than happy to answer all your Master Password questions.  Any problems or suggestions can be reported [as GitHub issues](https://github.com/Lyndir/MasterPassword/issues).




# Source Code

Master Password's algorithm is [documented](http://masterpasswordapp.com/algorithm.html) and its implementation is Free Software (GPLv3).



## Components

There are several components available here.  As an end-user, you can currently use the iOS app, the Android app, the OS X app, the Java desktop app, the C CLI app or the Java CLI app.  There are also several components that are useful for developers:

 - `core/c`: This is the reference implementation of the Master Password algorithm, written in C.
 - `core/java/algorithm`: This is a Java implementation of the Master Password algorithm.
 - `core/java/model`: This is an object model to simplify use of Master Password by Java applications.
 - `core/java/tests`: These are Java integration tests designed to ensure Master Password performs as expected.
 - `platform-android`: This is the official Android implementation of Master Password in Java.
 - `platform-darwin`: This is the official iOS and OS X implementation of Master Password in Objective-C.
 - `platform-independent/cli-c`: This is the platform-independent console implementation of Master Password, written in C.
 - `platform-independent/cli-java`: This is the platform-independent console implementation of Master Password, written in Java.
 - `platform-independent/gui-java`: This is the platform-independent desktop implementation of Master Password, written in Java.
 - `platform-independent/web-js`: This is the platform-independent browser application for Master Password, written in JavaScript.



## Building and running


### macOS or iOS

Make sure you have all relevant submodules checked out.

Go into `platform-darwin` and open `MasterPassword.xcworkspace` in Xcode.  Select the desired target from the Scheme Selector and build, run or archive.


### Web

Make sure you have all relevant submodules checked out.

Go into `platform-independent/web-js` and open `index.html` in your browser.  You should be able to run this locally, there is no need for hosting or an application server.


### Java

Go into the `gradle` directory and run `./gradlew build`.  All Java components will then be built:

 - `platform-independent/gui-java/build/distributions`:
   contains an archive with the Master Password Java GUI.  Unpack it and run the `gui` script.
 - `platform-independent/cli-java/build/distributions`:
   contains an archive with the Master Password Java command-line interface.  Unpack it and run the `cli` script.
 - `platform-android/build/outputs/apk`:
   contains the Android application package.  Install it on your Android device.

Note that in order to build the Android application, you will need to have the Android SDK installed and either have the environment variable `ANDROID_HOME` set to its location or a `gradle/local.properties` file with its location, eg. (for Homebrew users who installed the SDK using `brew install android-sdk`):

    sdk.dir=/usr/local/opt/android-sdk


### Native CLI

Go into the `platform-independent/cli-c` directory and run `./build`.  The native command-line client will then be built.

For detailed instructions, see [the native CLI instructions](platform-independent/cli-c/README.md).

### Docker

Using [Docker](https://hub.docker.com/r/ellioseven/mpw/), run with:

```
docker run -ti --rm ellioseven/mpw /usr/bin/mpw
```

## Support

Feel free to contribute by forking the project, reporting issues or joining the discussion on:

 - [Gitter](https://gitter.im/lyndir/MasterPassword)
 - #masterpassword (on chat.freenode.net)
 - #masterpassword:lyndir.com (on Matrix)
 - masterpassword@lyndir.com
