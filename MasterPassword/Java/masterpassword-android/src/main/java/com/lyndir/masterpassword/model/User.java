package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;


/**
 * @author lhunath, 2014-08-20
 */
public class User {

    private final String name;
    private final Avatar avatar;

    public User(final String name, final Avatar avatar) {
        this.name = name;
        this.avatar = avatar;
    }

    public String getName() {
        return name;
    }

    public Avatar getAvatar() {
        return avatar;
    }

    @Override
    public boolean equals(final Object obj) {
        return this == obj || obj instanceof User && name.equals( ((User) obj).name );
    }

    @Override
    public int hashCode() {
        return name.hashCode();
    }

    @Override
    public String toString() {
        return strf( "{User: %s}", name );
    }
}
