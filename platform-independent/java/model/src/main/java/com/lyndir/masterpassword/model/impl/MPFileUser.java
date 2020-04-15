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
import com.lyndir.masterpassword.model.*;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.io.File;
import java.io.IOException;
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
    private String                   keyID;
    private File                     file;
    private MPMarshalFormat          format;
    private MPMarshaller.ContentMode contentMode;
    private ReadableInstant          lastUsed;
    private boolean                  complete;

    private final MPFileUserPreferences preferences;

    @Nullable
    public static MPFileUser load(final File file)
            throws IOException, MPMarshalException {
        for (final MPMarshalFormat format : MPMarshalFormat.values())
            if (format.matches( file ))
                return format.unmarshaller().readUser( file );

        return null;
    }

    public MPFileUser(final String fullName, final File location) {
        this( fullName, null, MPAlgorithm.Version.CURRENT, location );
    }

    public MPFileUser(final String fullName, @Nullable final String keyID, final MPAlgorithm algorithm, final File location) {
        this( fullName, keyID, algorithm, 0, null, new Instant(), false,
              MPMarshaller.ContentMode.PROTECTED, MPMarshalFormat.DEFAULT, location );
    }

    @SuppressFBWarnings("PATH_TRAVERSAL_IN")
    public MPFileUser(final String fullName, @Nullable final String keyID, final MPAlgorithm algorithm, final int avatar,
                      @Nullable final MPResultType defaultType, final ReadableInstant lastUsed, final boolean hidePasswords,
                      final MPMarshaller.ContentMode contentMode, final MPMarshalFormat format, final File location) {
        super( avatar, fullName, algorithm );

        this.keyID = keyID;
        this.lastUsed = lastUsed;
        this.preferences = new MPFileUserPreferences( this, defaultType, hidePasswords );
        this.format = format;
        this.contentMode = contentMode;

        if (location.isDirectory())
            this.file = new File( location, getFullName() + getFormat().fileSuffix() );
        else
            this.file = location;
    }

    @Nullable
    @Override
    public String getKeyID() {
        return keyID;
    }

    @Nonnull
    @Override
    public MPUserPreferences getPreferences() {
        return preferences;
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

    public MPMarshaller.ContentMode getContentMode() {
        return contentMode;
    }

    public void setContentMode(final MPMarshaller.ContentMode contentMode) {
        if (this.contentMode == contentMode)
            return;

        this.contentMode = contentMode;
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
        return file;
    }

    public void migrateTo(final MPMarshalFormat format) {
        if (this.format == format)
            return;

        migrateTo( file.getParentFile(), format );
    }

    public void migrateTo(final File path) {
        migrateTo( path, format );
    }

    /**
     * Move the file for this user to the given path using a standard user-derived filename (ie. {@code [full name].[format suffix]})
     *
     * The user's old file is either moved to the new or deleted.  If the user's file was already at the destination, it doesn't change.
     * If a file already exists at the destination, it is overwritten.
     */
    @SuppressFBWarnings("PATH_TRAVERSAL_IN")
    public void migrateTo(final File path, final MPMarshalFormat newFormat) {
        MPMarshalFormat oldFormat = format;
        File            oldFile   = file, newFile = new File( path, getFullName() + newFormat.fileSuffix() );

        // If the format hasn't changed, migrate by moving the file: the contents doesn't need to change.
        if ((oldFormat == newFormat) && !oldFile.equals( newFile ) && oldFile.exists())
            if (!oldFile.renameTo( newFile ))
                logger.wrn( "Couldn't move %s to %s for migration.", oldFile, newFile );

        this.format = newFormat;
        this.file = newFile;

        // If the format has changed, save the new format into the new file and delete the old file.  Revert if the user cannot be saved.
        if ((oldFormat != newFormat) && !oldFile.equals( newFile ))
            if (save()) {
                if (oldFile.exists() && !oldFile.delete())
                    logger.wrn( "Couldn't delete %s after migration.", oldFile );
            } else {
                this.format = oldFormat;
                this.file = oldFile;
            }
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

    /**
     * @return {@code false} if the user is not fully loaded (complete), authenticated, or an issue prevented the marshalling.
     */
    public boolean save() {
        if (!isComplete())
            return false;

        try {
            getFormat().marshaller().marshall( this );
            return true;
        }
        catch (final MPKeyUnavailableException e) {
            logger.wrn( e, "Cannot write out changes for unauthenticated user: %s.", this );
        }
        catch (final IOException | MPMarshalException | MPAlgorithmException e) {
            logger.err( e, "Unable to write out changes for user: %s", this );
        }

        return false;
    }

    @Override
    public void reset() {
        keyID = null;

        super.reset();
    }

    @Nonnull
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
