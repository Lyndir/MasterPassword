package com.lyndir.masterpassword;

import android.content.Context;
import android.content.SharedPreferences;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;
import java.util.Set;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2016-02-20
 */
public class Preferences {

    private static final String PREF_TESTS_PASSED       = "integrityTestsPassed";
    private static final String PREF_NATIVE_KDF         = "nativeKDF";
    private static final String PREF_REMEMBER_FULL_NAME = "rememberFullName";
    private static final String PREF_FORGET_PASSWORD    = "forgetPassword";
    private static final String PREF_MASK_PASSWORD      = "maskPassword";
    private static final String PREF_FULL_NAME          = "fullName";
    private static final String PREF_SITE_TYPE          = "siteType";
    private static Preferences instance;

    private Context           context;
    @Nullable
    private SharedPreferences prefs;

    public static synchronized Preferences get(final Context context) {
        if (instance == null)
            instance = new Preferences( context );

        return instance;
    }

    private Preferences(Context context) {
        this.context = context;
    }

    @Nonnull
    private SharedPreferences prefs() {
        if (prefs == null)
            prefs = (context = context.getApplicationContext()).getSharedPreferences( getClass().getCanonicalName(), Context.MODE_PRIVATE );

        return prefs;
    }

    public boolean setNativeKDFEnabled(boolean enabled) {
        if (isAllowNativeKDF() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_NATIVE_KDF, enabled ).apply();
        return true;
    }

    public boolean isAllowNativeKDF() {
        return prefs().getBoolean( PREF_NATIVE_KDF, MasterKey.isAllowNativeByDefault() );
    }

    public boolean setTestsPassed(final Set<String> value) {
        if (Sets.symmetricDifference( getTestsPassed(), value ).isEmpty())
            return false;

        prefs().edit().putStringSet( PREF_TESTS_PASSED, value ).apply();
        return true;
    }

    public Set<String> getTestsPassed() {
        return prefs().getStringSet( PREF_TESTS_PASSED, ImmutableSet.<String>of() );
    }

    public boolean setRememberFullName(boolean enabled) {
        if (isRememberFullName() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_REMEMBER_FULL_NAME, enabled ).apply();
        return true;
    }

    public boolean isRememberFullName() {
        return prefs().getBoolean( PREF_REMEMBER_FULL_NAME, false );
    }

    public boolean setForgetPassword(boolean enabled) {
        if (isForgetPassword() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_FORGET_PASSWORD, enabled ).apply();
        return true;
    }

    public boolean isForgetPassword() {
        return prefs().getBoolean( PREF_FORGET_PASSWORD, false );
    }

    public boolean setMaskPassword(boolean enabled) {
        if (isMaskPassword() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_MASK_PASSWORD, enabled ).apply();
        return true;
    }

    public boolean isMaskPassword() {
        return prefs().getBoolean( PREF_MASK_PASSWORD, false );
    }

    public boolean setFullName(@Nullable String value) {
        if (getFullName().equals( value ))
            return false;

        prefs().edit().putString( PREF_FULL_NAME, value ).apply();
        return true;
    }

    @Nonnull
    public String getFullName() {
        return prefs().getString( PREF_FULL_NAME, "" );
    }

    public boolean setDefaultSiteType(@Nonnull MPSiteType value) {
        if (getDefaultSiteType().equals( value ))
            return false;

        prefs().edit().putInt( PREF_SITE_TYPE, value.ordinal() ).apply();
        return true;
    }

    @Nonnull
    public MPSiteType getDefaultSiteType() {
        return MPSiteType.values()[prefs().getInt( PREF_SITE_TYPE, MPSiteType.GeneratedLong.ordinal() )];
    }

    public boolean setDefaultVersion(@Nonnull MasterKey.Version value) {
        if (getDefaultVersion().equals( value ))
            return false;

        prefs().edit().putInt( PREF_SITE_TYPE, value.ordinal() ).apply();
        return true;
    }

    @Nonnull
    public MasterKey.Version getDefaultVersion() {
        return MasterKey.Version.values()[prefs().getInt( PREF_SITE_TYPE, MasterKey.Version.CURRENT.ordinal() )];
    }
}
