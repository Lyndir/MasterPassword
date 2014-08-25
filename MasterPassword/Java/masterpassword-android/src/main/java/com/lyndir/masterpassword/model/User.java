package com.lyndir.masterpassword.model;

/**
 * @author lhunath, 2014-08-20
 */
public class User {

    private String name;
    private Avatar    avatar;

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
}
