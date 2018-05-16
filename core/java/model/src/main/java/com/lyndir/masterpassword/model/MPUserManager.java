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

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Maps;
import java.util.Collection;
import java.util.Map;


/**
 * @author lhunath, 14-12-05
 */
public abstract class MPUserManager<U extends MPUser<?>> {

    private final Map<String, U> usersByName = Maps.newHashMap();

    protected MPUserManager(final Iterable<U> users) {
        for (final U user : users)
            usersByName.put( user.getFullName(), user );
    }

    public Collection<U> getUsers() {
        return ImmutableList.copyOf( usersByName.values() );
    }

    public U getUserNamed(final String fullName) {
        return usersByName.get( fullName );
    }

    public void addUser(final U user) {
        usersByName.put( user.getFullName(), user );
    }

    public void deleteUser(final U user) {
        usersByName.remove( user.getFullName() );
    }
}
