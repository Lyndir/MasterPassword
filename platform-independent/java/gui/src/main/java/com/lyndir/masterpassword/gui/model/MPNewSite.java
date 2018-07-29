package com.lyndir.masterpassword.gui.model;

import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.*;


/**
 * @author lhunath, 2018-07-27
 */
public class MPNewSite extends MPBasicSite<MPUser<?>, MPQuestion> {

    public MPNewSite(final MPUser<?> user, final String siteName) {
        super( user, siteName );
    }
}
