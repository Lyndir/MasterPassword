package com.lyndir.masterpassword.gui.model;

import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.*;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2018-07-27
 */
public class MPNewSite extends MPBasicSite<MPUser<?>, MPQuestion> {

    public MPNewSite(final MPUser<?> user, final String siteName) {
        super( user, siteName );
    }

    @Nonnull
    @Override
    public MPQuestion addQuestion(final String keyword) {
        throw new UnsupportedOperationException( "Cannot add a question to a site that hasn't been created yet." );
    }
}
