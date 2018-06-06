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

package com.lyndir.masterpassword.model.impl;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPQuestion;
import com.lyndir.masterpassword.model.MPSite;
import java.util.*;
import javax.annotation.Nullable;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 14-12-16
 */
public abstract class MPBasicSite<Q extends MPQuestion> implements MPSite<Q> {

    private String          name;
    private MPAlgorithm     algorithm;
    private UnsignedInteger counter;
    private MPResultType    resultType;
    private MPResultType    loginType;

    private final Collection<Q> questions = new LinkedHashSet<>();

    protected MPBasicSite(final String name, final MPAlgorithm algorithm) {
        this( name, algorithm, null, null, null );
    }

    protected MPBasicSite(final String name, final MPAlgorithm algorithm, @Nullable final UnsignedInteger counter,
                          @Nullable final MPResultType resultType, @Nullable final MPResultType loginType) {
        this.name = name;
        this.algorithm = algorithm;
        this.counter = (counter == null)? algorithm.mpw_default_counter(): counter;
        this.resultType = (resultType == null)? algorithm.mpw_default_result_type(): resultType;
        this.loginType = (loginType == null)? algorithm.mpw_default_login_type(): loginType;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public void setName(final String name) {
        this.name = name;
    }

    @Override
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        this.algorithm = algorithm;
    }

    @Override
    public UnsignedInteger getCounter() {
        return counter;
    }

    @Override
    public void setCounter(final UnsignedInteger counter) {
        this.counter = counter;
    }

    @Override
    public MPResultType getResultType() {
        return resultType;
    }

    @Override
    public void setResultType(final MPResultType resultType) {
        this.resultType = resultType;
    }

    @Override
    public MPResultType getLoginType() {
        return loginType;
    }

    @Override
    public void setLoginType(@Nullable final MPResultType loginType) {
        this.loginType = ifNotNullElse( loginType, getAlgorithm().mpw_default_login_type() );
    }

    @Override
    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext, @Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( keyPurpose, keyContext, getCounter(), getResultType(), state );
    }

    protected String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                               @Nullable final UnsignedInteger counter, final MPResultType type, @Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getUser().getMasterKey().siteResult(
                getName(), getAlgorithm(), ifNotNullElse( counter, getAlgorithm().mpw_default_counter() ),
                keyPurpose, keyContext, type, state );
    }

    protected String getState(final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                              @Nullable final UnsignedInteger counter, final MPResultType type, final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getUser().getMasterKey().siteState(
                getName(), getAlgorithm(), ifNotNullElse( counter, getAlgorithm().mpw_default_counter() ),
                keyPurpose, keyContext, type, state );
    }

    @Override
    public String getLogin(@Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( MPKeyPurpose.Identification, null, null, getLoginType(), state );
    }

    @Override
    public void addQuestion(final Q question) {
        questions.add( question );
    }

    @Override
    public void deleteQuestion(final Q question) {
        questions.remove( question );
    }

    @Override
    public Collection<Q> getQuestions() {
        return Collections.unmodifiableCollection( questions );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getName() );
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPSite) && Objects.equals( getName(), ((MPSite<?>) obj).getName() ));
    }

    @Override
    public int compareTo(@NotNull final MPSite<?> o) {
        return getName().compareTo( o.getName() );
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getName() );
    }
}
