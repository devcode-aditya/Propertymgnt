table 17 "G/L Entry"
{
    // LS = changes made by LS Retail
    // Code          Date      Name            Description
    // APNT-JDE      31.12.11  Tanweer         Added field and Key No. 11 for JDE Customization
    // APNT-IBU1.0   31.07.11  Tanweer         Added field for Inter BU Customization
    // APNT-AT1.0    07.09.11  Tanweer         Added field for Asset Transfer Customization
    // APNT-FIN1.0   07.09.11  Tanweer         Added fields and Key No. 12, 13, 17 and 19 for Finance Customization
    // APNT-JDE      18.09.11  Shameema        Added Key No. 16 for JDE Customization
    // APNT-IBU1.0   04.12.11  Ashish          Added key no. 18, "Document No.,G/L Account No.,Amount" for IBU reversal
    //                                         (as discussed with Tan)
    // APNT-IC1.0    18.04.12  Tanweer         Added fields for IC Customization
    // APNT-LM1.0    08.07.12  Shameema        Added fields for Lease Customization
    // DP = changes made by DVS
    // APNT-HR1.0    12.11.13  Sangeeta        Added fields and modified Key No. 5
    //                                         Added Key No. 13 & key No. 11 for HR & Payroll Customization
    // T006180       18.03.15  Tanweer         Added Key No. 22 for Lease Management Customizations
    // LALS          08.10.19  Ganesh          Added new filed Invoice rec date

    Caption = 'G/L Entry';
    DrillDownFormID = Form20;
    LookupFormID = Form20;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal.Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Bal. Account Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Bal. Account Type=CONST(IC Partner)) "IC Partner";
        }
        field(17;Amount;Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(23;"Global Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));
        }
        field(24;"Global Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));
        }
        field(27;"User ID";Code[20])
        {
            Caption = 'User ID';
            TableRelation = User;
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            var
                LoginMgt: Codeunit "418";
            begin
                LoginMgt.LookupUserID("User ID");
            end;
        }
        field(28;"Source Code";Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(29;"System-Created Entry";Boolean)
        {
            Caption = 'System-Created Entry';
        }
        field(30;"Prior-Year Entry";Boolean)
        {
            Caption = 'Prior-Year Entry';
        }
        field(41;"Job No.";Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(42;Quantity;Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0:5;
        }
        field(43;"VAT Amount";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(45;"Business Unit Code";Code[10])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(46;"Journal Batch Name";Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(47;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(48;"Gen. Posting Type";Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(49;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(50;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(51;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
        }
        field(52;"Transaction No.";Integer)
        {
            Caption = 'Transaction No.';
        }
        field(53;"Debit Amount";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(54;"Credit Amount";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(55;"Document Date";Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        field(56;"External Document No.";Code[20])
        {
            Caption = 'External Document No.';
        }
        field(57;"Source Type";Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(58;"Source No.";Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF (Source Type=CONST(Customer)) Customer
                            ELSE IF (Source Type=CONST(Vendor)) Vendor
                            ELSE IF (Source Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Source Type=CONST(Fixed Asset)) "Fixed Asset";
        }
        field(59;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(60;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(61;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(62;"Tax Group Code";Code[10])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(63;"Use Tax";Boolean)
        {
            Caption = 'Use Tax';
        }
        field(64;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(65;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(68;"Additional-Currency Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
        }
        field(69;"Add.-Currency Debit Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
        }
        field(70;"Add.-Currency Credit Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
        }
        field(71;"Close Income Statement Dim. ID";Integer)
        {
            Caption = 'Close Income Statement Dim. ID';
        }
        field(72;"IC Partner Code";Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(73;Reversed;Boolean)
        {
            Caption = 'Reversed';
        }
        field(74;"Reversed by Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "G/L Entry";
        }
        field(75;"Reversed Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "G/L Entry";
        }
        field(76;"G/L Account Name";Text[50])
        {
            CalcFormula = Lookup("G/L Account".Name WHERE (No.=FIELD(G/L Account No.)));
            Caption = 'G/L Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5400;"Prod. Order No.";Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(5600;"FA Entry Type";Option)
        {
            Caption = 'FA Entry Type';
            OptionCaption = ' ,Fixed Asset,Maintenance';
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        field(5601;"FA Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'FA Entry No.';
            TableRelation = IF (FA Entry Type=CONST(Fixed Asset)) "FA Ledger Entry"
                            ELSE IF (FA Entry Type=CONST(Maintenance)) "Maintenance Ledger Entry";
        }
        field(50000;"Actual Transaction No.";Integer)
        {
            Description = 'APNT-IBU1.0';
        }
        field(50001;"Exported To JDE";Boolean)
        {
            Description = 'JDE';
        }
        field(50002;"FA Posting Type";Option)
        {
            Description = 'AT1.0';
            OptionCaption = ' ,Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance,Transfer';
            OptionMembers = " ","Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance,Transfer;
        }
        field(50003;"IC Transaction No.";Integer)
        {
            Description = 'IC1.0';
        }
        field(50004;"IC Partner Direction";Option)
        {
            Description = 'IC1.0';
            OptionCaption = ' ,Outgoing,Incoming';
            OptionMembers = " ",Outgoing,Incoming;
        }
        field(50013;"Invoice Received Date";Date)
        {
            Description = 'LALS';
        }
        field(50051;"Created Date Time";DateTime)
        {
            Description = 'DT1.0';
        }
        field(50103;"Facility Due Date";Date)
        {
            Description = 'FIN1.0';
        }
        field(50104;"Facility No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50105;"Facility Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Over Draft,Letter of Credit,Trust Receipt,Loans,Bank Facility,Cheque';
            OptionMembers = " ","Over Draft","Letter of Credit","Trust Receipt",Loans,"Bank Facility",Cheque;
        }
        field(50106;"Charges Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Legalization,Bank,Issuance Comm.,Amendment,Interest,Loan';
            OptionMembers = " ",Legalization,Bank,"Issuance Comm.",Amendment,Interest,Loan;
        }
        field(50107;"Loan No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50108;"Real Estate No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50109;"Investment Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Fixed Deposit,Fixed Income,Hedge Fund,Preference Stock,Private Equity,Equity,Mutual Fund,Real Estate Fund,Equity Fund,Structured Instrument,Foreign Redemption Note';
            OptionMembers = " ","Fixed Deposit","Fixed Income","Hedge Fund","Preference Stock","Private Equity",Equity,"Mutual Fund","Real Estate Fund","Equity Fund","Structured Instrument","Foreign Redemption Note";
        }
        field(50110;"Investment No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50111;"Charge No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50203;Remarks;Text[250])
        {
            Description = 'APNT-PV1.0';
        }
        field(50500;"Lease Agreement No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Lease Management Header".No.;
        }
        field(50501;"Lease Agreement Charge No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Lease Charges/ Deposits"."Document No.";
        }
        field(50504;"Lease Agreement Charge Type";Option)
        {
            Description = 'APNT-LM1.0';
            OptionCaption = 'Deposit,Charge';
            OptionMembers = Deposit,Charge;
        }
        field(60000;"Employee No.";Code[20])
        {
            Description = 'HR1.0';
            TableRelation = Employee;
        }
        field(60001;"Payroll Type";Option)
        {
            Description = 'HR1.0';
            OptionCaption = ' ,Basic Salary,Housing,Transport,Re-imbursment,Deduction,Over Time,Loan,Advance,Leave Salary Accr,Allowance,Air Passage Accr,Bonus Accr,Gratuity Accr,Leave Salary,Gratuity,Air Passage,Bonus,National Pension Accr,Pension Payment,Commission';
            OptionMembers = " ","Basic Salary",Housing,Transport,"Re-imbursment",Deduction,"Over Time",Loan,Advance,"Leave Salary Accr",Allowance,"Air Passage Accr","Bonus Accr","Gratuity Accr","Leave Salary",Gratuity,"Air Passage",Bonus,"National Pension Accr","Pension Payment",Commission;

            trigger OnValidate()
            begin
                /*
                IF ("Payroll Type" <> "Payroll Type"::" " ) AND ("Account No." <> '') THEN
                BEGIN
                   TESTFIELD("Account No.");
                   IF ("Payroll Type" <> "Payroll Type"::Loan) AND ("Payroll Type" <> "Payroll Type"::Advance) THEN BEGIN
                
                     Emp.GET("Account No.");
                     EmpPostingGr.GET(Emp."Employee Posting Group");
                   CASE "Payroll Type" OF
                   "Payroll Type"::Allowance:
                   BEGIN
                     TESTFIELD("Payroll Source Type");
                     Allowances.GET("Payroll Source Type");
                     "Payroll A/C No.":=Allowances."Account No.";
                   END;
                   "Payroll Type"::"Basic Salary":
                     "Payroll A/C No.":=EmpPostingGr."Salary Account";
                   "Payroll Type"::"Over time":
                     "Payroll A/C No.":=EmpPostingGr."Overtime Account";
                   "Payroll Type"::Loan:
                     "Payroll A/C No.":=EmpPostingGr."Employee Loans Acc.";
                   "Payroll Type"::Advance:
                     "Payroll A/C No.":=EmpPostingGr."Employee Advances Acc.";
                   "Payroll Type"::"Leave Salary":
                     "Payroll A/C No.":=EmpPostingGr."Leave Salary Acc.";
                   END;
                END;
                END;
                */

            end;
        }
        field(60002;"Payroll A/C No.";Code[20])
        {
            Description = 'HR1.0';
            TableRelation = "G/L Account";
        }
        field(60003;"Payroll Parameter";Code[20])
        {
            Description = 'HR1.0';
            TableRelation = "G/L Account";
        }
        field(60030;"Bonus Accrual Entry";Boolean)
        {
            Description = 'HR1.0';
        }
        field(60031;"Last Bonus Accrued Date";Date)
        {
            Description = 'HR1.0';
        }
        field(10000702;"Batch No.";Code[10])
        {
            Caption = 'Batch No.';
        }
        field(33016800;"Ref. Document Type";Option)
        {
            Description = 'DP6.01.01';
            OptionCaption = 'Lease,Sale,Work Order';
            OptionMembers = Lease,Sale,"Work Order";
        }
        field(33016801;"Ref. Document No.";Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = "Agreement Header".No.;
        }
        field(33016806;"Ref. Document Line No.";Integer)
        {
            BlankZero = true;
            Description = 'DP6.01.01';
            TableRelation = "Agreement Line"."Line No." WHERE (Agreement No.=FIELD(Ref. Document No.),
                                                               Agreement Type=FIELD(Ref. Document Type));
        }
        field(33016810;"Chq No.";Code[20])
        {
            Description = 'DP6.01.01';
        }
        field(33016811;"Chq Date";Date)
        {
            Description = 'DP6.01.01';
        }
        field(33016812;"Chq Amount";Decimal)
        {
            Description = 'DP6.01.01';
        }
        field(33016813;"Issuing Bank Name";Text[50])
        {
            Description = 'DP6.01.01';
        }
        field(33016814;"Issuing Bank Branch";Text[30])
        {
            Description = 'DP6.01.01';
        }
    }

    keys
    {
        key(Key1;"Entry No.")
        {
            Clustered = true;
        }
        key(Key2;"G/L Account No.","Posting Date")
        {
            SumIndexFields = Amount,"Debit Amount","Credit Amount","Additional-Currency Amount","Add.-Currency Debit Amount","Add.-Currency Credit Amount";
        }
        key(Key3;"G/L Account No.","Global Dimension 1 Code","Global Dimension 2 Code","Posting Date")
        {
            SumIndexFields = Amount,"Debit Amount","Credit Amount","Additional-Currency Amount","Add.-Currency Debit Amount","Add.-Currency Credit Amount";
        }
        key(Key4;"G/L Account No.","Business Unit Code","Posting Date")
        {
            SumIndexFields = Amount,"Debit Amount","Credit Amount","Additional-Currency Amount","Add.-Currency Debit Amount","Add.-Currency Credit Amount";
        }
        key(Key5;"G/L Account No.","Business Unit Code","Global Dimension 1 Code","Global Dimension 2 Code","Posting Date","Employee No.")
        {
            SumIndexFields = Amount,"Debit Amount","Credit Amount","Additional-Currency Amount","Add.-Currency Debit Amount","Add.-Currency Credit Amount";
        }
        key(Key6;"Document No.","Posting Date")
        {
        }
        key(Key7;"Transaction No.")
        {
        }
        key(Key8;"IC Partner Code")
        {
        }
        key(Key9;"G/L Account No.","Job No.","Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key10;"Document No.","Posting Date","G/L Account No.")
        {
        }
        key(Key11;"Exported To JDE","Posting Date","Global Dimension 1 Code","Reason Code","G/L Account No.")
        {
        }
        key(Key12;"Facility Type","Facility No.")
        {
        }
        key(Key13;"Facility Type","Facility No.","Bal. Account Type","Bal. Account No.")
        {
        }
        key(Key14;"Loan No.")
        {
        }
        key(Key15;"Real Estate No.")
        {
        }
        key(Key16;"Source Code","Document No.","Posting Date","Global Dimension 1 Code","G/L Account No.")
        {
            SumIndexFields = Amount;
        }
        key(Key17;"Investment Type","Investment No.")
        {
        }
        key(Key18;"Document No.","G/L Account No.",Amount)
        {
        }
        key(Key19;"Charges Type","Charge No.")
        {
        }
        key(Key20;"Source Code","Lease Agreement No.","Lease Agreement Charge No.")
        {
            SumIndexFields = Amount;
        }
        key(Key21;"Employee No.","Payroll Type","Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key22;"Lease Agreement No.","Lease Agreement Charge Type","Lease Agreement Charge No.","G/L Account No.","Posting Date")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"Entry No.",Description,"G/L Account No.","Posting Date","Document Type","Document No.")
        {
        }
    }

    var
        GLSetup: Record "98";
        GLSetupRead: Boolean;
 
    procedure GetCurrencyCode(): Code[10]
    begin
        IF NOT GLSetupRead THEN BEGIN
          GLSetup.GET;
          GLSetupRead := TRUE;
        END;
        EXIT(GLSetup."Additional Reporting Currency");
    end;
 
    procedure ShowValueEntries()
    var
        GLItemLedgRelation: Record "5823";
        ValueEntry: Record "5802";
        TempValueEntry: Record "5802" temporary;
    begin
        GLItemLedgRelation.SETRANGE("G/L Entry No.","Entry No.");
        IF GLItemLedgRelation.FINDSET THEN
          REPEAT
            ValueEntry.GET(GLItemLedgRelation."Value Entry No.");
            TempValueEntry.INIT;
            TempValueEntry := ValueEntry;
            TempValueEntry.INSERT;
          UNTIL GLItemLedgRelation.NEXT = 0;

        FORM.RUNMODAL(0,TempValueEntry);
    end;
}

