package com.lyndir.lhunath.masterpassword;

import com.lyndir.lhunath.opal.system.util.MetaObject;
import com.lyndir.lhunath.opal.system.util.ObjectMeta;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public class MPTemplateCharacterClass extends MetaObject {

    private final char   identifier;
    @ObjectMeta(useFor = { })
    private final char[] characters;

    public MPTemplateCharacterClass(final char identifier, final char[] characters) {

        this.identifier = identifier;
        this.characters = characters;
    }

    public char getIdentifier() {

        return identifier;
    }

    public char getCharacterAtRollingIndex(final int index) {

        return characters[index % characters.length];
    }
}
