//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

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
public final class Preferences {

    private static final String      PREF_TESTS_PASSED       = "integrityTestsPassed";
    private static final String      PREF_NATIVE_KDF         = "nativeKDF";
    private static final String      PREF_REMEMBER_FULL_NAME = "rememberFullName";
    private static final String      PREF_FORGET_PASSWORD    = "forgetPassword";
    private static final String      PREF_MASK_PASSWORD      = "maskPassword";
    private static final String      PREF_FULL_NAME          = "fullName";
    private static final String      PREF_RESULT_TYPE        = "resultType";
    private static final String      PREF_ALGORITHM_VERSION  = "algorithmVersion";
    private static       Preferences instance;

    private Context           context;
    @Nullable
    private SharedPreferences prefs;

    public static synchronized Preferences get(final Context context) {
        if (instance == null)
            instance = new Preferences( context );

        return instance;
    }

    private Preferences(final Context context) {
        this.context = context;
    }

    @Nonnull
    private SharedPreferences prefs() {
        if (prefs == null)
            prefs = (context = context.getApplicationContext()).getSharedPreferences( getClass().getCanonicalName(), Context.MODE_PRIVATE );

        return prefs;
    }

    public boolean setNativeKDFEnabled(final boolean enabled) {
        if (isAllowNativeKDF() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_NATIVE_KDF, enabled ).apply();
        return true;
    }

    public boolean isAllowNativeKDF() {
        return prefs().getBoolean( PREF_NATIVE_KDF, true );
    }

    public boolean setTestsPassed(final Set<String> value) {
        if (Sets.symmetricDifference( getTestsPassed(), value ).isEmpty())
            return false;

        prefs().edit().putStringSet( PREF_TESTS_PASSED, value ).apply();
        return true;
    }

    public Set<String> getTestsPassed() {
        return prefs().getStringSet( PREF_TESTS_PASSED, ImmutableSet.of() );
    }

    public boolean setRememberFullName(final boolean enabled) {
        if (isRememberFullName() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_REMEMBER_FULL_NAME, enabled ).apply();
        return true;
    }

    public boolean isRememberFullName() {
        return prefs().getBoolean( PREF_REMEMBER_FULL_NAME, false );
    }

    public boolean setForgetPassword(final boolean enabled) {
        if (isForgetPassword() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_FORGET_PASSWORD, enabled ).apply();
        return true;
    }

    public boolean isForgetPassword() {
        return prefs().getBoolean( PREF_FORGET_PASSWORD, false );
    }

    public boolean setMaskPassword(final boolean enabled) {
        if (isMaskPassword() == enabled)
            return false;

        prefs().edit().putBoolean( PREF_MASK_PASSWORD, enabled ).apply();
        return true;
    }

    public boolean isMaskPassword() {
        return prefs().getBoolean( PREF_MASK_PASSWORD, false );
    }

    public boolean setFullName(@Nullable final String value) {
        if (getFullName().equals( value ))
            return false;

        prefs().edit().putString( PREF_FULL_NAME, value ).apply();
        return true;
    }

    @Nonnull
    public String getFullName() {
        return prefs().getString( PREF_FULL_NAME, "" );
    }

    public boolean setDefaultResultType(final MPResultType value) {
        if (getDefaultResultType() == value)
            return false;

        prefs().edit().putInt( PREF_RESULT_TYPE, value.ordinal() ).apply();
        return true;
    }

    @Nonnull
    public MPResultType getDefaultResultType() {
        return MPResultType.values()[
                prefs().getInt( PREF_RESULT_TYPE, getDefaultVersion().getAlgorithm().mpw_default_result_type().ordinal() )];
    }

    public boolean setDefaultVersion(final MPAlgorithm.Version value) {
        if (getDefaultVersion() == value)
            return false;

        prefs().edit().putInt( PREF_ALGORITHM_VERSION, value.ordinal() ).apply();
        return true;
    }

    @Nonnull
    public MPAlgorithm.Version getDefaultVersion() {
        return MPAlgorithm.Version.values()[
                prefs().getInt( PREF_ALGORITHM_VERSION, MPAlgorithm.Version.CURRENT.ordinal() )];
    }
}
