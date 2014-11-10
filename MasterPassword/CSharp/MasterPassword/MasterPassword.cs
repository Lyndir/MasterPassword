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
using System.Text;
using System.Net;
using System.Runtime.InteropServices;
using Replicon.Cryptography.SCrypt;
using System.Security.Cryptography;
using System.Diagnostics;
using System.IO;

namespace MasterPassword
{
    static class MasterPassword
    {
        private const uint MP_N = 32768;
        private const uint MP_r = 8;
        private const uint MP_p = 2;
        private const uint MP_dkLen = 64;

        private enum MPElementContentType
        {
            MPElementContentTypePassword,
            MPElementContentTypeNote,
            MPElementContentTypePicture,
        }

        [Flags]
        private enum MPElementTypeClass
        {
            /** Generate the password. */
            MPElementTypeClassGenerated = 1 << 4,
            /** Store the password. */
            MPElementTypeClassStored = 1 << 5,
        }

        [Flags]
        private enum MPElementFeature
        {
            /** Export the key-protected content data. */
            MPElementFeatureExportContent = 1 << 10,
            /** Never export content. */
            MPElementFeatureDevicePrivate = 1 << 11,
        }

        [Flags]
        private enum MPElementType
        {
            MPElementTypeGeneratedMaximum = 0x0 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,
            MPElementTypeGeneratedLong = 0x1 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,
            MPElementTypeGeneratedMedium = 0x2 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,
            MPElementTypeGeneratedBasic = 0x4 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,
            MPElementTypeGeneratedShort = 0x3 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,
            MPElementTypeGeneratedPIN = 0x5 | (int)MPElementTypeClass.MPElementTypeClassGenerated | 0x0,

            MPElementTypeStoredPersonal = 0x0 | (int)MPElementTypeClass.MPElementTypeClassStored | (int)MPElementFeature.MPElementFeatureExportContent,
            MPElementTypeStoredDevicePrivate = 0x1 | (int)MPElementTypeClass.MPElementTypeClassStored | (int)MPElementFeature.MPElementFeatureDevicePrivate,
        }

        public enum MPType
        {
            Maximum,
            Long,
            Medium,
            Basic,
            Short,
            PIN
        }

        private static string Hex(byte[] bytes)
        {
            return BitConverter.ToString(bytes);
        }

        private static string IDForBuf(byte[] bytes)
        {
            SHA256 sha256 = SHA256.Create();
            byte[] hash = sha256.ComputeHash(bytes);
            return BitConverter.ToString(hash);
        }

        private static string CipherForType(MPElementType type, byte seedByte)
        {
            string retValue = "";
            if (((int)type & (int)MPElementTypeClass.MPElementTypeClassGenerated) > 0)
            {
                switch (type)
                {
                    case MPElementType.MPElementTypeGeneratedMaximum:
                        {
                            string[] ciphers = { "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" };
                            retValue = ciphers[seedByte % 2];
                            break;
                        }

                    case MPElementType.MPElementTypeGeneratedLong:
                        {
                            string[] ciphers = { "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno", "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno", "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno", "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno", "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno", "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno", "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" };
                            retValue = ciphers[seedByte % 21];
                            break;
                        }

                    case MPElementType.MPElementTypeGeneratedMedium:
                        {
                            string[] ciphers = { "CvcnoCvc", "CvcCvcno" };
                            retValue = ciphers[seedByte % 2];
                            break;
                        }
                    case MPElementType.MPElementTypeGeneratedBasic:
                        {
                            string[] ciphers = { "aaanaaan", "aannaaan", "aaannaaa" };
                            retValue = ciphers[seedByte % 3];
                            break;
                        }
                    case MPElementType.MPElementTypeGeneratedShort:
                        {
                            retValue = "Cvcn";
                            break;
                        }

                    case MPElementType.MPElementTypeGeneratedPIN:
                        {
                            retValue = "nnnn";
                            break;
                        }

                    default:
                        {
                            Debug.WriteLine("Unknown generated type: %d", type);
                            break;
                        }
                }
            }
            return retValue;
        }

        private static char CharacterFromClass(char characterClass, byte seedByte)
        {
            char retValue = char.MinValue;
            string classCharacters = "";
            switch (characterClass)
            {
                case 'V':
                    classCharacters = "AEIOU";
                    break;
                case 'C':
                    classCharacters = "BCDFGHJKLMNPQRSTVWXYZ";
                    break;
                case 'v':
                    classCharacters = "aeiou";
                    break;
                case 'c':
                    classCharacters = "bcdfghjklmnpqrstvwxyz";
                    break;
                case 'A':
                    classCharacters = "AEIOUBCDFGHJKLMNPQRSTVWXYZ";
                    break;
                case 'a':
                    classCharacters = "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz";
                    break;
                case 'n':
                    classCharacters = "0123456789";
                    break;
                case 'o':
                    classCharacters = "@&%?,=[]_:-+*$#!'^~;()/.";
                    break;
                case 'x':
                    classCharacters = "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&*()";
                    break;
                default:
                    Debug.WriteLine("Unknown character class: %c", characterClass);
                    break;
            }
            if (classCharacters.Length > 0)
                retValue = classCharacters[seedByte % classCharacters.Length];

            return retValue;
        }

        static byte[] EncryptStringToBytes(string plainText, byte[] Key, byte[] IV)
        {
            // Check arguments. 
            if (plainText == null || plainText.Length <= 0)
                throw new ArgumentNullException("plainText");
            if (Key == null || Key.Length <= 0)
                throw new ArgumentNullException("Key");
            if (IV == null || IV.Length <= 0)
                throw new ArgumentNullException("Key");
            byte[] encrypted;
            // Create an RijndaelManaged object 
            // with the specified key and IV. 
            using (RijndaelManaged rijAlg = new RijndaelManaged())
            {
                rijAlg.Key = Key;
                rijAlg.IV = IV;

                // Create a decrytor to perform the stream transform.
                ICryptoTransform encryptor = rijAlg.CreateEncryptor(rijAlg.Key, rijAlg.IV);

                // Create the streams used for encryption. 
                using (MemoryStream msEncrypt = new MemoryStream())
                {
                    using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                    {
                        using (StreamWriter swEncrypt = new StreamWriter(csEncrypt))
                        {   // Write all data to the stream.
                            swEncrypt.Write(plainText);
                        }
                        encrypted = msEncrypt.ToArray();
                    }
                }
            }
            // Return the encrypted bytes from the memory stream. 
            return encrypted;
        }

        static string DecryptStringFromBytes(byte[] cipherText, byte[] Key, byte[] IV)
        {
            // Check arguments. 
            if (cipherText == null || cipherText.Length <= 0)
                throw new ArgumentNullException("cipherText");
            if (Key == null || Key.Length <= 0)
                throw new ArgumentNullException("Key");
            if (IV == null || IV.Length <= 0)
                throw new ArgumentNullException("Key");

            // Declare the string used to hold 
            // the decrypted text. 
            string plaintext = null;

            // Create an RijndaelManaged object 
            // with the specified key and IV. 
            using (RijndaelManaged rijAlg = new RijndaelManaged())
            {
                rijAlg.Key = Key;
                rijAlg.IV = IV;

                // Create a decrytor to perform the stream transform.
                ICryptoTransform decryptor = rijAlg.CreateDecryptor(rijAlg.Key, rijAlg.IV);

                // Create the streams used for decryption. 
                using (MemoryStream msDecrypt = new MemoryStream(cipherText))
                {
                    using (CryptoStream csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                    {
                        using (StreamReader srDecrypt = new StreamReader(csDecrypt))
                        {   // Read the decrypted bytes from the decrypting stream 
                            // and place them in a string.
                            plaintext = srDecrypt.ReadToEnd();
                        }
                    }
                }
            }
            return plaintext;
        }

        public static byte[] Encrypt(string masterPassword, string data)
        {
            byte[] retValue = new byte[0];
            if (masterPassword.Length > 0)
            {
                string mpNameSpace = "com.lyndir.masterpassword";
                byte[] mpNameSpaceBytes = new UTF8Encoding().GetBytes(mpNameSpace);
                byte[] masterPasswordBytes = new UTF8Encoding().GetBytes(masterPassword);
                byte[] masterKey = SCrypt.DeriveKey(masterPasswordBytes, mpNameSpaceBytes, MP_N, MP_r, MP_p, 32);
                using (RijndaelManaged rijndael = new RijndaelManaged())
                {
                    rijndael.Key = masterKey;
                    rijndael.GenerateIV();

                    byte[] encrypted = EncryptStringToBytes(data, rijndael.Key, rijndael.IV);
                    retValue = new byte[rijndael.IV.Length + encrypted.Length];
                    Array.Copy(rijndael.IV, retValue, rijndael.IV.Length);
                    Array.Copy(encrypted, 0, retValue, rijndael.IV.Length, encrypted.Length);
                }
            }
            return retValue;
        }

        public static string Decrypt(string masterPassword, byte[] data)
        {
            string retValue = "";
            if (masterPassword.Length > 0)
            {
                string mpNameSpace = "com.lyndir.masterpassword";
                byte[] mpNameSpaceBytes = new UTF8Encoding().GetBytes(mpNameSpace);
                byte[] masterPasswordBytes = new UTF8Encoding().GetBytes(masterPassword);
                byte[] masterKey = SCrypt.DeriveKey(masterPasswordBytes, mpNameSpaceBytes, MP_N, MP_r, MP_p, 32);

                using (RijndaelManaged rijndael = new RijndaelManaged())
                {
                    rijndael.Key = masterKey;
                    byte[] iv = new byte[rijndael.IV.Length];
                    Array.Copy(data, iv, iv.Length);
                    rijndael.IV = iv;
                    byte[] encrypted = new byte[data.Length - rijndael.IV.Length];
                    Array.Copy(data, rijndael.IV.Length, encrypted, 0, encrypted.Length);
                    retValue = DecryptStringFromBytes(encrypted, rijndael.Key, rijndael.IV);
                }
            }
            return retValue;
        }

        public static string GetMasterPasswordKeySHA(string masterPassword)
        {
            string retValue = "";
            if (masterPassword.Length > 0)
            {
                string mpNameSpace = "com.lyndir.masterpassword";
                byte[] mpNameSpaceBytes = new UTF8Encoding().GetBytes(mpNameSpace);
                byte[] masterPasswordBytes = new UTF8Encoding().GetBytes(masterPassword);
                byte[] masterKey = SCrypt.DeriveKey(masterPasswordBytes, mpNameSpaceBytes, MP_N, MP_r, MP_p, MP_dkLen);
                retValue = IDForBuf(masterKey);
            }
            return retValue;
        }

        public static string Calculate(string masterPassword, string userName, string siteName, int siteCounter, MPType mpType)
        {
            MPElementType[] passwordTypes = {MPElementType.MPElementTypeGeneratedMaximum, 
                                             MPElementType.MPElementTypeGeneratedLong,
                                             MPElementType.MPElementTypeGeneratedMedium,
                                             MPElementType.MPElementTypeGeneratedBasic,
                                             MPElementType.MPElementTypeGeneratedShort,
                                             MPElementType.MPElementTypeGeneratedPIN};

            MPElementType type = passwordTypes[(int)mpType];

            string retValue = "";
            if ((masterPassword.Length > 0) && (userName.Length > 0) && (siteName.Length > 0))
            {
                string mpNameSpace = "com.lyndir.masterpassword";
                byte[] mpNameSpaceBytes = new UTF8Encoding().GetBytes(mpNameSpace);
                byte[] userNameBytes = new UTF8Encoding().GetBytes(userName);
                UInt32 n_userNameLength = (UInt32)IPAddress.HostToNetworkOrder(userNameBytes.Length);
                int masterKeySaltLength = mpNameSpaceBytes.Length + sizeof(UInt32) + userNameBytes.Length;
                IntPtr masterKeySalt = Marshal.AllocHGlobal(masterKeySaltLength);
                IntPtr mks = masterKeySalt;
                Marshal.Copy(mpNameSpaceBytes, 0, mks, mpNameSpaceBytes.Length);
                mks += mpNameSpaceBytes.Length;
                Marshal.Copy(BitConverter.GetBytes(n_userNameLength), 0, mks, sizeof(UInt32));
                mks += sizeof(UInt32);
                Marshal.Copy(userNameBytes, 0, mks, userNameBytes.Length);
                mks += userNameBytes.Length;
                if ((mks.ToInt32() - masterKeySalt.ToInt32()) == masterKeySaltLength)
                {
                    byte[] masterKeySaltBytes = new byte[masterKeySaltLength];
                    Marshal.Copy(masterKeySalt, masterKeySaltBytes, 0, masterKeySaltLength);
                    //Debug.WriteLine("masterKeySalt ID: " + IDForBuf(masterKeySaltBytes));

                    byte[] masterPasswordBytes = new UTF8Encoding().GetBytes(masterPassword);
                    byte[] masterKey = SCrypt.DeriveKey(masterPasswordBytes, masterKeySaltBytes, MP_N, MP_r, MP_p, MP_dkLen);

                    //Debug.WriteLine("masterPassword Hex: " + Hex(masterPasswordBytes));
                    //Debug.WriteLine("masterPassword ID: " + IDForBuf(masterPasswordBytes));
                    //Debug.WriteLine("masterKey ID: " + IDForBuf(masterKey));

                    byte[] siteNameBytes = new UTF8Encoding().GetBytes(siteName);
                    UInt32 n_siteNameLength = (UInt32)IPAddress.HostToNetworkOrder(siteNameBytes.Length);
                    UInt32 n_siteCounter = (UInt32)IPAddress.HostToNetworkOrder(siteCounter);
                    int sitePasswordInfoLength = mpNameSpaceBytes.Length + sizeof(UInt32) + siteNameBytes.Length + sizeof(UInt32);
                    IntPtr sitePasswordInfo = Marshal.AllocHGlobal(sitePasswordInfoLength);
                    IntPtr sPI = sitePasswordInfo;
                    Marshal.Copy(mpNameSpaceBytes, 0, sPI, mpNameSpaceBytes.Length);
                    sPI += mpNameSpaceBytes.Length;
                    Marshal.Copy(BitConverter.GetBytes(n_siteNameLength), 0, sPI, sizeof(UInt32));
                    sPI += sizeof(UInt32);
                    Marshal.Copy(siteNameBytes, 0, sPI, siteNameBytes.Length);
                    sPI += siteNameBytes.Length;
                    Marshal.Copy(BitConverter.GetBytes(n_siteCounter), 0, sPI, sizeof(UInt32));
                    sPI += sizeof(UInt32);
                    if ((sPI.ToInt32() - sitePasswordInfo.ToInt32()) == sitePasswordInfoLength)
                    {
                        byte[] sitePasswordInfoBytes = new byte[sitePasswordInfoLength];
                        Marshal.Copy(sitePasswordInfo, sitePasswordInfoBytes, 0, sitePasswordInfoLength);
                        //Debug.WriteLine("seed from: hmac-sha256(masterKey, 'com.lyndir.masterpassword' | {0} | {1} | {2})", Hex(BitConverter.GetBytes(n_siteNameLength)), siteName, Hex(BitConverter.GetBytes(n_siteCounter)));
                        //Debug.WriteLine("sitePasswordInfo ID: " + IDForBuf(sitePasswordInfoBytes));


                        HMACSHA256 hmacsha256 = new HMACSHA256(masterKey);
                        byte[] sitePasswordSeed = hmacsha256.ComputeHash(sitePasswordInfoBytes);

                        //Debug.WriteLine("sitePasswordSeed ID: " + IDForBuf(sitePasswordSeed));

                        string cipher = CipherForType(type, sitePasswordSeed[0]);
                        //Debug.WriteLine("type: {0}, cipher: {1}", type.ToString(), cipher);
                        char[] sitePassword = new char[cipher.Length];
                        if (cipher.Length <= 32)
                        {
                            for (int c = 0; c < cipher.Length; c++)
                            {
                                sitePassword[c] = CharacterFromClass(cipher[c], sitePasswordSeed[c + 1]);
                                //Debug.WriteLine("class {0}, character {1}", cipher[c], sitePassword[c]);
                            }
                            retValue = new string(sitePassword);
                            //Debug.WriteLine(retValue);
                        }
                    }
                    Marshal.FreeHGlobal(sitePasswordInfo);
                }
                Marshal.FreeHGlobal(masterKeySalt);
            }
            return retValue;
        }
    }
}
