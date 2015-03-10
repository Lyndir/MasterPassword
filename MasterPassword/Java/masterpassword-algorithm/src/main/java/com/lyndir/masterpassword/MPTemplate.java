package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.collect.ImmutableList;
import com.lyndir.lhunath.opal.system.util.MetaObject;
import java.util.List;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public class MPTemplate extends MetaObject {

    private final String                         templateString;
    private final List<MPTemplateCharacterClass> template;

    MPTemplate(final String templateString) {

        ImmutableList.Builder<MPTemplateCharacterClass> builder = ImmutableList.builder();
        for (int i = 0; i < templateString.length(); ++i)
            builder.add( MPTemplateCharacterClass.forIdentifier( templateString.charAt( i ) ) );

        this.templateString = templateString;
        template = builder.build();
    }

    public String getTemplateString() {
        return templateString;
    }

    public MPTemplateCharacterClass getCharacterClassAtIndex(final int index) {

        return template.get( index );
    }

    public int length() {

        return template.size();
    }

    @Override
    public String toString() {
        return strf( "{MPTemplate: %s}", templateString );
    }
}
