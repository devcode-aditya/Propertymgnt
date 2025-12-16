table 81 "Gen. Journal Line"
{
    // LS = changes made by LS Retail
    // Code          Date        Name              Description
    // APNT-IBU1.0   03.08.11    Tanweer           Added fields and Key No. 4 for Inter BU Customization
    // APNT-AT1.0    07.09.11    Tanweer           Added field and code for Fixed Asset Transfer Customization
    // APNT-FIN1.0   08.09.11    Tanweer           Added code and field for Finance Custromization
    // APNT-CP1.0    28.09.11    Sangeeta          Added code for Closed Period
    // APNT-IBU1.0   05.02.12    Sangeeta          Added code for Inter BU Customization
    // APNT-ICT1.1   08.05.12    Sangeeta          Added code for IC Genjnl Customization
    // APNT-IBU1.1   04.06.12    Shameema          Added fields for IBU Adjustments Update function
    // APNT-IBU1.1   05.06.12    Shameema          Added code to test check printed for all document lines
    // APNT-FIN1.1   13.06.12    Shameema          Added code to clear IC Partner code if acct/bal. acct. is changed
    // APNT-LM1.0    08.07.12    Shameema          Added fields for Lease Customization
    // DP = changes made by DVS
    // APNT-HR1.0    12.11.13    Sangeeta          Added fields for HR & Payroll Customization.
    // T002747       12.02.14    Tanweer           Added code for LG Specific IC Jnl. Customization.
    // T006180       18.03.15    Tanweer           Added field for Lease Management Customizations
    // LALS          08.10.19    Ganesh            Added filed Invoice Reciv Date
    // T044145       13.07.22    Sujith            Added code for CRF_22_0859

    Caption = 'Gen. Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Description = 'HR1.0';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee;

            trigger OnValidate()
            begin
                IF ("Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                    "Account Type"::"IC Partner"]) AND
                   ("Bal. Account Type" IN ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                    "Bal. Account Type"::"IC Partner"])
                THEN
                    ERROR(
                      Text000,
                      FIELDCAPTION("Account Type"), FIELDCAPTION("Bal. Account Type"));
                VALIDATE("Account No.", '');
                IF "Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] THEN BEGIN
                    VALIDATE("Gen. Posting Type", "Gen. Posting Type"::" ");
                    VALIDATE("Gen. Bus. Posting Group", '');
                    VALIDATE("Gen. Prod. Posting Group", '');
                    VALIDATE("Lease Agreement No.", '');//APNT-LM1.0
                END ELSE
                    IF "Bal. Account Type" IN [
                       "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"]
                    THEN
                        VALIDATE("Payment Terms Code", '');
                UpdateSource;

                IF ("Account Type" <> "Account Type"::"Fixed Asset") AND
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                THEN BEGIN
                    "Depreciation Book Code" := '';
                    VALIDATE("FA Posting Type", "FA Posting Type"::" ");
                END;
                IF xRec."Account Type" IN
                   [xRec."Account Type"::Customer, xRec."Account Type"::Vendor]
                THEN BEGIN
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                END;

                IF ("Account Type" = "Account Type"::"IC Partner") AND
                   ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") AND
                   GLAcc.GET("Bal. Account No.")
                THEN
                    "IC Partner G/L Acc. No." := GLAcc."Default IC Partner G/L Acc. No"
                ELSE
                    "IC Partner G/L Acc. No." := '';

                IF "Journal Template Name" <> '' THEN
                    IF ("Account Type" = "Account Type"::"IC Partner") THEN BEGIN
                        GetTemplate;
                        IF GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany THEN
                            FIELDERROR("Account Type");
                    END;
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Description = 'HR1.0';
            TableRelation = IF (Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Account Type=CONST(Customer)) Customer
                            ELSE IF (Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Account Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Account Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Account Type=CONST(IC Partner)) "IC Partner"
                            ELSE IF (Account Type=CONST(Employee)) Employee;

            trigger OnValidate()
            var
                AccountingPeriods: Record "50";
                StartDate: Date;
            begin
                VALIDATE("Job No.",'');
                IF "Account No." = '' THEN BEGIN
                  UpdateLineBalance;
                  UpdateSource;
                  CreateDim(
                    DimMgt.TypeToTableID1("Account Type"),"Account No.",
                    DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                    DATABASE::Job,"Job No.",
                    DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                    DATABASE::Campaign,"Campaign No.");
                  IF xRec."Account No." <> '' THEN BEGIN
                    "Gen. Posting Type" := "Gen. Posting Type"::" ";
                    "Gen. Bus. Posting Group" := '';
                    "Gen. Prod. Posting Group" := '';
                    "VAT Bus. Posting Group" := '';
                    "VAT Prod. Posting Group" := '';
                    "Tax Area Code" := '';
                    "Tax Liable" := FALSE;
                    "Tax Group Code" := '';
                  END;
                  //APNT-FIN1.1 -
                  IF ("Bal. Account No." = '') OR
                     ("Bal. Account Type" IN
                      ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account","Bal. Account Type"::"Fixed Asset"]) THEN
                    "IC Partner Code" := '';
                  //APNT-FIN1.1 +
                  EXIT;
                END;

                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"IC Partner"] THEN
                  "IC Partner Code" := '';

                CASE "Account Type" OF
                  "Account Type"::"G/L Account":
                    BEGIN
                      GLAcc.GET("Account No.");
                      CheckGLAcc;
                      ReplaceInfo := "Bal. Account No." = '';
                      IF NOT ReplaceInfo THEN BEGIN
                        GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
                        ReplaceInfo := GenJnlBatch."Bal. Account No." <> '';
                      END;
                      IF ReplaceInfo THEN BEGIN
                        Description := GLAcc.Name;
                      END;
                      IF ("Bal. Account No." = '') OR
                         ("Bal. Account Type" IN
                          ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account"])
                      THEN BEGIN
                        "Posting Group" := '';
                        "Salespers./Purch. Code" := '';
                        "Payment Terms Code" := '';
                      END;
                      IF "Bal. Account No." = '' THEN
                        "Currency Code" := '';
                      IF NOT GenJnlBatch.GET("Journal Template Name","Journal Batch Name") OR
                         GenJnlBatch."Copy VAT Setup to Jnl. Lines"
                      THEN BEGIN
                        "Gen. Posting Type" := GLAcc."Gen. Posting Type";
                        "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
                        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                        "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                      END;
                      "Tax Area Code" := GLAcc."Tax Area Code";
                      "Tax Liable" := GLAcc."Tax Liable";
                      "Tax Group Code" := GLAcc."Tax Group Code";
                      IF "Posting Date" <> 0D THEN
                        IF "Posting Date" = CLOSINGDATE("Posting Date") THEN BEGIN
                          "Gen. Posting Type" := 0;
                          "Gen. Bus. Posting Group" := '';
                          "Gen. Prod. Posting Group" := '';
                          "VAT Bus. Posting Group" := '';
                          "VAT Prod. Posting Group" := '';
                        END;
                      //APNT-FIN1.1 -
                      IF ("Bal. Account No." = '') OR
                         ("Bal. Account Type" IN
                          ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account","Bal. Account Type"::"Fixed Asset"]) THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Account Type"::Customer:
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Acc. Receivables",FALSE);
                      END;
                      //APNT-CP1.0
                      Cust.GET("Account No.");
                      Cust.CheckBlockedCustOnJnls(Cust,"Document Type", FALSE);
                      IF (Cust."IC Partner Code" <> '') THEN BEGIN
                        IF GenJnlTemplate.GET("Journal Template Name") THEN;
                        IF (Cust."IC Partner Code" <> '' ) AND (ICPartner.GET(Cust."IC Partner Code")) THEN BEGIN
                          ICPartner.CheckICPartnerIndirect(FORMAT("Account Type"),"Account No.");
                          "IC Partner Code" := Cust."IC Partner Code";
                        END;
                      END;
                      Description := Cust.Name;
                      "Posting Group" := Cust."Customer Posting Group";
                      "Salespers./Purch. Code" := Cust."Salesperson Code";
                      "Payment Terms Code" := Cust."Payment Terms Code";
                      VALIDATE("Bill-to/Pay-to No.","Account No.");
                      VALIDATE("Sell-to/Buy-from No.", "Account No.");
                      IF SetCurrencyCode("Bal. Account Type","Bal. Account No.") THEN
                        Cust.TESTFIELD("Currency Code","Currency Code")
                      ELSE
                        "Currency Code" := Cust."Currency Code";
                      "Gen. Posting Type" := 0;
                      "Gen. Bus. Posting Group" := '';
                      "Gen. Prod. Posting Group" := '';
                      "VAT Bus. Posting Group" := '';
                      "VAT Prod. Posting Group" := '';
                      IF (Cust."Bill-to Customer No." <> '') AND (Cust."Bill-to Customer No." <> "Account No.") THEN BEGIN
                        OK := CONFIRM(Text014,FALSE,Cust.TABLECAPTION,Cust."No.",Cust.FIELDCAPTION("Bill-to Customer No."),
                        Cust."Bill-to Customer No.");
                        IF NOT OK THEN
                          ERROR('');
                      END;
                      VALIDATE("Payment Terms Code");
                    END;
                  "Account Type"::Vendor:
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Acc. Payable",FALSE);
                      END;
                      //APNT-CP1.0
                      Vend.GET("Account No.");
                      Vend.CheckBlockedVendOnJnls(Vend,"Document Type",FALSE);
                      //T044145 -
                      CompanyInformation.GET();
                      IF CompanyInformation."Enable Vendor Approval Process" THEN
                        Vend.CheckVendorStatus(Vend,FALSE);
                      //T044145 +
                      IF (Vend."IC Partner Code" <> '') THEN BEGIN
                        IF GenJnlTemplate.GET("Journal Template Name") THEN;
                        IF (Vend."IC Partner Code" <> '') AND (ICPartner.GET(Vend."IC Partner Code")) THEN BEGIN
                          ICPartner.CheckICPartnerIndirect(FORMAT("Account Type"),"Account No.");
                          "IC Partner Code" := Vend."IC Partner Code";
                        END;
                      END;
                      Description := Vend.Name;
                      "Posting Group" := Vend."Vendor Posting Group";
                      "Salespers./Purch. Code" := Vend."Purchaser Code";
                      "Payment Terms Code" := Vend."Payment Terms Code";
                      VALIDATE("Bill-to/Pay-to No.","Account No.");
                      VALIDATE("Sell-to/Buy-from No.","Account No.");
                      IF SetCurrencyCode("Bal. Account Type","Bal. Account No.") THEN
                        Vend.TESTFIELD("Currency Code","Currency Code")
                      ELSE
                        "Currency Code" := Vend."Currency Code";
                      "Gen. Posting Type" := 0;
                      "Gen. Bus. Posting Group" := '';
                      "Gen. Prod. Posting Group" := '';
                      "VAT Bus. Posting Group" := '';
                      "VAT Prod. Posting Group" := '';
                      IF (Vend."Pay-to Vendor No." <> '') AND (Vend."Pay-to Vendor No." <> "Account No.")  THEN BEGIN
                        OK := CONFIRM(Text014,FALSE,Vend.TABLECAPTION,Vend."No.",Vend.FIELDCAPTION("Pay-to Vendor No."),
                        Vend."Pay-to Vendor No.");
                        IF NOT OK THEN
                          ERROR('');
                      END;
                      VALIDATE("Payment Terms Code");
                   END;
                  "Account Type"::"Bank Account":
                    BEGIN
                      BankAcc.GET("Account No.");
                      BankAcc.TESTFIELD(Blocked,FALSE);
                      ReplaceInfo := "Bal. Account No." = '';
                      IF NOT ReplaceInfo THEN BEGIN
                        GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
                        ReplaceInfo := GenJnlBatch."Bal. Account No." <> '';
                      END;
                      IF ReplaceInfo THEN BEGIN
                        Description := BankAcc.Name;
                      END;
                      IF ("Bal. Account No." = '') OR
                         ("Bal. Account Type" IN
                          ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account"])
                      THEN BEGIN
                        "Posting Group" := '';
                        "Salespers./Purch. Code" := '';
                        "Payment Terms Code" := '';
                      END;
                      IF BankAcc."Currency Code" = '' THEN BEGIN
                        IF "Bal. Account No." = '' THEN
                          "Currency Code" := '';
                      END ELSE
                        IF SetCurrencyCode("Bal. Account Type","Bal. Account No.") THEN
                          BankAcc.TESTFIELD("Currency Code","Currency Code")
                        ELSE
                          "Currency Code" := BankAcc."Currency Code";
                      "Gen. Posting Type" := 0;
                      "Gen. Bus. Posting Group" := '';
                      "Gen. Prod. Posting Group" := '';
                      "VAT Bus. Posting Group" := '';
                      "VAT Prod. Posting Group" := '';
                      //APNT-FIN1.1 -
                      IF ("Bal. Account No." = '') OR
                         ("Bal. Account Type" IN
                          ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account","Bal. Account Type"::"Fixed Asset"]) THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Account Type"::"Fixed Asset":
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Fixed Assets",FALSE);
                      END;
                      //APNT-CP1.0
                      FA.GET("Account No.");
                      FA.TESTFIELD(FA.Blocked,FALSE);
                      FA.TESTFIELD(FA.Inactive,FALSE);
                      FA.TESTFIELD(FA."Budgeted Asset",FALSE);
                      Description := FA.Description;
                      IF "Depreciation Book Code" = '' THEN BEGIN
                        FASetup.GET;
                        "Depreciation Book Code" := FASetup."Default Depr. Book";
                        IF NOT FADeprBook.GET("Account No.","Depreciation Book Code") THEN
                          "Depreciation Book Code" := '';
                      END;
                      IF "Depreciation Book Code" <> '' THEN BEGIN
                        FADeprBook.GET("Account No.","Depreciation Book Code");
                        "Posting Group" := FADeprBook."FA Posting Group";
                      END;
                      GetFAVATSetup;
                      GetFAAddCurrExchRate;
                      //APNT-FIN1.1 -
                      IF ("Bal. Account No." = '') OR
                         ("Bal. Account Type" IN
                          ["Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account","Bal. Account Type"::"Fixed Asset"]) THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Account Type"::"IC Partner":
                    BEGIN
                      ICPartner.GET("Account No.");
                      ICPartner.CheckICPartner;
                      Description := ICPartner.Name;
                      IF ("Bal. Account No." = '') OR ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") THEN
                        "Currency Code" := ICPartner."Currency Code";
                      IF ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") AND ("Currency Code" = '') THEN
                        "Currency Code" := ICPartner."Currency Code";
                      "Gen. Posting Type" := 0;
                      "Gen. Bus. Posting Group" := '';
                      "Gen. Prod. Posting Group" := '';
                      "VAT Bus. Posting Group" := '';
                      "VAT Prod. Posting Group" := '';
                      "IC Partner Code" := "Account No.";
                    END;
                  //APNT-HR1.0
                  "Account Type"::Employee:
                    BEGIN
                      Employee.GET("Account No.");
                      Employee.TESTFIELD(Status,Employee.Status::Active);
                      Employee.TESTFIELD("Employee Posting Group");
                      Description := Employee."First Name";
                      "Posting Group" := Employee."Employee Posting Group";
                      VALIDATE("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
                      VALIDATE("Shortcut Dimension 2 Code", Employee."Global Dimension 2 Code");
                      "Gen. Bus. Posting Group" := '';
                      "Gen. Prod. Posting Group" := '';
                      "VAT Bus. Posting Group" := '';
                      "VAT Prod. Posting Group" := '';
                      "Employee No." :="Account No.";
                    END;
                  //APNT-HR1.0
                END;

                VALIDATE("Currency Code");
                VALIDATE("VAT Prod. Posting Group");
                UpdateLineBalance;
                UpdateSource;
                CreateDim(
                  DimMgt.TypeToTableID1("Account Type"),"Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                  DATABASE::Campaign,"Campaign No.");
            end;
        }
        field(5;"Posting Date";Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                VALIDATE("Document Date","Posting Date");
                VALIDATE("Currency Code");

                IF ((Rec."Posting Date" <> xRec."Posting Date") AND (Amount <> 0))  THEN
                  PaymentToleranceMgt.PmtTolGenJnl(Rec);

                ValidateApplyRequirements(Rec);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(6;"Document Type";Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;

            trigger OnValidate()
            begin
                VALIDATE("Payment Terms Code");
                IF "Account No." <> '' THEN
                  CASE "Account Type" OF
                    "Account Type"::Customer:
                       BEGIN
                         Cust.GET("Account No.");
                         Cust.CheckBlockedCustOnJnls(Cust,"Document Type",FALSE);
                       END;
                    "Account Type"::Vendor:
                       BEGIN
                         Vend.GET("Account No.");
                         Vend.CheckBlockedVendOnJnls(Vend,"Document Type",FALSE);
                        //T044145 -
                        CompanyInformation.GET();
                        IF CompanyInformation."Enable Vendor Approval Process" THEN
                          Vend.CheckVendorStatus(Vend,FALSE);
                        //T044145 +
                       END;
                  END;
                IF "Bal. Account No." <> '' THEN
                  CASE "Bal. Account Type" OF
                    "Account Type"::Customer:
                      BEGIN
                        Cust.GET("Bal. Account No.");
                        Cust.CheckBlockedCustOnJnls(Cust,"Document Type",FALSE);
                      END;
                    "Account Type"::Vendor:
                      BEGIN
                        Vend.GET("Bal. Account No.");
                        Vend.CheckBlockedVendOnJnls(Vend,"Document Type",FALSE);
                      END;
                  END;
                UpdateSalesPurchLCY;
                ValidateApplyRequirements(Rec);
            end;
        }
        field(7;"Document No.";Code[20])
        {
            Caption = 'Document No.';
        }
        field(8;Description;Text[50])
        {
            Caption = 'Description';
        }
        field(10;"VAT %";Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0:5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency;
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "VAT Amount" :=
                        ROUND(Amount * "VAT %" / (100 + "VAT %"),Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "VAT Base Amount" :=
                        ROUND(Amount - "VAT Amount",Currency."Amount Rounding Precision");
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    "VAT Amount" := Amount;
                  "VAT Calculation Type"::"Sales Tax":
                    IF ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) AND
                       "Use Tax"
                    THEN BEGIN
                      "VAT Amount" := 0;
                      "VAT %" := 0;
                    END ELSE BEGIN
                      "VAT Amount" :=
                        Amount -
                        SalesTaxCalculate.ReverseCalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable",
                          "Posting Date",Amount,Quantity,"Currency Factor");
                      IF Amount - "VAT Amount" <> 0 THEN
                        "VAT %" := ROUND(100 * "VAT Amount" / (Amount - "VAT Amount"),0.00001)
                      ELSE
                        "VAT %" := 0;
                      "VAT Amount" :=
                        ROUND("VAT Amount",Currency."Amount Rounding Precision");
                    END;
                END;
                "VAT Base Amount" := Amount - "VAT Amount";
                "VAT Difference" := 0;

                IF "Currency Code" = '' THEN
                  "VAT Amount (LCY)" := "VAT Amount"
                ELSE
                  "VAT Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        "Posting Date","Currency Code",
                        "VAT Amount","Currency Factor"));
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";

                UpdateSalesPurchLCY;
            end;
        }
        field(11;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Bal. Account Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Bal. Account Type=CONST(IC Partner)) "IC Partner";

            trigger OnValidate()
            var
                AccountingPeriods: Record "50";
                StartDate: Date;
            begin
                VALIDATE("Job No.",'');
                IF "Bal. Account No." = '' THEN BEGIN
                  UpdateLineBalance;
                  UpdateSource;
                  //APNT-HR1.0
                  IF Employee.GET("Employee No.") THEN BEGIN
                    VALIDATE("Shortcut Dimension 1 Code",Employee."Global Dimension 1 Code");
                    VALIDATE("Shortcut Dimension 2 Code",Employee."Global Dimension 2 Code");
                  END ELSE //APNT-HR1.0
                    CreateDim(
                      DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                      DimMgt.TypeToTableID1("Account Type"),"Account No.",
                      DATABASE::Job,"Job No.",
                      DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                      DATABASE::Campaign,"Campaign No.");
                  IF xRec."Bal. Account No." <> '' THEN BEGIN
                    "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
                    "Bal. Gen. Bus. Posting Group" := '';
                    "Bal. Gen. Prod. Posting Group" := '';
                    "Bal. VAT Bus. Posting Group" := '';
                    "Bal. VAT Prod. Posting Group" := '';
                    "Bal. Tax Area Code" := '';
                    "Bal. Tax Liable" := FALSE;
                    "Bal. Tax Group Code" := '';
                  END;
                  //APNT-FIN1.1 -
                  IF ("Account No." = '') OR
                     ("Account Type" IN
                      ["Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"])
                  THEN
                    "IC Partner Code" := '';
                  //APNT-FIN1.1 +
                  EXIT;
                END;
                IF xRec."Bal. Account Type" IN [xRec."Bal. Account Type"::Customer, xRec."Bal. Account Type"::Vendor,
                   xRec."Bal. Account Type"::"IC Partner"]
                THEN
                  "IC Partner Code" := '';

                CASE "Bal. Account Type" OF
                  "Bal. Account Type"::"G/L Account":
                    BEGIN
                      GLAcc.GET("Bal. Account No.");
                      CheckGLAcc;
                      IF "Account No." = '' THEN BEGIN
                        Description := GLAcc.Name;
                        "Currency Code" := '';
                      END;
                      IF ("Account No." = '') OR
                         ("Account Type" IN
                          ["Account Type"::"G/L Account","Account Type"::"Bank Account"])
                      THEN BEGIN
                        "Posting Group" := '';
                        "Salespers./Purch. Code" := '';
                        "Payment Terms Code" := '';
                      END;
                      IF NOT GenJnlBatch.GET("Journal Template Name","Journal Batch Name") OR
                         GenJnlBatch."Copy VAT Setup to Jnl. Lines"
                      THEN BEGIN
                        "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
                        "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
                        "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                        "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                        "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                      END;
                      "Bal. Tax Area Code" := GLAcc."Tax Area Code";
                      "Bal. Tax Liable" := GLAcc."Tax Liable";
                      "Bal. Tax Group Code" := GLAcc."Tax Group Code";
                      IF "Posting Date" <> 0D THEN
                        IF "Posting Date" = CLOSINGDATE("Posting Date") THEN BEGIN
                          "Bal. Gen. Bus. Posting Group" := '';
                          "Bal. Gen. Prod. Posting Group" := '';
                          "Bal. VAT Bus. Posting Group" := '';
                          "Bal. VAT Prod. Posting Group" := '';
                          "Bal. Gen. Posting Type" := 0;
                        END;
                      //APNT-FIN1.1 -
                      IF ("Account No." = '') OR
                         ("Account Type" IN
                          ["Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"])
                      THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Bal. Account Type"::Customer:
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Acc. Receivables",FALSE);
                      END;
                      //APNT-CP1.0
                      Cust.GET("Bal. Account No.");
                      Cust.CheckBlockedCustOnJnls(Cust,"Document Type",FALSE);
                      IF (Cust."IC Partner Code" <> '') THEN BEGIN
                        IF GenJnlTemplate.GET("Journal Template Name") THEN;
                        IF (Cust."IC Partner Code" <> '') AND (ICPartner.GET(Cust."IC Partner Code")) THEN BEGIN
                          ICPartner.CheckICPartnerIndirect(FORMAT("Bal. Account Type"),"Bal. Account No.");
                          "IC Partner Code" := Cust."IC Partner Code";
                        END;
                      END;

                      IF "Account No." = '' THEN BEGIN
                        Description := Cust.Name;
                      END;
                      "Posting Group" := Cust."Customer Posting Group";
                      "Salespers./Purch. Code" := Cust."Salesperson Code";
                      "Payment Terms Code" := Cust."Payment Terms Code";
                      VALIDATE("Bill-to/Pay-to No.","Bal. Account No.");
                      VALIDATE("Sell-to/Buy-from No.","Bal. Account No.");
                      IF ("Account No." = '') OR ("Account Type" = "Account Type"::"G/L Account") THEN
                        "Currency Code" := Cust."Currency Code";
                      IF ("Account Type" = "Account Type"::"Bank Account") AND ("Currency Code" = '') THEN
                        "Currency Code" := Cust."Currency Code";
                      "Bal. Gen. Posting Type" := 0;
                      "Bal. Gen. Bus. Posting Group" := '';
                      "Bal. Gen. Prod. Posting Group" := '';
                      "Bal. VAT Bus. Posting Group" := '';
                      "Bal. VAT Prod. Posting Group" := '';
                      IF (Cust."Bill-to Customer No." <> '') AND (Cust."Bill-to Customer No." <> "Bal. Account No.") THEN BEGIN
                        OK := CONFIRM(Text014,FALSE,Cust.TABLECAPTION,Cust."No.",Cust.FIELDCAPTION("Bill-to Customer No."),
                        Cust."Bill-to Customer No.");
                        IF NOT OK THEN
                          ERROR('');
                      END;
                      VALIDATE("Payment Terms Code");
                    END;
                  "Bal. Account Type"::Vendor:
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Acc. Payable",FALSE);
                      END;
                      //APNT-CP1.0
                     Vend.GET("Bal. Account No.");
                     Vend.CheckBlockedVendOnJnls(Vend,"Document Type",FALSE);
                     IF (Vend."IC Partner Code" <> '') THEN BEGIN
                       IF GenJnlTemplate.GET("Journal Template Name") THEN;
                       IF (Vend."IC Partner Code" <> '') AND (ICPartner.GET(Vend."IC Partner Code")) THEN BEGIN
                         ICPartner.CheckICPartnerIndirect(FORMAT("Bal. Account Type"),"Bal. Account No.");
                         "IC Partner Code" := Vend."IC Partner Code";
                       END;
                     END;

                     IF "Account No." = '' THEN BEGIN
                       Description := Vend.Name;
                     END;
                     "Posting Group" := Vend."Vendor Posting Group";
                     "Salespers./Purch. Code" := Vend."Purchaser Code";
                     "Payment Terms Code" := Vend."Payment Terms Code";
                     VALIDATE("Bill-to/Pay-to No.","Bal. Account No.");
                     VALIDATE("Sell-to/Buy-from No.","Bal. Account No.");
                     IF ("Account No." = '') OR ("Account Type" = "Account Type"::"G/L Account") THEN
                       "Currency Code" := Vend."Currency Code";
                     IF ("Account Type" = "Account Type"::"Bank Account") AND ("Currency Code" = '') THEN
                       "Currency Code" := Vend."Currency Code";
                     "Bal. Gen. Posting Type" := 0;
                     "Bal. Gen. Bus. Posting Group" := '';
                     "Bal. Gen. Prod. Posting Group" := '';
                     "Bal. VAT Bus. Posting Group" := '';
                     "Bal. VAT Prod. Posting Group" := '';
                     IF (Vend."Pay-to Vendor No." <> '') AND (Vend."Pay-to Vendor No." <> "Bal. Account No.")  THEN BEGIN
                       OK := CONFIRM(Text014,FALSE,Vend.TABLECAPTION,Vend."No.",Vend.FIELDCAPTION("Pay-to Vendor No."),
                       Vend."Pay-to Vendor No.");
                       IF NOT OK THEN
                         ERROR('');
                     END;
                     VALIDATE("Payment Terms Code");
                    END;
                  "Bal. Account Type"::"Bank Account":
                    BEGIN
                      BankAcc.GET("Bal. Account No.");
                      BankAcc.TESTFIELD(Blocked,FALSE);
                      IF "Account No." = '' THEN BEGIN
                        Description := BankAcc.Name;
                      END;
                      IF ("Account No." = '') OR
                         ("Account Type" IN
                          ["Account Type"::"G/L Account","Account Type"::"Bank Account"])
                      THEN BEGIN
                        "Posting Group" := '';
                        "Salespers./Purch. Code" := '';
                        "Payment Terms Code" := '';
                      END;
                      IF BankAcc."Currency Code" = '' THEN BEGIN
                        IF "Account No." = '' THEN
                          "Currency Code" := '';
                      END ELSE
                        IF SetCurrencyCode("Bal. Account Type","Bal. Account No.") THEN
                          BankAcc.TESTFIELD("Currency Code","Currency Code")
                        ELSE
                          "Currency Code" := BankAcc."Currency Code";
                      "Bal. Gen. Posting Type" := 0;
                      "Bal. Gen. Bus. Posting Group" := '';
                      "Bal. Gen. Prod. Posting Group" := '';
                      "Bal. VAT Bus. Posting Group" := '';
                      "Bal. VAT Prod. Posting Group" := '';
                      //APNT-FIN1.1 -
                      IF ("Account No." = '') OR
                         ("Account Type" IN
                          ["Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"])
                      THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Bal. Account Type"::"Fixed Asset":
                    BEGIN
                      //APNT-CP1.0
                      IF "Posting Date" <> 0D THEN BEGIN
                        StartDate := CALCDATE('-CM',"Posting Date");
                        AccountingPeriods.GET(StartDate);
                        AccountingPeriods.TESTFIELD("Closed Fixed Assets",FALSE);
                      END;
                      //APNT-CP1.0
                      FA.GET("Bal. Account No.");
                      FA.TESTFIELD(FA.Blocked,FALSE);
                      FA.TESTFIELD(FA.Inactive,FALSE);
                      FA.TESTFIELD(FA."Budgeted Asset",FALSE);
                      IF "Account No." = '' THEN BEGIN
                        Description := FA.Description;
                      END;
                      IF "Depreciation Book Code" = '' THEN BEGIN
                        FASetup.GET;
                        "Depreciation Book Code" := FASetup."Default Depr. Book";
                        IF NOT FADeprBook.GET("Bal. Account No.","Depreciation Book Code") THEN
                          "Depreciation Book Code" := '';
                      END;
                      IF "Depreciation Book Code" <> '' THEN BEGIN
                        FADeprBook.GET("Bal. Account No.","Depreciation Book Code");
                        "Posting Group" := FADeprBook."FA Posting Group";
                      END;
                      GetFAVATSetup;
                      GetFAAddCurrExchRate;
                      //APNT-FIN1.1 -
                      IF ("Account No." = '') OR
                         ("Account Type" IN
                          ["Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"])
                      THEN
                        "IC Partner Code" := '';
                      //APNT-FIN1.1 +
                    END;
                  "Bal. Account Type"::"IC Partner":
                    BEGIN
                      ICPartner.GET("Bal. Account No.");
                      IF "Account No." = '' THEN BEGIN
                        Description := ICPartner.Name;
                      END;
                      IF ("Account No." = '') OR ("Account Type" = "Account Type"::"G/L Account") THEN
                        "Currency Code" := ICPartner."Currency Code";
                      IF ("Account Type" = "Account Type"::"Bank Account") AND ("Currency Code" = '') THEN
                        "Currency Code" := ICPartner."Currency Code";
                      "Bal. Gen. Posting Type" := 0;
                      "Bal. Gen. Bus. Posting Group" := '';
                      "Bal. Gen. Prod. Posting Group" := '';
                      "Bal. VAT Bus. Posting Group" := '';
                      "Bal. VAT Prod. Posting Group" := '';
                      "IC Partner Code" := "Bal. Account No.";
                    END;

                END;

                VALIDATE("Currency Code");
                VALIDATE("Bal. VAT Prod. Posting Group");
                UpdateLineBalance;
                UpdateSource;
                //APNT-HR1.0
                IF Employee.GET("Employee No.") THEN BEGIN
                  VALIDATE("Shortcut Dimension 1 Code",Employee."Global Dimension 1 Code");
                  VALIDATE("Shortcut Dimension 2 Code",Employee."Global Dimension 2 Code");
                END ELSE//APNT-HR1.0
                  CreateDim(
                    DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                    DimMgt.TypeToTableID1("Account Type"),"Account No.",
                    DATABASE::Job,"Job No.",
                    DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                    DATABASE::Campaign,"Campaign No.");

                IF ("Account Type" = "Account Type"::"IC Partner") AND
                   ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")
                THEN
                  "IC Partner G/L Acc. No." := GLAcc."Default IC Partner G/L Acc. No";
            end;
        }
        field(12;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                IF "Bal. Account Type" = "Bal. Account Type"::"Bank Account" THEN BEGIN
                  IF BankAcc3.GET("Bal. Account No.") AND (BankAcc3."Currency Code" <> '')THEN
                    BankAcc3.TESTFIELD("Currency Code","Currency Code");
                END;
                IF "Account Type" = "Account Type"::"Bank Account" THEN BEGIN
                  IF BankAcc3.GET("Account No.") AND (BankAcc3."Currency Code" <> '') THEN
                    BankAcc3.TESTFIELD("Currency Code","Currency Code");
                END;
                IF ("Recurring Method" IN
                    ["Recurring Method"::"B  Balance","Recurring Method"::"RB Reversing Balance"]) AND
                   ("Currency Code" <> '')
                THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Currency Code"),FIELDCAPTION("Recurring Method"),"Recurring Method");

                IF "Currency Code" <> '' THEN BEGIN
                  GetCurrency;
                  IF ("Currency Code" <> xRec."Currency Code") OR
                     ("Posting Date" <> xRec."Posting Date") OR
                     (CurrFieldNo = FIELDNO("Currency Code")) OR
                     ("Currency Factor" = 0)
                  THEN
                    "Currency Factor" :=
                      CurrExchRate.ExchangeRate("Posting Date","Currency Code");
                END ELSE
                  "Currency Factor" := 0;
                VALIDATE("Currency Factor");

                IF (("Currency Code" <> xRec."Currency Code") AND (Amount <> 0)) THEN
                  PaymentToleranceMgt.PmtTolGenJnl(Rec);
            end;
        }
        field(13;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                IF "Currency Code" = '' THEN
                  "Amount (LCY)" := Amount
                ELSE
                  "Amount (LCY)" := ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date","Currency Code",
                      Amount,"Currency Factor"));

                Amount := ROUND(Amount,Currency."Amount Rounding Precision");
                IF (CurrFieldNo <> 0) AND
                   (CurrFieldNo <> FIELDNO("Applies-to Doc. No.")) AND
                   ((("Account Type" = "Account Type"::Customer) AND
                     ("Account No." <> '') AND (Amount > 0) AND
                     (CurrFieldNo <> FIELDNO("Bal. Account No."))) OR
                    (("Bal. Account Type" = "Bal. Account Type"::Customer) AND
                     ("Bal. Account No." <> '') AND (Amount < 0) AND
                     (CurrFieldNo <> FIELDNO("Account No."))))
                THEN
                  CustCheckCreditLimit.GenJnlLineCheck(Rec);

                VALIDATE("VAT %");
                VALIDATE("Bal. VAT %");
                UpdateLineBalance;

                IF ((Rec.Amount <> xRec.Amount))  THEN BEGIN
                  IF ("Applies-to Doc. No." <> '') OR ("Applies-to ID" <> '') THEN
                    SetApplyToAmount;
                  PaymentToleranceMgt.PmtTolGenJnl(Rec);
                END;

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(14;"Debit Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Debit Amount" := ROUND("Debit Amount",Currency."Amount Rounding Precision");
                Correction := "Debit Amount" < 0;
                Amount := "Debit Amount";
                VALIDATE(Amount);
            end;
        }
        field(15;"Credit Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Credit Amount" := ROUND("Credit Amount",Currency."Amount Rounding Precision");
                Correction := "Credit Amount" < 0;
                Amount := -"Credit Amount";
                VALIDATE(Amount);
            end;
        }
        field(16;"Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                IF "Currency Code" = '' THEN BEGIN
                  Amount := "Amount (LCY)";
                  VALIDATE(Amount);
                END ELSE BEGIN
                  IF CheckFixedCurrency THEN BEGIN
                    GetCurrency;
                    Amount := ROUND(
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date","Currency Code",
                        "Amount (LCY)","Currency Factor"),
                        Currency."Amount Rounding Precision")
                  END ELSE BEGIN
                    TESTFIELD("Amount (LCY)");
                    TESTFIELD(Amount);
                    "Currency Factor" := Amount / "Amount (LCY)";
                  END;

                  VALIDATE("VAT %");
                  VALIDATE("Bal. VAT %");
                  UpdateLineBalance;
                END;
            end;
        }
        field(17;"Balance (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        field(18;"Currency Factor";Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0:15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                IF ("Currency Code" = '') AND ("Currency Factor" <> 0) THEN
                  FIELDERROR("Currency Factor",STRSUBSTNO(Text002,FIELDCAPTION("Currency Code")));
                VALIDATE(Amount);
            end;
        }
        field(19;"Sales/Purch. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        field(20;"Profit (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(21;"Inv. Discount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(22;"Bill-to/Pay-to No.";Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = IF (Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor;

            trigger OnValidate()
            begin
                IF Rec."Bill-to/Pay-to No." <> xRec."Bill-to/Pay-to No." THEN
                  "Ship-to/Order Address Code" := '';
                GLSetup.GET;
                IF GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." THEN
                  UpdateCountryCodeAndVATRegNo("Bill-to/Pay-to No.");
            end;
        }
        field(23;"Posting Group";Code[10])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Account Type=CONST(Customer)) "Customer Posting Group"
                            ELSE IF (Account Type=CONST(Vendor)) "Vendor Posting Group"
                            ELSE IF (Account Type=CONST(Fixed Asset)) "FA Posting Group";
        }
        field(24;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(25;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(26;"Salespers./Purch. Code";Code[10])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                  DimMgt.TypeToTableID1("Account Type"),"Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::Campaign,"Campaign No.");
            end;
        }
        field(29;"Source Code";Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(30;"System-Created Entry";Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(34;"On Hold";Code[3])
        {
            Caption = 'On Hold';
        }
        field(35;"Applies-to Doc. Type";Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(36;"Applies-to Doc. No.";Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                GenJnlPostLine: Codeunit "12";
                PaymentToleranceMgt: Codeunit "426";
                OldAppliesToDocNo: Code[20];
            begin
                IF xRec."Line No." = 0 THEN
                  xRec.Amount := Amount;

                OldAppliesToDocNo := "Applies-to Doc. No.";
                "Applies-to Doc. No." := '';

                IF "Bal. Account Type" IN
                  ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]
                THEN BEGIN
                  AccNo := "Bal. Account No.";
                  AccType := "Bal. Account Type";
                  CLEAR(CustLedgEntry);
                  CLEAR(VendLedgEntry);
                END ELSE BEGIN
                  AccNo := "Account No.";
                  AccType := "Account Type";
                  CLEAR(CustLedgEntry);
                  CLEAR(VendLedgEntry);
                END;

                xRec."Currency Code" := "Currency Code";
                xRec."Posting Date" := "Posting Date";

                CASE AccType OF
                  AccType::Customer:
                    BEGIN
                      CustLedgEntry.SETCURRENTKEY("Customer No.",Open,Positive,"Due Date");
                      CustLedgEntry.SETRANGE("Customer No.",AccNo);
                      CustLedgEntry.SETRANGE(Open,TRUE);
                      IF "Applies-to Doc. No." <> '' THEN BEGIN
                        CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                        CustLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                        IF NOT CustLedgEntry.FIND('-') THEN BEGIN
                          CustLedgEntry.SETRANGE("Document Type");
                          CustLedgEntry.SETRANGE("Document No.");
                        END;
                      END;
                      IF "Applies-to ID" <> '' THEN BEGIN
                        CustLedgEntry.SETRANGE("Applies-to ID","Applies-to ID");
                        IF NOT CustLedgEntry.FIND('-') THEN
                          CustLedgEntry.SETRANGE("Applies-to ID");
                      END;
                      IF "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " THEN BEGIN
                        CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                        IF NOT CustLedgEntry.FIND('-') THEN
                          CustLedgEntry.SETRANGE("Document Type");
                      END;
                      IF  "Applies-to Doc. No." <>''THEN BEGIN
                        CustLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                        IF NOT CustLedgEntry.FIND('-') THEN
                          CustLedgEntry.SETRANGE("Document No.");
                      END;
                      IF Amount <> 0 THEN BEGIN
                        CustLedgEntry.SETRANGE(Positive,Amount < 0);
                        IF CustLedgEntry.FIND('-') THEN;
                        CustLedgEntry.SETRANGE(Positive);
                      END;
                      ApplyCustEntries.SetGenJnlLine(Rec,GenJnlLine.FIELDNO("Applies-to Doc. No."));
                      ApplyCustEntries.SETTABLEVIEW(CustLedgEntry);
                      ApplyCustEntries.SETRECORD(CustLedgEntry);
                      ApplyCustEntries.LOOKUPMODE(TRUE);
                      IF ApplyCustEntries.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ApplyCustEntries.GETRECORD(CustLedgEntry);
                        CLEAR(ApplyCustEntries);
                        IF "Currency Code" <> CustLedgEntry."Currency Code" THEN
                          IF Amount = 0 THEN BEGIN
                            FromCurrencyCode := GetShowCurrencyCode("Currency Code");
                            ToCurrencyCode := GetShowCurrencyCode(CustLedgEntry."Currency Code");
                            IF NOT
                               CONFIRM(
                                 Text003 +
                                 Text004,TRUE,
                                 FIELDCAPTION("Currency Code"),TABLECAPTION,FromCurrencyCode,
                                 ToCurrencyCode)
                            THEN
                              ERROR(Text005);
                            VALIDATE("Currency Code",CustLedgEntry."Currency Code");
                          END ELSE
                            GenJnlApply.CheckAgainstApplnCurrency(
                              "Currency Code",CustLedgEntry."Currency Code",
                              GenJnlLine."Account Type"::Customer,TRUE);
                        IF Amount = 0 THEN BEGIN
                          CustLedgEntry.CALCFIELDS("Remaining Amount");
                          IF CustLedgEntry."Amount to Apply" <> 0 THEN BEGIN
                            IF GenJnlPostLine.CheckCalcPmtDiscGenJnlCust(Rec,CustLedgEntry,0,FALSE)
                            THEN BEGIN
                              IF ABS(CustLedgEntry."Amount to Apply") >=
                                ABS(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible")
                              THEN
                                Amount := -(CustLedgEntry."Remaining Amount" -
                                  CustLedgEntry."Remaining Pmt. Disc. Possible")
                              ELSE
                                Amount := -CustLedgEntry."Amount to Apply";
                            END ELSE
                              Amount := -CustLedgEntry."Amount to Apply";
                          END ELSE BEGIN
                          IF GenJnlPostLine.CheckCalcPmtDiscGenJnlCust(Rec,CustLedgEntry,0,FALSE)
                          THEN
                            Amount := -(CustLedgEntry."Remaining Amount" -
                              CustLedgEntry."Remaining Pmt. Disc. Possible")
                          ELSE
                            Amount := -CustLedgEntry."Remaining Amount";
                          END;
                          IF "Bal. Account Type" IN
                            ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]
                          THEN
                            Amount := -Amount;
                          VALIDATE(Amount);
                        END;
                        "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                        "Applies-to Doc. No." := CustLedgEntry."Document No.";
                        "Applies-to ID" := '';
                      END ELSE BEGIN
                        "Applies-to Doc. No." := OldAppliesToDocNo;
                        CLEAR(ApplyCustEntries);
                      END;
                    END;
                  AccType::Vendor:
                    BEGIN
                      VendLedgEntry.SETCURRENTKEY("Vendor No.",Open,Positive,"Due Date");
                      VendLedgEntry.SETRANGE("Vendor No.",AccNo);
                      VendLedgEntry.SETRANGE(Open,TRUE);
                      IF "Applies-to Doc. No." <> '' THEN BEGIN
                        VendLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                        VendLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                        IF NOT VendLedgEntry.FIND('-') THEN BEGIN
                          VendLedgEntry.SETRANGE("Document Type");
                          VendLedgEntry.SETRANGE("Document No.");
                        END;
                      END;
                      IF "Applies-to ID" <> '' THEN BEGIN
                        VendLedgEntry.SETRANGE("Applies-to ID","Applies-to ID");
                        IF NOT VendLedgEntry.FIND('-') THEN
                          VendLedgEntry.SETRANGE("Applies-to ID");
                      END;
                      IF "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " THEN BEGIN
                        VendLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                        IF NOT VendLedgEntry.FIND('-') THEN
                          VendLedgEntry.SETRANGE("Document Type");
                      END;
                      IF  "Applies-to Doc. No." <>''THEN BEGIN
                        VendLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                        IF NOT VendLedgEntry.FIND('-') THEN
                          VendLedgEntry.SETRANGE("Document No.");
                      END;
                      IF Amount <> 0 THEN BEGIN
                        VendLedgEntry.SETRANGE(Positive,Amount < 0);
                        IF VendLedgEntry.FIND('-') THEN;
                        VendLedgEntry.SETRANGE(Positive);
                      END;
                      ApplyVendEntries.SetGenJnlLine(Rec,GenJnlLine.FIELDNO("Applies-to Doc. No."));
                      ApplyVendEntries.SETTABLEVIEW(VendLedgEntry);
                      ApplyVendEntries.SETRECORD(VendLedgEntry);
                      ApplyVendEntries.LOOKUPMODE(TRUE);
                      IF ApplyVendEntries.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ApplyVendEntries.GETRECORD(VendLedgEntry);
                        CLEAR(ApplyVendEntries);
                        IF "Currency Code" <> VendLedgEntry."Currency Code" THEN
                          IF Amount = 0 THEN BEGIN
                            FromCurrencyCode := GetShowCurrencyCode("Currency Code");
                            ToCurrencyCode := GetShowCurrencyCode(VendLedgEntry."Currency Code");
                            IF NOT
                               CONFIRM(
                                 Text003 +
                                 Text004,TRUE,
                                 FIELDCAPTION("Currency Code"),TABLECAPTION,FromCurrencyCode,
                                 ToCurrencyCode)
                            THEN
                              ERROR(Text005);
                            VALIDATE("Currency Code",VendLedgEntry."Currency Code");
                          END ELSE
                            GenJnlApply.CheckAgainstApplnCurrency(
                              "Currency Code",VendLedgEntry."Currency Code",GenJnlLine."Account Type"::Vendor,TRUE);
                        IF Amount = 0 THEN BEGIN
                          VendLedgEntry.CALCFIELDS("Remaining Amount");
                          IF VendLedgEntry."Amount to Apply" <> 0 THEN BEGIN
                            IF GenJnlPostLine.CheckCalcPmtDiscGenJnlVend(Rec,VendLedgEntry,0,FALSE)
                            THEN BEGIN
                              IF ABS(VendLedgEntry."Amount to Apply") >=
                                ABS(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible")
                              THEN
                                Amount := -(VendLedgEntry."Remaining Amount" -
                                  VendLedgEntry."Remaining Pmt. Disc. Possible")
                              ELSE
                                Amount := -VendLedgEntry."Amount to Apply";
                            END ELSE
                              Amount := -VendLedgEntry."Amount to Apply";
                          END ELSE BEGIN
                          IF GenJnlPostLine.CheckCalcPmtDiscGenJnlVend(Rec,VendLedgEntry,0,FALSE)
                          THEN
                            Amount := -(VendLedgEntry."Remaining Amount" -
                              VendLedgEntry."Remaining Pmt. Disc. Possible")
                          ELSE
                            Amount := -VendLedgEntry."Remaining Amount";
                          END;
                          IF "Bal. Account Type" IN
                            ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]
                          THEN
                            Amount := -Amount;
                          VALIDATE(Amount);
                        END;
                        "Applies-to Doc. Type" := VendLedgEntry."Document Type";
                        "Applies-to Doc. No." := VendLedgEntry."Document No.";
                        "Applies-to ID" := '';
                      END ELSE BEGIN
                        "Applies-to Doc. No." := OldAppliesToDocNo;
                        CLEAR(ApplyVendEntries);
                      END;
                    END;
                  ELSE
                    "Applies-to Doc. No." := OldAppliesToDocNo;
                END;

                IF (xRec.Amount <> 0) THEN
                  IF NOT PaymentToleranceMgt.PmtTolGenJnl(Rec) THEN
                    EXIT;
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "21";
                VendLedgEntry: Record "25";
                TempGenJnlLine: Record "81" temporary;
            begin
                IF ("Applies-to Doc. No." = '') AND (xRec."Applies-to Doc. No." <> '') THEN BEGIN
                  PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec,xRec."Applies-to Doc. No.");

                  TempGenJnlLine := Rec;
                  IF (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) OR
                    (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor)
                  THEN
                    CODEUNIT.RUN(CODEUNIT::"Exchange Acc. G/L Journal Line",TempGenJnlLine);

                  IF TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer THEN BEGIN
                    CustLedgEntry.SETCURRENTKEY("Document No.");
                    CustLedgEntry.SETRANGE("Document No.",xRec."Applies-to Doc. No.");
                    IF NOT(xRec."Applies-to Doc. Type" = "Document Type"::" ") THEN
                      CustLedgEntry.SETRANGE("Document Type",xRec."Applies-to Doc. Type");
                    CustLedgEntry.SETRANGE("Customer No.",TempGenJnlLine."Account No.");
                    CustLedgEntry.SETRANGE(Open,TRUE);
                    IF CustLedgEntry.FIND('-') THEN BEGIN
                      IF CustLedgEntry."Amount to Apply" <> 0 THEN  BEGIN
                        CustLedgEntry."Amount to Apply" := 0;
                        CODEUNIT.RUN(CODEUNIT::"Cust. Entry-Edit",CustLedgEntry);
                      END;
                    END;
                  END ELSE IF TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Vendor THEN BEGIN
                    VendLedgEntry.SETCURRENTKEY("Document No.");
                    VendLedgEntry.SETRANGE("Document No.",xRec."Applies-to Doc. No.");
                    IF NOT(xRec."Applies-to Doc. Type" = "Document Type"::" ") THEN
                      VendLedgEntry.SETRANGE("Document Type",xRec."Applies-to Doc. Type");
                    VendLedgEntry.SETRANGE("Vendor No.",TempGenJnlLine."Account No.");
                    VendLedgEntry.SETRANGE(Open,TRUE);
                    IF VendLedgEntry.FIND('-') THEN BEGIN
                      IF VendLedgEntry."Amount to Apply" <> 0 THEN  BEGIN
                        VendLedgEntry."Amount to Apply" := 0;
                        CODEUNIT.RUN(CODEUNIT::"Vend. Entry-Edit",VendLedgEntry);
                      END;
                    END;
                  END;

                END;

                IF (("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND (Amount <> 0)) THEN BEGIN
                  IF xRec."Applies-to Doc. No." <> '' THEN
                    PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec,xRec."Applies-to Doc. No.");
                  SetApplyToAmount;
                  PaymentToleranceMgt.PmtTolGenJnl(Rec);
                END;

                ValidateApplyRequirements(Rec);
            end;
        }
        field(38;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(39;"Pmt. Discount Date";Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(40;"Payment Discount %";Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(42;"Job No.";Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            begin
                IF ("Job No." = xRec."Job No.") THEN
                  EXIT;

                SourceCodeSetup.GET;
                IF "Source Code" <> SourceCodeSetup."Job G/L WIP" THEN
                  VALIDATE("Job Task No.",'');
                IF "Job No." = '' THEN BEGIN
                  CreateDim(
                    DATABASE::Job,"Job No.",
                    DimMgt.TypeToTableID1("Account Type"),"Account No.",
                    DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                    DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                    DATABASE::Campaign,"Campaign No.");
                  EXIT;
                END;

                TESTFIELD("Account Type","Account Type"::"G/L Account");
                IF "Bal. Account No." <> '' THEN
                  TESTFIELD("Bal. Account Type","Bal. Account Type"::"G/L Account");
                Job.GET("Job No.");
                Job.TestBlocked;
                "Job Currency Code" := Job."Currency Code";

                CreateDim(
                  DATABASE::Job,"Job No.",
                  DimMgt.TypeToTableID1("Account Type"),"Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                  DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code",
                  DATABASE::Campaign,"Campaign No.");
            end;
        }
        field(43;Quantity;Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                VALIDATE(Amount);
            end;
        }
        field(44;"VAT Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
                GenJnlBatch.TESTFIELD("Allow VAT Difference",TRUE);
                IF NOT ("VAT Calculation Type" IN
                  ["VAT Calculation Type"::"Normal VAT","VAT Calculation Type"::"Reverse Charge VAT"])
                THEN
                  ERROR(
                    Text010,FIELDCAPTION("VAT Calculation Type"),
                    "VAT Calculation Type"::"Normal VAT","VAT Calculation Type"::"Reverse Charge VAT");
                IF "VAT Amount" <> 0 THEN BEGIN
                  TESTFIELD("VAT %");
                  TESTFIELD(Amount);
                END;

                GetCurrency;
                "VAT Amount" := ROUND("VAT Amount",Currency."Amount Rounding Precision",Currency.VATRoundingDirection);

                IF "VAT Amount" * Amount < 0 THEN
                  IF "VAT Amount" > 0 THEN
                    ERROR(Text011,FIELDCAPTION("VAT Amount"))
                  ELSE
                    ERROR(Text012,FIELDCAPTION("VAT Amount"));

                "VAT Base Amount" := Amount - "VAT Amount";

                "VAT Difference" :=
                  "VAT Amount" -
                  ROUND(
                    Amount * "VAT %" / (100 + "VAT %"),
                    Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                IF ABS("VAT Difference") > Currency."Max. VAT Difference Allowed" THEN
                  ERROR(Text013,FIELDCAPTION("VAT Difference"),Currency."Max. VAT Difference Allowed");

                IF "Currency Code" = '' THEN
                  "VAT Amount (LCY)" := "VAT Amount"
                ELSE
                  "VAT Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        "Posting Date","Currency Code",
                        "VAT Amount","Currency Factor"));
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";

                UpdateSalesPurchLCY;
            end;
        }
        field(45;"VAT Posting";Option)
        {
            Caption = 'VAT Posting';
            Editable = false;
            OptionCaption = 'Automatic VAT Entry,Manual VAT Entry';
            OptionMembers = "Automatic VAT Entry","Manual VAT Entry";
        }
        field(47;"Payment Terms Code";Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                "Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Payment Discount %" := 0;
                IF ("Account Type" <> "Account Type"::"G/L Account") OR
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                THEN
                  CASE "Document Type" OF
                    "Document Type"::Invoice:
                      IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                        PaymentTerms.GET("Payment Terms Code");
                        "Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                        "Pmt. Discount Date" := CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                        "Payment Discount %" := PaymentTerms."Discount %";
                      END;
                    "Document Type"::"Credit Memo":
                      IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                        PaymentTerms.GET("Payment Terms Code");
                        IF PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN BEGIN
                          "Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                          "Pmt. Discount Date" :=
                            CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                          "Payment Discount %" := PaymentTerms."Discount %";
                        END ELSE
                          "Due Date" := "Document Date";
                      END;
                    ELSE
                      "Due Date" := "Document Date";
                  END;
            end;
        }
        field(48;"Applies-to ID";Code[20])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                IF ("Applies-to ID" <> xRec."Applies-to ID") AND (xRec."Applies-to ID" <> '') THEN
                  ClearCustVendApplnEntry;
            end;
        }
        field(50;"Business Unit Code";Code[10])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(51;"Journal Batch Name";Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE (Journal Template Name=FIELD(Journal Template Name));
        }
        field(52;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53;"Recurring Method";Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ' ,F  Fixed,V  Variable,B  Balance,RF Reversing Fixed,RV Reversing Variable,RB Reversing Balance';
            OptionMembers = " ","F  Fixed","V  Variable","B  Balance","RF Reversing Fixed","RV Reversing Variable","RB Reversing Balance";

            trigger OnValidate()
            begin
                IF "Recurring Method" IN
                   ["Recurring Method"::"B  Balance","Recurring Method"::"RB Reversing Balance"]
                THEN
                  TESTFIELD("Currency Code",'');
            end;
        }
        field(54;"Expiration Date";Date)
        {
            Caption = 'Expiration Date';
        }
        field(55;"Recurring Frequency";DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(56;"Allocated Amt. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Gen. Jnl. Allocation".Amount WHERE (Journal Template Name=FIELD(Journal Template Name),
                                                                   Journal Batch Name=FIELD(Journal Batch Name),
                                                                   Journal Line No.=FIELD(Line No.)));
            Caption = 'Allocated Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57;"Gen. Posting Type";Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            begin
                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Bank Account"] THEN
                  TESTFIELD("Gen. Posting Type","Gen. Posting Type"::" ");
                IF ("Gen. Posting Type" = "Gen. Posting Type"::Settlement) AND (CurrFieldNo <> 0) THEN
                  ERROR(Text006,"Gen. Posting Type");
                CheckVATInAlloc;
                IF "Gen. Posting Type" > 0 THEN
                  VALIDATE("VAT Prod. Posting Group");
            end;
        }
        field(58;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Bank Account"] THEN
                  TESTFIELD("Gen. Bus. Posting Group",'');
                IF xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" THEN
                  IF GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp,"Gen. Bus. Posting Group") THEN
                    VALIDATE("VAT Bus. Posting Group",GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(59;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Bank Account"] THEN
                  TESTFIELD("Gen. Prod. Posting Group",'');
                IF xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" THEN
                  IF GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp,"Gen. Prod. Posting Group") THEN
                    VALIDATE("VAT Prod. Posting Group",GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(60;"VAT Calculation Type";Option)
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(61;"EU 3-Party Trade";Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(62;"Allow Application";Boolean)
        {
            Caption = 'Allow Application';
            InitValue = true;
        }
        field(63;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";

            trigger OnValidate()
            begin
                IF ("Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Fixed Asset",
                    "Account Type"::"IC Partner"]) AND
                   ("Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Fixed Asset",
                    "Bal. Account Type"::"IC Partner"])
                THEN
                  ERROR(
                    Text000,
                    FIELDCAPTION("Account Type"),FIELDCAPTION("Bal. Account Type"));
                VALIDATE("Bal. Account No.",'');
                VALIDATE("IC Partner G/L Acc. No.",'');
                IF "Bal. Account Type" IN
                   ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"]
                THEN BEGIN
                  VALIDATE("Bal. Gen. Posting Type","Bal. Gen. Posting Type"::" ");
                  VALIDATE("Bal. Gen. Bus. Posting Group",'');
                  VALIDATE("Bal. Gen. Prod. Posting Group",'');
                END ELSE
                  IF "Account Type" IN [
                     "Bal. Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"]
                  THEN
                    VALIDATE("Payment Terms Code",'');
                UpdateSource;
                IF ("Account Type" <> "Account Type"::"Fixed Asset") AND
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                THEN BEGIN
                  "Depreciation Book Code" := '';
                  VALIDATE("FA Posting Type","FA Posting Type"::" ");
                END;
                IF xRec."Bal. Account Type" IN
                   [xRec."Bal. Account Type"::Customer,xRec."Bal. Account Type"::Vendor]
                THEN BEGIN
                  "Bill-to/Pay-to No." := '';
                  "Ship-to/Order Address Code" := '';
                  "Sell-to/Buy-from No." := '';
                END;
                IF ("Account Type" IN [
                    "Account Type"::"G/L Account","Account Type"::"Bank Account","Account Type"::"Fixed Asset"]) AND
                  ("Bal. Account Type" IN [
                    "Bal. Account Type"::"G/L Account","Bal. Account Type"::"Bank Account","Bal. Account Type"::"Fixed Asset"])
                THEN BEGIN
                  VALIDATE("Payment Terms Code",'');
                END;

                IF ("Bal. Account Type" = "Bal. Account Type"::"IC Partner") THEN BEGIN
                  GetTemplate;
                  IF GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany THEN
                    FIELDERROR("Bal. Account Type");
                END;
            end;
        }
        field(64;"Bal. Gen. Posting Type";Option)
        {
            Caption = 'Bal. Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            begin
                IF "Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"] THEN
                  TESTFIELD("Bal. Gen. Posting Type","Bal. Gen. Posting Type"::" ");
                IF ("Bal. Gen. Posting Type" = "Gen. Posting Type"::Settlement) AND (CurrFieldNo <> 0) THEN
                  ERROR(Text006,"Bal. Gen. Posting Type");
                IF "Bal. Gen. Posting Type" > 0 THEN
                  VALIDATE("Bal. VAT Prod. Posting Group");

                IF ("Account Type" <> "Account Type"::"Fixed Asset") AND
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                THEN BEGIN
                  "Depreciation Book Code" := '';
                  VALIDATE("FA Posting Type","FA Posting Type"::" ");
                END;
            end;
        }
        field(65;"Bal. Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"] THEN
                  TESTFIELD("Bal. Gen. Bus. Posting Group",'');
                IF xRec."Bal. Gen. Bus. Posting Group" <> "Bal. Gen. Bus. Posting Group" THEN
                  IF GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp,"Bal. Gen. Bus. Posting Group") THEN
                    VALIDATE("Bal. VAT Bus. Posting Group",GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(66;"Bal. Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"] THEN
                  TESTFIELD("Bal. Gen. Prod. Posting Group",'');
                IF xRec."Bal. Gen. Prod. Posting Group" <> "Bal. Gen. Prod. Posting Group" THEN
                  IF GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp,"Bal. Gen. Prod. Posting Group") THEN
                    VALIDATE("Bal. VAT Prod. Posting Group",GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(67;"Bal. VAT Calculation Type";Option)
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(68;"Bal. VAT %";Decimal)
        {
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0:5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency;
                CASE "Bal. VAT Calculation Type" OF
                  "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "Bal. VAT Amount" :=
                        ROUND(-Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Bal. VAT Base Amount" :=
                        ROUND(-Amount - "Bal. VAT Amount",Currency."Amount Rounding Precision");
                    END;
                  "Bal. VAT Calculation Type"::"Full VAT":
                    "Bal. VAT Amount" := -Amount;
                  "Bal. VAT Calculation Type"::"Sales Tax":
                    IF ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) AND
                       "Bal. Use Tax"
                    THEN BEGIN
                      "Bal. VAT Amount" := 0;
                      "Bal. VAT %" := 0;
                    END ELSE BEGIN
                      "Bal. VAT Amount" :=
                        -(Amount -
                          SalesTaxCalculate.ReverseCalculateTax(
                            "Bal. Tax Area Code","Bal. Tax Group Code","Bal. Tax Liable",
                            "Posting Date",Amount,Quantity,"Currency Factor"));
                      IF Amount + "Bal. VAT Amount" <> 0 THEN
                        "Bal. VAT %" := ROUND(100 * (-"Bal. VAT Amount") / (Amount + "Bal. VAT Amount"),0.00001)
                      ELSE
                        "Bal. VAT %" := 0;
                      "Bal. VAT Amount" :=
                        ROUND("Bal. VAT Amount",Currency."Amount Rounding Precision");
                    END;
                END;
                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");
                "Bal. VAT Difference" := 0;

                IF "Currency Code" = '' THEN
                  "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                ELSE
                  "Bal. VAT Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date","Currency Code",
                      "Bal. VAT Amount","Currency Factor"));
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");

                UpdateSalesPurchLCY;
            end;
        }
        field(69;"Bal. VAT Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';

            trigger OnValidate()
            begin
                GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
                GenJnlBatch.TESTFIELD("Allow VAT Difference",TRUE);
                IF NOT ("Bal. VAT Calculation Type" IN
                  ["Bal. VAT Calculation Type"::"Normal VAT","Bal. VAT Calculation Type"::"Reverse Charge VAT"])
                THEN
                  ERROR(
                    Text010,FIELDCAPTION("Bal. VAT Calculation Type"),
                    "Bal. VAT Calculation Type"::"Normal VAT","Bal. VAT Calculation Type"::"Reverse Charge VAT");
                IF "Bal. VAT Amount" <> 0 THEN BEGIN
                  TESTFIELD("Bal. VAT %");
                  TESTFIELD(Amount);
                END;

                GetCurrency;
                "Bal. VAT Amount" :=
                  ROUND("Bal. VAT Amount",Currency."Amount Rounding Precision",Currency.VATRoundingDirection);

                IF "Bal. VAT Amount" * Amount > 0 THEN
                  IF "Bal. VAT Amount" > 0 THEN
                    ERROR(Text011,FIELDCAPTION("Bal. VAT Amount"))
                  ELSE
                    ERROR(Text012,FIELDCAPTION("Bal. VAT Amount"));

                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");

                "Bal. VAT Difference" :=
                  "Bal. VAT Amount" -
                  ROUND(
                    -Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),
                    Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                IF ABS("Bal. VAT Difference") > Currency."Max. VAT Difference Allowed" THEN
                  ERROR(
                    Text013,FIELDCAPTION("Bal. VAT Difference"),Currency."Max. VAT Difference Allowed");

                IF "Currency Code" = '' THEN
                  "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                ELSE
                  "Bal. VAT Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date","Currency Code",
                      "Bal. VAT Amount","Currency Factor"));
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");

                UpdateSalesPurchLCY;
            end;
        }
        field(70;"Bank Payment Type";Option)
        {
            Caption = 'Bank Payment Type';
            OptionCaption = ' ,Computer Check,Manual Check';
            OptionMembers = " ","Computer Check","Manual Check";

            trigger OnValidate()
            begin
                IF ("Bank Payment Type" <> "Bank Payment Type"::" ") AND
                   ("Account Type" <> "Account Type"::"Bank Account") AND
                   ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
                THEN
                  ERROR(
                    Text007,
                    FIELDCAPTION("Account Type"),FIELDCAPTION("Bal. Account Type"));
                IF ("Account Type" = "Account Type"::"Fixed Asset") AND
                   ("Bank Payment Type" <> "Bank Payment Type"::" ")
                THEN
                  FIELDERROR("Account Type");
            end;
        }
        field(71;"VAT Base Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "VAT Base Amount" := ROUND("VAT Base Amount",Currency."Amount Rounding Precision");
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    Amount :=
                      ROUND(
                        "VAT Base Amount" * (1 + "VAT %" / 100),
                        Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                  "VAT Calculation Type"::"Full VAT":
                    IF "VAT Base Amount" <> 0 THEN
                      FIELDERROR(
                        "VAT Base Amount",
                        STRSUBSTNO(
                          Text008,FIELDCAPTION("VAT Calculation Type"),
                          "VAT Calculation Type"));
                  "VAT Calculation Type"::"Sales Tax":
                    IF ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) AND
                       "Use Tax"
                    THEN BEGIN
                      "VAT Amount" := 0;
                      "VAT %" := 0;
                      Amount := "VAT Base Amount" + "VAT Amount";
                    END ELSE BEGIN
                      "VAT Amount" :=
                        SalesTaxCalculate.CalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable","Posting Date",
                          "VAT Base Amount",Quantity,"Currency Factor");
                      IF "VAT Base Amount" <> 0 THEN
                        "VAT %" := ROUND(100 * "VAT Amount" / "VAT Base Amount",0.00001)
                      ELSE
                        "VAT %" := 0;
                      "VAT Amount" :=
                        ROUND("VAT Amount",Currency."Amount Rounding Precision");
                      Amount := "VAT Base Amount" + "VAT Amount";
                    END;
                END;
                VALIDATE(Amount);
            end;
        }
        field(72;"Bal. VAT Base Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Bal. VAT Base Amount" := ROUND("Bal. VAT Base Amount",Currency."Amount Rounding Precision");
                CASE "Bal. VAT Calculation Type" OF
                  "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                    Amount :=
                      ROUND(
                        -"Bal. VAT Base Amount" * (1 + "Bal. VAT %" / 100),
                        Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                  "Bal. VAT Calculation Type"::"Full VAT":
                    IF "Bal. VAT Base Amount" <> 0 THEN
                      FIELDERROR(
                        "Bal. VAT Base Amount",
                        STRSUBSTNO(
                          Text008,FIELDCAPTION("Bal. VAT Calculation Type"),
                          "Bal. VAT Calculation Type"));
                  "Bal. VAT Calculation Type"::"Sales Tax":
                    IF ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) AND
                       "Bal. Use Tax"
                    THEN BEGIN
                      "Bal. VAT Amount" := 0;
                      "Bal. VAT %" := 0;
                      Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                    END ELSE BEGIN
                      "Bal. VAT Amount" :=
                        SalesTaxCalculate.CalculateTax(
                          "Bal. Tax Area Code","Bal. Tax Group Code","Bal. Tax Liable",
                          "Posting Date","Bal. VAT Base Amount",Quantity,"Currency Factor");
                      IF "Bal. VAT Base Amount" <> 0 THEN
                        "Bal. VAT %" := ROUND(100 * "Bal. VAT Amount" / "Bal. VAT Base Amount",0.00001)
                      ELSE
                        "Bal. VAT %" := 0;
                      "Bal. VAT Amount" :=
                        ROUND("Bal. VAT Amount",Currency."Amount Rounding Precision");
                      Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                    END;
                END;
                VALIDATE(Amount);
            end;
        }
        field(73;Correction;Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                VALIDATE(Amount);
            end;
        }
        field(75;"Check Printed";Boolean)
        {
            Caption = 'Check Printed';
            Editable = false;
        }
        field(76;"Document Date";Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                VALIDATE("Payment Terms Code");
            end;
        }
        field(77;"External Document No.";Code[20])
        {
            Caption = 'External Document No.';
        }
        field(78;"Source Type";Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                IF ("Account Type" <> "Account Type"::"G/L Account") AND ("Account No." <> '') OR
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") AND ("Bal. Account No." <> '')
                THEN
                  UpdateSource
                ELSE
                  "Source No." := '';
            end;
        }
        field(79;"Source No.";Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF (Source Type=CONST(Customer)) Customer
                            ELSE IF (Source Type=CONST(Vendor)) Vendor
                            ELSE IF (Source Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Source Type=CONST(Fixed Asset)) "Fixed Asset";

            trigger OnValidate()
            begin
                IF ("Account Type" <> "Account Type"::"G/L Account") AND ("Account No." <> '') OR
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") AND ("Bal. Account No." <> '')
                THEN
                  UpdateSource;
            end;
        }
        field(80;"Posting No. Series";Code[10])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(82;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                VALIDATE("VAT %");
            end;
        }
        field(83;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                VALIDATE("VAT %");
            end;
        }
        field(84;"Tax Group Code";Code[10])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                VALIDATE("VAT %");
            end;
        }
        field(85;"Use Tax";Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                TESTFIELD("Gen. Posting Type","Gen. Posting Type"::Purchase);
                VALIDATE("VAT %");
            end;
        }
        field(86;"Bal. Tax Area Code";Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                VALIDATE("Bal. VAT %");
            end;
        }
        field(87;"Bal. Tax Liable";Boolean)
        {
            Caption = 'Bal. Tax Liable';

            trigger OnValidate()
            begin
                VALIDATE("Bal. VAT %");
            end;
        }
        field(88;"Bal. Tax Group Code";Code[10])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                VALIDATE("Bal. VAT %");
            end;
        }
        field(89;"Bal. Use Tax";Boolean)
        {
            Caption = 'Bal. Use Tax';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Gen. Posting Type","Bal. Gen. Posting Type"::Purchase);
                VALIDATE("Bal. VAT %");
            end;
        }
        field(90;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Bank Account"] THEN
                  TESTFIELD("VAT Bus. Posting Group",'');

                VALIDATE("VAT Prod. Posting Group");

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(91;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                IF "Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Bank Account"] THEN
                  TESTFIELD("VAT Prod. Posting Group",'');

                CheckVATInAlloc;

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                IF "Gen. Posting Type" <> 0 THEN BEGIN
                  IF NOT VATPostingSetup.GET("VAT Bus. Posting Group","VAT Prod. Posting Group") THEN
                    VATPostingSetup.INIT;
                  "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                  CASE "VAT Calculation Type" OF
                    "VAT Calculation Type"::"Normal VAT":
                      "VAT %" := VATPostingSetup."VAT %";
                    "VAT Calculation Type"::"Full VAT":
                      CASE "Gen. Posting Type" OF
                        "Gen. Posting Type"::Sale:
                          BEGIN
                            VATPostingSetup.TESTFIELD("Sales VAT Account");
                            TESTFIELD("Account No.",VATPostingSetup."Sales VAT Account");
                          END;
                        "Gen. Posting Type"::Purchase:
                          BEGIN
                            VATPostingSetup.TESTFIELD("Purchase VAT Account");
                            TESTFIELD("Account No.",VATPostingSetup."Purchase VAT Account");
                          END;
                      END;
                  END;
                END;
                VALIDATE("VAT %");

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(92;"Bal. VAT Bus. Posting Group";Code[10])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" IN
                   ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"]
                THEN
                  TESTFIELD("Bal. VAT Bus. Posting Group",'');

                VALIDATE("Bal. VAT Prod. Posting Group");
            end;
        }
        field(93;"Bal. VAT Prod. Posting Group";Code[10])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" IN
                   ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Bank Account"]
                THEN
                  TESTFIELD("Bal. VAT Prod. Posting Group",'');

                "Bal. VAT %" := 0;
                "Bal. VAT Calculation Type" := "Bal. VAT Calculation Type"::"Normal VAT";
                IF "Bal. Gen. Posting Type" <> 0 THEN BEGIN
                  IF NOT VATPostingSetup.GET("Bal. VAT Bus. Posting Group","Bal. VAT Prod. Posting Group") THEN
                    VATPostingSetup.INIT;
                  "Bal. VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                  CASE "Bal. VAT Calculation Type" OF
                    "Bal. VAT Calculation Type"::"Normal VAT":
                      "Bal. VAT %" := VATPostingSetup."VAT %";
                    "Bal. VAT Calculation Type"::"Full VAT":
                      CASE "Bal. Gen. Posting Type" OF
                        "Bal. Gen. Posting Type"::Sale:
                          BEGIN
                            VATPostingSetup.TESTFIELD("Sales VAT Account");
                            TESTFIELD("Bal. Account No.",VATPostingSetup."Sales VAT Account");
                          END;
                        "Bal. Gen. Posting Type"::Purchase:
                          BEGIN
                            VATPostingSetup.TESTFIELD("Purchase VAT Account");
                            TESTFIELD("Bal. Account No.",VATPostingSetup."Purchase VAT Account");
                          END;
                      END;
                  END;
                END;
                VALIDATE("Bal. VAT %");
            end;
        }
        field(95;"Additional-Currency Posting";Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        field(98;"FA Add.-Currency Factor";Decimal)
        {
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0:15;
            MinValue = 0;
        }
        field(99;"Source Currency Code";Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(100;"Source Currency Amount";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        field(101;"Source Curr. VAT Base Amount";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        field(102;"Source Curr. VAT Amount";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        field(103;"VAT Base Discount %";Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0:5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(104;"VAT Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(105;"VAT Base Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(106;"Bal. VAT Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        field(107;"Bal. VAT Base Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount (LCY)';
            Editable = false;
        }
        field(108;"Reversing Entry";Boolean)
        {
            Caption = 'Reversing Entry';
            Editable = false;
        }
        field(109;"Allow Zero-Amount Posting";Boolean)
        {
            Caption = 'Allow Zero-Amount Posting';
            Editable = false;
        }
        field(110;"Ship-to/Order Address Code";Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = IF (Account Type=CONST(Customer)) "Ship-to Address".Code WHERE (Customer No.=FIELD(Bill-to/Pay-to No.))
                            ELSE IF (Account Type=CONST(Vendor)) "Order Address".Code WHERE (Vendor No.=FIELD(Bill-to/Pay-to No.))
                            ELSE IF (Bal. Account Type=CONST(Customer)) "Ship-to Address".Code WHERE (Customer No.=FIELD(Bill-to/Pay-to No.))
                            ELSE IF (Bal. Account Type=CONST(Vendor)) "Order Address".Code WHERE (Vendor No.=FIELD(Bill-to/Pay-to No.));
        }
        field(111;"VAT Difference";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(112;"Bal. VAT Difference";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
        }
        field(113;"IC Partner Code";Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(114;"IC Direction";Option)
        {
            Caption = 'IC Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;
        }
        field(116;"IC Partner G/L Acc. No.";Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";

            trigger OnValidate()
            var
                ICGLAccount: Record "410";
            begin
                IF "IC Partner G/L Acc. No." <> '' THEN BEGIN
                  GetTemplate;
                  GenJnlTemplate.TESTFIELD(Type,GenJnlTemplate.Type::Intercompany);
                  IF ICGLAccount.GET("IC Partner G/L Acc. No.") THEN
                    ICGLAccount.TESTFIELD(Blocked,FALSE);
                END
            end;
        }
        field(117;"IC Partner Transaction No.";Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
        }
        field(118;"Sell-to/Buy-from No.";Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
            TableRelation = IF (Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor;

            trigger OnValidate()
            begin
                GLSetup.GET;
                IF GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No." THEN
                  UpdateCountryCodeAndVATRegNo("Sell-to/Buy-from No.");
            end;
        }
        field(119;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "381";
            begin
                VATRegNoFormat.Test("VAT Registration No.","Country/Region Code",'',0);
            end;
        }
        field(120;"Country/Region Code";Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = Country/Region;

            trigger OnValidate()
            begin
                VALIDATE("VAT Registration No.");
            end;
        }
        field(121;Prepayment;Boolean)
        {
            Caption = 'Prepayment';
        }
        field(122;"Financial Void";Boolean)
        {
            Caption = 'Financial Void';
            Editable = false;
        }
        field(1001;"Job Task No.";Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE (Job No.=FIELD(Job No.));

            trigger OnValidate()
            begin
                IF "Job Task No." = '' THEN BEGIN
                  "Job Quantity" := 0;
                  "Job Currency Factor" := 0;
                  "Job Currency Code" := '';
                  "Job Unit Price" := 0;
                  "Job Total Price" := 0;
                  "Job Line Amount" := 0;
                  "Job Line Discount Amount" := 0;
                  "Job Unit Cost" := 0;
                  "Job Total Cost" := 0;
                  "Job Line Discount %" := 0;

                  "Job Unit Price (LCY)" := 0;
                  "Job Total Price (LCY)" := 0;
                  "Job Line Amount (LCY)" := 0;
                  "Job Line Disc. Amount (LCY)" := 0;
                  "Job Unit Cost (LCY)" := 0;
                  "Job Total Cost (LCY)" := 0;
                  EXIT;
                END;

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1002;"Job Unit Price (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Job Unit Price (LCY)';
            Editable = false;
        }
        field(1003;"Job Total Price (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Total Price (LCY)';
            Editable = false;
        }
        field(1004;"Job Quantity";Decimal)
        {
            Caption = 'Job Quantity';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1005;"Job Unit Cost (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Job Unit Cost (LCY)';
            Editable = false;
        }
        field(1006;"Job Line Discount %";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Line Discount %';

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Line Discount %","Job Line Discount %");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1007;"Job Line Disc. Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Line Discount Amount (LCY)","Job Line Disc. Amount (LCY)");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1008;"Job Unit Of Measure Code";Code[10])
        {
            Caption = 'Job Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(1009;"Job Line Type";Option)
        {
            Caption = 'Job Line Type';
            OptionCaption = ' ,Schedule,Contract,Both Schedule and Contract';
            OptionMembers = " ",Schedule,Contract,"Both Schedule and Contract";
        }
        field(1010;"Job Unit Price";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Price';

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Unit Price","Job Unit Price");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1011;"Job Total Price";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Price';
            Editable = false;
        }
        field(1012;"Job Unit Cost";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Cost';
            Editable = false;
        }
        field(1013;"Job Total Cost";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Cost';
            Editable = false;
        }
        field(1014;"Job Line Discount Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Discount Amount';

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Line Discount Amount","Job Line Discount Amount");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1015;"Job Line Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Amount';

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Line Amount","Job Line Amount");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1016;"Job Total Cost (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Total Cost (LCY)';
            Editable = false;
        }
        field(1017;"Job Line Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine;
                  JobJnlLine.VALIDATE("Line Amount (LCY)","Job Line Amount (LCY)");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1018;"Job Currency Factor";Decimal)
        {
            Caption = 'Job Currency Factor';
        }
        field(1019;"Job Currency Code";Code[10])
        {
            Caption = 'Job Currency Code';

            trigger OnValidate()
            begin
                IF ("Job Currency Code" <> xRec."Job Currency Code") OR ("Job Currency Code" <> '') THEN
                  IF JobTaskIsSet THEN BEGIN
                    CreateTempJobJnlLine;
                    UpdatePricesFromJobJnlLine;
                  END;
            end;
        }
        field(5050;"Campaign No.";Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Campaign,"Campaign No.",
                  DimMgt.TypeToTableID1("Account Type"),"Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"),"Bal. Account No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::"Salesperson/Purchaser","Salespers./Purch. Code");
            end;
        }
        field(5400;"Prod. Order No.";Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
        }
        field(5600;"FA Posting Date";Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601;"FA Posting Type";Option)
        {
            Caption = 'FA Posting Type';
            Description = 'APNT-AT1.0';
            OptionCaption = ' ,Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance,Transfer';
            OptionMembers = " ","Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance,Transfer;

            trigger OnValidate()
            begin
                IF  NOT (("Account Type" = "Account Type"::"Fixed Asset") OR
                    ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")) AND
                    ("FA Posting Type" = "FA Posting Type"::" ")
                THEN BEGIN
                  "FA Posting Date" := 0D;
                  "Salvage Value" := 0;
                  "No. of Depreciation Days" := 0;
                  "Depr. until FA Posting Date" := FALSE;
                  "Depr. Acquisition Cost" := FALSE;
                  "Maintenance Code" := '';
                  "Insurance No." := '';
                  "Budgeted FA No." := '';
                  "Duplicate in Depreciation Book" := '';
                  "Use Duplication List" := FALSE;
                  "FA Reclassification Entry" := FALSE;
                  "FA Error Entry No." := 0;
                END;

                IF "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" THEN
                  TESTFIELD("Insurance No.",'');
                IF "FA Posting Type" <> "FA Posting Type"::Maintenance THEN
                  TESTFIELD("Maintenance Code",'');
                GetFAVATSetup;
                GetFAAddCurrExchRate;

                //APNT-AT1.0
                IF "FA Posting Type" <> "FA Posting Type"::Transfer THEN
                  "Temp. FA Posting Type" := "FA Posting Type";
                //APNT-AT1.0
            end;
        }
        field(5602;"Depreciation Book Code";Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                IF "Depreciation Book Code" = '' THEN
                  EXIT;

                IF ("Account No." <> '') AND
                   ("Account Type" = "Account Type"::"Fixed Asset")
                THEN BEGIN
                  FADeprBook.GET("Account No.","Depreciation Book Code");
                  "Posting Group" := FADeprBook."FA Posting Group";
                END;

                IF ("Bal. Account No." <> '') AND
                   ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")
                THEN BEGIN
                  FADeprBook.GET("Bal. Account No.","Depreciation Book Code");
                  "Posting Group" := FADeprBook."FA Posting Group";
                END;
                GetFAVATSetup;
                GetFAAddCurrExchRate;
            end;
        }
        field(5603;"Salvage Value";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5604;"No. of Depreciation Days";Integer)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        field(5605;"Depr. until FA Posting Date";Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606;"Depr. Acquisition Cost";Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609;"Maintenance Code";Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                IF "Maintenance Code" <> '' THEN
                  TESTFIELD("FA Posting Type","FA Posting Type"::Maintenance);
            end;
        }
        field(5610;"Insurance No.";Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;

            trigger OnValidate()
            begin
                IF "Insurance No." <> '' THEN
                  TESTFIELD("FA Posting Type","FA Posting Type"::"Acquisition Cost");
            end;
        }
        field(5611;"Budgeted FA No.";Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                IF "Budgeted FA No." <> '' THEN BEGIN
                  FA.GET("Budgeted FA No.");
                  FA.TESTFIELD(FA."Budgeted Asset",TRUE);
                END;
            end;
        }
        field(5612;"Duplicate in Depreciation Book";Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := FALSE;
            end;
        }
        field(5613;"Use Duplication List";Boolean)
        {
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(5614;"FA Reclassification Entry";Boolean)
        {
            Caption = 'FA Reclassification Entry';
        }
        field(5615;"FA Error Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(5616;"Index Entry";Boolean)
        {
            Caption = 'Index Entry';
        }
        field(50000;"Temp. FA Posting Type";Option)
        {
            Description = 'APNT-AT1.0';
            OptionCaption = ' ,Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance,Transfer';
            OptionMembers = " ","Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance,Transfer;
        }
        field(50001;"IBU Entry";Boolean)
        {
            Description = 'IBU1.0';
        }
        field(50002;"IBU Created";Boolean)
        {
            Description = 'IBU1.0';
        }
        field(50003;"Recurring IBU";Boolean)
        {
            Description = 'IBU1.0';
        }
        field(50004;Payee;Text[70])
        {
            Description = 'IBU1.0';
        }
        field(50005;"IBU Check Printed";Boolean)
        {
            Description = 'IBU1.0';
        }
        field(50006;"IPC Bal. Account Type";Option)
        {
            Description = 'IBU1.0';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
        }
        field(50007;"IPC Bal. Account No.";Code[20])
        {
            Description = 'IBU1.0';
        }
        field(50008;"Cheque No.";Code[20])
        {
            Description = 'IBU1.0';
        }
        field(50009;"Cheque Date";Date)
        {
            Description = 'IBU1.0';
        }
        field(50010;"IC Transaction No.";Integer)
        {
            Description = 'IC1.0';
            Editable = false;
        }
        field(50011;"IC Partner Direction";Option)
        {
            Description = 'IC1.0';
            OptionCaption = ' ,Outgoing,Incoming';
            OptionMembers = " ",Outgoing,Incoming;
        }
        field(50012;"Doc. No. Before Posting";Code[20])
        {
            Description = 'IC1.0';
        }
        field(50013;"Invoice Received Date";Date)
        {
            Description = 'LALS';
        }
        field(50050;"IBU Transaction No.";Integer)
        {
            Description = 'IBU1.1';
        }
        field(50051;"IBU User ID";Code[20])
        {
            Description = 'IBU1.1';
        }
        field(50103;"Facility Due Date";Date)
        {
            Description = 'FIN1.0';
        }
        field(50104;"LC No.";Code[20])
        {
            Description = 'FIN1.0';
            TableRelation = "Letter of Credit".No. WHERE (Status=FILTER(Closed));

            trigger OnValidate()
            var
                LC: Record "50012";
            begin
                //APNT-FIN1.0
                IF "LC No." <> '' THEN BEGIN
                  LC.GET("LC No.");
                  VALIDATE("Document Type","Document Type"::Payment);
                  VALIDATE("Account Type","Account Type"::"Bank Account");
                  VALIDATE("Account No.",LC."Bank No.");
                  CLEAR("Bal. Account Type");
                  VALIDATE("Bal. Account No.",'');
                  VALIDATE("Currency Code",LC."Currency Code");
                  "Currency Factor" := LC."Currency Factor";
                  VALIDATE(Amount,LC."Total LC Amount");
                  VALIDATE("Shortcut Dimension 1 Code",LC."Shortcut Dimension 1 Code");
                  VALIDATE("Shortcut Dimension 2 Code",LC."Shortcut Dimension 2 Code");
                END ELSE BEGIN
                  CLEAR("Document Type");
                  CLEAR("Account Type");
                  VALIDATE("Account No.",'');
                  CLEAR("Bal. Account Type");
                  VALIDATE("Bal. Account No.",'');
                  VALIDATE("Currency Code",'');
                  VALIDATE(Amount,0);
                  VALIDATE("Shortcut Dimension 1 Code",'');
                  VALIDATE("Shortcut Dimension 2 Code",'');
                END;
                //APNT-FIN1.0
            end;
        }
        field(50105;"Charges Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Legalization,Bank,Issuance Comm.,Amendment,Interest,Loan';
            OptionMembers = " ",Legalization,Bank,"Issuance Comm.",Amendment,Interest,Loan;
        }
        field(50106;"Facility Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Over Draft,Letter of Credit,Trust Receipt,Loans,Bank Facility,Cheque';
            OptionMembers = " ","Over Draft","Letter of Credit","Trust Receipt",Loans,"Bank Facility",Cheque;
        }
        field(50107;"Facility No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50108;"SG No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50109;"Loan No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50110;"Real Estate No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50111;"Investment Type";Option)
        {
            Description = 'FIN1.0';
            OptionCaption = ' ,Fixed Deposit,Fixed Income,Hedge Fund,Preference Stock,Private Equity,Equity,Mutual Fund,Real Estate Fund,Equity Fund,Structured Instrument,Foreign Redemption Note';
            OptionMembers = " ","Fixed Deposit","Fixed Income","Hedge Fund","Preference Stock","Private Equity",Equity,"Mutual Fund","Real Estate Fund","Equity Fund","Structured Instrument","Foreign Redemption Note";
        }
        field(50112;"Investment No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50113;"Contact No.";Code[20])
        {
            Description = 'FIN1.0';
            TableRelation = Contact;
        }
        field(50114;"Bank No.";Code[20])
        {
            Description = 'FIN1.0';
            TableRelation = "Bank Account";
        }
        field(50115;"Charge No.";Code[20])
        {
            Description = 'FIN1.0';
        }
        field(50203;Remarks;Text[250])
        {
            Description = 'APNT-PV1.0';
        }
        field(50204;"Payment Voucher";Boolean)
        {
            Description = 'APNT-PV1.0';
        }
        field(50205;"Bank Currency Code";Code[10])
        {
            Caption = 'Bank Currency Code';
            Description = 'APNT-PV1.0';
            TableRelation = Currency;
        }
        field(50206;"Bank Currency Factor";Decimal)
        {
            Caption = 'Bank Currency Factor';
            DecimalPlaces = 0:15;
            Description = 'APNT-PV1.0';
            Editable = false;
            MinValue = 0;
        }
        field(50500;"Lease Agreement No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Lease Management Header".No.;

            trigger OnValidate()
            var
                DocDim: Record "357";
                JnlLineDim: Record "356";
            begin
                //APNT-LM1.0 -
                GLSetup.GET;
                IF "Lease Agreement No." <> '' THEN BEGIN
                  TESTFIELD("Account Type","Account Type"::"G/L Account");
                  DocDim.RESET;
                  DocDim.SETRANGE("Table ID",DATABASE::"Lease Management Header");
                  DocDim.SETRANGE("Document No.","Lease Agreement No.");
                  IF DocDim.FINDFIRST THEN REPEAT
                    JnlLineDim.RESET;
                    JnlLineDim.SETRANGE("Table ID",DATABASE::"Gen. Journal Line");
                    JnlLineDim.SETRANGE("Journal Template Name","Journal Template Name");
                    JnlLineDim.SETRANGE("Journal Batch Name","Journal Batch Name");
                    JnlLineDim.SETRANGE("Journal Line No.","Line No.");
                    JnlLineDim.SETRANGE("Dimension Code",DocDim."Dimension Code");
                    IF NOT JnlLineDim.FINDFIRST THEN BEGIN
                      JnlLineDim.INIT;
                      JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                      JnlLineDim."Journal Template Name" := "Journal Template Name";
                      JnlLineDim."Journal Batch Name" := "Journal Batch Name";
                      JnlLineDim."Journal Line No." := "Line No.";
                      JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                      JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                      JnlLineDim.INSERT;
                      IF DocDim."Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
                        "Shortcut Dimension 1 Code" := DocDim."Dimension Value Code";
                      IF DocDim."Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
                        "Shortcut Dimension 2 Code" := DocDim."Dimension Value Code";
                    END;
                  UNTIL DocDim.NEXT = 0;
                END;
                CLEAR("Posted Lease Agmt. No.");
                CLEAR("Posted Lease Agmt. Charge No.");
                //APNT-LM1.0 +
            end;
        }
        field(50501;"Lease Agreement Charge No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Charges/ Deposits";

            trigger OnValidate()
            var
                AgreeChargeAmt: Record "50504";
            begin
                //APNT-LM1.0
                AgreeChargeAmt.RESET;
                AgreeChargeAmt.SETRANGE("Document Type",AgreeChargeAmt."Document Type"::"Lease Agreement");
                AgreeChargeAmt.SETRANGE("Document No.","Lease Agreement No.");
                AgreeChargeAmt.SETRANGE("Charge No.","Lease Agreement Charge No.");
                IF NOT AgreeChargeAmt.FIND('-') THEN
                  ERROR('Agreement Charge Amount not found with Charge No. %1',"Lease Agreement Charge No.");
                CLEAR("Posted Lease Agmt. No.");
                CLEAR("Posted Lease Agmt. Charge No.");
                //APNT-LM1.0
            end;
        }
        field(50502;"Posted Lease Agmt. No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Posted Lease Mgt. Header".No.;

            trigger OnValidate()
            var
                DocDim: Record "359";
                JnlLineDim: Record "356";
            begin
                //APNT-LM1.0 -
                GLSetup.GET;
                IF "Posted Lease Agmt. No." <> '' THEN BEGIN
                  TESTFIELD("Account Type","Account Type"::"G/L Account");
                  DocDim.RESET;
                  DocDim.SETRANGE("Table ID",DATABASE::"Posted Lease Mgt. Header");
                  DocDim.SETRANGE("Document No.","Posted Lease Agmt. No.");
                  IF DocDim.FINDFIRST THEN REPEAT
                    JnlLineDim.RESET;
                    JnlLineDim.SETRANGE("Table ID",DATABASE::"Gen. Journal Line");
                    JnlLineDim.SETRANGE("Journal Template Name","Journal Template Name");
                    JnlLineDim.SETRANGE("Journal Batch Name","Journal Batch Name");
                    JnlLineDim.SETRANGE("Journal Line No.","Line No.");
                    JnlLineDim.SETRANGE("Dimension Code",DocDim."Dimension Code");
                    IF NOT JnlLineDim.FINDFIRST THEN BEGIN
                      JnlLineDim.INIT;
                      JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                      JnlLineDim."Journal Template Name" := "Journal Template Name";
                      JnlLineDim."Journal Batch Name" := "Journal Batch Name";
                      JnlLineDim."Journal Line No." := "Line No.";
                      JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                      JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                      JnlLineDim.INSERT;
                      IF DocDim."Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
                        "Shortcut Dimension 1 Code" := DocDim."Dimension Value Code";
                      IF DocDim."Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
                        "Shortcut Dimension 2 Code" := DocDim."Dimension Value Code";
                    END;
                  UNTIL DocDim.NEXT = 0;
                END;
                CLEAR("Lease Agreement No.");
                CLEAR("Lease Agreement Charge No.");
                //APNT-LM1.0 +
            end;
        }
        field(50503;"Posted Lease Agmt. Charge No.";Code[20])
        {
            Description = 'APNT-LM1.0';
            TableRelation = "Lease Charges/ Deposits"."Charge No." WHERE (Document No.=FIELD(Posted Lease Agmt. No.),
                                                                          Document Type=CONST(Lease Agreement));

            trigger OnValidate()
            var
                AgreeChargeAmt: Record "50504";
            begin
                //APNT-LM1.0
                AgreeChargeAmt.RESET;
                AgreeChargeAmt.SETRANGE("Document Type",AgreeChargeAmt."Document Type"::"Lease Agreement");
                AgreeChargeAmt.SETRANGE("Document No.","Posted Lease Agmt. No.");
                AgreeChargeAmt.SETRANGE("Charge No.","Posted Lease Agmt. Charge No.");
                IF NOT AgreeChargeAmt.FIND('-') THEN
                  ERROR('Agreement Charge Amount not found with Charge No. %1',"Posted Lease Agmt. Charge No.");
                CLEAR("Lease Agreement No.");
                CLEAR("Lease Agreement Charge No.");
                //APNT-LM1.0
            end;
        }
        field(50504;"Lease Agreement Charge Type";Option)
        {
            Description = 'APNT-LM1.0';
            OptionCaption = 'Deposit,Charge';
            OptionMembers = Deposit,Charge;
        }
        field(50505;"Jnl Doc. No. Before Posting";Code[20])
        {
        }
        field(50600;"VAN Payment Push";Boolean)
        {
            Description = 'APNT-VAN1.0';
        }
        field(60000;"Salary Disb. No.";Code[20])
        {
            Description = 'HR1.0';
            TableRelation = "Salary Disbursments Header";
        }
        field(60001;"Payroll Type";Option)
        {
            Description = 'HR1.0';
            OptionCaption = ' ,Basic Salary,Housing,Transport,Re-imbursement,Deduction,Over Time,Loan,Advance,Leave Salary Accr,Allowance,Air Passage Accr,Bonus Accr,Gratuity Accr,Leave Salary,Gratuity,Air Passage,Bonus,National Pension Accr,Pension Payment,Commission';
            OptionMembers = " ","Basic Salary",Housing,Transport,"Re-imbursement",Deduction,"Over Time",Loan,Advance,"Leave Salary Accr",Allowance,"Air Passage Accr","Bonus Accr","Gratuity Accr","Leave Salary",Gratuity,"Air Passage",Bonus,"National Pension Accr","Pension Payment",Commission;

            trigger OnValidate()
            begin
                IF NOT ("Payroll Type" IN ["Payroll Type"::" ","Payroll Type"::"Over Time","Payroll Type"::Commission,"Payroll Type"::Loan]) AND
                  ("Account No." <> '') THEN BEGIN
                  IF Employee.GET("Account No.") THEN BEGIN
                    EmpPostingGrp.GET(Employee."Employee Posting Group","Payroll Type");
                    CASE "Payroll Type" OF
                      "Payroll Type"::"Leave Salary Accr":
                        "Payroll A/C No." := EmpPostingGrp."Account No.";
                    END
                  END;
                END
            end;
        }
        field(60002;"Payroll A/C No.";Code[20])
        {
            Description = 'HR1.0';
        }
        field(60003;"Payroll Parameter";Code[10])
        {
            Description = 'HR1.0';
            TableRelation = "Payroll Structure".Code;

            trigger OnValidate()
            begin
                IF PayrollParameter.GET("Payroll Parameter") THEN BEGIN
                  "Payroll Type" := PayrollParameter.Type;
                  Description := PayrollParameter.Description;
                  IF Employee.GET("Employee No.") THEN BEGIN
                    EmpPostingGrp.GET(Employee."Employee Posting Group","Payroll Parameter");
                    "Account Type" := EmpPostingGrp."Account Type";
                    "Account No." := EmpPostingGrp."Account No.";
                    "Payroll A/C No." := EmpPostingGrp."Account No.";
                  END;
                END;
            end;
        }
        field(60004;"Employee No.";Code[20])
        {
            Description = 'HR1.0';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                IF Employee.GET("Employee No.") THEN BEGIN
                  VALIDATE("Shortcut Dimension 1 Code",Employee."Global Dimension 1 Code");
                  VALIDATE("Shortcut Dimension 2 Code",Employee."Global Dimension 2 Code");

                  TableID[1] := DATABASE::Employee;
                  No[1] := "Employee No.";
                  DimMgt.GetDefaultDim(TableID,No,'',"Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
                  IF "Line No." <> 0 THEN
                    DimMgt.UpdateDocDefaultDim(
                      DATABASE::"Gen. Journal Line",DocDim."Document Type"::" ","Document No.","Line No.",
                      "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");

                END;
            end;
        }
        field(60028;"Payroll Open Statement No.";Code[20])
        {
            Description = 'HR1.0';
        }
        field(60029;"Payroll Open Stmt. Line No.";Integer)
        {
            Description = 'HR1.0';
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
        field(10000703;"Only Two Dimensions";Boolean)
        {
            Caption = 'Only Two Dimensions';
        }
        field(10001350;"InStore-Created Entry";Boolean)
        {
            Caption = 'InStore-Created Entry';
            Description = 'LS6.1-01';
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
            TableRelation = "Agreement Header".No. WHERE (Agreement Status=FILTER(Active|Closed),
                                                          Client No.=FIELD(Account No.));
        }
        field(33016802;"Premise Code";Code[20])
        {
            Description = 'DP6.01.01';

            trigger OnLookup()
            var
                AgreementPremiseRec: Record "33016841";
                PremiseRec: Record "33016814";
                PremiseFrm: Form "33016803";
            begin
                //DP6.01.01 START
                IF "Ref. Document No." <> '' THEN BEGIN
                  AgreementPremiseRec.RESET;
                  AgreementPremiseRec.SETFILTER("Agreement No.","Ref. Document No.");
                  IF AgreementPremiseRec.FINDSET THEN BEGIN
                    REPEAT
                      IF PremiseRec.GET(AgreementPremiseRec."Premise No.") THEN
                        PremiseRec.MARK(TRUE);
                    UNTIL AgreementPremiseRec.NEXT = 0;
                    PremiseRec.MARKEDONLY(TRUE);
                  END;
                  PremiseFrm.SETTABLEVIEW(PremiseRec);
                  PremiseFrm.SETRECORD(PremiseRec);
                  PremiseFrm.LOOKUPMODE(TRUE);
                  IF PremiseFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    PremiseFrm.GETRECORD(PremiseRec);
                    "Premise Code" := PremiseRec."No.";
                  END;
                END ELSE BEGIN
                  PremiseRec.RESET;
                  PremiseFrm.SETTABLEVIEW(PremiseRec);
                  PremiseFrm.SETRECORD(PremiseRec);
                  PremiseFrm.LOOKUPMODE(TRUE);
                  IF PremiseFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    PremiseFrm.GETRECORD(PremiseRec);
                    "Premise Code" := PremiseRec."No.";
                  END;
                END;
                //DP6.01.01 STOP
            end;
        }
        field(33016803;"Payment Type";Option)
        {
            Description = 'DP6.01.01';
            OptionCaption = ' ,Lease,Sale';
            OptionMembers = " ",Lease,Sale;
        }
        field(33016804;"Period Start";Date)
        {
            Description = 'DP6.01.01';
        }
        field(33016805;"Period End";Date)
        {
            Description = 'DP6.01.01';
        }
        field(33016806;"Ref. Document Line No.";Integer)
        {
            BlankZero = true;
            Description = 'DP6.01.01';
            TableRelation = "Agreement Line"."Line No." WHERE (Agreement No.=FIELD(Ref. Document No.),
                                                               Agreement Type=FIELD(Ref. Document Type));

            trigger OnValidate()
            var
                AgrmtLine: Record "33016816";
            begin
                //DP6.01.01 START
                IF "Ref. Document Type" = "Ref. Document Type"::Lease THEN BEGIN
                  IF AgrmtLine.GET(AgrmtLine."Agreement Type"::Lease,"Ref. Document No.","Ref. Document Line No.") THEN BEGIN
                    "Client No." := AgrmtLine."Client No.";
                    "Element Type" := AgrmtLine."Element Type";
                  END;
                END;
                //DP6.01.01 STOP
            end;
        }
        field(33016807;"Client No.";Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = Customer.No.;
        }
        field(33016808;"Element Type";Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = "Agreement Element".Code;
        }
        field(33016809;"Select Line";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016810;"Chq No.";Code[20])
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Account Type","Bal. Account Type"::"Bank Account"); //DP6.01.01
            end;
        }
        field(33016811;"Chq Date";Date)
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Account Type","Bal. Account Type"::"Bank Account"); //DP6.01.01
            end;
        }
        field(33016812;"Chq Amount";Decimal)
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Account Type","Bal. Account Type"::"Bank Account"); //DP6.01.01
            end;
        }
        field(33016813;"Issuing Bank Name";Text[50])
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Account Type","Bal. Account Type"::"Bank Account"); //DP6.01.01
            end;
        }
        field(33016814;"Issuing Bank Branch";Text[30])
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Bal. Account Type","Bal. Account Type"::"Bank Account"); //DP6.01.01
            end;
        }
        field(33016815;Printed;Boolean)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016816;Approved;Boolean)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016819;Processed;Boolean)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016820;"Applied Agrmt. Amount";Decimal)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(99001485;"Statement No.";Code[20])
        {
            Caption = 'Statement No.';
        }
    }

    keys
    {
        key(Key1;"Journal Template Name","Journal Batch Name","Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
            SumIndexFields = "Balance (LCY)";
        }
        key(Key2;"Journal Template Name","Journal Batch Name","Posting Date","Document No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3;"Account Type","Account No.","Applies-to Doc. Type","Applies-to Doc. No.")
        {
        }
        key(Key4;"Journal Template Name","Journal Batch Name","Document No.","Posting Date","Shortcut Dimension 1 Code")
        {
        }
        key(Key5;"Ref. Document Type","Ref. Document No.","Line No.")
        {
        }
        key(Key6;"Chq Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JnlLineDim: Record "356";
        LMSetup: Record "50502";
        LMLines: Record "50501";
        AgrmtApplicationLines: Record "33016871";
        PostedPayrollStmtLines: Record "60085";
    begin
        TESTFIELD("Check Printed",FALSE);
        //APNT-IBU1.1 -
        TestCheckPrinted;
        //APNT-IBU1.1 +
        TESTFIELD(Approved,FALSE); //DP6.01.01

        ClearCustVendApplnEntry;

        JnlLineDim.SETRANGE("Table ID",DATABASE::"Gen. Jnl. Allocation");
        JnlLineDim.SETRANGE("Journal Template Name","Journal Template Name");
        JnlLineDim.SETRANGE("Journal Batch Name","Journal Batch Name");
        JnlLineDim.SETRANGE("Journal Line No.","Line No.");
        JnlLineDim.DELETEALL;

        GenJnlAlloc.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlAlloc.SETRANGE("Journal Batch Name","Journal Batch Name");
        GenJnlAlloc.SETRANGE("Journal Line No.","Line No.");
        GenJnlAlloc.DELETEALL;

        //DP6.01.01 START
        AgrmtApplicationLines.SETRANGE("Journal Template Name","Journal Template Name");
        AgrmtApplicationLines.SETRANGE("Journal Batch Name","Journal Batch Name");
        AgrmtApplicationLines.SETRANGE("Journal Line No.","Line No.");
        AgrmtApplicationLines.DELETEALL;
        //DP6.01.01 STOP

        DimMgt.DeleteJnlLineDim(
          DATABASE::"Gen. Journal Line",
          "Journal Template Name","Journal Batch Name","Line No.",0);

        //APNT-IBU1.0
        IF "IC Direction" = "IC Direction"::Incoming THEN
          ERROR('IC Gen. Journal Line with IC Direction Incoming cannot be deleted.');
        //APNT-IBU1.0

        //APNT-LM1.0 -
        LMSetup.GET;
        IF ("Lease Agreement No." <> '') AND ("Lease Agreement Charge No." = '') THEN BEGIN
          IF ("Journal Template Name" = LMSetup.Template) AND ("Journal Batch Name" = LMSetup.Batch) THEN BEGIN
            LMLines.RESET;
            LMLines.SETRANGE("Document Type",LMLines."Document Type"::"Lease Agreement");
            LMLines.SETRANGE("Document No.","Lease Agreement No.");
            LMLines.SETRANGE("End Date","Posting Date");
            IF LMLines.FINDFIRST THEN BEGIN
              LMLines."Line Created" := FALSE;
              LMLines.MODIFY;
            END;
          END;
        END;
        //APNT-LM1.0 +

        //T002747
        IF ("Payroll Open Statement No." <> '') AND ("Payroll Open Stmt. Line No." <> 0) THEN BEGIN
          PostedPayrollStmtLines.RESET;
          PostedPayrollStmtLines.SETRANGE("Statement No.","Payroll Open Statement No.");
          PostedPayrollStmtLines.SETRANGE("Line No.","Payroll Open Stmt. Line No.");
          IF PostedPayrollStmtLines.FINDFIRST THEN BEGIN
            PostedPayrollStmtLines."IC Journal Created" := FALSE;
            PostedPayrollStmtLines.MODIFY;
          END;
        END;
        //T002747
    end;

    trigger OnInsert()
    var
        JnlLineDim: Record "356";
    begin
        JnlLineDim.LOCKTABLE;
        GenJnlAlloc.LOCKTABLE;
        LOCKTABLE;
        GenJnlTemplate.GET("Journal Template Name");
        GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
        "Check Printed" := FALSE;

        ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");

        //APNT-LM1.0
        IF "Lease Agreement No." <> '' THEN
          VALIDATE("Lease Agreement No.");
        IF "Posted Lease Agmt. No." <> '' THEN
          VALIDATE("Posted Lease Agmt. No.");
        //APNT-LM1.0

        //LS -
        GetRetailSetup();
        IF RetailSetup."Only Two Dimensions" THEN
          "Only Two Dimensions" := RetailSetup."Only Two Dimensions";
        IF NOT "Only Two Dimensions" THEN
        //LS +
          DimMgt.InsertJnlLineDim(
            DATABASE::"Gen. Journal Line",
            "Journal Template Name","Journal Batch Name","Line No.",0,
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");

        //APNT-IC1.0
        ICGenJnlLine.RESET;
        ICGenJnlLine.SETCURRENTKEY("Journal Template Name","Journal Batch Name","Document No.");
        ICGenJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
        ICGenJnlLine.SETRANGE("Journal Batch Name","Journal Batch Name");
        ICGenJnlLine.SETRANGE("Document No.","Document No.");
        ICGenJnlLine.SETFILTER("IC Partner Code",'<>%1','');
        //APNT-IC1.1
        ICGenJnlLine.SETFILTER("Account Type",'<>%1',"Account Type"::"IC Partner");
        //APNT-IC1.1
        IF ICGenJnlLine.FINDFIRST THEN BEGIN
          IF ICGenJnlLine."IC Partner Direction" <> ICGenJnlLine."IC Partner Direction"::" " THEN BEGIN
            "IC Transaction No." := ICGenJnlLine."IC Transaction No.";
            "IC Partner Direction" := ICGenJnlLine."IC Partner Direction";
          END;
        END;
        //APNT-IC1.0
    end;

    trigger OnModify()
    begin
        TESTFIELD("Check Printed",FALSE);
        //APNT-IBU1.1 -
        TestCheckPrinted;
        //APNT-IBU1.1 +

        IF ("Applies-to ID" = '') AND (xRec."Applies-to ID" <> '') THEN
          ClearCustVendApplnEntry;

        //APNT-IC1.0
        ICGenJnlLine.RESET;
        ICGenJnlLine.SETCURRENTKEY("Journal Template Name","Journal Batch Name","Document No.");
        ICGenJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
        ICGenJnlLine.SETRANGE("Journal Batch Name","Journal Batch Name");
        ICGenJnlLine.SETRANGE("Document No.","Document No.");
        ICGenJnlLine.SETFILTER("IC Partner Code",'<>%1','');
        //APNT-IC1.1
        ICGenJnlLine.SETFILTER("Account Type",'<>%1',"Account Type"::"IC Partner");
        //APNT-IC1.1

        IF ICGenJnlLine.FINDFIRST THEN BEGIN
          IF ICGenJnlLine."IC Partner Direction" <> ICGenJnlLine."IC Partner Direction"::" " THEN BEGIN
            "IC Transaction No." := ICGenJnlLine."IC Transaction No.";
            "IC Partner Direction" := ICGenJnlLine."IC Partner Direction";
          END;
        END;
        //APNT-IC1.0
    end;

    trigger OnRename()
    begin
        TESTFIELD("Check Printed",FALSE);
        //APNT-IBU1.1 -
        TestCheckPrinted;
        //APNT-IBU1.1 +
    end;

    var
        Text000: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text001: Label 'You must not specify %1 when %2 is %3.';
        Text002: Label 'cannot be specified without %1';
        Text003: Label 'The %1 in the %2 will be changed from %3 to %4.\';
        Text004: Label 'Do you wish to continue?';
        Text005: Label 'The update has been interrupted to respect the warning.';
        Text006: Label 'The %1 option can only be used internally in the system.';
        Text007: Label '%1 or %2 must be a Bank Account.';
        Text008: Label ' must be 0 when %1 is %2.';
        Text009: Label 'LCY';
        Text010: Label '%1 must be %2 or %3.';
        Text011: Label '%1 must be negative.';
        Text012: Label '%1 must be positive.';
        Text013: Label 'The %1 must not be more than %2.';
        GenJnlTemplate: Record "80";
        GenJnlBatch: Record "232";
        GenJnlLine: Record "81";
        GLAcc: Record "15";
        Cust: Record "18";
        Cust2: Record "18";
        Vend: Record "23";
        Vend2: Record "23";
        ICPartner: Record "413";
        Currency: Record "4";
        CurrExchRate: Record "330";
        PaymentTerms: Record "3";
        CustLedgEntry: Record "21";
        VendLedgEntry: Record "25";
        GenJnlAlloc: Record "221";
        VATPostingSetup: Record "325";
        BankAcc: Record "270";
        BankAcc2: Record "270";
        BankAcc3: Record "270";
        FA: Record "5600";
        FASetup: Record "5603";
        FADeprBook: Record "5612";
        GenBusPostingGrp: Record "250";
        GenProdPostingGrp: Record "251";
        GLSetup: Record "98";
        Job: Record "167";
        JobJnlLine: Record "210" temporary;
        ApplyCustEntries: Form "232";
        ApplyVendEntries: Form "233";
        NoSeriesMgt: Codeunit "396";
        CustCheckCreditLimit: Codeunit "312";
        SalesTaxCalculate: Codeunit "398";
        GenJnlApply: Codeunit "225";
        CustEntrySetApplID: Codeunit "101";
        VendEntrySetApplID: Codeunit "111";
        DimMgt: Codeunit "408";
        PaymentToleranceMgt: Codeunit "426";
        AccNo: Code[20];
        FromCurrencyCode: Code[10];
        ToCurrencyCode: Code[10];
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        ReplaceInfo: Boolean;
        CurrencyCode: Code[10];
        Text014: Label 'The %1 %2 has a %3 %4.\Do you still want to use %1 %2 in this journal line?';
        OK: Boolean;
        TemplateFound: Boolean;
        Text015: Label 'You are not allowed to apply and post an entry to an entry with an earlier posting date.\\Instead, post %1 %2 and then apply it to %3 %4.';
        CurrencyDate: Date;
        SourceCodeSetup: Record "242";
        RetailSetup: Record "10000700";
        RetailSetupAlreadyRetrieved: Boolean;
        ICGenJnlLine: Record "81";
        GenJnlLineRec: Record "81";
        Text33016832: Label 'You are not allowed to edit Receipt Journal Line No. = %1';
        Text33016836: Label 'You are not allowed to print copy of Receipt';
        Text33016837: Label 'You are not allowed to Approve Receipt Jnl Lines';
        Text33016838: Label 'No Line selected';
        Text33016839: Label 'Applied Agrmt. Amount must be equal to %1';
        Employee: Record "5200";
        EmpPostingGrp: Record "60016";
        PayrollParameter: Record "60035";
        DefaultDim: Record "352";
        DimensionValue: Record "349";
        No: array [10] of Code[20];
        TableID: array [10] of Integer;
        DocDim: Record "357";
        HRSetup: Record "5218";
        CompanyInformation: Record "79";
 
    procedure EmptyLine(): Boolean
    begin
        EXIT(
          ("Account No." = '') AND (Amount = 0) AND
          (("Bal. Account No." = '') OR NOT "System-Created Entry"));
    end;
 
    procedure UpdateLineBalance()
    begin
        IF ((Amount > 0) AND (NOT Correction)) OR
           ((Amount < 0) AND Correction)
        THEN BEGIN
          "Debit Amount" := Amount;
          "Credit Amount" := 0
        END ELSE BEGIN
          "Debit Amount" := 0;
          "Credit Amount" := -Amount;
        END;
        IF "Currency Code" = '' THEN
          "Amount (LCY)" := Amount;
        CASE TRUE OF
          ("Account No." <> '') AND ("Bal. Account No." <> ''):
            "Balance (LCY)" := 0;
          "Bal. Account No." <> '':
            "Balance (LCY)" := -"Amount (LCY)";
          ELSE
            "Balance (LCY)" := "Amount (LCY)";
        END;

        CLEAR(GenJnlAlloc);
        GenJnlAlloc.UpdateAllocations(Rec);

        UpdateSalesPurchLCY;
    end;
 
    procedure SetUpNewLine(LastGenJnlLine: Record "81";Balance: Decimal;BottomLine: Boolean)
    begin
        GenJnlTemplate.GET("Journal Template Name");
        GenJnlBatch.GET("Journal Template Name","Journal Batch Name");
        GenJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlLine.SETRANGE("Journal Batch Name","Journal Batch Name");
        IF GenJnlLine.FIND('-') THEN BEGIN
          "Posting Date" := LastGenJnlLine."Posting Date";
          "Document Date" := LastGenJnlLine."Posting Date";
          "Document No." := LastGenJnlLine."Document No.";
          IF BottomLine AND
             (Balance - LastGenJnlLine."Balance (LCY)" = 0) AND
             NOT LastGenJnlLine.EmptyLine
          THEN
            "Document No." := INCSTR("Document No.");
        END ELSE BEGIN
          "Posting Date" := WORKDATE;
          "Document Date" := WORKDATE;
          IF GenJnlBatch."No. Series" <> '' THEN BEGIN
            CLEAR(NoSeriesMgt);
            "Document No." := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series","Posting Date");
          END;
        END;
        IF GenJnlTemplate.Recurring THEN
          "Recurring Method" := LastGenJnlLine."Recurring Method";
        "Account Type" := LastGenJnlLine."Account Type";
        "Document Type" := LastGenJnlLine."Document Type";
        "Source Code" := GenJnlTemplate."Source Code";
        "Reason Code" := GenJnlBatch."Reason Code";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";
        "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
        IF ("Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor,"Account Type"::"Fixed Asset"]) AND
           ("Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor,"Bal. Account Type"::"Fixed Asset"])
        THEN
          "Account Type" := "Account Type"::"G/L Account";
        VALIDATE("Bal. Account No.",GenJnlBatch."Bal. Account No.");
        Description := '';
    end;

    local procedure CheckVATInAlloc()
    begin
        IF "Gen. Posting Type" <> 0 THEN BEGIN
          GenJnlAlloc.RESET;
          GenJnlAlloc.SETRANGE("Journal Template Name","Journal Template Name");
          GenJnlAlloc.SETRANGE("Journal Batch Name","Journal Batch Name");
          GenJnlAlloc.SETRANGE("Journal Line No.","Line No.");
          IF GenJnlAlloc.FIND('-') THEN
            REPEAT
              GenJnlAlloc.CheckVAT(Rec);
            UNTIL GenJnlAlloc.NEXT = 0;
        END;
    end;

    local procedure SetCurrencyCode(AccType2: Option "G/L Account",Customer,Vendor,"Bank Account";AccNo2: Code[20]): Boolean
    begin
        "Currency Code" := '';
        IF AccNo2 <> '' THEN
          CASE AccType2 OF
            AccType2::Customer:
              IF Cust2.GET(AccNo2) THEN
                "Currency Code" := Cust2."Currency Code";
            AccType2::Vendor:
              IF Vend2.GET(AccNo2) THEN
                "Currency Code" := Vend2."Currency Code";
            AccType2::"Bank Account":
              IF BankAcc2.GET(AccNo2) THEN
                "Currency Code" := BankAcc2."Currency Code";
          END;
        EXIT("Currency Code" <> '');
    end;

    local procedure GetCurrency()
    begin
        IF "Additional-Currency Posting" =
           "Additional-Currency Posting"::"Additional-Currency Amount Only"
        THEN BEGIN
          IF GLSetup."Additional Reporting Currency" = '' THEN
            GLSetup.GET;
          CurrencyCode := GLSetup."Additional Reporting Currency";
        END ELSE
          CurrencyCode := "Currency Code";

        IF CurrencyCode = '' THEN BEGIN
          CLEAR(Currency);
          Currency.InitRoundingPrecision
        END ELSE
          IF CurrencyCode <> Currency.Code THEN BEGIN
            Currency.GET(CurrencyCode);
            Currency.TESTFIELD("Amount Rounding Precision");
          END;
    end;
 
    procedure UpdateSource()
    var
        SourceExists1: Boolean;
        SourceExists2: Boolean;
    begin
        SourceExists1 := ("Account Type" <> "Account Type"::"G/L Account") AND ("Account No." <> '');
        SourceExists2 := ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") AND ("Bal. Account No." <> '');
        CASE TRUE OF
          SourceExists1 AND NOT SourceExists2:
            BEGIN
              "Source Type" := "Account Type";
              "Source No." := "Account No.";
            END;
          SourceExists2 AND NOT SourceExists1:
            BEGIN
              "Source Type" := "Bal. Account Type";
              "Source No." := "Bal. Account No.";
            END;
          ELSE BEGIN
            "Source Type" := "Source Type"::" ";
            "Source No." := '';
          END;
        END;
    end;

    local procedure CheckGLAcc()
    begin
        GLAcc.CheckGLAcc;
        IF GLAcc."Direct Posting" OR ("Journal Template Name" = '') OR "System-Created Entry" THEN
          EXIT;
        IF "Posting Date" <> 0D THEN
          IF "Posting Date" = CLOSINGDATE("Posting Date") THEN
            EXIT;
        GLAcc.TESTFIELD("Direct Posting",TRUE);
    end;
 
    procedure GetFAAddCurrExchRate()
    var
        DeprBook: Record "5611";
        FANo: Code[20];
        UseFAAddCurrExchRate: Boolean;
    begin
        "FA Add.-Currency Factor" := 0;
        IF ("FA Posting Type" <> "FA Posting Type"::" ") AND
           ("Depreciation Book Code" <> '')
        THEN BEGIN
          IF ("Account Type" = "Account Type"::"Fixed Asset") THEN
            FANo := "Account No.";
          IF ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset") THEN
            FANo := "Bal. Account No.";
          IF FANo <> '' THEN BEGIN
            DeprBook.GET("Depreciation Book Code");
            CASE "FA Posting Type" OF
              "FA Posting Type"::"Acquisition Cost":
                UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate - Acq. Cost";
              "FA Posting Type"::Depreciation:
                UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Depr.";
              "FA Posting Type"::"Write-Down":
                UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate -Write-Down";
              "FA Posting Type"::Appreciation:
                UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch. Rate - Apprec.";
              "FA Posting Type"::"Custom 1":
                UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 1";
              "FA Posting Type"::"Custom 2":
                UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 2";
              "FA Posting Type"::Disposal:
                UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Disp.";
              "FA Posting Type"::Maintenance:
                UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Maint.";
            END;
            IF UseFAAddCurrExchRate THEN BEGIN
              FADeprBook.GET(FANo,"Depreciation Book Code");
              FADeprBook.TESTFIELD("FA Add.-Currency Factor");
              "FA Add.-Currency Factor" := FADeprBook."FA Add.-Currency Factor";
            END;
          END;
        END;
    end;
 
    procedure GetShowCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        IF CurrencyCode <> '' THEN
          EXIT(CurrencyCode)
        ELSE
          EXIT(Text009);
    end;
 
    procedure ClearCustVendApplnEntry()
    var
        TempCustLedgEntry: Record "21";
        TempVendLedgEntry: Record "25";
        CustEntryEdit: Codeunit "103";
        VendEntryEdit: Codeunit "113";
    begin
        IF Rec."Bal. Account Type" IN
           ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]
        THEN BEGIN
          AccType := Rec."Bal. Account Type";
          AccNo := Rec."Bal. Account No.";
        END ELSE BEGIN
          AccType := Rec."Account Type";
          AccNo := Rec."Account No.";
        END;
        CASE AccType OF
          AccType::Customer:
            BEGIN
              CustLedgEntry.RESET;
              IF Rec."Applies-to ID" <> '' THEN BEGIN
                CustLedgEntry.SETCURRENTKEY("Customer No.","Applies-to ID",Open);
                CustLedgEntry.SETRANGE("Customer No.",AccNo);
                CustLedgEntry.SETRANGE("Applies-to ID",Rec."Applies-to ID");
                CustLedgEntry.SETRANGE(Open,TRUE);
                IF CustLedgEntry.FIND('-') THEN BEGIN
                  CustLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                  CustLedgEntry."Accepted Payment Tolerance" := 0;
                  CustLedgEntry."Amount to Apply" := 0;
                  CustEntrySetApplID.SetApplId(CustLedgEntry,TempCustLedgEntry,0,0,'');
                END;
              END ELSE IF Rec."Applies-to Doc. No." <> '' THEN BEGIN
                CustLedgEntry.SETCURRENTKEY("Document No.");
                CustLedgEntry.SETRANGE("Document No.",Rec."Applies-to Doc. No.");
                CustLedgEntry.SETRANGE("Document Type",Rec."Applies-to Doc. Type");
                CustLedgEntry.SETRANGE("Customer No.",AccNo);
                CustLedgEntry.SETRANGE(Open,TRUE);
                IF CustLedgEntry.FIND('-') THEN BEGIN
                  CustLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                  CustLedgEntry."Accepted Payment Tolerance" := 0;
                  CustLedgEntry."Amount to Apply" := 0;
                  CustEntryEdit.RUN(CustLedgEntry);
                END;
              END;
            END;
          AccType::Vendor:
            BEGIN
              VendLedgEntry.RESET;
              IF Rec."Applies-to ID" <> '' THEN BEGIN
                VendLedgEntry.SETCURRENTKEY("Vendor No.","Applies-to ID",Open);
                VendLedgEntry.SETRANGE("Vendor No.",AccNo);
                VendLedgEntry.SETRANGE("Applies-to ID",Rec."Applies-to ID");
                VendLedgEntry.SETRANGE(Open,TRUE);
                IF VendLedgEntry.FIND('-') THEN BEGIN
                  VendLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                  VendLedgEntry."Accepted Payment Tolerance" := 0;
                  VendLedgEntry."Amount to Apply" := 0;
                  VendEntrySetApplID.SetApplId(VendLedgEntry,TempVendLedgEntry,0,0,'');
              END;
              END ELSE IF Rec."Applies-to Doc. No." <> '' THEN BEGIN
                VendLedgEntry.SETCURRENTKEY("Document No.");
                VendLedgEntry.SETRANGE("Document No.",Rec."Applies-to Doc. No.");
                VendLedgEntry.SETRANGE("Document Type",Rec."Applies-to Doc. Type");
                VendLedgEntry.SETRANGE("Vendor No.",AccNo);
                VendLedgEntry.SETRANGE(Open,TRUE);
                IF VendLedgEntry.FIND('-') THEN BEGIN
                  VendLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                  VendLedgEntry."Accepted Payment Tolerance" := 0;
                  VendLedgEntry."Amount to Apply" := 0;
                  VendEntryEdit.RUN(VendLedgEntry);
                END;
              END;
          END;
        END;
    end;
 
    procedure CheckFixedCurrency(): Boolean
    var
        CurrExchRate: Record "330";
    begin
        CurrExchRate.SETRANGE("Currency Code","Currency Code");
        CurrExchRate.SETRANGE("Starting Date",0D,"Posting Date");

        IF NOT CurrExchRate.FIND('+') THEN
          EXIT(FALSE);

        IF CurrExchRate."Relational Currency Code" = '' THEN
          EXIT(
            CurrExchRate."Fix Exchange Rate Amount" =
            CurrExchRate."Fix Exchange Rate Amount"::Both);

        IF CurrExchRate."Fix Exchange Rate Amount" <>
          CurrExchRate."Fix Exchange Rate Amount"::Both
        THEN
          EXIT(FALSE);

        CurrExchRate.SETRANGE("Currency Code",CurrExchRate."Relational Currency Code");
        IF CurrExchRate.FIND('+') THEN
          EXIT(
            CurrExchRate."Fix Exchange Rate Amount" =
            CurrExchRate."Fix Exchange Rate Amount"::Both);

        EXIT(FALSE);
    end;
 
    procedure CreateDim(Type1: Integer;No1: Code[20];Type2: Integer;No2: Code[20];Type3: Integer;No3: Code[20];Type4: Integer;No4: Code[20];Type5: Integer;No5: Code[20])
    var
        TableID: array [10] of Integer;
        No: array [10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDim(
          TableID,No,"Source Code","Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");

        //LS -
        GetRetailSetup();
        IF RetailSetup."Only Two Dimensions" THEN
          "Only Two Dimensions" := RetailSetup."Only Two Dimensions";
        IF NOT "Only Two Dimensions" THEN
        //LS +

        IF "Line No." <> 0 THEN
          DimMgt.UpdateJnlLineDefaultDim(
            DATABASE::"Gen. Journal Line","Journal Template Name",
            "Journal Batch Name","Line No.",0,
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        TESTFIELD("Check Printed",FALSE);

        //LS -
        GetRetailSetup();
        IF RetailSetup."Only Two Dimensions" THEN
          "Only Two Dimensions" := RetailSetup."Only Two Dimensions";
        IF NOT "Only Two Dimensions" THEN
        //LS +

        IF "Line No." <> 0 THEN BEGIN
          DimMgt.SaveJnlLineDim(
            DATABASE::"Gen. Journal Line","Journal Template Name",
            "Journal Batch Name","Line No.",0,FieldNumber,ShortcutDimCode);
          IF MODIFY THEN;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);
        TESTFIELD("Check Printed",FALSE);

        //LS -
        GetRetailSetup();
        IF RetailSetup."Only Two Dimensions" THEN
          "Only Two Dimensions" := RetailSetup."Only Two Dimensions";
        IF NOT "Only Two Dimensions" THEN
        //LS +

        IF "Line No." <> 0 THEN BEGIN
          DimMgt.SaveJnlLineDim(
            DATABASE::"Gen. Journal Line","Journal Template Name",
            "Journal Batch Name","Line No.",0,FieldNumber,ShortcutDimCode);
          MODIFY;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowShortcutDimCode(var ShortcutDimCode: array [8] of Code[20])
    begin
        IF "Line No." <> 0 THEN
          DimMgt.ShowJnlLineDim(
            DATABASE::"Gen. Journal Line","Journal Template Name",
            "Journal Batch Name","Line No.",0,ShortcutDimCode)
        ELSE
          DimMgt.ShowTempDim(ShortcutDimCode);
    end;
 
    procedure GetFAVATSetup()
    var
        LocalGlAcc: Record "15";
        FAPostingGr: Record "5606";
        FABalAcc: Boolean;
    begin
        IF CurrFieldNo = 0 THEN
          EXIT;
        IF ("Account Type" <> "Account Type"::"Fixed Asset") AND
           ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
        THEN
          EXIT;
        FABalAcc := ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset");
        IF NOT FABalAcc THEN BEGIN
          "Gen. Posting Type" := "Gen. Posting Type"::" ";
          "Gen. Bus. Posting Group" := '';
          "Gen. Prod. Posting Group" := '';
          "VAT Bus. Posting Group" := '';
          "VAT Prod. Posting Group" := '';
          "Tax Group Code" := '';
          VALIDATE("VAT Prod. Posting Group");
        END;
        IF FABalAcc THEN BEGIN
          "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
          "Bal. Gen. Bus. Posting Group" := '';
          "Bal. Gen. Prod. Posting Group" := '';
          "Bal. VAT Bus. Posting Group" := '';
          "Bal. VAT Prod. Posting Group" := '';
          "Bal. Tax Group Code" := '';
          VALIDATE("Bal. VAT Prod. Posting Group");
        END;
        IF NOT GenJnlBatch.GET("Journal Template Name","Journal Batch Name") OR
          GenJnlBatch."Copy VAT Setup to Jnl. Lines"
        THEN BEGIN
          IF (("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") OR
             ("FA Posting Type" = "FA Posting Type"::Disposal) OR
             ("FA Posting Type" = "FA Posting Type"::Maintenance)) AND
             ("Posting Group" <> '')
          THEN BEGIN
            IF FAPostingGr.GET("Posting Group") THEN BEGIN
              IF "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" THEN BEGIN
                FAPostingGr.TESTFIELD("Acquisition Cost Account");
                LocalGlAcc.GET(FAPostingGr."Acquisition Cost Account");
              END;
              IF "FA Posting Type" = "FA Posting Type"::Disposal THEN BEGIN
                FAPostingGr.TESTFIELD("Acq. Cost Acc. on Disposal");
                LocalGlAcc.GET(FAPostingGr."Acq. Cost Acc. on Disposal");
              END;
              IF "FA Posting Type" = "FA Posting Type"::Maintenance THEN BEGIN
                FAPostingGr.TESTFIELD("Maintenance Expense Account");
                LocalGlAcc.GET(FAPostingGr."Maintenance Expense Account");
              END;
              LocalGlAcc.CheckGLAcc;
              IF NOT FABalAcc THEN BEGIN
                "Gen. Posting Type" := LocalGlAcc."Gen. Posting Type";
                "Gen. Bus. Posting Group" := LocalGlAcc."Gen. Bus. Posting Group";
                "Gen. Prod. Posting Group" := LocalGlAcc."Gen. Prod. Posting Group";
                "VAT Bus. Posting Group" := LocalGlAcc."VAT Bus. Posting Group";
                "VAT Prod. Posting Group" := LocalGlAcc."VAT Prod. Posting Group";
                "Tax Group Code" := LocalGlAcc."Tax Group Code";
                VALIDATE("VAT Prod. Posting Group");
              END ELSE BEGIN;
                "Bal. Gen. Posting Type" := LocalGlAcc."Gen. Posting Type";
                "Bal. Gen. Bus. Posting Group" := LocalGlAcc."Gen. Bus. Posting Group";
                "Bal. Gen. Prod. Posting Group" := LocalGlAcc."Gen. Prod. Posting Group";
                "Bal. VAT Bus. Posting Group" := LocalGlAcc."VAT Bus. Posting Group";
                "Bal. VAT Prod. Posting Group" := LocalGlAcc."VAT Prod. Posting Group";
                "Bal. Tax Group Code" := LocalGlAcc."Tax Group Code";
                VALIDATE("Bal. VAT Prod. Posting Group");
              END;
            END;
          END;
        END;
    end;
 
    procedure GetTemplate()
    begin
        IF NOT TemplateFound THEN
          GenJnlTemplate.GET("Journal Template Name");
        TemplateFound := TRUE;
    end;

    local procedure UpdateSalesPurchLCY()
    begin
        "Sales/Purch. (LCY)" := 0;
        IF (NOT "System-Created Entry") AND ("Document Type" IN ["Document Type"::Invoice,"Document Type"::"Credit Memo"]) THEN BEGIN
          IF ("Account Type" IN ["Account Type"::Customer,"Account Type"::Vendor]) AND ("Bal. Account No." <> '') THEN
            "Sales/Purch. (LCY)" := "Amount (LCY)" + "Bal. VAT Amount (LCY)";
          IF ("Bal. Account Type" IN ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]) AND ("Account No." <> '') THEN
            "Sales/Purch. (LCY)" := -("Amount (LCY)" - "VAT Amount (LCY)");
        END;
    end;
 
    procedure SetApplyToAmount()
    begin
        IF "Account Type" = "Account Type"::Customer THEN BEGIN
          CustLedgEntry.SETCURRENTKEY("Document No.");
          CustLedgEntry.SETRANGE("Document No.",Rec."Applies-to Doc. No.");
          CustLedgEntry.SETRANGE("Customer No.","Account No.");
          CustLedgEntry.SETRANGE(Open,TRUE);
          IF CustLedgEntry.FIND('-') THEN
            IF CustLedgEntry."Amount to Apply" = 0 THEN  BEGIN
              CustLedgEntry.CALCFIELDS("Remaining Amount");
              CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
              CODEUNIT.RUN(CODEUNIT::"Cust. Entry-Edit",CustLedgEntry);
            END;
        END ELSE IF "Account Type" = "Account Type"::Vendor THEN BEGIN
          VendLedgEntry.SETCURRENTKEY("Document No.");
          VendLedgEntry.SETRANGE("Document No.",Rec."Applies-to Doc. No.");
          VendLedgEntry.SETRANGE("Vendor No.","Account No.");
          VendLedgEntry.SETRANGE(Open,TRUE);
          IF VendLedgEntry.FIND('-') THEN
            IF VendLedgEntry."Amount to Apply" = 0 THEN  BEGIN
              VendLedgEntry.CALCFIELDS("Remaining Amount");
              VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
              CODEUNIT.RUN(CODEUNIT::"Vend. Entry-Edit",VendLedgEntry);
            END;
        END;
    end;
 
    procedure ValidateApplyRequirements(TempGenJnlLine: Record "81" temporary)
    var
        ExchAccGLJnlLine: Codeunit "366";
    begin
        IF (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) OR
          (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor)
        THEN
          ExchAccGLJnlLine.RUN(TempGenJnlLine);

        IF TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer THEN BEGIN
          IF TempGenJnlLine."Applies-to ID" <> '' THEN BEGIN
            CustLedgEntry.SETCURRENTKEY("Customer No.","Applies-to ID",Open);
            CustLedgEntry.SETRANGE("Customer No.",TempGenJnlLine."Account No.");
            CustLedgEntry.SETRANGE("Applies-to ID",TempGenJnlLine."Applies-to ID");
            CustLedgEntry.SETRANGE(Open,TRUE);
            IF CustLedgEntry.FIND('-') THEN
              REPEAT
                IF (TempGenJnlLine."Posting Date" < CustLedgEntry."Posting Date") THEN
                  ERROR(
                    Text015,TempGenJnlLine."Document Type",TempGenJnlLine."Document No.",
                    CustLedgEntry."Document Type",CustLedgEntry."Document No.");
              UNTIL CustLedgEntry.NEXT = 0;
          END ELSE IF TempGenJnlLine."Applies-to Doc. No." <> '' THEN BEGIN
            CustLedgEntry.SETCURRENTKEY("Document No.");
            CustLedgEntry.SETRANGE("Document No.",TempGenJnlLine."Applies-to Doc. No.");
            IF TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " THEN
              CustLedgEntry.SETRANGE("Document Type",TempGenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SETRANGE("Customer No.",TempGenJnlLine."Account No.");
            CustLedgEntry.SETRANGE(Open,TRUE);
            IF CustLedgEntry.FIND('-') THEN
              IF (TempGenJnlLine."Posting Date" < CustLedgEntry."Posting Date") THEN
                ERROR(
                  Text015,TempGenJnlLine."Document Type",TempGenJnlLine."Document No.",
                  CustLedgEntry."Document Type",CustLedgEntry."Document No.");
          END;
        END ELSE IF TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Vendor THEN BEGIN
          IF TempGenJnlLine."Applies-to ID" <> '' THEN BEGIN
            VendLedgEntry.SETCURRENTKEY("Vendor No.","Applies-to ID",Open);
            VendLedgEntry.SETRANGE("Vendor No.",TempGenJnlLine."Account No.");
            VendLedgEntry.SETRANGE("Applies-to ID",TempGenJnlLine."Applies-to ID");
            VendLedgEntry.SETRANGE(Open,TRUE);
              REPEAT
                IF (TempGenJnlLine."Posting Date" < VendLedgEntry."Posting Date") THEN
                  ERROR(
                    Text015,TempGenJnlLine."Document Type",TempGenJnlLine."Document No.",
                    VendLedgEntry."Document Type",VendLedgEntry."Document No.");
              UNTIL VendLedgEntry.NEXT = 0;
            IF VendLedgEntry.FIND('-') THEN BEGIN
            END;
          END ELSE IF TempGenJnlLine."Applies-to Doc. No." <> '' THEN BEGIN
            VendLedgEntry.SETCURRENTKEY("Document No.");
            VendLedgEntry.SETRANGE("Document No.",TempGenJnlLine."Applies-to Doc. No.");
            IF TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " THEN
              VendLedgEntry.SETRANGE("Document Type",TempGenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SETRANGE("Vendor No.",TempGenJnlLine."Account No.");
            VendLedgEntry.SETRANGE(Open,TRUE);
            IF VendLedgEntry.FIND('-') THEN
              IF (TempGenJnlLine."Posting Date" < VendLedgEntry."Posting Date") THEN
                ERROR(
                  Text015,TempGenJnlLine."Document Type",TempGenJnlLine."Document No.",
                  VendLedgEntry."Document Type",VendLedgEntry."Document No.");
          END;
        END;
    end;

    local procedure UpdateCountryCodeAndVATRegNo(No: Code[20])
    begin
        IF No = '' THEN BEGIN
          "Country/Region Code" := '';
          "VAT Registration No." := '';
          EXIT;
        END;

        GLSetup.GET;
        CASE TRUE OF
          ("Account Type" = "Account Type"::Customer) OR ("Bal. Account Type" = "Bal. Account Type"::Customer):
            BEGIN
              Cust.GET(No);
              "Country/Region Code" := Cust."Country/Region Code";
              "VAT Registration No." := Cust."VAT Registration No.";
            END;
          ("Account Type" = "Account Type"::Vendor) OR ("Bal. Account Type" = "Bal. Account Type"::Vendor):
            BEGIN
              Vend.GET(No);
              "Country/Region Code" := Vend."Country/Region Code";
              "VAT Registration No." := Vend."VAT Registration No.";
            END;
        END;
    end;
 
    procedure JobTaskIsSet(): Boolean
    begin
        EXIT(("Job No." <> '') AND ("Job Task No." <> '') AND ("Account Type" = "Account Type"::"G/L Account"));
    end;
 
    procedure CreateTempJobJnlLine()
    var
        TmpJobJnlOverallCurrencyFactor: Decimal;
    begin
        TESTFIELD("Posting Date");
        CLEAR(JobJnlLine);
        JobJnlLine.DontCheckStdCost;
        JobJnlLine.VALIDATE("Job No.","Job No.");
        JobJnlLine.VALIDATE("Job Task No.","Job Task No.");
        IF CurrFieldNo <> FIELDNO("Posting Date") THEN
          JobJnlLine.VALIDATE("Posting Date","Posting Date")
        ELSE
          JobJnlLine.VALIDATE("Posting Date",xRec."Posting Date");
        JobJnlLine.VALIDATE(Type,JobJnlLine.Type::"G/L Account");
        IF "Job Currency Code" <> '' THEN BEGIN
          IF "Posting Date" = 0D THEN
            CurrencyDate := WORKDATE
          ELSE
            CurrencyDate := "Posting Date";

          IF "Currency Code" = "Job Currency Code" THEN
            "Job Currency Factor" := "Currency Factor"
          ELSE
            "Job Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate,"Job Currency Code");
          JobJnlLine.SetCurrencyFactor("Job Currency Factor");
        END;
        JobJnlLine.VALIDATE("No.","Account No.");
        JobJnlLine.VALIDATE(Quantity,"Job Quantity");

        IF "Currency Factor" = 0 THEN BEGIN
          IF "Job Currency Factor" = 0 THEN
            TmpJobJnlOverallCurrencyFactor := 1
          ELSE
            TmpJobJnlOverallCurrencyFactor := "Job Currency Factor";
        END ELSE BEGIN
          IF "Job Currency Factor" = 0 THEN
            TmpJobJnlOverallCurrencyFactor := "Currency Factor"
          ELSE
            TmpJobJnlOverallCurrencyFactor := "Job Currency Factor" / "Currency Factor"
        END;

        IF "Job Quantity" <> 0 THEN
          JobJnlLine.VALIDATE("Unit Cost",((Amount - "VAT Amount") * TmpJobJnlOverallCurrencyFactor) / "Job Quantity");

        IF (xRec."Account No." = "Account No.") AND (xRec."Job Task No." = "Job Task No.") AND ("Job Unit Price" <> 0) THEN BEGIN
          JobJnlLine."Unit Price" := xRec."Job Unit Price";
          JobJnlLine."Line Amount" := xRec."Job Line Amount";
          JobJnlLine."Line Discount %" := xRec."Job Line Discount %";
          JobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
          JobJnlLine.VALIDATE("Unit Price");
        END;
    end;
 
    procedure UpdatePricesFromJobJnlLine()
    begin
        "Job Unit Price" := JobJnlLine."Unit Price";
        "Job Total Price" := JobJnlLine."Total Price";
        "Job Line Amount" := JobJnlLine."Line Amount";
        "Job Line Discount Amount" := JobJnlLine."Line Discount Amount";
        "Job Unit Cost" := JobJnlLine."Unit Cost";
        "Job Total Cost" := JobJnlLine."Total Cost";
        "Job Line Discount %" := JobJnlLine."Line Discount %";

        "Job Unit Price (LCY)" := JobJnlLine."Unit Price (LCY)";
        "Job Total Price (LCY)" := JobJnlLine."Total Price (LCY)";
        "Job Line Amount (LCY)" := JobJnlLine."Line Amount (LCY)";
        "Job Line Disc. Amount (LCY)" := JobJnlLine."Line Discount Amount (LCY)";
        "Job Unit Cost (LCY)" := JobJnlLine."Unit Cost (LCY)";
        "Job Total Cost (LCY)" := JobJnlLine."Total Cost (LCY)";
    end;
 
    procedure GetAppliesToDocDueDate(): Date
    var
        CustLedgEntry: Record "21";
        VendLedgEntry: Record "25";
    begin
        IF "Bal. Account Type" IN
          ["Bal. Account Type"::Customer,"Bal. Account Type"::Vendor]
        THEN BEGIN
          AccNo := "Bal. Account No.";
          AccType := "Bal. Account Type";
          CLEAR(CustLedgEntry);
          CLEAR(VendLedgEntry);
        END ELSE BEGIN
          AccNo := "Account No.";
          AccType := "Account Type";
          CLEAR(CustLedgEntry);
          CLEAR(VendLedgEntry);
        END;

        CASE AccType OF
          AccType::Customer:
            BEGIN
              CustLedgEntry.SETCURRENTKEY("Customer No.",Open,Positive,"Due Date");
              CustLedgEntry.SETRANGE("Customer No.",AccNo);
              CustLedgEntry.SETRANGE(Open,TRUE);
              IF "Applies-to Doc. No." <> '' THEN BEGIN
                CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                CustLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                IF NOT CustLedgEntry.FINDFIRST THEN BEGIN
                  CustLedgEntry.SETRANGE("Document Type");
                  CustLedgEntry.SETRANGE("Document No.");
                END;
              END ELSE
                IF "Applies-to ID" <> '' THEN BEGIN
                  CustLedgEntry.SETRANGE("Applies-to ID","Applies-to ID");
                  IF NOT CustLedgEntry.FINDFIRST THEN
                    CustLedgEntry.SETRANGE("Applies-to ID");
                END;
              EXIT(CustLedgEntry."Due Date");
            END;
          AccType::Vendor:
            BEGIN
              VendLedgEntry.SETCURRENTKEY("Vendor No.",Open,Positive,"Due Date");
              VendLedgEntry.SETRANGE("Vendor No.",AccNo);
              VendLedgEntry.SETRANGE(Open,TRUE);
              IF "Applies-to Doc. No." <> '' THEN BEGIN
                VendLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                VendLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                IF NOT VendLedgEntry.FINDFIRST THEN BEGIN
                  VendLedgEntry.SETRANGE("Document Type");
                  VendLedgEntry.SETRANGE("Document No.");
                END;
              END ELSE
                IF "Applies-to ID" <> '' THEN BEGIN
                  VendLedgEntry.SETRANGE("Applies-to ID","Applies-to ID");
                  IF NOT VendLedgEntry.FINDFIRST THEN
                    VendLedgEntry.SETRANGE("Applies-to ID");
                END;
              EXIT(VendLedgEntry."Due Date");
            END;
        END;
    end;
 
    procedure GetRetailSetup()
    begin
        //LS
        //GetRetailSetup

        IF NOT RetailSetupAlreadyRetrieved THEN BEGIN
          RetailSetup.GET;
          RetailSetupAlreadyRetrieved := TRUE;
        END;
    end;
 
    procedure TestCheckPrinted()
    begin
        //APNT-IBU1.1 -
        GenJnlLineRec.RESET;
        GenJnlLineRec.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlLineRec.SETRANGE("Journal Batch Name","Journal Batch Name");
        GenJnlLineRec.SETRANGE("Document No.","Document No.");
        IF GenJnlLineRec.FINDFIRST THEN BEGIN
          GenJnlLineRec.SETRANGE("Check Printed",TRUE);
          IF GenJnlLineRec.FINDFIRST THEN
            ERROR('Check Printed should be No for Document No. %1',GenJnlLineRec."Document No.");
        END;
        //APNT-IBU1.1 +
    end;
 
    procedure "--DP--"()
    begin
    end;
 
    procedure EditBankLine()
    var
        UserSetup: Record "91";
        RcptJnlLine: Record "81";
        PDCMgt: Codeunit "33016806";
    begin
        //DP6.01.01 START
        TESTFIELD(Approved,TRUE);

        UserSetup.GET(USERID);
        IF UserSetup."Edit Receipt Journal" THEN BEGIN
          RcptJnlLine.RESET;
          RcptJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
          RcptJnlLine.SETRANGE("Journal Batch Name","Journal Batch Name");
          RcptJnlLine.SETRANGE("Line No.","Line No.");
          RcptJnlLine.SETRANGE(Processed,FALSE);
          IF RcptJnlLine.FINDFIRST THEN BEGIN
            RcptJnlLine.VALIDATE(Approved,FALSE);
            RcptJnlLine.VALIDATE(Printed,FALSE);
            RcptJnlLine."Select Line" := FALSE;
            RcptJnlLine.MODIFY;
          END;
          PDCMgt.EditAppliedAgrmtEntries(RcptJnlLine);
        END ELSE
          ERROR(Text33016832,"Line No.");
        //DP6.01.01 STOP
    end;
 
    procedure ApproveBankLine(ToPrint: Boolean)
    var
        JournalLineRec: Record "81";
        JournalLineRec1: Record "81";
        JournalLineRec2: Record "81";
        UserSetup: Record "91";
        PDCMgt: Codeunit "33016806";
    begin
        //DP6.01.01 START
        UserSetup.GET(USERID);
        IF UserSetup."Approve Reciept Jnl" THEN BEGIN
          JournalLineRec.RESET;
          JournalLineRec.SETRANGE("Journal Template Name","Journal Template Name");
          JournalLineRec.SETRANGE("Journal Batch Name","Journal Batch Name");
          JournalLineRec.SETRANGE(Processed,FALSE);
          JournalLineRec.SETRANGE("Select Line",TRUE);
          IF JournalLineRec.COUNT = 0 THEN
            ERROR(Text33016838);

          JournalLineRec1.COPYFILTERS(JournalLineRec);
          IF JournalLineRec1.FINDSET THEN BEGIN
            REPEAT
              JournalLineRec1.TESTFIELD(Printed,FALSE);
              JournalLineRec1.TESTFIELD(Approved,FALSE);
              JournalLineRec1.TESTFIELD(Amount);
              IF JournalLineRec1."Applied Agrmt. Amount" <> 0 THEN
                IF JournalLineRec1."Credit Amount" <> JournalLineRec1."Applied Agrmt. Amount" THEN
                  ERROR(Text33016839,JournalLineRec1."Credit Amount");
            UNTIL JournalLineRec1.NEXT = 0;
          END;

          IF ToPrint THEN
            REPORT.RUN(REPORT::"Client Receipt",TRUE,FALSE,JournalLineRec);

          IF JournalLineRec.FINDSET THEN BEGIN
            REPEAT
              IF JournalLineRec."Applied Agrmt. Amount" <> 0 THEN
                PDCMgt.InsertAppliedAgrmtEntries(JournalLineRec);
              JournalLineRec2 := JournalLineRec;
              JournalLineRec2."Select Line" := FALSE;
              JournalLineRec2.VALIDATE(Approved,TRUE);
              JournalLineRec2.MODIFY;
            UNTIL JournalLineRec.NEXT = 0;
          END;
        END ELSE
          ERROR(Text33016837);

        //DP6.01.01 STOP
    end;
 
    procedure PrintReceipt()
    var
        JournalLineRec: Record "81";
        JournalLineRec1: Record "81";
        JournalLineRec2: Record "81";
        UserSetup: Record "91";
    begin
        //DP6.01.01 START
        JournalLineRec.RESET;
        JournalLineRec.SETRANGE("Journal Template Name","Journal Template Name");
        JournalLineRec.SETRANGE("Journal Batch Name","Journal Batch Name");
        JournalLineRec.SETRANGE(Processed,FALSE);
        JournalLineRec.SETRANGE("Select Line",TRUE);
        IF JournalLineRec.COUNT = 0 THEN
          ERROR(Text33016838);

        JournalLineRec1.COPYFILTERS(JournalLineRec);
        IF JournalLineRec1.FINDSET THEN BEGIN
          REPEAT
            JournalLineRec1.TESTFIELD(Approved,TRUE);
          UNTIL JournalLineRec1.NEXT = 0;
        END;

        REPORT.RUN(REPORT::"Client Receipt",TRUE,FALSE,JournalLineRec);
        //DP6.01.01 STOP
    end;
 
    procedure PrintReceiptCopy()
    var
        JournalLineRec: Record "81";
        JournalLineRec1: Record "81";
        JournalLineRec2: Record "81";
        UserSetup: Record "91";
    begin
        //DP6.01.01 START
        UserSetup.GET(USERID);
        IF UserSetup."Print Receipt Copy" THEN BEGIN
          JournalLineRec.RESET;
          JournalLineRec.SETRANGE("Journal Template Name","Journal Template Name");
          JournalLineRec.SETRANGE("Journal Batch Name","Journal Batch Name");
          JournalLineRec.SETRANGE(Processed,FALSE);
          JournalLineRec.SETRANGE("Select Line",TRUE);
          IF JournalLineRec.COUNT = 0 THEN
            ERROR(Text33016838);

          JournalLineRec1.COPYFILTERS(JournalLineRec);
          IF JournalLineRec1.FINDSET THEN BEGIN
            REPEAT
              JournalLineRec1.TESTFIELD(Printed,TRUE);
            UNTIL JournalLineRec1.NEXT = 0;
          END;

          REPORT.RUN(REPORT::"Client Receipt Copy",TRUE,FALSE,JournalLineRec);

          IF JournalLineRec.FINDSET THEN BEGIN
            REPEAT
              JournalLineRec2 := JournalLineRec;
              JournalLineRec2."Select Line" := FALSE;
              JournalLineRec2.MODIFY;
            UNTIL JournalLineRec.NEXT = 0;
          END;
        END ELSE
          ERROR(Text33016836);
        //DP6.01.01 STOP
    end;
 
    procedure UnProcessRcptJournal()
    var
        JournalLineRec: Record "81";
        JournalLineRec1: Record "81";
        JournalLineRec2: Record "81";
    begin
        //DP6.01.01 START
        JournalLineRec.RESET;
        JournalLineRec.SETRANGE("Journal Template Name","Journal Template Name");
        JournalLineRec.SETRANGE("Journal Batch Name","Journal Batch Name");
        JournalLineRec.SETRANGE(Processed,TRUE);
        JournalLineRec.SETRANGE("Select Line",TRUE);
        IF JournalLineRec.COUNT = 0 THEN
          ERROR(Text33016838);

        IF JournalLineRec.FINDSET THEN BEGIN
          REPEAT
            JournalLineRec2 := JournalLineRec;
            JournalLineRec2.Processed := FALSE;
            JournalLineRec2."Select Line" := FALSE;
            JournalLineRec2.MODIFY;
          UNTIL JournalLineRec.NEXT = 0;
        END;
        //DP6.01.01 STOP
    end;
}

