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
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MasterPassword
{
    static class Program
    {
        static Mutex mutex = new Mutex(true, "MasterPassword");

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            if (mutex.WaitOne(TimeSpan.Zero, true))
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new frmMain());
                mutex.ReleaseMutex();
            }
            else
                NativeMethods.PostMessage((IntPtr)NativeMethods.HWND_BROADCAST, NativeMethods.WM_SHOWME, IntPtr.Zero, IntPtr.Zero);
        }
    }
}
