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
import java.io.File;
import java.io.IOException;
import java.util.Objects;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.ReadableInstant;


/**
 * @author lhunath, 14-12-07
 */
@SuppressWarnings("ComparableImplementedButEqualsNotOverridden")
public class MPFileUser extends MPBasicUser<MPFileSite> {

    private static final Logger logger = Logger.get( MPFileUser.class );

    @Nullable
    private byte[]                   keyID;
    private File                     path;
    private MPMarshalFormat          format;
    private MPMarshaller.ContentMode contentMode;

    private MPResultType    defaultType;
    private ReadableInstant lastUsed;
    private boolean         complete;

    @Nullable
    public static MPFileUser load(final File file)
            throws IOException, MPMarshalException {
        for (final MPMarshalFormat format : MPMarshalFormat.values())
            if (file.getName().endsWith( format.fileSuffix() ))
                    return format.unmarshaller().readUser( file );

        return null;
    }

    public MPFileUser(final String fullName, final File path) {
        this( fullName, null, MPAlgorithm.Version.CURRENT.getAlgorithm(), path );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPAlgorithm algorithm, final File path) {
        this( fullName, keyID, algorithm, 0, null, new Instant(),
              MPMarshaller.ContentMode.PROTECTED, MPMarshalFormat.DEFAULT, path );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPAlgorithm algorithm,
                      final int avatar, @Nullable final MPResultType defaultType, final ReadableInstant lastUsed,
                      final MPMarshaller.ContentMode contentMode, final MPMarshalFormat format, final File path) {
        super( avatar, fullName, algorithm );

        this.keyID = (keyID != null)? keyID.clone(): null;
        this.defaultType = (defaultType != null)? defaultType: algorithm.mpw_default_result_type();
        this.lastUsed = lastUsed;
        this.path = path;
        this.format = format;
        this.contentMode = contentMode;
    }

    @Nullable
    @Override
    public byte[] getKeyID() {
        return (keyID == null)? null: keyID.clone();
    }

    public void setPath(final File path) {
        this.path = path;
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
        if (Objects.equals( this.format, format ))
            return;

        this.format = format;
        setChanged();
    }

    public MPMarshaller.ContentMode getContentMode() {
        return contentMode;
    }

    public void setContentMode(final MPMarshaller.ContentMode contentMode) {
        if (Objects.equals( this.contentMode, contentMode ))
            return;

        this.contentMode = contentMode;
        setChanged();
    }

    public MPResultType getDefaultType() {
        return defaultType;
    }

    public void setDefaultType(final MPResultType defaultType) {
        if (Objects.equals( this.defaultType, defaultType ))
            return;

        this.defaultType = defaultType;
        setChanged();
    }

    public ReadableInstant getLastUsed() {
        return lastUsed;
    }

    public void use() {
        lastUsed = new Instant();
        setChanged();
    }

    protected boolean isComplete() {
        return complete;
    }

    protected void setComplete() {
        complete = true;
    }

    public File getFile() {
        return new File( path, getFullName() + getFormat().fileSuffix() );
    }

    @Override
    public void authenticate(final MPMasterKey masterKey)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {
        super.authenticate( masterKey );

        try {
            getFormat().unmarshaller().readSites( this );
        }
        catch (final IOException | MPMarshalException e) {
            logger.err( e, "While reading sites on authentication." );
        }

        if (keyID == null) {
            keyID = masterKey.getKeyID( getAlgorithm() );
            setChanged();
        }
    }

    public void save() {
        try {
            if (isComplete())
                getFormat().marshaller().marshall( this );
        }
        catch (final MPKeyUnavailableException e) {
            logger.wrn( e, "Cannot write out changes for unauthenticated user: %s.", this );
        }
        catch (final IOException | MPMarshalException | MPAlgorithmException e) {
            logger.err( e, "Unable to write out changes for user: %s", this );
        }
    }

    @Override
    public void reset() {
        keyID = null;

        super.reset();
    }

    @Override
    public MPFileSite addSite(final String siteName) {
        return addSite( new MPFileSite( this, siteName ) );
    }

    @Override
    protected void onChanged() {
        save();

        super.onChanged();
    }

    @Override
    public int compareTo(@Nonnull final MPUser<?> o) {
        int comparison = (o instanceof MPFileUser)? ((MPFileUser) o).getLastUsed().compareTo( getLastUsed() ): 0;
        if (comparison != 0)
            return comparison;

        return super.compareTo( o );
    }
}
