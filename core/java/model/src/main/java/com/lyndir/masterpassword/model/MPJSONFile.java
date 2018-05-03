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

package com.lyndir.masterpassword.model;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.*;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;


/**
 * @author lhunath, 2018-04-27
 */
public class MPJSONFile {

    private static final DateTimeFormatter dateFormatter = ISODateTimeFormat.dateTimeNoMillis();

    Export export;
    User   user;

    public MPJSONFile(final MPFileUser user, final MPMasterKey masterKey, final MPMarshaller.ContentMode contentMode)
            throws MPInvalidatedException {
        //    if (!user.fullName || !strlen( user.fullName )) {
        //        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing full name." };
        //        return false;
        //    }
        //    if (!user.masterPassword || !strlen( user.masterPassword )) {
        //        *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Missing master password." };
        //        return false;
        //    }
        //    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user.algorithm, user.fullName, user.masterPassword )) {
        //        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
        //        return false;
        //    }

        // Section: "export"
        Export fileExport = this.export = new Export();
        fileExport.format = 1;
        fileExport.redacted = contentMode.isRedacted();
        fileExport.date = dateFormatter.print( new Instant() );

        // Section: "user"
        User fileUser = this.user = new User();
        fileUser.avatar = user.getAvatar();
        fileUser.fullName = user.getFullName();

        fileUser.lastUsed = dateFormatter.print( user.getLastUsed() );
        fileUser.keyId = CodeUtils.encodeHex( masterKey.getKeyID( user.getAlgorithm() ) );

        fileUser.algorithm = user.getAlgorithm().version();
        fileUser.defaultType = user.getDefaultType();

        // Section "sites"
        fileUser.sites = new LinkedHashMap<>();
        for (final MPFileSite site : user.getSites()) {
            Site   fileSite;
            String content = null, loginContent = null;
            if (!contentMode.isRedacted()) {
                // Clear Text
                content = masterKey.siteResult( site.getSiteName(), site.getSiteCounter(),
                                                MPKeyPurpose.Authentication, null, site.getResultType(), site.getSiteContent(),
                                                site.getAlgorithm() );
                loginContent = masterKey.siteResult( site.getSiteName(), site.getAlgorithm().mpw_default_counter(),
                                                     MPKeyPurpose.Identification, null, site.getLoginType(), site.getLoginContent(),
                                                     site.getAlgorithm() );
            } else {
                // Redacted
                if (site.getResultType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    content = site.getSiteContent();
                if (site.getLoginType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    loginContent = site.getLoginContent();
            }

            fileUser.sites.put( site.getSiteName(), fileSite = new Site() );
            fileSite.type = site.getResultType();
            fileSite.counter = site.getSiteCounter();
            fileSite.algorithm = site.getAlgorithm().version();
            fileSite.password = content;
            fileSite.login_name = loginContent;
            fileSite.loginType = site.getLoginType();

            fileSite.uses = site.getUses();
            fileSite.lastUsed = dateFormatter.print( site.getLastUsed() );

            fileSite.questions = new LinkedHashMap<>();
            //                for (size_t q = 0; q < site.questions_count; ++q) {
            //                    MPMarshalledQuestion *question = &site.questions[q];
            //                    if (!question.keyword)
            //                        continue;
            //
            //                    json_object *json_site_question = json_object_new_object();
            //                    json_object_object_add( json_site_questions, question.keyword, json_site_question );
            //                    json_object_object_add( json_site_question, "type = question.type;
            //
            //                    if (!user.redacted) {
            //                        // Clear Text
            //                const char *answerContent = mpw_siteResult( masterKey, site.name, MPCounterValueInitial,
            //                                                            MPKeyPurposeRecovery, question.keyword, question.type, question.content, site.algorithm );
            //                        json_object_object_add( json_site_question, "answer = answerContent;
            //                    }
            //                    else {
            //                        // Redacted
            //                        if (site.type & MPSiteFeatureExportContent && question.content && strlen( question.content ))
            //                            json_object_object_add( json_site_question, "answer = question.content;
            //                    }
            //                }

            //                json_object *json_site_mpw = json_object_new_object();
            //                fileSite._ext_mpw = json_site_mpw;
            //                if (site.url)
            //                    json_object_object_add( json_site_mpw, "url", site.url );
        }
    }

    public MPFileUser toUser() {
        return new MPFileUser( user.fullName, CodeUtils.decodeHex( user.keyId ), user.algorithm.getAlgorithm(), user.avatar, user.defaultType, dateFormatter.parseDateTime( user.lastUsed ), MPMarshalFormat.JSON );
    }

    public static class Export {

        int     format;
        boolean redacted;
        String  date;
    }


    public static class User {

        String              fullName;

        MPMasterKey.Version algorithm;
        boolean             redacted;

        int          avatar;
        MPResultType defaultType;
        String       lastUsed;
        String       keyId;

        Map<String, Site> sites;
    }


    public static class Site {

        @Nullable
        String password;
        @Nullable
        String login_name;
        String              name;
        String              content;
        MPResultType        type;
        UnsignedInteger     counter;
        MPMasterKey.Version algorithm;

        String       loginContent;
        MPResultType loginType;

        String url;
        int    uses;
        String lastUsed;

        Map<String, Question> questions;
    }


    public static class Question {

        String       keyword;
        String       content;
        MPResultType type;
    }
}
