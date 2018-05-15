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

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import javax.annotation.Nullable;


/**
 * @see MPMasterKey.Version
 */
@SuppressWarnings({ "FieldMayBeStatic", "NewMethodNamingConvention", "MethodReturnAlwaysConstant" })
public abstract class MPAlgorithm {

    public abstract byte[] masterKey(String fullName, char[] masterPassword);

    public abstract byte[] siteKey(byte[] masterKey, String siteName, UnsignedInteger siteCounter,
                                   MPKeyPurpose keyPurpose, @Nullable String keyContext);

    public abstract String siteResult(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
                                      MPKeyPurpose keyPurpose, @Nullable String keyContext,
                                      MPResultType resultType, @Nullable String resultParam);

    public abstract String sitePasswordFromTemplate(byte[] masterKey, byte[] siteKey,
                                                    MPResultType resultType, @Nullable String resultParam);

    public abstract String sitePasswordFromCrypt(byte[] masterKey, byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    public abstract String sitePasswordFromDerive(byte[] masterKey, byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    public abstract String siteState(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
                                     MPKeyPurpose keyPurpose, @Nullable String keyContext,
                                     MPResultType resultType, String resultParam);

    // Configuration

    public abstract MPMasterKey.Version version();

    /**
     * mpw: defaults: password result type.
     */
    public abstract MPResultType mpw_default_result_type();

    /**
     * mpw: defaults: login result type.
     */
    public abstract MPResultType mpw_default_login_type();

    /**
     * mpw: defaults: answer result type.
     */
    public abstract MPResultType mpw_default_answer_type();

    /**
     * mpw: defaults: initial counter value.
     */
    public abstract UnsignedInteger mpw_default_counter();

    /**
     * mpw: validity for the time-based rolling counter (s).
     */
    public abstract long mpw_otp_window();

    /**
     * mpw: Key ID hash.
     */
    public abstract MessageDigests mpw_hash();

    /**
     * mpw: Site digest.
     */
    public abstract MessageAuthenticationDigests mpw_digest();

    /**
     * mpw: Platform-agnostic byte order.
     */
    public abstract ByteOrder mpw_byteOrder();

    /**
     * mpw: Input character encoding.
     */
    public abstract Charset mpw_charset();

    /**
     * mpw: Master key size (byte).
     */
    public abstract int mpw_dkLen();

    /**
     * mpw: Minimum size for derived keys (bit).
     */
    public abstract int mpw_keySize_min();

    /**
     * mpw: Maximum size for derived keys (bit).
     */
    public abstract int mpw_keySize_max();

    /**
     * scrypt: Parallelization parameter.
     */
    public abstract int scrypt_p();

    /**
     * scrypt: Memory cost parameter.
     */
    public abstract int scrypt_r();

    /**
     * scrypt: CPU cost parameter.
     */
    public abstract int scrypt_N();

    // Utilities

    abstract byte[] toBytes(int number);

    abstract byte[] toBytes(UnsignedInteger number);

    abstract byte[] toBytes(char[] characters);

    abstract byte[] toID(byte[] bytes);
}
