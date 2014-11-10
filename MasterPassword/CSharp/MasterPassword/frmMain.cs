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
using System.IO;
using System.Windows.Forms;
using Newtonsoft.Json;
using System.Security.Cryptography;


namespace MasterPassword
{
    public partial class frmMain : Form
    {
        private const int PASSWORD_VISIBILITY_MS = 15 * 1000;   // Show the password for 15 seconds, then remove from vision
        private Dictionary<string, MRUData> mruData = new Dictionary<string, MRUData>();
        private Timer timerVisibitlity = new Timer();
        public frmMain()
        {
            InitializeComponent();

            toolTip1.SetToolTip(btnDelete, "Delete site from list");

            timerVisibitlity.Interval = PASSWORD_VISIBILITY_MS;
            timerVisibitlity.Tick += timerVisibitlity_Tick;

            #region Test Case
            // Test case, should produce:
            //  masterKeySalt ID: 8C-45-CA-48-46-73-5F-C7-29-ED-8B-52-E8-74-88-15-5E-18-56-B9-CD-CA-6D-FF-88-10-A6-E8-46-BE-ED-20
            //  masterPassword Hex: 62-61-6E-61-6E-61-20-63-6F-6C-6F-72-65-64-20-64-75-63-6B-6C-69-6E-67
            //  masterPassword ID: A7-20-D6-A4-20-75-33-DA-98-54-55-8B-15-3A-41-E0-55-AF-32-D9-EC-1F-2C-61-6F-90-8E-99-8E-50-37-2F
            //  masterKey ID: AE-F3-B9-47-97-3D-21-19-4D-2D-34-28-D9-70-FE-88-5D-EB-62-B1-DA-A3-30-30-CF-AA-C4-05-6A-A6-36-33
            //  seed from: hmac-sha256(masterKey, 'com.lyndir.masterpassword' | 00-00-00-15 | masterpasswordapp.com | 00-00-00-01)
            //  sitePasswordInfo ID: 2A-CA-06-25-BA-02-3C-64-DB-2A-65-EF-03-C5-21-BB-E2-A2-88-EE-82-A1-9C-40-2E-C0-AF-AA-0F-85-EF-11
            //  sitePasswordSeed ID: 60-71-19-F6-5D-F8-43-1A-5E-00-D8-61-39-A0-33-18-4D-21-56-C9-24-B3-BA-73-31-59-A0-BA-45-4C-E1-E6
            //  type: MPElementTypeGeneratedLong, cipher: CvcvnoCvcvCvcc
            //  class C, character D
            //  class v, character o
            //  class c, character r
            //  class v, character a
            //  class n, character 6
            //  class o, character .
            //  class C, character N
            //  class v, character u
            //  class c, character d
            //  class v, character i
            //  class C, character D
            //  class v, character u
            //  class c, character h
            //  class c, character j
            //  Dora6.NudiDuhj
            //MasterPassword.Calculate("banana colored duckling", "Robert Lee Mitchel", "masterpasswordapp.com", 1, MasterPassword.MPType.Long);
            #endregion Test Case
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == NativeMethods.WM_SHOWME)
                ShowMe();
            base.WndProc(ref m);
        }

        private void ShowMe()
        {
            if (WindowState == FormWindowState.Minimized)
                WindowState = FormWindowState.Normal;
            // Bring window on top of everything else
            TopMost = true;
            // And set it back to normal
            TopMost = false;
        }

        void timerVisibitlity_Tick(object sender, EventArgs e)
        {
            timerVisibitlity.Stop();
            txtPassword.Text = "";
        }

        private bool LoadMRU(string fileName)
        {
            bool retValue = false;
            string appDataPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), Application.ProductName, fileName);
            if (File.Exists(appDataPath))
            {
                string json = "";
                using (BinaryReader br = new BinaryReader(File.Open(appDataPath, FileMode.Open)))
                {
                    byte[] encrypted = br.ReadBytes((int)new FileInfo(appDataPath).Length);
                    br.Close();
                    json = MasterPassword.Decrypt(txtMasterPassword.Text, encrypted);
                }
                if (json.Length > 0)
                {
                    mruData = JsonConvert.DeserializeObject<Dictionary<string, MRUData>>(json);
                    // Populate siteNames combo
                    List<string> siteNames = new List<string>(mruData.Keys);
                    cmbSite.Items.Clear();
                    cmbSite.Items.AddRange(siteNames.ToArray());
                    retValue = true;
                }
            }
            return retValue;
        }

        private void SaveMRU(string fileName)
        {
            string appDataPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), Application.ProductName, fileName);
            string json = JsonConvert.SerializeObject(mruData);
            byte[] encrypted = MasterPassword.Encrypt(txtMasterPassword.Text, json);
            Directory.CreateDirectory(Path.GetDirectoryName(appDataPath));
            using (BinaryWriter bw = new BinaryWriter(File.Create(appDataPath)))
            {
                bw.Write(encrypted);
                bw.Close();
            }
        }

        private void btnGetPassword_Click(object sender, EventArgs e)
        {
            if (txtUsername.Text.Length == 0)
                return;
            if (cmbSite.Text.Length == 0)
                return;
            if (cmbType.SelectedIndex == -1)
                cmbType.SelectedIndex = 0;
            txtPassword.Text = MasterPassword.Calculate(txtMasterPassword.Text, txtUsername.Text, cmbSite.Text, (int)nudCounter.Value, (MasterPassword.MPType)cmbType.SelectedIndex);
            timerVisibitlity.Start();
            if (mruData.ContainsKey(cmbSite.Text))
            {   // Update mruData
                mruData[cmbSite.Text].PasswordType = (MasterPassword.MPType)cmbType.SelectedIndex;
                mruData[cmbSite.Text].SiteCounter = (int)nudCounter.Value;
                mruData[cmbSite.Text].UserName = txtUsername.Text;
            }
            else 
            {   // Add mruData
                mruData.Add(cmbSite.Text, new MRUData(txtUsername.Text, cmbSite.Text, (int)nudCounter.Value, (MasterPassword.MPType)cmbType.SelectedIndex));
                // And add to list
                cmbSite.Items.Add(cmbSite.Text);
            }
            UpdateButtonStates();
        }

        private void frmMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            string fileTitle = MasterPassword.GetMasterPasswordKeySHA(txtMasterPassword.Text);
            if (fileTitle.Length > 0)
            {
                fileTitle = fileTitle.Replace("-", string.Empty);
                SaveMRU(fileTitle + ".dat");
            }
        }

        private void cmbSite_Check(object sender, EventArgs e)
        {
            if (mruData.ContainsKey(cmbSite.Text))
            {   // Update other fields to last used
                cmbType.SelectedIndex = (int)mruData[cmbSite.Text].PasswordType;
                nudCounter.Value = mruData[cmbSite.Text].SiteCounter;
                txtUsername.Text = mruData[cmbSite.Text].UserName;
            }
            UpdateButtonStates();
        }

        private void UpdateButtonStates()
        {
            if ((txtMasterPassword.Text.Length > 0) && (txtUsername.Text.Length > 0) && (cmbSite.Text.Length > 0) && (cmbType.SelectedIndex != -1))
                btnGetPassword.Enabled = true;
            else
                btnGetPassword.Enabled = false;
            btnDelete.Enabled = mruData.ContainsKey(cmbSite.Text);
        }

        private void txtMasterPassword_Leave(object sender, EventArgs e)
        {
            string fileTitle = MasterPassword.GetMasterPasswordKeySHA(txtMasterPassword.Text);
            if (fileTitle.Length > 0)
            {
                fileTitle = fileTitle.Replace("-", string.Empty);
                if (LoadMRU(fileTitle + ".dat"))
                    cmbSite.Focus();
                else
                {
                    txtUsername.Text = "";
                    txtPassword.Text = "";
                    cmbType.SelectedIndex = -1;
                    cmbSite.Items.Clear();
                    nudCounter.Value = 1;
                }
            }
        }

        private void btnDelete_Click(object sender, EventArgs e)
        {
            if (mruData.ContainsKey(cmbSite.Text))
            {
                mruData.Remove(cmbSite.Text);
                int index = cmbSite.FindStringExact(cmbSite.Text);
                if (index != -1)
                    cmbSite.Items.RemoveAt(index);
                cmbSite.Text = "";
                txtUsername.Text = "";
                txtPassword.Text = "";
                nudCounter.Value = 1;
                cmbType.SelectedIndex = -1;
                cmbSite.Focus();
                UpdateButtonStates();
            }
        }

        private void txtUsername_Leave(object sender, EventArgs e)
        {
            UpdateButtonStates();
        }

        private void cmbType_Leave(object sender, EventArgs e)
        {
            UpdateButtonStates();
        }

        private void nudCounter_Leave(object sender, EventArgs e)
        {
            UpdateButtonStates();
        }

        private void cmbSite_Enter(object sender, EventArgs e)
        {
            txtUsername.Text = "";
            cmbType.SelectedIndex = -1;
            nudCounter.Value = 1;
            txtPassword.Text = "";
            UpdateButtonStates();
        }

        private void cmbType_SelectedIndexChanged(object sender, EventArgs e)
        {
            UpdateButtonStates();
        }
    }
}
