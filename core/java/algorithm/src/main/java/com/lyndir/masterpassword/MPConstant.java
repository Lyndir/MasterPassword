package com.lyndir.masterpassword;

import com.google.common.base.Charsets;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import java.nio.ByteOrder;
import java.nio.charset.Charset;


/**
 * @author lhunath, 2016-10-29
 */
public class MPConstant {

    /* Environment */

    /**
     * mpw: default user name if one is not provided.
     */
    public static final String env_userName     = "MP_USERNAME";
    /**
     * mpw: default site type if one is not provided.
     *
     * @see MPSiteType#forOption(String)
     */
    public static final String env_siteType     = "MP_SITETYPE";
    /**
     * mpw: default site counter value if one is not provided.
     */
    public static final String env_siteCounter  = "MP_SITECOUNTER";
    /**
     * mpw: default path to look for run configuration files if the platform default is not desired.
     */
    public static final String env_rcDir        = "MP_RCDIR";
    /**
     * mpw: permit automatic update checks.
     */
    public static final String env_checkUpdates = "MP_CHECKUPDATES";

    /* Algorithm */

    /**
     * scrypt: CPU cost parameter.
     */
    public static final int                          scrypt_N      = 32768;
    /**
     * scrypt: Memory cost parameter.
     */
    public static final int                          scrypt_r      = 8;
    /**
     * scrypt: Parallelization parameter.
     */
    public static final int                          scrypt_p      = 2;
    /**
     * mpw: Master key size (byte).
     */
    public static final int                          mpw_dkLen     = 64;
    /**
     * mpw: Input character encoding.
     */
    public static final Charset                      mpw_charset   = Charsets.UTF_8;
    /**
     * mpw: Platform-agnostic byte order.
     */
    public static final ByteOrder                    mpw_byteOrder = ByteOrder.BIG_ENDIAN;
    /**
     * mpw: Site digest.
     */
    public static final MessageAuthenticationDigests mpw_digest    = MessageAuthenticationDigests.HmacSHA256;
    /**
     * mpw: Key ID hash.
     */
    public static final MessageDigests               mpw_hash      = MessageDigests.SHA256;
}
