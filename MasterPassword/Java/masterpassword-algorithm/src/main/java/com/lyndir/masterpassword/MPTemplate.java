package com.lyndir.masterpassword;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
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

    MPTemplate(final String template) {

        ImmutableList.Builder<MPTemplateCharacterClass> builder = ImmutableList.builder();
        for (int i = 0; i < template.length(); ++i)
            builder.add( MPTemplateCharacterClass.forIdentifier( template.charAt( i ) ) );

        this.template = builder.build();
    }

    public MPTemplateCharacterClass getCharacterClassAtIndex(final int index) {

        return template.get( index );
    }

    public int length() {

        return template.size();
    }
}
