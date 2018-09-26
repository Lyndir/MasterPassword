package com.lyndir.masterpassword.gui.model;

import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.MPBasicSite;
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

    public <S extends MPSite<?>> S addTo(final MPUser<S> user) {
        S site = user.addSite( getSiteName() );
        site.setAlgorithm( getAlgorithm() );
        site.setCounter( getCounter() );
        site.setLoginType( getLoginType() );
        site.setResultType( getResultType() );

        return site;
    }
}
