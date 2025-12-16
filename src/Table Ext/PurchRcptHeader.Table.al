table 120 "Purch. Rcpt. Header"
{
    // LS = changes made by LS Retail
    // Code          Date      Name          Description
    // APNT-CO1.0    16.08.10  Tanweer       Added fields for Costing Customization
    // APNT-JDE      31.12.11  Tanweer       Added fields for JDE Customization
    // APNT-1.0      07.09.11  Tanweer       Added field
    // APNT-IC1.0    19.04.12  Tanweer       Added fields for IC Customization
    // APNT-CO2.0    07.05.12  Ashish        Added fields for Costing Customization (Sequence no. added)
    // APNT-HHT1.0   01.11.12  Sujith        Added fields for HHT Customization
    // DP = changes made by DVS
    // T008434       17.11.15  Shameema      Added for batch posting
    // APNT-WMS1.0   23.11.16  Sujith        Added field and Key No 7 for WMS Palm Integration.

    Caption = 'Purch. Rcpt. Header';
    DataCaptionFields = "No.", "Buy-from Vendor Name";
    LookupFormID = Form145;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(5; "Pay-to Name"; Text[50])
        {
            Caption = 'Pay-to Name';
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
        }
        field(7; "Pay-to Address"; Text[50])
        {
            Caption = 'Pay-to Address';
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity("Pay-to City", "Pay-to Post Code", FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Pay-to City", "Pay-to Post Code");
            end;
        }
        field(10; "Pay-to Contact"; Text[50])
        {
            Caption = 'Pay-to Contact';
        }
        field(11; "Your Reference"; Text[30])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE(Customer No.=FIELD(Sell-to Customer No.));
        }
        field(13;"Ship-to Name";Text[50])
        {
            Caption = 'Ship-to Name';
        }
        field(14;"Ship-to Name 2";Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15;"Ship-to Address";Text[50])
        {
            Caption = 'Ship-to Address';
        }
        field(16;"Ship-to Address 2";Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17;"Ship-to City";Text[30])
        {
            Caption = 'Ship-to City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity("Ship-to City","Ship-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Ship-to City","Ship-to Post Code");
            end;
        }
        field(18;"Ship-to Contact";Text[50])
        {
            Caption = 'Ship-to Contact';
        }
        field(19;"Order Date";Date)
        {
            Caption = 'Order Date';
        }
        field(20;"Posting Date";Date)
        {
            Caption = 'Posting Date';
        }
        field(21;"Expected Receipt Date";Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(22;"Posting Description";Text[50])
        {
            Caption = 'Posting Description';
        }
        field(23;"Payment Terms Code";Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(24;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(25;"Payment Discount %";Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0:5;
        }
        field(26;"Pmt. Discount Date";Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27;"Shipment Method Code";Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(28;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE (Use As In-Transit=CONST(No));

            trigger OnLookup()
            var
                lBOUtils: Codeunit "99001452";
            begin
                VALIDATE("Location Code", lBOUtils.LookupLocation("Store No.", "Location Code"));  //LS
            end;

            trigger OnValidate()
            var
                lBOUtils: Codeunit "99001452";
            begin
                //LS -
                IF "Location Code" <> '' THEN
                  lBOUtils.StoreLocationOk("Store No.", "Location Code");
                //LS +
            end;
        }
        field(29;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));
        }
        field(30;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));
        }
        field(31;"Vendor Posting Group";Code[10])
        {
            Caption = 'Vendor Posting Group';
            Editable = false;
            TableRelation = "Vendor Posting Group";
        }
        field(32;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(33;"Currency Factor";Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0:15;
            MinValue = 0;
        }
        field(37;"Invoice Disc. Code";Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        field(41;"Language Code";Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(43;"Purchaser Code";Code[10])
        {
            Caption = 'Purchaser Code';
            TableRelation = Salesperson/Purchaser;
        }
        field(44;"Order No.";Code[20])
        {
            Caption = 'Order No.';
        }
        field(46;Comment;Boolean)
        {
            CalcFormula = Exist("Purch. Comment Line" WHERE (Document Type=CONST(Receipt),
                                                             No.=FIELD(No.),
                                                             Document Line No.=CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47;"No. Printed";Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(51;"On Hold";Code[3])
        {
            Caption = 'On Hold';
        }
        field(52;"Applies-to Doc. Type";Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(53;"Applies-to Doc. No.";Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            begin
                VendLedgEntry.SETCURRENTKEY("Document No.");
                VendLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                VendLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                FORM.RUN(0,VendLedgEntry);
            end;
        }
        field(55;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account";
        }
        field(66;"Vendor Order No.";Code[20])
        {
            Caption = 'Vendor Order No.';
        }
        field(67;"Vendor Shipment No.";Code[20])
        {
            Caption = 'Vendor Shipment No.';
        }
        field(70;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(72;"Sell-to Customer No.";Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(73;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(76;"Transaction Type";Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(77;"Transport Method";Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(78;"VAT Country/Region Code";Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = Country/Region;
        }
        field(79;"Buy-from Vendor Name";Text[50])
        {
            Caption = 'Buy-from Vendor Name';
        }
        field(80;"Buy-from Vendor Name 2";Text[50])
        {
            Caption = 'Buy-from Vendor Name 2';
        }
        field(81;"Buy-from Address";Text[50])
        {
            Caption = 'Buy-from Address';
        }
        field(82;"Buy-from Address 2";Text[50])
        {
            Caption = 'Buy-from Address 2';
        }
        field(83;"Buy-from City";Text[30])
        {
            Caption = 'Buy-from City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity("Buy-from City","Buy-from Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Buy-from City","Buy-from Post Code");
            end;
        }
        field(84;"Buy-from Contact";Text[50])
        {
            Caption = 'Buy-from Contact';
        }
        field(85;"Pay-to Post Code";Code[20])
        {
            Caption = 'Pay-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode("Pay-to City","Pay-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Pay-to City","Pay-to Post Code");
            end;
        }
        field(86;"Pay-to County";Text[30])
        {
            Caption = 'Pay-to County';
        }
        field(87;"Pay-to Country/Region Code";Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            TableRelation = Country/Region;
        }
        field(88;"Buy-from Post Code";Code[20])
        {
            Caption = 'Buy-from Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode("Buy-from City","Buy-from Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Buy-from City","Buy-from Post Code");
            end;
        }
        field(89;"Buy-from County";Text[30])
        {
            Caption = 'Buy-from County';
        }
        field(90;"Buy-from Country/Region Code";Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
            TableRelation = Country/Region;
        }
        field(91;"Ship-to Post Code";Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode("Ship-to City","Ship-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Ship-to City","Ship-to Post Code");
            end;
        }
        field(92;"Ship-to County";Text[30])
        {
            Caption = 'Ship-to County';
        }
        field(93;"Ship-to Country/Region Code";Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = Country/Region;
        }
        field(94;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(95;"Order Address Code";Code[10])
        {
            Caption = 'Order Address Code';
            TableRelation = "Order Address".Code WHERE (Vendor No.=FIELD(Buy-from Vendor No.));
        }
        field(97;"Entry Point";Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(98;Correction;Boolean)
        {
            Caption = 'Correction';
        }
        field(99;"Document Date";Date)
        {
            Caption = 'Document Date';
        }
        field(101;"Area";Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(102;"Transaction Specification";Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(104;"Payment Method Code";Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(109;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(110;"Order No. Series";Code[10])
        {
            Caption = 'Order No. Series';
            TableRelation = "No. Series";
        }
        field(112;"User ID";Code[20])
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
        field(113;"Source Code";Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(114;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(115;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(116;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(119;"VAT Base Discount %";Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(151;"Quote No.";Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(5050;"Campaign No.";Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052;"Buy-from Contact No.";Code[20])
        {
            Caption = 'Buy-from Contact No.';
            TableRelation = Contact;
        }
        field(5053;"Pay-to Contact no.";Code[20])
        {
            Caption = 'Pay-to Contact no.';
            TableRelation = Contact;
        }
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5790;"Requested Receipt Date";Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        field(5791;"Promised Receipt Date";Date)
        {
            Caption = 'Promised Receipt Date';
            Editable = false;
        }
        field(5792;"Lead Time Calculation";DateFormula)
        {
            Caption = 'Lead Time Calculation';
            Editable = false;
        }
        field(5793;"Inbound Whse. Handling Time";DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';
            Editable = false;
        }
        field(50001;"Total Landed Cost (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Description = 'APNT-CO1.0';
            Editable = false;
        }
        field(50002;"Cost Factor";Decimal)
        {
            DecimalPlaces = 0:2;
            Description = 'APNT-CO1.0';
            Editable = false;
        }
        field(50005;"No Item Charges";Boolean)
        {
            Description = 'APNT-CO1.0';
        }
        field(50006;"Exported to JDE";Boolean)
        {
            Description = 'JDE';
        }
        field(50007;"Vendor Invoice Amount";Decimal)
        {
            CalcFormula = Sum("Purch. Inv. Line".Amount WHERE (Document No.=FIELD(No.)));
            Description = 'JDE';
            FieldClass = FlowField;
        }
        field(50008;"Line Discount";Decimal)
        {
            CalcFormula = Sum("Purch. Inv. Line"."Line Discount Amount" WHERE (Document No.=FIELD(No.)));
            Description = 'JDE';
            FieldClass = FlowField;
        }
        field(50009;"Order Reference";Code[20])
        {
            Description = 'APNT-1.0';
        }
        field(50010;"IC Transaction No.";Integer)
        {
            Description = 'IC1.0';
        }
        field(50011;"IC Partner Direction";Option)
        {
            Description = 'IC1.0';
            OptionCaption = ' ,Outgoing,Incoming';
            OptionMembers = " ",Outgoing,Incoming;
        }
        field(50100;"Receipt Confirmed from HHT";Boolean)
        {
            Description = 'HHT1.0';
        }
        field(50101;"Receipt Confirmed By";Code[20])
        {
            Description = 'HHT1.0';
            TableRelation = User;
        }
        field(50102;"Receipt Confirmed On";Date)
        {
            Description = 'HHT1.0';
        }
        field(50150;"Batch Post";Boolean)
        {
            Description = 'T008434';
        }
        field(50151;"Batch Post - User ID";Code[20])
        {
            Description = 'T008434';
        }
        field(50152;"Batch Post - DateTime";DateTime)
        {
            Description = 'T008434';
        }
        field(50171;Sequence;Integer)
        {
            Description = 'CO2.0';
            InitValue = 1;
        }
        field(50200;"WMS Exported";Boolean)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50201;"From Port Post Code";Code[20])
        {
            Caption = 'From Port Post Code';
            Description = 'APNT-WMS1.0';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(50202;"From Port City";Text[30])
        {
            Caption = 'From Port  City';
            Description = 'APNT-WMS1.0';
        }
        field(50203;"To Port Post Code";Code[20])
        {
            Caption = 'To Port Post Code';
            Description = 'APNT-WMS1.0';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(50204;"To Port City";Text[30])
        {
            Caption = 'To Port  City';
            Description = 'APNT-WMS1.0';
        }
        field(50205;"Vendor Invoice Date";Date)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50206;"Sent Request";Boolean)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50207;"Sent Request By";Code[20])
        {
            Description = 'APNT-WMS1.0';
            TableRelation = "User Setup";
        }
        field(50208;"Sent Request Date";Date)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50209;"Sent Request Time";Time)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50210;"Dispatch Order Number";Code[20])
        {
            Description = 'APNT-WMS1.0';
        }
        field(50700;"Vendor Invoice No.";Code[20])
        {
            Description = 'APNT-WMS1.0';
        }
        field(10000700;"Store No.";Code[10])
        {
            Caption = 'Store No.';
            TableRelation = Store;

            trigger OnValidate()
            var
                lStore: Record "99001470";
            begin
                //LS -
                "Location Code" := '';
                IF "Store No." <> '' THEN
                  IF lStore.GET("Store No.") THEN
                    "Location Code" := lStore."Location Code";
                //LS +
            end;
        }
        field(10001300;"Retail Status";Option)
        {
            Caption = 'Retail Status';
            OptionCaption = 'New,Sent, Part. receipt,Closed - ok,Closed - difference';
            OptionMembers = New,Sent," Part. receipt","Closed - ok","Closed - difference";
        }
        field(10001301;"Receiving/Picking No.";Code[20])
        {
            Caption = 'Receiving/Picking No.';
            TableRelation = "Posted P/R Counting Header";
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
            TableRelation = IF (Ref. Document Type=FILTER(Sale|Lease)) "Agreement Header".No.
                            ELSE IF (Ref. Document Type=FILTER(Work Order)) "Work Order Header".No.;
        }
        field(99008500;"Date Received";Date)
        {
            Caption = 'Date Received';
        }
        field(99008501;"Time Received";Time)
        {
            Caption = 'Time Received';
        }
        field(99008507;"BizTalk Purchase Receipt";Boolean)
        {
            Caption = 'BizTalk Purchase Receipt';
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Order No.")
        {
        }
        key(Key3;"Pay-to Vendor No.")
        {
        }
        key(Key4;"Buy-from Vendor No.")
        {
        }
        key(Key5;"Receiving/Picking No.")
        {
        }
        key(Key6;"Vendor Invoice No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"No.","Buy-from Vendor No.","Pay-to Vendor No.","Posting Date","Posting Description")
        {
        }
    }

    trigger OnDelete()
    begin
        LOCKTABLE;
        PostPurchLinesDelete.DeletePurchRcptLines(Rec);

        PurchCommentLine.SETRANGE("Document Type",PurchCommentLine."Document Type"::Receipt);
        PurchCommentLine.SETRANGE("No.","No.");
        PurchCommentLine.DELETEALL;

        DimMgt.DeletePostedDocDim(DATABASE::"Purch. Rcpt. Header","No.",0);

        ApprovalsMgt.DeletePostedApprovalEntry(DATABASE::"Purch. Rcpt. Header","No.");
    end;

    var
        PurchRcptHeader: Record "120";
        PurchCommentLine: Record "43";
        VendLedgEntry: Record "25";
        PostCode: Record "225";
        PostPurchLinesDelete: Codeunit "364";
        DimMgt: Codeunit "408";
        ApprovalsMgt: Codeunit "439";
 
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "77";
    begin
        WITH PurchRcptHeader DO BEGIN
          COPY(Rec);
          ReportSelection.SETRANGE(Usage,ReportSelection.Usage::"P.Receipt");
          ReportSelection.SETFILTER("Report ID",'<>0');
          ReportSelection.FIND('-');
          REPEAT
            REPORT.RUNMODAL(ReportSelection."Report ID",ShowRequestForm,FALSE,PurchRcptHeader);
          UNTIL ReportSelection.NEXT = 0;
        END;
    end;
 
    procedure Navigate()
    var
        NavigateForm: Form "344";
    begin
        NavigateForm.SetDoc("Posting Date","No.");
        NavigateForm.RUN;
    end;
}

