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
        for (final MPUser user : users)
            usersByName.put( user.getFullName(), user );
    }

    public SortedSet<MPUser> getUsers() {
        return FluentIterable.from( usersByName.values() ).toSortedSet( Ordering.natural() );
    }

    public MPUser getUserNamed(final String fullName) {
        return usersByName.get( fullName );
    }

    public void addUser(final MPUser user) {
        usersByName.put( user.getFullName(), user );
    }

    public void deleteUser(final MPUser user) {
        usersByName.remove( user.getFullName() );
    }
}
