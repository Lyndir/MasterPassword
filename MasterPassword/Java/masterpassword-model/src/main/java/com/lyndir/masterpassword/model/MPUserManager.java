package com.lyndir.masterpassword.model;

import com.google.common.collect.*;
import java.util.*;


/**
 * @author lhunath, 14-12-05
 */
public abstract class MPUserManager {

    private final Map<String, MPUser> usersByName = Maps.newHashMap();
    static MPUserManager instance;

    public static MPUserManager get() {
        return instance;
    }

    protected MPUserManager(final Iterable<MPUser> users) {
        for (MPUser user : users)
            addUser( user );
    }

    public SortedSet<MPUser> getUsers() {
        return FluentIterable.from( usersByName.values() ).toSortedSet( Ordering.natural() );
    }

    public void addUser(final MPUser user) {
        usersByName.put( user.getFullName(), user );
    }
}
