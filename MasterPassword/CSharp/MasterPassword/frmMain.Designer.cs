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
namespace MasterPassword
{
    partial class frmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmMain));
            this.label1 = new System.Windows.Forms.Label();
            this.txtUsername = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.cmbType = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.nudCounter = new System.Windows.Forms.NumericUpDown();
            this.txtPassword = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.txtMasterPassword = new System.Windows.Forms.TextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.btnGetPassword = new System.Windows.Forms.Button();
            this.cmbSite = new System.Windows.Forms.ComboBox();
            this.btnDelete = new System.Windows.Forms.Button();
            this.toolTip1 = new System.Windows.Forms.ToolTip(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.nudCounter)).BeginInit();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(12, 73);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(58, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Username:";
            // 
            // txtUsername
            // 
            this.txtUsername.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtUsername.CharacterCasing = System.Windows.Forms.CharacterCasing.Lower;
            this.txtUsername.Location = new System.Drawing.Point(77, 65);
            this.txtUsername.Name = "txtUsername";
            this.txtUsername.Size = new System.Drawing.Size(235, 20);
            this.txtUsername.TabIndex = 3;
            this.txtUsername.Leave += new System.EventHandler(this.txtUsername_Leave);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 100);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(34, 13);
            this.label2.TabIndex = 2;
            this.label2.Text = "Type:";
            // 
            // cmbType
            // 
            this.cmbType.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.cmbType.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.Append;
            this.cmbType.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cmbType.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cmbType.FormattingEnabled = true;
            this.cmbType.Items.AddRange(new object[] {
            "x - maximum (20 characters, contains symbols)",
            "l - long (Copy-friendly, 14 characters, contains symbols)",
            "m - medium  (Copy-friendly, 8 characters, contains symbols)",
            "b - basic (8 characters, no symbols)",
            "s - short (Copy-friendly, 4 characters, no symbols)",
            "p - pin (4 numbers)"});
            this.cmbType.Location = new System.Drawing.Point(77, 92);
            this.cmbType.Name = "cmbType";
            this.cmbType.Size = new System.Drawing.Size(235, 21);
            this.cmbType.TabIndex = 4;
            this.cmbType.SelectedIndexChanged += new System.EventHandler(this.cmbType_SelectedIndexChanged);
            this.cmbType.Leave += new System.EventHandler(this.cmbType_Leave);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(12, 46);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(28, 13);
            this.label3.TabIndex = 4;
            this.label3.Text = "Site:";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(12, 126);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(47, 13);
            this.label4.TabIndex = 6;
            this.label4.Text = "Counter:";
            // 
            // nudCounter
            // 
            this.nudCounter.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.nudCounter.Location = new System.Drawing.Point(77, 119);
            this.nudCounter.Maximum = new decimal(new int[] {
            100000000,
            0,
            0,
            0});
            this.nudCounter.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.nudCounter.Name = "nudCounter";
            this.nudCounter.Size = new System.Drawing.Size(125, 20);
            this.nudCounter.TabIndex = 5;
            this.nudCounter.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.nudCounter.Leave += new System.EventHandler(this.nudCounter_Leave);
            // 
            // txtPassword
            // 
            this.txtPassword.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtPassword.BackColor = System.Drawing.Color.LemonChiffon;
            this.txtPassword.Font = new System.Drawing.Font("Calibri", 14.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtPassword.Location = new System.Drawing.Point(77, 145);
            this.txtPassword.Name = "txtPassword";
            this.txtPassword.ReadOnly = true;
            this.txtPassword.Size = new System.Drawing.Size(235, 31);
            this.txtPassword.TabIndex = 7;
            this.txtPassword.TabStop = false;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(12, 155);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(56, 13);
            this.label5.TabIndex = 9;
            this.label5.Text = "Password:";
            // 
            // txtMasterPassword
            // 
            this.txtMasterPassword.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtMasterPassword.Location = new System.Drawing.Point(77, 12);
            this.txtMasterPassword.Name = "txtMasterPassword";
            this.txtMasterPassword.PasswordChar = '*';
            this.txtMasterPassword.Size = new System.Drawing.Size(235, 20);
            this.txtMasterPassword.TabIndex = 0;
            this.txtMasterPassword.Leave += new System.EventHandler(this.txtMasterPassword_Leave);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(12, 20);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(65, 13);
            this.label6.TabIndex = 10;
            this.label6.Text = "Master pwd:";
            // 
            // btnGetPassword
            // 
            this.btnGetPassword.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnGetPassword.Enabled = false;
            this.btnGetPassword.Location = new System.Drawing.Point(209, 119);
            this.btnGetPassword.Name = "btnGetPassword";
            this.btnGetPassword.Size = new System.Drawing.Size(103, 23);
            this.btnGetPassword.TabIndex = 6;
            this.btnGetPassword.Text = "Get &Password";
            this.btnGetPassword.UseVisualStyleBackColor = true;
            this.btnGetPassword.Click += new System.EventHandler(this.btnGetPassword_Click);
            // 
            // cmbSite
            // 
            this.cmbSite.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.cmbSite.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.SuggestAppend;
            this.cmbSite.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cmbSite.FormattingEnabled = true;
            this.cmbSite.Location = new System.Drawing.Point(77, 38);
            this.cmbSite.Name = "cmbSite";
            this.cmbSite.Size = new System.Drawing.Size(235, 21);
            this.cmbSite.TabIndex = 1;
            this.cmbSite.SelectedIndexChanged += new System.EventHandler(this.cmbSite_Check);
            this.cmbSite.Enter += new System.EventHandler(this.cmbSite_Enter);
            this.cmbSite.Leave += new System.EventHandler(this.cmbSite_Check);
            // 
            // btnDelete
            // 
            this.btnDelete.Enabled = false;
            this.btnDelete.FlatAppearance.BorderSize = 0;
            this.btnDelete.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.btnDelete.Image = ((System.Drawing.Image)(resources.GetObject("btnDelete.Image")));
            this.btnDelete.Location = new System.Drawing.Point(51, 40);
            this.btnDelete.Name = "btnDelete";
            this.btnDelete.Size = new System.Drawing.Size(19, 19);
            this.btnDelete.TabIndex = 2;
            this.btnDelete.TabStop = false;
            this.btnDelete.UseVisualStyleBackColor = true;
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(324, 182);
            this.Controls.Add(this.btnDelete);
            this.Controls.Add(this.cmbSite);
            this.Controls.Add(this.btnGetPassword);
            this.Controls.Add(this.txtMasterPassword);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.txtPassword);
            this.Controls.Add(this.nudCounter);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cmbType);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.txtUsername);
            this.Controls.Add(this.label1);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MaximizeBox = false;
            this.MaximumSize = new System.Drawing.Size(800, 220);
            this.MinimumSize = new System.Drawing.Size(260, 220);
            this.Name = "frmMain";
            this.Text = "MasterPassword";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.frmMain_FormClosing);
            ((System.ComponentModel.ISupportInitialize)(this.nudCounter)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox txtUsername;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cmbType;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.NumericUpDown nudCounter;
        private System.Windows.Forms.TextBox txtPassword;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.TextBox txtMasterPassword;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Button btnGetPassword;
        private System.Windows.Forms.ComboBox cmbSite;
        private System.Windows.Forms.Button btnDelete;
        private System.Windows.Forms.ToolTip toolTip1;
    }
}

