// MASTERPASSWORD FOR WINDOWS
// --------------------------
// Created by Michel Verhagen
// Copyright (C)2014 GuruCE Limited
//
// Released under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
//
// Contains software provided by Maarten Billemont and used under the GPL v3 License.
//
// Copyright (c) 2012 Lyndir. All rights reserved.
//
// Contains software provided by Replicon Inc. and used under this license:
//
// Replicon.Cryptography.SCrypt
// Copyright (c) 2012, Replicon Inc.
// All rights reserved.
//
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace MasterPassword
{
    class MRUData
    {
        public MRUData(string userName, string siteName, int siteCounter, MasterPassword.MPType passwordType)
        {
            this.UserName = userName;
            this.SiteName = siteName;
            this.SiteCounter = siteCounter;
            this.PasswordType = passwordType;
        }
        public string UserName { get; set; }
        public string SiteName { get; set; }
        public int SiteCounter { get; set; }
        public MasterPassword.MPType PasswordType { get; set; }
    }
}
