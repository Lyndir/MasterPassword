package com.lyndir.masterpassword.model;

import com.google.common.collect.ImmutableList;
import java.util.Collection;


/**
 * @author lhunath, 14-12-05
 */
public abstract class MPSiteManager {

    private final MPUser user;

    public MPSiteManager(final MPUser user) {
        this.user = user;
    }

    public MPUser getUser() {
        return user;
    }

    public Collection<MPSiteResult> findSitesByName(String query) {
        ImmutableList.Builder<MPSiteResult> results = ImmutableList.builder();
        for (MPSite site : user.getSites())
            if (site.getSiteName().startsWith( query ))
                results.add( new MPSiteResult( site ) );

        return results.build();
    }
}
