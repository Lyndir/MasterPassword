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

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.core.util.Separators;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import com.lyndir.masterpassword.model.MPModelConstants;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.io.File;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.annotation.Nullable;
import org.joda.time.Instant;


/**
 * @author lhunath, 2018-04-27
 */
@SuppressFBWarnings("URF_UNREAD_FIELD")
public class MPJSONFile extends MPJSONAnyObject {

    MPJSONFile() {
    }

    MPJSONFile(final MPFileUser modelUser)
            throws MPAlgorithmException, MPKeyUnavailableException {

        // Section: "export"
        export = new Export();
        export.format = 1;
        export.redacted = modelUser.getContentMode().isRedacted();
        export.date = MPModelConstants.dateTimeFormatter.print( new Instant() );

        // Section: "user"
        user = new User();
        user.avatar = modelUser.getAvatar();
        user.full_name = modelUser.getFullName();
        user.last_used = MPModelConstants.dateTimeFormatter.print( modelUser.getLastUsed() );
        user.key_id = modelUser.getKeyID();
        user.algorithm = modelUser.getAlgorithm().version();
        user._ext_mpw = new User.Ext() {
            {
                default_type = modelUser.getPreferences().getDefaultType();
                hide_passwords = modelUser.getPreferences().isHidePasswords();
            }
        };

        // Section "sites"
        sites = new LinkedHashMap<>();
        for (final MPFileSite modelSite : modelUser.getSites()) {
            String content = null, loginContent = null;

            if (!export.redacted) {
                // Clear Text
                content = modelSite.getResult();
                loginContent = modelUser.getMasterKey().siteResult(
                        modelSite.getSiteName(), modelSite.getAlgorithm(), modelSite.getAlgorithm().mpw_default_counter(),
                        MPKeyPurpose.Identification, null, modelSite.getLoginType(), modelSite.getLoginState() );
            } else {
                // Redacted
                if (modelSite.getResultType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    content = modelSite.getResultState();
                if (modelSite.getLoginType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    loginContent = modelSite.getLoginState();
            }

            Site site = sites.get( modelSite.getSiteName() );
            if (site == null)
                sites.put( modelSite.getSiteName(), site = new Site() );
            site.type = modelSite.getResultType();
            site.counter = modelSite.getCounter().longValue();
            site.algorithm = modelSite.getAlgorithm().version();
            site.password = content;
            site.login_name = loginContent;
            site.login_type = modelSite.getLoginType();

            site.uses = modelSite.getUses();
            site.last_used = MPModelConstants.dateTimeFormatter.print( modelSite.getLastUsed() );

            site.questions = new LinkedHashMap<>();
            for (final MPFileQuestion question : modelSite.getQuestions())
                site.questions.put( question.getKeyword(), new Site.Question() {
                    {
                        type = question.getType();

                        if (!export.redacted) {
                            // Clear Text
                            answer = question.getAnswer();
                        } else {
                            // Redacted
                            if (question.getType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                                answer = question.getAnswerState();
                        }
                    }
                } );

            site._ext_mpw = new Site.Ext() {
                {
                    url = modelSite.getUrl();
                }
            };
        }
    }

    MPFileUser readUser(final File file) {
        MPAlgorithm algorithm = ifNotNullElse( user.algorithm, MPAlgorithm.Version.CURRENT );

        return new MPFileUser(
                user.full_name, user.key_id, algorithm, user.avatar,
                (user._ext_mpw != null)? user._ext_mpw.default_type: null,
                (user.last_used != null)? MPModelConstants.dateTimeFormatter.parseDateTime( user.last_used ): new Instant(),
                (user._ext_mpw != null) && user._ext_mpw.hide_passwords,
                export.redacted? MPMarshaller.ContentMode.PROTECTED: MPMarshaller.ContentMode.VISIBLE,
                MPMarshalFormat.JSON, file
        );
    }

    void readSites(final MPFileUser user)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {
        for (final Map.Entry<String, Site> siteEntry : sites.entrySet()) {
            String siteName = siteEntry.getKey();
            Site   fileSite = siteEntry.getValue();
            MPFileSite site = new MPFileSite(
                    user, siteName, fileSite.algorithm, UnsignedInteger.valueOf( fileSite.counter ),
                    fileSite.type, export.redacted? fileSite.password: null,
                    fileSite.login_type, export.redacted? fileSite.login_name: null,
                    (fileSite._ext_mpw != null)? fileSite._ext_mpw.url: null, fileSite.uses,
                    (fileSite.last_used != null)? MPModelConstants.dateTimeFormatter.parseDateTime( fileSite.last_used ): new Instant() );

            if (!export.redacted) {
                if (fileSite.password != null)
                    site.setSitePassword( (fileSite.type != null)? fileSite.type: MPResultType.StoredPersonal, fileSite.password );
                if (fileSite.login_name != null)
                    site.setLoginName( (fileSite.login_type != null)? fileSite.login_type: MPResultType.StoredPersonal,
                                       fileSite.login_name );
            }

            if (fileSite.questions != null)
                for (final Map.Entry<String, Site.Question> questionEntry : fileSite.questions.entrySet()) {
                    Site.Question fileQuestion = questionEntry.getValue();
                    MPFileQuestion question = new MPFileQuestion( site, ifNotNullElse( questionEntry.getKey(), "" ),
                                                                  fileQuestion.type, export.redacted? fileQuestion.answer: null );

                    if (!export.redacted && (fileQuestion.answer != null))
                        question.setAnswer( (fileQuestion.type != null)? fileQuestion.type: MPResultType.StoredPersonal,
                                            fileQuestion.answer );

                    site.addQuestion( question );
                }

            user.addSite( site );
        }
    }

    // -- Data

    Export            export = new Export();
    User              user   = new User();
    Map<String, Site> sites  = new LinkedHashMap<>();


    public static class Export extends MPJSONAnyObject {

        int     format;
        boolean redacted;
        @Nullable
        String date;
    }


    public static class User extends MPJSONAnyObject {

        int    avatar;
        String full_name;
        String last_used;
        @Nullable
        String              key_id;
        @Nullable
        MPAlgorithm.Version algorithm;

        @Nullable
        Ext _ext_mpw;


        public static class Ext extends MPJSONAnyObject {

            @Nullable
            MPResultType default_type;
            boolean hide_passwords;
        }
    }


    public static class Site extends MPJSONAnyObject {

        @Nullable
        MPResultType type;
        long                counter;
        MPAlgorithm.Version algorithm = MPAlgorithm.Version.CURRENT;
        @Nullable
        String       password;
        @Nullable
        String       login_name;
        @Nullable
        MPResultType login_type;

        int uses;
        @Nullable
        String last_used;

        @Nullable
        Map<String, Question> questions;

        @Nullable
        Ext _ext_mpw;


        public static class Ext extends MPJSONAnyObject {

            @Nullable
            String url;
        }


        public static class Question extends MPJSONAnyObject {

            @Nullable
            MPResultType type;
            @Nullable
            String       answer;
        }
    }
}

