package com.lyndir.masterpassword.model;

import com.google.common.collect.Sets;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.MPSiteType;
import java.util.*;
import org.joda.time.DateTime;


/**
 * @author lhunath, 14-12-07
 */
public class MPUser {

    private final String     fullName;
    private final byte[]     keyID;
    private final int        avatar;
    private final MPSiteType defaultType;
    private final DateTime   lastUsed;
    private final Collection<MPSite> sites = Sets.newHashSet();

    public MPUser(final String fullName, final byte[] keyID) {
        this( fullName, keyID, 0, MPSiteType.GeneratedLong, new DateTime() );
    }

    public MPUser(final String fullName, final byte[] keyID, final int avatar, final MPSiteType defaultType, final DateTime lastUsed) {
        this.fullName = fullName;
        this.keyID = keyID;
        this.avatar = avatar;
        this.defaultType = defaultType;
        this.lastUsed = lastUsed;
    }

    public void addSite(final MPSite site) {
        sites.add( site );
    }

    public String getFullName() {
        return fullName;
    }

    public boolean hasKeyID(final byte[] keyID) {
        return Arrays.equals( this.keyID, keyID );
    }

    public String exportKeyID() {
        return CodeUtils.encodeHex( keyID );
    }

    public int getAvatar() {
        return avatar;
    }

    public MPSiteType getDefaultType() {
        return defaultType;
    }

    public DateTime getLastUsed() {
        return lastUsed;
    }

    public Iterable<MPSite> getSites() {
        return sites;
    }
}
