package com.lyndir.masterpassword.gui.model;

import com.lyndir.masterpassword.model.MPSite;
import com.lyndir.masterpassword.model.impl.MPBasicQuestion;


/**
 * @author lhunath, 2018-07-27
 */
public class MPNewQuestion extends MPBasicQuestion {

    public MPNewQuestion(final MPSite<?> site, final String keyword) {
        super( site, keyword, site.getAlgorithm().mpw_default_answer_type() );
    }
}
