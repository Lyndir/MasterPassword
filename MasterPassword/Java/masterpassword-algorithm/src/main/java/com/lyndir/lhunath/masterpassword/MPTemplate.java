package com.lyndir.lhunath.masterpassword;

import com.google.common.collect.ImmutableList;
import com.lyndir.lhunath.opal.system.util.MetaObject;
import java.util.List;
import java.util.Map;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public class MPTemplate extends MetaObject {

    private final List<MPTemplateCharacterClass> template;

    public MPTemplate(final String template, final Map<Character, MPTemplateCharacterClass> characterClasses) {

        ImmutableList.Builder<MPTemplateCharacterClass> builder = ImmutableList.<MPTemplateCharacterClass>builder();
        for (int i = 0; i < template.length(); ++i)
            builder.add( characterClasses.get( template.charAt( i ) ) );

        this.template = builder.build();
    }

    public MPTemplate(final List<MPTemplateCharacterClass> template) {

        this.template = template;
    }

    public MPTemplateCharacterClass getCharacterClassAtIndex(final int index) {

        return template.get( index );
    }

    public int length() {

        return template.size();
    }
}
