table 114 "Sales Cr.Memo Header"
{
    // Code          Date      Name          Description
    // APNT-LD1.0    26.07.10  Tanweer       Added code for Linked Dimensions Customization
    // APNT-ID1.0    17.08.10  Tanweer       Added fields for Invoice Discount Customization
    // APNT-JDE      31.12.11  Tanweer       Added fields for JDE Customization
    // APNT-1.0      15.10.11  Tanweer       Added field for Markup functionality
    // APNT-IC1.0    19.04.12  Tanweer       Added fields for IC Customization
    // APNT-HHT1.0   01.11.12  Sujith        Added fields for HHT Customization
    // DP = changes made by DVS
    // APNT-HRU1.0   26.11.13  Sangeeta      Added fields for HRU Customization.
    // APNT-HRU1.0   23.07.14  Sangeeta      Added Cancellation date for HRU Customization..
    // T004906       18.09.14  Tanweer       Added field 50017
    // APNT-T006863  12.04.15  Sangeeta      Added Cashier ID,
    // T008434       17.11.15  Shameema      Added for batch posting
    // APNT-WMS1.0   23.11.16  Sujith        Added field for WMS Palm Integration.
    // APNT-eCom     17.12.20  Sujith        Added code eCom integration
    // eCom-CR       25.02.21  Sujith        Added field for eCommerce integration CR

    Caption = 'Sales Cr.Memo Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    LookupFormID = Form144;

    fields
    {
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[50])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[50])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity("Bill-to City", "Bill-to Post Code", FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Bill-to City", "Bill-to Post Code");
            end;
        }
        field(10; "Bill-to Contact"; Text[50])
        {
            Caption = 'Bill-to Contact';
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
        field(20;"Posting Date";Date)
        {
            Caption = 'Posting Date';
        }
        field(21;"Shipment Date";Date)
        {
            Caption = 'Shipment Date';
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
        field(31;"Customer Posting Group";Code[10])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
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
        field(34;"Customer Price Group";Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(35;"Prices Including VAT";Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(37;"Invoice Disc. Code";Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        field(40;"Customer Disc. Group";Code[10])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(41;"Language Code";Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(43;"Salesperson Code";Code[10])
        {
            Caption = 'Salesperson Code';
            TableRelation = Salesperson/Purchaser;
        }
        field(46;Comment;Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE (Document Type=CONST(Posted Credit Memo),
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
                CustLedgEntry.SETCURRENTKEY("Document No.");
                CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                CustLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                FORM.RUN(0,CustLedgEntry);
            end;
        }
        field(55;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account";
        }
        field(60;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Cr.Memo Line".Amount WHERE (Document No.=FIELD(No.)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61;"Amount Including VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Cr.Memo Line"."Amount Including VAT" WHERE (Document No.=FIELD(No.)));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';
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
        field(75;"EU 3-Party Trade";Boolean)
        {
            Caption = 'EU 3-Party Trade';
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
        field(79;"Sell-to Customer Name";Text[50])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(80;"Sell-to Customer Name 2";Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
        }
        field(81;"Sell-to Address";Text[50])
        {
            Caption = 'Sell-to Address';
        }
        field(82;"Sell-to Address 2";Text[50])
        {
            Caption = 'Sell-to Address 2';
        }
        field(83;"Sell-to City";Text[30])
        {
            Caption = 'Sell-to City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity("Sell-to City","Sell-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Sell-to City","Sell-to Post Code");
            end;
        }
        field(84;"Sell-to Contact";Text[50])
        {
            Caption = 'Sell-to Contact';
        }
        field(85;"Bill-to Post Code";Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode("Bill-to City","Bill-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Bill-to City","Bill-to Post Code");
            end;
        }
        field(86;"Bill-to County";Text[30])
        {
            Caption = 'Bill-to County';
        }
        field(87;"Bill-to Country/Region Code";Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = Country/Region;
        }
        field(88;"Sell-to Post Code";Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode("Sell-to City","Sell-to Post Code",FALSE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Sell-to City","Sell-to Post Code");
            end;
        }
        field(89;"Sell-to County";Text[30])
        {
            Caption = 'Sell-to County';
        }
        field(90;"Sell-to Country/Region Code";Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
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
        field(97;"Exit Point";Code[10])
        {
            Caption = 'Exit Point';
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
        field(100;"External Document No.";Code[20])
        {
            Caption = 'External Document No.';
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
        field(107;"Pre-Assigned No. Series";Code[10])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(108;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(111;"Pre-Assigned No.";Code[20])
        {
            Caption = 'Pre-Assigned No.';
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
        field(134;"Prepmt. Cr. Memo No. Series";Code[10])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        field(136;"Prepayment Credit Memo";Boolean)
        {
            Caption = 'Prepayment Credit Memo';
        }
        field(137;"Prepayment Order No.";Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        field(5050;"Campaign No.";Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052;"Sell-to Contact No.";Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
        }
        field(5053;"Bill-to Contact No.";Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
        }
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5900;"Service Mgt. Document";Boolean)
        {
            Caption = 'Service Mgt. Document';
        }
        field(6601;"Return Order No.";Code[20])
        {
            Caption = 'Return Order No.';
        }
        field(6602;"Return Order No. Series";Code[10])
        {
            Caption = 'Return Order No. Series';
            TableRelation = "No. Series";
        }
        field(7001;"Allow Line Disc.";Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(7200;"Get Return Receipt Used";Boolean)
        {
            Caption = 'Get Return Receipt Used';
        }
        field(50001;"Credit Sales";Boolean)
        {
            CalcFormula = Exist("Sales Invoice Line" WHERE (Document No.=FIELD(No.),
                                                            Description=CONST("CUSTOMER AED-P ")));
            Description = 'JDE';
            FieldClass = FlowField;
        }
        field(50002;"Exported to JDE";Boolean)
        {
            Description = 'JDE';
        }
        field(50003;"Invoice Discount %";Decimal)
        {
            Description = 'ID1.0';
        }
        field(50004;"Invoice Discount Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Description = 'ID1.0';
        }
        field(50005;"Markup %";Decimal)
        {
            Description = 'APNT-1.0';
        }
        field(50006;"IC Transaction No.";Integer)
        {
            Description = 'IC1.0';
        }
        field(50007;"IC Partner Direction";Option)
        {
            Description = 'IC1.0';
            OptionCaption = ' ,Outgoing,Incoming';
            OptionMembers = " ",Outgoing,Incoming;
        }
        field(50017;COGS;Decimal)
        {
            CalcFormula = Sum("Value Entry"."Cost Posted to G/L" WHERE (Item Ledger Entry Type=CONST(Sale),
                                                                        Document No.=FIELD(No.)));
            Description = 'T004906';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50100;"Shipment Confirmed from HHT";Boolean)
        {
            Description = 'HHT1.0';
        }
        field(50101;"Shipment Confirmed By";Code[20])
        {
            Description = 'HHT1.0';
            TableRelation = User;
        }
        field(50102;"Shipment Confirmed On";Date)
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
        field(50200;"Statement Posted";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50201;"Open Statement No.";Code[20])
        {
            Description = 'APNT-HRU1.0';
        }
        field(50202;"Retrieved At POS";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50203;"Deposit Amount";Decimal)
        {
            Caption = 'Prepayment Amount';
            Description = 'APNT-HRU1.0';
        }
        field(50204;"Deposit Received";Boolean)
        {
            Caption = 'Prepayment Received';
            Description = 'APNT-HRU1.0';
        }
        field(50205;"Created Time";Time)
        {
            Description = 'APNT-HRU1.0';
            Editable = false;
        }
        field(50206;"Created Date";Date)
        {
            Description = 'APNT-HRU1.0';
            Editable = false;
        }
        field(50207;"Cancellation Time";Time)
        {
            Description = 'APNT-HRU1.0';
            Editable = false;
        }
        field(50208;"Lines Reversed";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50209;"HRU Document";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50210;"Transaction Posted";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50211;"Premise Type";Option)
        {
            Description = 'APNT-HRU1.0';
            OptionCaption = 'Villa,Apartment,Office,Self Collection,Cargo/Dropoff';
            OptionMembers = Villa,Apartment,Office,"Self Collection","Cargo/Dropoff";
        }
        field(50212;"ISD Code";Code[10])
        {
            Description = 'APNT-HRU1.0';
        }
        field(50213;"Offer Amount";Decimal)
        {
            Description = 'APNT-HRU1.0';
            Editable = false;
        }
        field(50214;"SO Transaction Posted";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50215;"Phone Area Code";Integer)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50216;"Mobile Area Code";Integer)
        {
            Description = 'APNT-HRU1.0';
            MinValue = 3;
        }
        field(50218;"Cancellation Date";Date)
        {
            Description = 'APNT-HRU1.0';
            Editable = false;
        }
        field(50300;"WMS Exported";Boolean)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50301;"Sent Request";Boolean)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50302;"Sent Request By";Code[20])
        {
            Description = 'APNT-WMS1.0';
            TableRelation = "User Setup";
        }
        field(50303;"Sent Request Date";Date)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50304;"Sent Request Time";Time)
        {
            Description = 'APNT-WMS1.0';
        }
        field(50305;"Dispatch Order Number";Code[20])
        {
            Description = 'APNT-WMS1.0';
        }
        field(50306;"WMS Customer Export";Boolean)
        {
            Description = 'APNT-WMS2.0';
        }
        field(50307;"WMS Update SO";Boolean)
        {
            Description = 'APNT-WMS2.0';
        }
        field(50308;"VAN Sales Order";Boolean)
        {
            Description = 'APNT-VAN1.0';
        }
        field(50309;"Push to VAN";Boolean)
        {
            Description = 'APNT-VAN1.0';
        }
        field(50310;"Exported to VAN";Boolean)
        {
            Description = 'APNT-VAN1.0';
        }
        field(50800;"eCOM Order";Boolean)
        {
            Description = 'eCOM';
        }
        field(50801;"Magento Last Status";Text[100])
        {
            Description = 'eCom';
            Editable = false;
        }
        field(50802;"Magento Last Entry No";Integer)
        {
            Description = 'eCom';
            Editable = false;
        }
        field(50803;"NAV Last Status";Text[100])
        {
            Description = 'eCom';
            Editable = false;
        }
        field(50850;"eCom Original Sales Order No.";Code[20])
        {
            Description = 'eCom';
        }
        field(50851;"eCom Original Sales Invoice No";Code[20])
        {
            Description = 'eCom-CR';
        }
        field(54001;"Mobile Phone No.";Text[30])
        {
            Description = 'eCom';
        }
        field(54002;"E-Mail";Text[80])
        {
            Description = 'eCom';
        }
        field(54003;"Bill-to House No.";Text[30])
        {
            Description = 'eCom';
        }
        field(54004;"Ship-to House No.";Text[30])
        {
            Description = 'eCom';
        }
        field(10000711;"Cashier ID";Code[10])
        {
            Caption = 'Cashier ID';
            Description = 'T006863';
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
        field(33016802;"Agreement Invoice/Cr Memo";Boolean)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(99008509;"Date Sent";Date)
        {
            Caption = 'Date Sent';
        }
        field(99008510;"Time Sent";Time)
        {
            Caption = 'Time Sent';
        }
        field(99008517;"BizTalk Sales Credit Memo";Boolean)
        {
            Caption = 'BizTalk Sales Credit Memo';
        }
        field(99008521;"BizTalk Document Sent";Boolean)
        {
            Caption = 'BizTalk Document Sent';
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Pre-Assigned No.")
        {
        }
        key(Key3;"Sell-to Customer No.","External Document No.")
        {
        }
        key(Key4;"Return Order No.")
        {
        }
        key(Key5;"Sell-to Customer No.","No.")
        {
        }
        key(Key6;"Prepayment Order No.")
        {
        }
        key(Key7;"Exported to JDE","No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"No.","Sell-to Customer No.","Bill-to Customer No.","Posting Date","Posting Description")
        {
        }
    }

    trigger OnDelete()
    var
        DimMgt: Codeunit "408";
    begin
        TESTFIELD("No. Printed");
        LOCKTABLE;
        PostSalesLinesDelete.DeleteSalesCrMemoLines(Rec);

        SalesCommentLine.SETRANGE("Document Type",SalesCommentLine."Document Type"::"Posted Credit Memo");
        SalesCommentLine.SETRANGE("No.","No.");
        SalesCommentLine.DELETEALL;

        DimMgt.DeletePostedDocDim(DATABASE::"Sales Cr.Memo Header","No.",0);

        ApprovalsMgt.DeletePostedApprovalEntry(DATABASE::"Sales Cr.Memo Header","No.");
    end;

    var
        SalesCrMemoHeader: Record "114";
        SalesCommentLine: Record "44";
        CustLedgEntry: Record "21";
        PostCode: Record "225";
        PostSalesLinesDelete: Codeunit "363";
        ApprovalsMgt: Codeunit "439";
 
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "77";
    begin
        WITH SalesCrMemoHeader DO BEGIN
          COPY(Rec);
          FIND('-');
          ReportSelection.SETRANGE(Usage,ReportSelection.Usage::"S.Cr.Memo");
          ReportSelection.SETFILTER("Report ID",'<>0');
          ReportSelection.FIND('-');
          REPEAT
            REPORT.RUNMODAL(ReportSelection."Report ID",ShowRequestForm,FALSE,SalesCrMemoHeader);
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
 
    procedure LookupAdjmtValueEntries()
    var
        ValueEntry: Record "5802";
    begin
        ValueEntry.SETCURRENTKEY("Document No.");
        ValueEntry.SETRANGE("Document No.","No.");
        ValueEntry.SETRANGE("Document Type",ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SETRANGE(Adjustment,TRUE);
        FORM.RUNMODAL(0,ValueEntry);
    end;
}

