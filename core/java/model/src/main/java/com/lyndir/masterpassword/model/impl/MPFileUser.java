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

package com.lyndir.masterpassword.model.impl;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import com.lyndir.masterpassword.model.MPUser;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.ReadableInstant;


/**
 * @author lhunath, 14-12-07
 */
@SuppressWarnings("ComparableImplementedButEqualsNotOverridden")
public class MPFileUser extends MPBasicUser<MPFileSite> {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPFileUser.class );

    @Nullable
    private byte[]                   keyID;
    private MPMarshalFormat          format;
    private MPMarshaller.ContentMode contentMode;

    private MPResultType    defaultType;
    private ReadableInstant lastUsed;

    @Nullable
    private MPJSONFile json;

    public MPFileUser(final String fullName) {
        this( fullName, null, MPAlgorithm.Version.CURRENT.getAlgorithm() );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPAlgorithm algorithm) {
        this( fullName, keyID, algorithm, 0, algorithm.mpw_default_result_type(), new Instant(),
              MPMarshalFormat.DEFAULT, MPMarshaller.ContentMode.PROTECTED );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPAlgorithm algorithm,
                      final int avatar, final MPResultType defaultType, final ReadableInstant lastUsed,
                      final MPMarshalFormat format, final MPMarshaller.ContentMode contentMode) {
        super( avatar, fullName, algorithm );

        this.keyID = (keyID == null)? null: keyID.clone();
        this.defaultType = defaultType;
        this.lastUsed = lastUsed;
        this.format = format;
        this.contentMode = contentMode;
    }

    @Nullable
    @Override
    public byte[] getKeyID() {
        return (keyID == null)? null: keyID.clone();
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        if (!algorithm.equals( getAlgorithm() ) && (keyID != null)) {
            if (masterKey == null)
                throw new IllegalStateException( "Cannot update algorithm when keyID is set but masterKey is unavailable." );

            try {
                keyID = masterKey.getKeyID( algorithm );
            }
            catch (final MPKeyUnavailableException e) {
                throw new IllegalStateException( "Cannot update algorithm when keyID is set but masterKey is unavailable.", e );
            }
            catch (final MPAlgorithmException e) {
                throw new IllegalStateException( e );
            }
        }

        super.setAlgorithm( algorithm );
    }

    public MPMarshalFormat getFormat() {
        return format;
    }

    public void setFormat(final MPMarshalFormat format) {
        this.format = format;
    }

    public MPMarshaller.ContentMode getContentMode() {
        return contentMode;
    }

    public void setContentMode(final MPMarshaller.ContentMode contentMode) {
        this.contentMode = contentMode;
    }

    public MPResultType getDefaultType() {
        return defaultType;
    }

    public void setDefaultType(final MPResultType defaultType) {
        this.defaultType = defaultType;
    }

    public ReadableInstant getLastUsed() {
        return lastUsed;
    }

    public void use() {
        lastUsed = new Instant();
    }

    public void setJSON(final MPJSONFile json) {
        this.json = json;
    }

    @Nonnull
    public MPJSONFile getJSON() {
        return (json == null)? json = new MPJSONFile(): json;
    }

    @Override
    public void authenticate(final MPMasterKey masterKey)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {
        super.authenticate( masterKey );

        if (keyID == null)
            keyID = masterKey.getKeyID( getAlgorithm() );
    }

    void save()
            throws MPKeyUnavailableException, MPAlgorithmException {
        MPFileUserManager.get().save( this, getMasterKey() );
    }

    @Override
    public int compareTo(final MPUser<?> o) {
        int comparison = (o instanceof MPFileUser)? getLastUsed().compareTo( ((MPFileUser) o).getLastUsed() ): 0;
        if (comparison != 0)
            return comparison;

        return super.compareTo( o );
    }
}
