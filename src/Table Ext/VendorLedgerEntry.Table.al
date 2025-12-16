table 25 "Vendor Ledger Entry"
{
    // Code          Date      Name        Description
    // APNT-JDE      31.12.11  Tanweer     Added Key No. 16 for JDE Customization
    // APNT-IBU1.0   31.07.11  Tanweer     Added fields for Inter BU Customization
    // APNT-FIN1.0   08.09.11  Tanweer     Added field for Finance Customization
    // APNT-JDE      18.09.11  Shameema    Added Key No. 17 for JDE Customization
    // DP = changes made by DVS
    // LALS          08.10.19  Ganesh      Added new feild invocie reciv data

    Caption = 'Vendor Ledger Entry';
    DrillDownFormID = Form29;
    LookupFormID = Form29;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
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
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry".Amount WHERE(Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                          Entry Type=FILTER(Initial Entry|Unrealized Loss|Unrealized Gain|Realized Loss|Realized Gain|Payment Discount|'Payment Discount (VAT Excl.)'|'Payment Discount (VAT Adjustment)'|Payment Tolerance|Payment Discount Tolerance|'Payment Tolerance (VAT Excl.)'|'Payment Tolerance (VAT Adjustment)'|'Payment Discount Tolerance (VAT Excl.)'|'Payment Discount Tolerance (VAT Adjustment)'),
                                                                          Posting Date=FIELD(Date Filter)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14;"Remaining Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry".Amount WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                          Posting Date=FIELD(Date Filter)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15;"Original Amt. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                  Entry Type=FILTER(Initial Entry),
                                                                                  Posting Date=FIELD(Date Filter)));
            Caption = 'Original Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16;"Remaining Amt. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                  Posting Date=FIELD(Date Filter)));
            Caption = 'Remaining Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17;"Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                  Entry Type=FILTER(Initial Entry|Unrealized Loss|Unrealized Gain|Realized Loss|Realized Gain|Payment Discount|'Payment Discount (VAT Excl.)'|'Payment Discount (VAT Adjustment)'|Payment Tolerance|Payment Discount Tolerance|'Payment Tolerance (VAT Excl.)'|'Payment Tolerance (VAT Adjustment)'|'Payment Discount Tolerance (VAT Excl.)'|'Payment Discount Tolerance (VAT Adjustment)'),
                                                                                  Posting Date=FIELD(Date Filter)));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18;"Purchase (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Purchase (LCY)';
        }
        field(20;"Inv. Discount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(21;"Buy-from Vendor No.";Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            TableRelation = Vendor;
        }
        field(22;"Vendor Posting Group";Code[10])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
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
        field(25;"Purchaser Code";Code[10])
        {
            Caption = 'Purchaser Code';
            TableRelation = Salesperson/Purchaser;
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
        field(33;"On Hold";Code[3])
        {
            Caption = 'On Hold';
        }
        field(34;"Applies-to Doc. Type";Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(35;"Applies-to Doc. No.";Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(36;Open;Boolean)
        {
            Caption = 'Open';
        }
        field(37;"Due Date";Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
            end;
        }
        field(38;"Pmt. Discount Date";Date)
        {
            Caption = 'Pmt. Discount Date';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
            end;
        }
        field(39;"Original Pmt. Disc. Possible";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            Editable = false;
        }
        field(40;"Pmt. Disc. Rcd.(LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Rcd.(LCY)';
        }
        field(43;Positive;Boolean)
        {
            Caption = 'Positive';
        }
        field(44;"Closed by Entry No.";Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(45;"Closed at Date";Date)
        {
            Caption = 'Closed at Date';
        }
        field(46;"Closed by Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
        }
        field(47;"Applies-to ID";Code[20])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
            end;
        }
        field(49;"Journal Batch Name";Code[10])
        {
            Caption = 'Journal Batch Name';
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(50;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(52;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Bal. Account Type=CONST(Fixed Asset)) "Fixed Asset";
        }
        field(53;"Transaction No.";Integer)
        {
            Caption = 'Transaction No.';
        }
        field(54;"Closed by Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Closed by Amount (LCY)';
        }
        field(58;"Debit Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Debit Amount" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                  Entry Type=FILTER(<>Application),
                                                                                  Posting Date=FIELD(Date Filter)));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59;"Credit Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Credit Amount" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                   Entry Type=FILTER(<>Application),
                                                                                   Posting Date=FIELD(Date Filter)));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60;"Debit Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Debit Amount (LCY)" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                        Entry Type=FILTER(<>Application),
                                                                                        Posting Date=FIELD(Date Filter)));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61;"Credit Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry"."Credit Amount (LCY)" WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                                         Entry Type=FILTER(<>Application),
                                                                                         Posting Date=FIELD(Date Filter)));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62;"Document Date";Date)
        {
            Caption = 'Document Date';
        }
        field(63;"External Document No.";Code[20])
        {
            Caption = 'External Document No.';
        }
        field(64;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(65;"Closed by Currency Code";Code[10])
        {
            Caption = 'Closed by Currency Code';
            TableRelation = Currency;
        }
        field(66;"Closed by Currency Amount";Decimal)
        {
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
        }
        field(73;"Adjusted Currency Factor";Decimal)
        {
            Caption = 'Adjusted Currency Factor';
            DecimalPlaces = 0:15;
        }
        field(74;"Original Currency Factor";Decimal)
        {
            Caption = 'Original Currency Factor';
            DecimalPlaces = 0:15;
        }
        field(75;"Original Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Vendor Ledg. Entry".Amount WHERE (Vendor Ledger Entry No.=FIELD(Entry No.),
                                                                          Entry Type=FILTER(Initial Entry),
                                                                          Posting Date=FIELD(Date Filter)));
            Caption = 'Original Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76;"Date Filter";Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(77;"Remaining Pmt. Disc. Possible";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
                CALCFIELDS(Amount,"Original Amount");

                IF "Remaining Pmt. Disc. Possible" * Amount < 0 THEN
                  FIELDERROR("Remaining Pmt. Disc. Possible",STRSUBSTNO(Text000,FIELDCAPTION(Amount)));

                IF ABS("Remaining Pmt. Disc. Possible") > ABS("Original Amount") THEN
                  FIELDERROR("Remaining Pmt. Disc. Possible",STRSUBSTNO(Text001,FIELDCAPTION("Original Amount")));
            end;
        }
        field(78;"Pmt. Disc. Tolerance Date";Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
            end;
        }
        field(79;"Max. Payment Tolerance";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
                CALCFIELDS(Amount,"Remaining Amount");

                IF "Max. Payment Tolerance" * Amount < 0 THEN
                  FIELDERROR("Max. Payment Tolerance",STRSUBSTNO(Text000,FIELDCAPTION(Amount)));

                IF ABS("Max. Payment Tolerance") > ABS("Remaining Amount") THEN
                  FIELDERROR("Max. Payment Tolerance",STRSUBSTNO(Text001,FIELDCAPTION("Remaining Amount")));
            end;
        }
        field(81;"Accepted Payment Tolerance";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Accepted Payment Tolerance';
        }
        field(82;"Accepted Pmt. Disc. Tolerance";Boolean)
        {
            Caption = 'Accepted Pmt. Disc. Tolerance';
        }
        field(83;"Pmt. Tolerance (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Tolerance (LCY)';
        }
        field(84;"Amount to Apply";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Apply';

            trigger OnValidate()
            begin
                TESTFIELD(Open,TRUE);
                CALCFIELDS("Remaining Amount");

                IF "Amount to Apply" * "Remaining Amount" < 0 THEN
                  FIELDERROR("Amount to Apply",STRSUBSTNO(Text000,FIELDCAPTION("Remaining Amount")));

                IF ABS("Amount to Apply") > ABS("Remaining Amount") THEN
                  FIELDERROR("Amount to Apply",STRSUBSTNO(Text001,FIELDCAPTION("Remaining Amount")));
            end;
        }
        field(85;"IC Partner Code";Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(86;"Applying Entry";Boolean)
        {
            Caption = 'Applying Entry';
        }
        field(87;Reversed;Boolean)
        {
            Caption = 'Reversed';
        }
        field(88;"Reversed by Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(89;"Reversed Entry No.";Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(90;Prepayment;Boolean)
        {
            Caption = 'Prepayment';
        }
        field(50000;"IBU Entry";Boolean)
        {
            Description = 'IBU1.0';
        }
        field(50002;"IPC Bal. Account Type";Option)
        {
            Description = 'IBU1.0';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
        }
        field(50003;"IPC Bal. Account No.";Code[20])
        {
            Description = 'IBU1.0';
        }
        field(50004;"Facility Type";Option)
        {
            Description = 'APNT-FIN1.0';
            OptionCaption = ' ,Over Draft,Letter of Credit,Trust Receipt,Loans,Bank Facility';
            OptionMembers = " ","Over Draft","Letter of Credit","Trust Receipt",Loans,"Bank Facility";
            TableRelation = "Hierarchy Nodes"."Hierarchy Code";
        }
        field(50005;"Facility No.";Code[20])
        {
            Description = 'APNT-FIN1.0';
        }
        field(50006;"Charges Type";Option)
        {
            Description = 'APNT-FIN1.0';
            OptionCaption = ' ,Legalization,Bank,Issuance Comm.,Amendment,Interest';
            OptionMembers = " ",Legalization,Bank,"Issuance Comm.",Amendment,Interest;
        }
        field(50013;"Invoice Received Date";Date)
        {
            Description = 'LALS';
        }
        field(50203;Remarks;Text[250])
        {
            Description = 'APNT-PV1.0';
        }
        field(33016800;"Ref. Document Type";Option)
        {
            Description = 'DP6.01.01';
            Editable = false;
            OptionCaption = 'Lease,Sale,Work Order';
            OptionMembers = Lease,Sale,"Work Order";
        }
        field(33016801;"Ref. Document No.";Code[20])
        {
            Description = 'DP6.01.01';
            Editable = false;
            TableRelation = IF (Ref. Document Type=FILTER(Lease|Sale)) "Agreement Header".No.
                            ELSE IF (Ref. Document Type=FILTER(Work Order)) "Work Order Header".No.;
        }
        field(33016802;"Ref. Document Line No.";Integer)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
    }

    keys
    {
        key(Key1;"Entry No.")
        {
            Clustered = true;
        }
        key(Key2;"Vendor No.","Posting Date","Currency Code")
        {
            SumIndexFields = "Purchase (LCY)","Inv. Discount (LCY)";
        }
        key(Key3;"Document No.")
        {
        }
        key(Key4;"External Document No.")
        {
        }
        key(Key5;"Vendor No.",Open,Positive,"Due Date","Currency Code")
        {
        }
        key(Key6;Open,"Due Date")
        {
        }
        key(Key7;"Document Type","Vendor No.","Posting Date","Currency Code")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Purchase (LCY)","Inv. Discount (LCY)";
        }
        key(Key8;"Closed by Entry No.")
        {
        }
        key(Key9;"Transaction No.")
        {
        }
        key(Key10;"Vendor No.","Applies-to ID",Open,Positive,"Due Date")
        {
        }
        key(Key11;"Document No.","Document Type","Vendor No.")
        {
        }
        key(Key12;"Document No.","Vendor No.","Currency Code","External Document No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"Entry No.",Description,"Vendor No.","Posting Date","Document Type","Document No.")
        {
        }
    }

    var
        Text000: Label 'must have the same sign as %1';
        Text001: Label 'must not be larger than %1';
        VendorLedgEntry: Record "25";
 
    procedure DrillDownOnEntries(var DtldVendLedgEntry: Record "380")
    var
        VendLedgEntry: Record "25";
    begin
        VendLedgEntry.RESET;
        DtldVendLedgEntry.COPYFILTER("Vendor No.",VendLedgEntry."Vendor No.");
        DtldVendLedgEntry.COPYFILTER("Currency Code",VendLedgEntry."Currency Code");
        DtldVendLedgEntry.COPYFILTER("Initial Entry Global Dim. 1",VendLedgEntry."Global Dimension 1 Code");
        DtldVendLedgEntry.COPYFILTER("Initial Entry Global Dim. 2",VendLedgEntry."Global Dimension 2 Code");
        VendLedgEntry.SETCURRENTKEY("Vendor No.","Posting Date");
        VendLedgEntry.SETRANGE(Open,TRUE);
        FORM.RUN(0,VendLedgEntry);
    end;
 
    procedure DrillDownOnOverdueEntries(var DtldVendLedgEntry: Record "380")
    var
        VendLedgEntry: Record "25";
    begin
        VendLedgEntry.RESET;
        DtldVendLedgEntry.COPYFILTER("Vendor No.",VendLedgEntry."Vendor No.");
        DtldVendLedgEntry.COPYFILTER("Currency Code",VendLedgEntry."Currency Code");
        DtldVendLedgEntry.COPYFILTER("Initial Entry Global Dim. 1",VendLedgEntry."Global Dimension 1 Code");
        DtldVendLedgEntry.COPYFILTER("Initial Entry Global Dim. 2",VendLedgEntry."Global Dimension 2 Code");
        VendLedgEntry.SETCURRENTKEY("Vendor No.","Posting Date");
        VendLedgEntry.SETFILTER("Date Filter",'..%1',WORKDATE);
        VendLedgEntry.SETFILTER("Due Date",'..%1',WORKDATE);
        VendLedgEntry.SETFILTER("Remaining Amount",'<>%1',0);
        FORM.RUN(0,VendLedgEntry);
    end;
 
    procedure GetOriginalCurrencyFactor(): Decimal
    begin
        IF "Original Currency Factor" = 0 THEN
          EXIT(1);
        EXIT("Original Currency Factor");
    end;
}

