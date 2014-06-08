package com.lyndir.lhunath.masterpassword;

/**
 * @author lhunath, 2014-06-08
 */
public class User {
    private final String name;
    private final byte[] key;

    public User(final String name, final byte[] key) {
        this.name = name;
        this.key = key;
    }

    public String getName() {
        return name;
    }

    public byte[] getKey() {
        return key;
    }
}
