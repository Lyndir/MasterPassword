/* Copyright (c) 2012 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  GTLPlusPerson.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   Google+ API (plus/v1moments)
// Description:
//   The Google+ API enables developers to build on top of the Google+ platform.
// Documentation:
//   http://developers.google.com/+/api/
// Classes:
//   GTLPlusPerson (0 custom class methods, 21 custom properties)
//   GTLPlusPersonEmailsItem (0 custom class methods, 3 custom properties)
//   GTLPlusPersonImage (0 custom class methods, 1 custom properties)
//   GTLPlusPersonName (0 custom class methods, 6 custom properties)
//   GTLPlusPersonOrganizationsItem (0 custom class methods, 9 custom properties)
//   GTLPlusPersonPlacesLivedItem (0 custom class methods, 2 custom properties)
//   GTLPlusPersonUrlsItem (0 custom class methods, 3 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLPlusPersonEmailsItem;
@class GTLPlusPersonImage;
@class GTLPlusPersonName;
@class GTLPlusPersonOrganizationsItem;
@class GTLPlusPersonPlacesLivedItem;
@class GTLPlusPersonUrlsItem;

// ----------------------------------------------------------------------------
//
//   GTLPlusPerson
//

@interface GTLPlusPerson : GTLObject

// A short biography for this person.
@property (copy) NSString *aboutMe;

// The person's date of birth, represented as YYYY-MM-DD.
@property (copy) NSString *birthday;

// The current location for this person.
@property (copy) NSString *currentLocation;

// The name of this person, suitable for display.
@property (copy) NSString *displayName;

// A list of email addresses for this person.
@property (retain) NSArray *emails;  // of GTLPlusPersonEmailsItem

// ETag of this response for caching purposes.
@property (copy) NSString *ETag;

// The person's gender. Possible values are:
// - "male" - Male gender.
// - "female" - Female gender.
// - "other" - Other.
@property (copy) NSString *gender;

// If "true", indicates that the person has installed the app that is making the
// request and has chosen to expose this install state to the caller. A value of
// "false" indicates that the install state cannot be determined (it is either
// not installed or the person has chosen to keep this information private).
@property (retain) NSNumber *hasApp;  // boolValue

// The ID of this person.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (copy) NSString *identifier;

// The representation of the person's profile photo.
@property (retain) GTLPlusPersonImage *image;

// Identifies this resource as a person. Value: "plus#person".
@property (copy) NSString *kind;

// The languages spoken by this person.
@property (retain) NSArray *languagesSpoken;  // of NSString

// An object representation of the individual components of a person's name.
@property (retain) GTLPlusPersonName *name;

// The nickname of this person.
@property (copy) NSString *nickname;

// Type of person within Google+. Possible values are:
// - "person" - represents an actual person.
// - "page" - represents a page.
@property (copy) NSString *objectType;

// A list of current or past organizations with which this person is associated.
@property (retain) NSArray *organizations;  // of GTLPlusPersonOrganizationsItem

// A list of places where this person has lived.
@property (retain) NSArray *placesLived;  // of GTLPlusPersonPlacesLivedItem

// The person's relationship status. Possible values are:
// - "single" - Person is single.
// - "in_a_relationship" - Person is in a relationship.
// - "engaged" - Person is engaged.
// - "married" - Person is married.
// - "its_complicated" - The relationship is complicated.
// - "open_relationship" - Person is in an open relationship.
// - "widowed" - Person is widowed.
// - "in_domestic_partnership" - Person is in a domestic partnership.
// - "in_civil_union" - Person is in a civil union.
@property (copy) NSString *relationshipStatus;

// The brief description (tagline) of this person.
@property (copy) NSString *tagline;

// The URL of this person's profile.
@property (copy) NSString *url;

// A list of URLs for this person.
@property (retain) NSArray *urls;  // of GTLPlusPersonUrlsItem

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonEmailsItem
//

@interface GTLPlusPersonEmailsItem : GTLObject

// If "true", indicates this email address is the person's primary one.
@property (retain) NSNumber *primary;  // boolValue

// The type of address. Possible values are:
// - "home" - Home email address.
// - "work" - Work email address.
// - "other" - Other.
@property (copy) NSString *type;

// The email address.
@property (copy) NSString *value;

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonImage
//

@interface GTLPlusPersonImage : GTLObject

// The URL of the person's profile photo. To re-size the image and crop it to a
// square, append the query string ?sz=x, where x is the dimension in pixels of
// each side.
@property (copy) NSString *url;

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonName
//

@interface GTLPlusPersonName : GTLObject

// The family name (last name) of this person.
@property (copy) NSString *familyName;

// The full name of this person, including middle names, suffixes, etc.
@property (copy) NSString *formatted;

// The given name (first name) of this person.
@property (copy) NSString *givenName;

// The honorific prefixes (such as "Dr." or "Mrs.") for this person.
@property (copy) NSString *honorificPrefix;

// The honorific suffixes (such as "Jr.") for this person.
@property (copy) NSString *honorificSuffix;

// The middle name of this person.
@property (copy) NSString *middleName;

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonOrganizationsItem
//

@interface GTLPlusPersonOrganizationsItem : GTLObject

// The department within the organization.
@property (copy) NSString *department;

// A short description of the person's role in this organization.
// Remapped to 'descriptionProperty' to avoid NSObject's 'description'.
@property (copy) NSString *descriptionProperty;

// The date the person left this organization.
@property (copy) NSString *endDate;

// The location of this organization.
@property (copy) NSString *location;

// The name of the organization.
@property (copy) NSString *name;

// If "true", indicates this organization is the person's primary one (typically
// interpreted as current one).
@property (retain) NSNumber *primary;  // boolValue

// The date the person joined this organization.
@property (copy) NSString *startDate;

// The person's job title or role within the organization.
@property (copy) NSString *title;

// The type of organization. Possible values are:
// - "work" - Work.
// - "school" - School.
@property (copy) NSString *type;

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonPlacesLivedItem
//

@interface GTLPlusPersonPlacesLivedItem : GTLObject

// If "true", this place of residence is this person's primary residence.
@property (retain) NSNumber *primary;  // boolValue

// A place where this person has lived. For example: "Seattle, WA", "Near
// Toronto".
@property (copy) NSString *value;

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPersonUrlsItem
//

@interface GTLPlusPersonUrlsItem : GTLObject

// If "true", this URL is the person's primary URL.
@property (retain) NSNumber *primary;  // boolValue

// The type of URL. Possible values are:
// - "home" - URL for home.
// - "work" - URL for work.
// - "blog" - URL for blog.
// - "profile" - URL for profile.
// - "other" - Other.
@property (copy) NSString *type;

// The URL value.
@property (copy) NSString *value;

@end
