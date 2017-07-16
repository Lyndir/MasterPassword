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


#include <stdio.h>
#include <time.h>
#include <json-c/json.h>
#include "mpw-marshall.h"
#include "mpw-util.h"

MPMarshalledUser mpw_marshall_user(
        const char *fullName, MPMasterKey masterKey, const MPAlgorithmVersion algorithmVersion) {

    return (MPMarshalledUser){
            .name = fullName,
            .key = masterKey,
            .version = algorithmVersion,

            .avatar = 0,
            .defaultType = MPSiteTypeGeneratedLong,
            .lastUsed = 0,

            .sites_count = 0,
            .sites = NULL,
    };
};

MPMarshalledSite mpw_marshall_site(
        MPMarshalledUser *marshalledUser,
        const char *siteName, const MPSiteType siteType, const uint32_t siteCounter, const MPAlgorithmVersion algorithmVersion) {

    marshalledUser->sites = realloc( marshalledUser->sites, marshalledUser->sites_count + 1 );
    return marshalledUser->sites[marshalledUser->sites_count++] = (MPMarshalledSite){
            .name = siteName,
            .type = siteType,
            .counter = siteCounter,
            .version = algorithmVersion,

            .loginName = NULL,
            .loginGenerated = 0,

            .url = NULL,
            .uses = 0,
            .lastUsed = 0,

            .questions_count = 0,
            .questions = NULL,
    };
};

MPMarshalledQuestion mpw_marshal_question(
        MPMarshalledSite *marshalledSite, const char *keyword) {

    marshalledSite->questions = realloc( marshalledSite->questions, marshalledSite->questions_count + 1 );
    return marshalledSite->questions[marshalledSite->questions_count++] = (MPMarshalledQuestion){
            .keyword = keyword,
    };
}

#define try_asprintf(...) ({ if (asprintf( __VA_ARGS__ ) < 0) return false; })

bool mpw_marshall_write_flat(
        char **out, bool redacted, const MPMarshalledUser *marshalledUser) {

    try_asprintf( out, "# Master Password site export\n" );
    if (redacted)
        try_asprintf( out, "#     Export of site names and passwords in clear-text.\n" );
    else
        try_asprintf( out, "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n" );
    try_asprintf( out, "# \n" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "# Format: %d\n", 1 );

    size_t dateSize = 21;
    char dateString[dateSize];
    time_t now = time( NULL );
    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &now ) ))
        try_asprintf( out, "# Date: %s\n", dateString );
    try_asprintf( out, "# User Name: %s\n", marshalledUser->name );
    try_asprintf( out, "# Full Name: %s\n", marshalledUser->name );
    try_asprintf( out, "# Avatar: %u\n", marshalledUser->avatar );
    try_asprintf( out, "# Key ID: %s\n", mpw_id_buf( marshalledUser->key, MPMasterKeySize ) );
    try_asprintf( out, "# Algorithm: %d\n", marshalledUser->version );
    try_asprintf( out, "# Default Type: %d\n", marshalledUser->defaultType );
    try_asprintf( out, "# Passwords: %s\n", redacted? "PROTECTED": "VISIBLE" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "#\n" );
    try_asprintf( out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    try_asprintf( out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    for (int s = 0; s < marshalledUser->sites_count; ++s) {
        MPMarshalledSite site = marshalledUser->sites[s];

        const char *content = NULL;
        if (!redacted && site.type & MPSiteTypeClassGenerated)
            content = mpw_passwordForSite( marshalledUser->key, site.name, site.type, site.counter,
                    MPSiteVariantPassword, NULL, site.version );
        // TODO: Personal Passwords

        if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &site.lastUsed ) ))
            try_asprintf( out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site.uses, (long)site.type, (long)site.version, (long)site.counter,
                    site.loginName?: "", site.name, content?: "" );
    }
    return true;
}

bool mpw_marshall_write_json(
        char **out, bool redacted, const MPMarshalledUser *marshalledUser) {

    json_object *json_out = json_object_new_object();

    // Section: "export"
    json_object *json_export = json_object_new_object();
    json_object_object_add( json_out, "export", json_export );
    json_object_object_add( json_export, "format", json_object_new_int( 1 ) );
    json_object_object_add( json_export, "redacted", json_object_new_boolean( redacted ) );

    size_t dateSize = 21;
    char dateString[dateSize];
    time_t now = time( NULL );
    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &now ) ))
        json_object_object_add( json_export, "date", json_object_new_string( dateString ) );
    json_object_put( json_export );

    // Section: "user"
    json_object *json_user = json_object_new_object();
    json_object_object_add( json_out, "user", json_user );
    json_object_object_add( json_user, "avatar", json_object_new_int( marshalledUser->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( marshalledUser->name ) );

    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &marshalledUser->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    json_object_object_add( json_user, "key_id", json_object_new_string( mpw_id_buf( marshalledUser->key, MPMasterKeySize ) ) );

    json_object_object_add( json_user, "algorithm", json_object_new_int( marshalledUser->version ) );
    json_object_object_add( json_user, "default_type", json_object_new_int( marshalledUser->defaultType ) );
    json_object_put( json_user );

    // Section "sites"
    json_object *json_sites = json_object_new_object();
    json_object_object_add( json_out, "sites", json_sites );
    for (int s = 0; s < marshalledUser->sites_count; ++s) {
        MPMarshalledSite site = marshalledUser->sites[s];

        const char *content = site.content;
        if (!redacted && site.type & MPSiteTypeClassGenerated)
            content = mpw_passwordForSite( marshalledUser->key, site.name, site.type, site.counter,
                    MPSiteVariantPassword, NULL, site.version );
        // TODO: Personal Passwords
        //else if (redacted && content)
        //    content = aes128_cbc( marshalledUser->key, content );

        json_object *json_site = json_object_new_object();
        json_object_object_add( json_sites, site.name, json_site );
        json_object_object_add( json_site, "type", json_object_new_int( site.type ) );
        json_object_object_add( json_site, "counter", json_object_new_int( site.counter ) );
        json_object_object_add( json_site, "algorithm", json_object_new_int( site.version ) );
        if (content)
            json_object_object_add( json_site, "password", json_object_new_string( content ) );

        json_object_object_add( json_site, "login_name", json_object_new_string( site.loginName?: "" ) );
        json_object_object_add( json_site, "login_generated", json_object_new_boolean( site.loginGenerated ) );

        json_object_object_add( json_site, "uses", json_object_new_int( site.uses ) );
        if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &site.lastUsed ) ))
            json_object_object_add( json_site, "last_used", json_object_new_string( dateString ) );

        json_object *json_site_questions = json_object_new_object();
        json_object_object_add( json_site, "questions", json_site_questions );
        for (int q = 0; q < site.questions_count; ++q) {
            MPMarshalledQuestion question = site.questions[q];

            json_object *json_site_question = json_object_new_object();
            json_object_object_add( json_site_questions, question.keyword, json_site_question );

            if (!redacted)
                json_object_object_add( json_site_question, "answer", json_object_new_string(
                        mpw_passwordForSite( marshalledUser->key, site.name, MPSiteTypeGeneratedPhrase, 1,
                                MPSiteVariantAnswer, question.keyword, site.version ) ) );
            json_object_put( json_site_question );
        }
        json_object_put( json_site_questions );

        json_object *json_site_mpw = json_object_new_object();
        json_object_object_add( json_site, "_ext_mpw", json_site_mpw );
        json_object_object_add( json_site_mpw, "url", json_object_new_string( site.url ) );
        json_object_put( json_site_mpw );
        json_object_put( json_site );
    }
    json_object_put( json_sites );

    try_asprintf( out, "%s\n", json_object_to_json_string_ext( json_out, JSON_C_TO_STRING_PRETTY ) );
    json_object_put( json_out );

    return true;
}

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, bool redacted,
        const MPMarshalledUser *marshalledUser) {

    switch (outFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_write_flat( out, redacted, marshalledUser );
        case MPMarshallFormatJSON:
            return mpw_marshall_write_json( out, redacted, marshalledUser );
    }

    return false;
}

MPMarshalledUser mpw_marshall_read_flat(
        char *in) {

//    // Compile patterns.
//    static NSRegularExpression *headerPattern;
//    static NSArray *sitePatterns;
//    NSError *error = NULL;
//    if (!headerPattern) {
//        headerPattern = [[NSRegularExpression alloc]
//                initWithPattern:"^#[[:space:]]*([^:]+): (.*)"
//                        options:(NSRegularExpressionOptions)0 error:&error];
//        if (error) {
//            MPError( error, "Error loading the header pattern." );
//            return MPImportResultInternalError;
//        }
//    }
//    if (!sitePatterns) {
//        sitePatterns = @[
//                [[NSRegularExpression alloc] // Format 0
//                        initWithPattern:"^([^ ]+) +([[:digit:]]+) +([[:digit:]]+)(:[[:digit:]]+)? +([^\t]+)\t(.*)"
//                                options:(NSRegularExpressionOptions)0 error:&error],
//                [[NSRegularExpression alloc] // Format 1
//                        initWithPattern:"^([^ ]+) +([[:digit:]]+) +([[:digit:]]+)(:[[:digit:]]+)?(:[[:digit:]]+)? +([^\t]*)\t *([^\t]+)\t(.*)"
//                                options:(NSRegularExpressionOptions)0 error:&error]
//        ];
//        if (error) {
//            MPError( error, "Error loading the site patterns." );
//            return MPImportResultInternalError;
//        }
//    }
//
    // Parse import data.
    int importFormat = 0;
    MPMarshalledUser user;
    int importAvatar = -1;
    int importKeyID;
    char *importUserName = NULL;
    MPAlgorithmVersion importAlgorithm = MPAlgorithmVersionCurrent;
    MPSiteType importDefaultType = (MPSiteType)0;
    bool headerStarted = false, headerEnded = false, clearText = false;
//    NSMutableSet *sitesToDelete = [NSMutableSet set];
//    NSMutableArray *importedSiteSites = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
//    NSFetchRequest *siteFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
//    for (NSString *importedSiteLine in importedSiteLines) {

//        if ([importedSiteLine hasPrefix:"#"]) {
//            // Comment or header
//            if (!headerStarted) {
//                if ([importedSiteLine isEqualToString:"##"])
//                    headerStarted = YES;
//                continue;
//            }
//            if (headerEnded)
//                continue;
//            if ([importedSiteLine isEqualToString:"##"]) {
//                headerEnded = YES;
//                continue;
//            }
//
//            // Header
//            if ([headerPattern numberOfMatchesInString:importedSiteLine options:(NSMatchingOptions)0
//                                                 range:NSMakeRange( 0, [importedSiteLine length] )] != 1) {
//                err( "Invalid header format in line: %", importedSiteLine );
//                return MPImportResultMalformedInput;
//            }
//            NSTextCheckingResult *headerSites = [[headerPattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
//                                                                          range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
//            NSString *headerName = [importedSiteLine substringWithRange:[headerSites rangeAtIndex:1]];
//            NSString *headerValue = [importedSiteLine substringWithRange:[headerSites rangeAtIndex:2]];
//
//            if ([headerName isEqualToString:"Format"]) {
//                importFormat = (NSUInteger)[headerValue integerValue];
//                if (importFormat >= [sitePatterns count]) {
//                    err( "Unsupported import format: %lu", (unsigned long)importFormat );
//                    return MPImportResultInternalError;
//                }
//            }
//            if (([headerName isEqualToString:"User Name"] || [headerName isEqualToString:"Full Name"]) && !importUserName) {
//                importUserName = headerValue;
//
//                NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
//                userFetchRequest.predicate = [NSPredicate predicateWithFormat:"name == %", importUserName];
//                NSArray *users = [context executeFetchRequest:userFetchRequest error:&error];
//                if (!users) {
//                    MPError( error, "While looking for user: %@.", importUserName );
//                    return MPImportResultInternalError;
//                }
//                if ([users count] > 1) {
//                    err( "While looking for user: %@, found more than one: %lu", importUserName, (unsigned long)[users count] );
//                    return MPImportResultInternalError;
//                }
//
//                user = [users lastObject];
//                dbg( "Existing user? %", [user debugDescription] );
//            }
//            if ([headerName isEqualToString:"Avatar"])
//                importAvatar = (NSUInteger)[headerValue integerValue];
//            if ([headerName isEqualToString:"Key ID"])
//                importKeyID = [headerValue decodeHex];
//            if ([headerName isEqualToString:"Version"]) {
//                importBundleVersion = headerValue;
//                importAlgorithm = MPAlgorithmDefaultForBundleVersion( importBundleVersion );
//            }
//            if ([headerName isEqualToString:"Algorithm"])
//                importAlgorithm = MPAlgorithmForVersion( (MPAlgorithmVersion)[headerValue integerValue] );
//            if ([headerName isEqualToString:"Default Type"])
//                importDefaultType = (MPSiteType)[headerValue integerValue];
//            if ([headerName isEqualToString:"Passwords"]) {
//                if ([headerValue isEqualToString:"VISIBLE"])
//                    clearText = YES;
//            }
//
//            continue;
//        }
//        if (!headerEnded)
//            continue;
//        if (![importUserName length])
//            return MPImportResultMalformedInput;
//        if (![importedSiteLine length])
//            continue;
//
//        // Site
//        NSRegularExpression *sitePattern = sitePatterns[importFormat];
//        if ([sitePattern numberOfMatchesInString:importedSiteLine options:(NSMatchingOptions)0
//                                           range:NSMakeRange( 0, [importedSiteLine length] )] != 1) {
//            err( "Invalid site format in line: %", importedSiteLine );
//            return MPImportResultMalformedInput;
//        }
//        NSTextCheckingResult *siteElements = [[sitePattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
//                                                                     range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
//        NSString *lastUsed, *uses, *type, *version, *counter, *siteName, *loginName, *exportContent;
//        switch (importFormat) {
//            case 0:
//                lastUsed = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
//                uses = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
//                type = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
//                version = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
//                if ([version length])
//                    version = [version substringFromIndex:1]; // Strip the leading colon.
//                counter = "";
//                loginName = "";
//                siteName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
//                exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];
//                break;
//            case 1:
//                lastUsed = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
//                uses = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
//                type = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
//                version = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
//                if ([version length])
//                    version = [version substringFromIndex:1]; // Strip the leading colon.
//                counter = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
//                if ([counter length])
//                    counter = [counter substringFromIndex:1]; // Strip the leading colon.
//                loginName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];
//                siteName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:7]];
//                exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:8]];
//                break;
//            default:
//                err( "Unexpected import format: %lu", (unsigned long)importFormat );
//                return MPImportResultInternalError;
//        }
//
//        // Find existing site.
//        if (user) {
//            siteFetchRequest.predicate = [NSPredicate predicateWithFormat:"name == %@ AND user == %", siteName, user];
//            NSArray *existingSites = [context executeFetchRequest:siteFetchRequest error:&error];
//            if (!existingSites) {
//                MPError( error, "Lookup of existing sites failed for site: %@, user: %@.", siteName, user.userID );
//                return MPImportResultInternalError;
//            }
//            if ([existingSites count]) {
//                dbg( "Existing sites: %", existingSites );
//                [sitesToDelete addObjectsFromArray:existingSites];
//            }
//        }
//        [importedSiteSites addObject:@[ lastUsed, uses, type, version, counter, loginName, siteName, exportContent ]];
//        dbg( "Will import site: lastUsed=%@, uses=%@, type=%@, version=%@, counter=%@, loginName=%@, siteName=%@, exportContent=%",
//                lastUsed, uses, type, version, counter, loginName, siteName, exportContent );
//    }
//
//    // Ask for confirmation to import these sites and the master password of the user.
//    inf( "Importing %lu sites, deleting %lu sites, for user: %", (unsigned long)[importedSiteSites count],
//            (unsigned long)[sitesToDelete count], [MPUserEntity idFor:importUserName] );
//    NSString *userMasterPassword = askUserPassword( user? user.name: importUserName, [importedSiteSites count],
//            [sitesToDelete count] );
//    if (!userMasterPassword) {
//        inf( "Import cancelled." );
//        return MPImportResultCancelled;
//    }
//    MPKey *userKey = [[MPKey alloc] initForFullName:user? user.name: importUserName withMasterPassword:userMasterPassword];
//    if (user && ![[userKey keyIDForAlgorithm:user.algorithm] isEqualToData:user.keyID])
//        return MPImportResultInvalidPassword;
//    __block MPKey *importKey = userKey;
//    if (importKeyID && ![[importKey keyIDForAlgorithm:importAlgorithm] isEqualToData:importKeyID])
//        importKey = [[MPKey alloc] initForFullName:importUserName withMasterPassword:askImportPassword( importUserName )];
//    if (importKeyID && ![[importKey keyIDForAlgorithm:importAlgorithm] isEqualToData:importKeyID])
//        return MPImportResultInvalidPassword;
//
//    // Delete existing sites.
//    if (sitesToDelete.count)
//        [sitesToDelete enumerateObjectsUsingBlock:^(id obj, bool *stop) {
//            inf( "Deleting site: %@, it will be replaced by an imported site.", [obj name] );
//            [context deleteObject:obj];
//        }];
//
//    // Make sure there is a user.
//    if (user) {
//        if (importAvatar != NSNotFound)
//            user.avatar = importAvatar;
//        if (importDefaultType)
//            user.defaultType = importDefaultType;
//        dbg( "Updating User: %", [user debugDescription] );
//    }
//    else {
//        user = [MPUserEntity insertNewObjectInContext:context];
//        user.name = importUserName;
//        user.algorithm = MPAlgorithmDefault;
//        user.keyID = [userKey keyIDForAlgorithm:user.algorithm];
//        user.defaultType = importDefaultType?: user.algorithm.defaultType;
//        if (importAvatar != NSNotFound)
//            user.avatar = importAvatar;
//        dbg( "Created User: %", [user debugDescription] );
//    }
//
//    // Import new sites.
//    for (NSArray *siteElements in importedSiteSites) {
//        NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:siteElements[0]];
//        NSUInteger uses = (unsigned)[siteElements[1] integerValue];
//        MPSiteType type = (MPSiteType)[siteElements[2] integerValue];
//        MPAlgorithmVersion version = (MPAlgorithmVersion)[siteElements[3] integerValue];
//        NSUInteger counter = [siteElements[4] length]? (unsigned)[siteElements[4] integerValue]: NSNotFound;
//        NSString *loginName = [siteElements[5] length]? siteElements[5]: NULL;
//        NSString *siteName = siteElements[6];
//        NSString *exportContent = siteElements[7];
//
//        // Create new site.
//        id<MPAlgorithm> algorithm = MPAlgorithmForVersion( version );
//        Class entityType = [algorithm classOfType:type];
//        if (!entityType) {
//            err( "Invalid site type in import file: %@ has type %lu", siteName, (long)type );
//            return MPImportResultInternalError;
//        }
//        MPSiteEntity *site = (MPSiteEntity *)[entityType insertNewObjectInContext:context];
//        site.name = siteName;
//        site.loginName = loginName;
//        site.user = user;
//        site.type = type;
//        site.uses = uses;
//        site.lastUsed = lastUsed;
//        site.algorithm = algorithm;
//        if ([exportContent length]) {
//            if (clearText)
//                [site.algorithm importClearTextPassword:exportContent intoSite:site usingKey:userKey];
//            else
//                [site.algorithm importProtectedPassword:exportContent protectedByKey:importKey intoSite:site usingKey:userKey];
//        }
//        if ([site isKindOfClass:[MPGeneratedSiteEntity class]] && counter != NSNotFound)
//            ((MPGeneratedSiteEntity *)site).counter = counter;
//
//        dbg( "Created Site: %", [site debugDescription] );
//    }
//
//    if (![context saveToStore])
//        return MPImportResultInternalError;
//
//    inf( "Import completed successfully." );
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:MPSitesImportedNotification object:NULL userInfo:@{
//            MPSitesImportedNotificationUserKey: user
//    }];
//
//    return MPImportResultSuccess;
    return (MPMarshalledUser){};
}

MPMarshalledUser mpw_marshall_read_json(
        char *in) {

    return (MPMarshalledUser){};
}

MPMarshalledUser mpw_marshall_read(
        char *in, const MPMarshallFormat outFormat) {

    switch (outFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_read_flat( in );
        case MPMarshallFormatJSON:
            return mpw_marshall_read_json( in );
    }

    return (MPMarshalledUser){};
}
