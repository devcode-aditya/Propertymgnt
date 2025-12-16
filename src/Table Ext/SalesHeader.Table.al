table 36 "Sales Header"
{
    // LS = changes made by LS Retail
    // Code          Date      Name          Description
    // APNT-LD1.0    26.07.10  Tanweer       Added code for Linked Dimensions Customization
    // APNT-ID1.0    17.08.10  Tanweer       Added fields for Invoice Discount Customization
    // APNT-JDE      31.12.11  Tanweer       Added fields for JDE Customization
    // APNT-1.0      15.10.11  Tanweer       Added field for Markup functionality
    // APNT-IC1.0    19.04.12  Tanweer       Added fields for IC Customization
    // APNT-1.0      26.06.12  Sangeeta      Added code for credit limit warning bug fix.
    // APNT-HHT1.0   01.11.12  Sujith        Added fields for HHT Customization
    // LG-0016       12.02.13  Tanweer       Added Key No. 13 & Code for External Document No. Validation
    // DP = changes made by DVS
    // APNT-HRU1.0   26.11.13  Sangeeta      Added fields & Code for HRU Customization.
    // APNT-HRU1.1   26.06.14  Sangeeta      Added code to validate dimension from location in salesperson code.
    // APNT-HRU1.0   23.07.14  Sangeeta      Added Cancellation date for HRU Customization..
    // HRUCRM1.0     24.07.14  Sujith        Added Key No 14 HRUCRM Customization
    // T004720       26.08.14  Shameema      Added code for hru document reference in ledger
    // T004906       18.09.14  Tanweer       Added field 50017
    // T008434       17.11.15  Shameema      Added for batch posting
    // APNT-WMS1.0   23.11.16  Sujith        Added field for WMS Palm Integration.
    // APNT-eCom     09.11.20  Sujith        Added code for eCommerce integration.
    // eCom-CR       25.02.21  Sujith          Added field for eCommerce integration CR

    Caption = 'Sales Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    LookupFormID = Form45;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Opp: Record "5092";
                lLocationCode: Code[10];
                lStore: Record "99001470";
                LocationRec: Record "14";
                DefaultDimension: Record "352";
            begin
                TESTFIELD(Status, Status::Open);
                IF ("Sell-to Customer No." <> xRec."Sell-to Customer No.") AND
                   (xRec."Sell-to Customer No." <> '')
                THEN BEGIN
                    IF ("Opportunity No." <> '') AND ("Document Type" IN ["Document Type"::Quote, "Document Type"::Order]) THEN
                        ERROR(
                          Text062,
                          FIELDCAPTION("Sell-to Customer No."),
                          FIELDCAPTION("Opportunity No."),
                          "Opportunity No.",
                          "Document Type");
                    IF HideValidationDialog OR NOT GUIALLOWED THEN
                        Confirmed := TRUE
                    ELSE
                        Confirmed := CONFIRM(Text004, FALSE, FIELDCAPTION("Sell-to Customer No."));
                    IF Confirmed THEN BEGIN
                        SalesLine.SETRANGE("Document Type", "Document Type");
                        SalesLine.SETRANGE("Document No.", "No.");
                        IF "Sell-to Customer No." = '' THEN BEGIN
                            IF SalesLine.FINDFIRST THEN
                                ERROR(
                                  Text005,
                                  FIELDCAPTION("Sell-to Customer No."));
                            INIT;
                            SalesSetup.GET;
                            "No. Series" := xRec."No. Series";
                            InitRecord;
                            IF xRec."Shipping No." <> '' THEN BEGIN
                                "Shipping No. Series" := xRec."Shipping No. Series";
                                "Shipping No." := xRec."Shipping No.";
                            END;
                            IF xRec."Posting No." <> '' THEN BEGIN
                                "Posting No. Series" := xRec."Posting No. Series";
                                "Posting No." := xRec."Posting No.";
                            END;
                            IF xRec."Return Receipt No." <> '' THEN BEGIN
                                "Return Receipt No. Series" := xRec."Return Receipt No. Series";
                                "Return Receipt No." := xRec."Return Receipt No.";
                            END;
                            IF xRec."Prepayment No." <> '' THEN BEGIN
                                "Prepayment No. Series" := xRec."Prepayment No. Series";
                                "Prepayment No." := xRec."Prepayment No.";
                            END;
                            IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
                                "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
                                "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
                            END;
                            EXIT;
                        END;
                        IF "Document Type" = "Document Type"::Order THEN
                            SalesLine.SETFILTER("Quantity Shipped", '<>0')
                        ELSE
                            IF "Document Type" = "Document Type"::Invoice THEN BEGIN
                                SalesLine.SETRANGE("Sell-to Customer No.", xRec."Sell-to Customer No.");
                                SalesLine.SETFILTER("Shipment No.", '<>%1', '');
                            END;

                        IF SalesLine.FINDFIRST THEN
                            IF "Document Type" = "Document Type"::Order THEN
                                SalesLine.TESTFIELD("Quantity Shipped", 0)
                            ELSE
                                SalesLine.TESTFIELD("Shipment No.", '');
                        SalesLine.SETRANGE("Shipment No.");
                        SalesLine.SETRANGE("Quantity Shipped");

                        IF "Document Type" = "Document Type"::Order THEN BEGIN
                            SalesLine.SETFILTER("Prepmt. Amt. Inv.", '<>0');
                            IF SalesLine.FIND('-') THEN
                                SalesLine.TESTFIELD("Prepmt. Amt. Inv.", 0);
                            SalesLine.SETRANGE("Prepmt. Amt. Inv.");
                        END;

                        IF "Document Type" = "Document Type"::"Return Order" THEN
                            SalesLine.SETFILTER("Return Qty. Received", '<>0')
                        ELSE
                            IF "Document Type" = "Document Type"::"Credit Memo" THEN BEGIN
                                SalesLine.SETRANGE("Sell-to Customer No.", xRec."Sell-to Customer No.");
                                SalesLine.SETFILTER("Return Receipt No.", '<>%1', '');
                            END;

                        IF SalesLine.FINDFIRST THEN
                            IF "Document Type" = "Document Type"::"Return Order" THEN
                                SalesLine.TESTFIELD("Return Qty. Received", 0)
                            ELSE
                                SalesLine.TESTFIELD("Return Receipt No.", '');
                        SalesLine.RESET
                    END ELSE BEGIN
                        Rec := xRec;
                        EXIT;
                    END;
                END;

                IF ("Document Type" = "Document Type"::Order) AND
                   (xRec."Sell-to Customer No." <> "Sell-to Customer No.")
                THEN BEGIN
                    SalesLine.SETRANGE("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SETRANGE("Document No.", "No.");
                    SalesLine.SETFILTER("Purch. Order Line No.", '<>0');
                    IF NOT SalesLine.ISEMPTY THEN
                        ERROR(
                          Text006,
                          FIELDCAPTION("Sell-to Customer No."));
                    SalesLine.RESET;
                END;

                GetCust("Sell-to Customer No.");

                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, FALSE);
                Cust.TESTFIELD("Gen. Bus. Posting Group");
                "Sell-to Customer Template Code" := '';
                "Sell-to Customer Name" := Cust.Name;
                "Sell-to Customer Name 2" := Cust."Name 2";
                "Sell-to Address" := Cust.Address;
                "Sell-to Address 2" := Cust."Address 2";
                "Sell-to City" := Cust.City;
                "Sell-to Post Code" := Cust."Post Code";
                "Sell-to County" := Cust.County;
                "Sell-to Country/Region Code" := Cust."Country/Region Code";
                IF NOT SkipSellToContact THEN
                    "Sell-to Contact" := Cust.Contact;
                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
                "VAT Registration No." := Cust."VAT Registration No.";
                "Shipping Advice" := Cust."Shipping Advice";
                "Responsibility Center" := UserMgt.GetRespCenter(0, Cust."Responsibility Center");
                //LS -
                "Phone No." := Cust."Phone No.";
                "E-Mail" := Cust."E-Mail";
                //LS +

                //LS -
                //VALIDATE("Location Code",UserMgt.GetLocation(0,Cust."Location Code","Responsibility Center"));
                IF "Store No." = '' THEN BEGIN
                    lLocationCode := UserMgt.GetLocation(0, Cust."Location Code", "Responsibility Center");
                    IF lLocationCode = '' THEN
                        "Store No." := ''
                    ELSE BEGIN
                        lStore.FindStore(lLocationCode, lStore);
                        "Store No." := lStore."No.";
                        VALIDATE("Location Code", lLocationCode)
                    END
                END;
                //LS +

                IF "Sell-to Customer No." = xRec."Sell-to Customer No." THEN BEGIN
                    IF ShippedSalesLinesExist OR ReturnReceiptExist THEN BEGIN
                        TESTFIELD("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                        TESTFIELD("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                    END;
                END;

                "Sell-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Sell-to IC Partner Code" <> '') AND ("IC Direction" = "IC Direction"::Outgoing);

                IF Cust."Bill-to Customer No." <> '' THEN
                    VALIDATE("Bill-to Customer No.", Cust."Bill-to Customer No.")
                ELSE BEGIN
                    IF "Bill-to Customer No." = "Sell-to Customer No." THEN
                        SkipBillToContact := TRUE;
                    VALIDATE("Bill-to Customer No.", "Sell-to Customer No.");
                    SkipBillToContact := FALSE;
                END;
                VALIDATE("Ship-to Code", '');

                GetShippingTime(FIELDNO("Sell-to Customer No."));

                IF (xRec."Sell-to Customer No." <> "Sell-to Customer No.") OR
                   (xRec."Currency Code" <> "Currency Code") OR
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") OR
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                THEN
                    RecreateSalesLines(FIELDCAPTION("Sell-to Customer No."));

                IF NOT SkipSellToContact THEN
                    UpdateSellToCont("Sell-to Customer No.");

                //APNT-LD1.0
                IF "Sell-to Customer No." <> '' THEN BEGIN
                    IF LocationRec.GET("Location Code") THEN BEGIN
                        GLSetup.GET;
                        DefaultDimension.RESET;
                        DefaultDimension.SETRANGE("Table ID", 15);
                        DefaultDimension.SETRANGE("Dimension Code", GLSetup."Shortcut Dimension 1 Code");
                        DefaultDimension.SETRANGE("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
                        IF DefaultDimension.FINDFIRST() THEN BEGIN
                            LocationRec.TESTFIELD("Shortcut Dimension 1 Code");
                            VALIDATE("Shortcut Dimension 1 Code", LocationRec."Shortcut Dimension 1 Code");
                        END;
                    END ELSE
                        VALIDATE("Shortcut Dimension 1 Code", '');
                END;
                //APNT-LD1.0
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    SalesSetup.GET;
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                END;
            end;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                TempDocDim: Record "357" temporary;
            begin
                TESTFIELD(Status, Status::Open);
                IF (xRec."Bill-to Customer No." <> "Bill-to Customer No.") AND
                   (xRec."Bill-to Customer No." <> '')
                THEN BEGIN
                    IF HideValidationDialog OR NOT GUIALLOWED THEN
                        Confirmed := TRUE
                    ELSE
                        Confirmed := CONFIRM(Text004, FALSE, FIELDCAPTION("Bill-to Customer No."));
                    IF Confirmed THEN BEGIN
                        SalesLine.SETRANGE("Document Type", "Document Type");
                        SalesLine.SETRANGE("Document No.", "No.");
                        IF "Document Type" = "Document Type"::Order THEN
                            SalesLine.SETFILTER("Quantity Shipped", '<>0')
                        ELSE
                            IF "Document Type" = "Document Type"::Invoice THEN
                                SalesLine.SETFILTER("Shipment No.", '<>%1', '');

                        IF SalesLine.FINDFIRST THEN
                            IF "Document Type" = "Document Type"::Order THEN
                                SalesLine.TESTFIELD("Quantity Shipped", 0)
                            ELSE
                                SalesLine.TESTFIELD("Shipment No.", '');
                        SalesLine.SETRANGE("Shipment No.");
                        SalesLine.SETRANGE("Quantity Shipped");

                        IF "Document Type" = "Document Type"::Order THEN BEGIN
                            SalesLine.SETFILTER("Prepmt. Amt. Inv.", '<>0');
                            IF SalesLine.FIND('-') THEN
                                SalesLine.TESTFIELD("Prepmt. Amt. Inv.", 0);
                            SalesLine.SETRANGE("Prepmt. Amt. Inv.");
                        END;

                        IF "Document Type" = "Document Type"::"Return Order" THEN
                            SalesLine.SETFILTER("Return Qty. Received", '<>0')
                        ELSE
                            IF "Document Type" = "Document Type"::"Credit Memo" THEN
                                SalesLine.SETFILTER("Return Receipt No.", '<>%1', '');

                        IF SalesLine.FINDFIRST THEN
                            IF "Document Type" = "Document Type"::"Return Order" THEN
                                SalesLine.TESTFIELD("Return Qty. Received", 0)
                            ELSE
                                SalesLine.TESTFIELD("Return Receipt No.", '');
                        SalesLine.RESET
                    END ELSE
                        "Bill-to Customer No." := xRec."Bill-to Customer No.";
                END;

                GetCust("Bill-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, FALSE);
                Cust.TESTFIELD("Customer Posting Group");

                //APNT-1.0
                CustCheckCreditLimit.SetxRecCust(xRec."Sell-to Customer No.");
                //APNT-1.0


                IF GUIALLOWED AND (CurrFieldNo <> 0) AND ("Document Type" <= "Document Type"::Invoice) THEN BEGIN
                    "Amount Including VAT" := 0;
                    CASE "Document Type" OF
                        "Document Type"::Quote, "Document Type"::Invoice:
                            CustCheckCreditLimit.SalesHeaderCheck(Rec);
                        "Document Type"::Order:
                            BEGIN
                                IF "Bill-to Customer No." <> xRec."Bill-to Customer No." THEN BEGIN
                                    SalesLine.SETRANGE("Document Type", SalesLine."Document Type"::Order);
                                    SalesLine.SETRANGE("Document No.", "No.");
                                    SalesLine.CALCSUMS("Outstanding Amount", "Shipped Not Invoiced");
                                    "Amount Including VAT" := SalesLine."Outstanding Amount" + SalesLine."Shipped Not Invoiced";
                                END;
                                CustCheckCreditLimit.SalesHeaderCheck(Rec);
                            END;
                    END;
                    CALCFIELDS("Amount Including VAT");
                END;

                "Bill-to Customer Template Code" := '';
                "Bill-to Name" := Cust.Name;
                "Bill-to Name 2" := Cust."Name 2";
                "Bill-to Address" := Cust.Address;
                "Bill-to Address 2" := Cust."Address 2";
                "Bill-to City" := Cust.City;
                "Bill-to Post Code" := Cust."Post Code";
                "Bill-to County" := Cust.County;
                "Bill-to Country/Region Code" := Cust."Country/Region Code";
                "VAT Country/Region Code" := Cust."Country/Region Code";
                IF NOT SkipBillToContact THEN
                    "Bill-to Contact" := Cust.Contact;
                "Payment Terms Code" := Cust."Payment Terms Code";

                IF "Document Type" = "Document Type"::"Credit Memo" THEN BEGIN
                    "Payment Method Code" := '';
                    IF PaymentTerms.GET("Payment Terms Code") THEN
                        IF PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN
                            "Payment Method Code" := Cust."Payment Method Code"
                END ELSE
                    "Payment Method Code" := Cust."Payment Method Code";

                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                GLSetup.GET;
                IF GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." THEN
                    "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Customer Posting Group" := Cust."Customer Posting Group";
                "Currency Code" := Cust."Currency Code";
                "Customer Price Group" := Cust."Customer Price Group";
                "Prices Including VAT" := Cust."Prices Including VAT";
                "Allow Line Disc." := Cust."Allow Line Disc.";
                "Invoice Disc. Code" := Cust."Invoice Disc. Code";
                "Customer Disc. Group" := Cust."Customer Disc. Group";
                "Language Code" := Cust."Language Code";
                "Salesperson Code" := Cust."Salesperson Code";
                "Combine Shipments" := Cust."Combine Shipments";
                Reserve := Cust.Reserve;
                "VAT Registration No." := Cust."VAT Registration No.";
                IF "Document Type" = "Document Type"::Order THEN
                    "Prepayment %" := Cust."Prepayment %";

                IF "Bill-to Customer No." = xRec."Bill-to Customer No." THEN BEGIN
                    IF ShippedSalesLinesExist THEN BEGIN
                        TESTFIELD("Customer Disc. Group", xRec."Customer Disc. Group");
                        TESTFIELD("Currency Code", xRec."Currency Code");
                    END;
                END;

                TempDocDim.GetDimensions(DATABASE::"Sales Header", "Document Type", "No.", 0, TempDocDim);

                CreateDim(
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Customer Template", "Bill-to Customer Template Code");

                VALIDATE("Payment Terms Code");
                VALIDATE("Payment Method Code");
                VALIDATE("Currency Code");

                IF (xRec."Sell-to Customer No." = "Sell-to Customer No.") AND
                   (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                THEN
                    RecreateSalesLines(FIELDCAPTION("Bill-to Customer No."))
                ELSE
                    IF (xRec."Bill-to Customer No." <> '') AND SalesLinesExist THEN
                        TempDocDim.UpdateAllLineDim(DATABASE::"Sales Header", "Document Type", "No.", TempDocDim);

                IF NOT SkipBillToContact THEN
                    UpdateBillToCont("Bill-to Customer No.");

                "Bill-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Bill-to IC Partner Code" <> '') AND ("IC Direction" = "IC Direction"::Outgoing);
            end;
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
                PostCode.LookUpCity("Bill-to City", "Bill-to Post Code", TRUE);
            end;

            trigger OnValidate()
            begin
                IF "Date Received" = 0D THEN
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

            trigger OnValidate()
            var
                lStore: Record "99001470";
            begin
                IF ("Document Type" = "Document Type"::Order) AND
                   (xRec."Ship-to Code" <> "Ship-to Code")
                THEN BEGIN
                  SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Purch. Order Line No.",'<>0');
                  IF NOT SalesLine.ISEMPTY THEN
                    ERROR(
                      Text006,
                      FIELDCAPTION("Ship-to Code"));
                  SalesLine.RESET;
                END;
                
                IF ("Document Type" <> "Document Type"::"Return Order") AND
                   ("Document Type" <> "Document Type"::"Credit Memo")
                THEN BEGIN
                  IF "Ship-to Code" <> '' THEN BEGIN
                    IF xRec."Ship-to Code" <> '' THEN
                      BEGIN
                      GetCust("Sell-to Customer No.");
                      //LS -
                      /*
                      IF Cust."Location Code" <> '' THEN
                        VALIDATE("Location Code",Cust."Location Code");
                      */
                      IF "Store No." = '' THEN
                        IF Cust."Location Code" <> '' THEN BEGIN
                          IF lStore.FindStore(Cust."Location Code", lStore) THEN
                            "Store No." := lStore."No.";
                          VALIDATE("Location Code",Cust."Location Code");
                        END;
                      //LS +
                      "Tax Area Code" := Cust."Tax Area Code";
                    END;
                    ShipToAddr.GET("Sell-to Customer No.","Ship-to Code");
                    "Ship-to Name" := ShipToAddr.Name;
                    "Ship-to Name 2" := ShipToAddr."Name 2";
                    "Ship-to Address" := ShipToAddr.Address;
                    "Ship-to Address 2" := ShipToAddr."Address 2";
                    "Ship-to City" := ShipToAddr.City;
                    "Ship-to Post Code" := ShipToAddr."Post Code";
                    VALIDATE("Ship-to Post Code"); //LS
                    "Ship-to County" := ShipToAddr.County;
                    VALIDATE("Ship-to Country/Region Code",ShipToAddr."Country/Region Code");
                    "Ship-to Contact" := ShipToAddr.Contact;
                    "Shipment Method Code" := ShipToAddr."Shipment Method Code";
                    //LS -
                    /*
                    IF ShipToAddr."Location Code" <> '' THEN
                      VALIDATE("Location Code",ShipToAddr."Location Code");
                    */
                    IF "Store No." = '' THEN
                      IF ShipToAddr."Location Code" <> '' THEN BEGIN
                        IF lStore.FindStore(ShipToAddr."Location Code", lStore) THEN
                          "Store No." := lStore."No.";
                        VALIDATE("Location Code",ShipToAddr."Location Code");
                      END;
                    //LS +
                    "Shipping Agent Code" := ShipToAddr."Shipping Agent Code";
                    "Shipping Agent Service Code" := ShipToAddr."Shipping Agent Service Code";
                    IF ShipToAddr."Tax Area Code" <> '' THEN
                      "Tax Area Code" := ShipToAddr."Tax Area Code";
                    "Tax Liable" := ShipToAddr."Tax Liable";
                  END ELSE
                    IF "Sell-to Customer No." <> '' THEN BEGIN
                      GetCust("Sell-to Customer No.");
                      "Ship-to Name" := Cust.Name;
                      "Ship-to Name 2" := Cust."Name 2";
                      "Ship-to Address" := Cust.Address;
                      "Ship-to Address 2" := Cust."Address 2";
                      "Ship-to City" := Cust.City;
                      "Ship-to Post Code" := Cust."Post Code";
                      VALIDATE("Ship-to Post Code"); //LS
                      "Ship-to County" := Cust.County;
                      VALIDATE("Ship-to Country/Region Code",Cust."Country/Region Code");
                      "Ship-to Contact" := Cust.Contact;
                      "Shipment Method Code" := Cust."Shipment Method Code";
                      "Tax Area Code" := Cust."Tax Area Code";
                      "Tax Liable" := Cust."Tax Liable";
                      //LS -
                      /*
                      IF Cust."Location Code" <> '' THEN
                        VALIDATE("Location Code",Cust."Location Code");
                      */
                      IF "Store No." = '' THEN
                        IF Cust."Location Code" <> '' THEN BEGIN
                          IF lStore.FindStore(Cust."Location Code", lStore) THEN
                            "Store No." := lStore."No.";
                          VALIDATE("Location Code",Cust."Location Code");
                        END;
                      //LS +
                      "Shipping Agent Code" := Cust."Shipping Agent Code";
                      "Shipping Agent Service Code" := Cust."Shipping Agent Service Code";
                    END;
                END;
                
                GetShippingTime(FIELDNO("Ship-to Code"));
                
                IF (xRec."Sell-to Customer No." = "Sell-to Customer No.") AND
                   (xRec."Ship-to Code" <> "Ship-to Code")
                THEN
                  IF (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") OR
                     (xRec."Tax Area Code" <> "Tax Area Code")
                  THEN
                    RecreateSalesLines(FIELDCAPTION("Ship-to Code"))
                  ELSE BEGIN
                    IF xRec."Shipping Agent Code" <> "Shipping Agent Code" THEN
                      MessageIfSalesLinesExist(FIELDCAPTION("Shipping Agent Code"));
                    IF xRec."Shipping Agent Service Code" <> "Shipping Agent Service Code" THEN
                      MessageIfSalesLinesExist(FIELDCAPTION("Shipping Agent Service Code"));
                    IF xRec."Tax Liable" <> "Tax Liable" THEN
                      VALIDATE("Tax Liable");
                  END;

            end;
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
                PostCode.LookUpCity("Ship-to City","Ship-to Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                IF "Date Received" = 0D THEN
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

            trigger OnValidate()
            begin
                IF ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND
                   NOT ("Order Date" = xRec."Order Date")
                THEN
                  PriceMessageIfSalesLinesExist(FIELDCAPTION("Order Date"));
            end;
        }
        field(20;"Posting Date";Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestNoSeriesDate(
                  "Posting No.","Posting No. Series",
                  FIELDCAPTION("Posting No."),FIELDCAPTION("Posting No. Series"));
                TestNoSeriesDate(
                  "Prepayment No.","Prepayment No. Series",
                  FIELDCAPTION("Prepayment No."),FIELDCAPTION("Prepayment No. Series"));
                TestNoSeriesDate(
                  "Prepmt. Cr. Memo No.","Prepmt. Cr. Memo No. Series",
                  FIELDCAPTION("Prepmt. Cr. Memo No."),FIELDCAPTION("Prepmt. Cr. Memo No. Series"));

                VALIDATE("Document Date","Posting Date");

                IF ("Document Type" IN ["Document Type"::Invoice,"Document Type"::"Credit Memo"]) AND
                   NOT ("Posting Date" = xRec."Posting Date")
                THEN
                  PriceMessageIfSalesLinesExist(FIELDCAPTION("Posting Date"));

                IF "Currency Code" <> '' THEN BEGIN
                  UpdateCurrencyFactor;
                  IF "Currency Factor" <> xRec."Currency Factor" THEN
                    ConfirmUpdateCurrencyFactor;
                END;
                UpdateSalesLineDate;  //DP6.01.01
            end;
        }
        field(21;"Shipment Date";Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Shipment Date"),CurrFieldNo <> 0);
            end;
        }
        field(22;"Posting Description";Text[50])
        {
            Caption = 'Posting Description';
        }
        field(23;"Payment Terms Code";Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                  PaymentTerms.GET("Payment Terms Code");
                  IF (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND
                      NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos")
                  THEN BEGIN
                    VALIDATE("Due Date","Document Date");
                    VALIDATE("Pmt. Discount Date",0D);
                    VALIDATE("Payment Discount %",0);
                  END ELSE BEGIN
                    "Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                    "Pmt. Discount Date" := CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                  IF xRec."Document Date"="Document Date" THEN
                     VALIDATE("Payment Discount %",PaymentTerms."Discount %")
                  END;
                END ELSE BEGIN
                  VALIDATE("Due Date","Document Date");
                IF xRec."Document Date"="Document Date" THEN BEGIN
                  VALIDATE("Pmt. Discount Date",0D);
                  VALIDATE("Payment Discount %",0);
                END;
                END;
                IF xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" THEN BEGIN
                  IF xRec."Prepayment Due Date" = 0D THEN
                    "Prepayment Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                  VALIDATE("Prepmt. Payment Terms Code","Payment Terms Code");
                END;
            end;
        }
        field(24;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(25;"Payment Discount %";Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "Payment Discount %" < GLSetup."VAT Tolerance %" THEN
                  "VAT Base Discount %" := "Payment Discount %"
                ELSE
                  "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                VALIDATE("VAT Base Discount %");
            end;
        }
        field(26;"Pmt. Discount Date";Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27;"Shipment Method Code";Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
            end;
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
                lStore: Record "99001470";
                lStoreLocation: Record "10001416";
                LocationRec: Record "14";
                DefaultDimension: Record "352";
                SalesLinesRec: Record "37";
            begin
                TESTFIELD(Status,Status::Open);
                
                lBOUtils.StoreLocationOk("Store No.", "Location Code"); //LS
                
                //APNT-LD1.0
                /*
                IF ("Location Code" <> xRec."Location Code") AND
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                THEN
                  MessageIfSalesLinesExist(FIELDCAPTION("Location Code"));
                */
                //APNT-LD1.0
                UpdateShipToAddress;
                
                //LS -
                "Retail Special Order" := lStoreLocation.GET("Store No.","Location Code") AND lStoreLocation."Special Order Location";
                IF "Retail Special Order" AND NOT("Prices Including VAT") THEN
                  VALIDATE("Prices Including VAT",TRUE);
                //LS +
                
                IF "Location Code" <> '' THEN BEGIN
                  IF Location.GET("Location Code") THEN
                    "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                END ELSE BEGIN
                  IF InvtSetup.GET THEN
                    "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                END;
                
                //APNT-LD1.0
                IF "Sell-to Customer No." <> '' THEN BEGIN
                  IF LocationRec.GET("Location Code") THEN BEGIN
                    GLSetup.GET;
                    DefaultDimension.RESET;
                    DefaultDimension.SETRANGE("Table ID",15);
                    DefaultDimension.SETRANGE("Dimension Code",GLSetup."Shortcut Dimension 1 Code");
                    DefaultDimension.SETRANGE("Value Posting",DefaultDimension."Value Posting"::"Code Mandatory");
                    IF DefaultDimension.FINDFIRST() THEN BEGIN
                      LocationRec.TESTFIELD("Shortcut Dimension 1 Code");
                      VALIDATE("Shortcut Dimension 1 Code",LocationRec."Shortcut Dimension 1 Code");
                    END;
                  END ELSE
                    VALIDATE("Shortcut Dimension 1 Code",'');
                
                  SalesLinesRec.RESET;
                  SalesLinesRec.SETRANGE("Document Type","Document Type");
                  SalesLinesRec.SETRANGE("Document No.","No.");
                  SalesLinesRec.SETFILTER("No.",'<>%1','');
                  IF SalesLinesRec.FINDFIRST() THEN REPEAT
                    SalesLinesRec."Location Code" := "Location Code";
                    //APNT-HRU1.0 -
                    SalesLinesRec."Pick Location" := "Location Code";
                    //APNT-HRU1.0 +
                    SalesLinesRec.MODIFY;
                  UNTIL SalesLinesRec.NEXT = 0;
                END;
                //APNT-LD1.0

            end;
        }
        field(29;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(30;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
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
            TableRelation = Currency;

            trigger OnValidate()
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date")]) OR ("Currency Code" <> xRec."Currency Code") THEN
                  TESTFIELD(Status,Status::Open);
                IF (CurrFieldNo <> FIELDNO("Currency Code")) AND ("Currency Code" = xRec."Currency Code") THEN
                  UpdateCurrencyFactor
                ELSE BEGIN
                  IF "Currency Code" <> xRec."Currency Code" THEN BEGIN
                    UpdateCurrencyFactor;
                    RecreateSalesLines(FIELDCAPTION("Currency Code"));
                  END ELSE
                    IF "Currency Code" <> '' THEN BEGIN
                      UpdateCurrencyFactor;
                      IF "Currency Factor" <> xRec."Currency Factor" THEN
                        ConfirmUpdateCurrencyFactor;
                    END;
                END;
            end;
        }
        field(33;"Currency Factor";Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0:15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                IF "Currency Factor" <> xRec."Currency Factor" THEN
                  UpdateSalesLines(FIELDCAPTION("Currency Factor"),FALSE);
            end;
        }
        field(34;"Customer Price Group";Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FIELDCAPTION("Customer Price Group"));
            end;
        }
        field(35;"Prices Including VAT";Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                SalesLine: Record "37";
                Currency: Record "4";
                JobPostLine: Codeunit "1001";
                RecalculatePrice: Boolean;
            begin
                TESTFIELD(Status,Status::Open);

                IF "Prices Including VAT" <> xRec."Prices Including VAT" THEN BEGIN
                  SalesLine.SETRANGE("Document Type","Document Type");
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Job Contract Entry No.",'<>%1',0);
                  IF SalesLine.FIND('-') THEN BEGIN
                    SalesLine.TESTFIELD("Job No.",'');
                    SalesLine.TESTFIELD("Job Contract Entry No.",0);
                  END;

                  SalesLine.RESET;
                  SalesLine.SETRANGE("Document Type","Document Type");
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Unit Price",'<>%1',0);
                  SalesLine.SETFILTER("VAT %",'<>%1',0);
                  IF SalesLine.FINDFIRST THEN BEGIN
                    RecalculatePrice :=
                      CONFIRM(
                        STRSUBSTNO(
                          Text024 +
                          Text026,
                          FIELDCAPTION("Prices Including VAT"),SalesLine.FIELDCAPTION("Unit Price")),
                        TRUE);
                    SalesLine.SetSalesHeader(Rec);

                    IF "Currency Code" = '' THEN
                      Currency.InitRoundingPrecision
                    ELSE
                      Currency.GET("Currency Code");
                    SalesLine.LOCKTABLE;
                    LOCKTABLE;
                    SalesLine.FINDSET;
                    REPEAT
                      SalesLine.TESTFIELD("Quantity Invoiced",0);
                      SalesLine.TESTFIELD("Prepmt. Amt. Inv.",0);
                      IF NOT RecalculatePrice THEN BEGIN
                        SalesLine."VAT Difference" := 0;
                        SalesLine.InitOutstandingAmount;
                      END ELSE
                        IF "Prices Including VAT" THEN BEGIN
                          SalesLine."Unit Price" :=
                            ROUND(
                              SalesLine."Unit Price" * (1 + (SalesLine."VAT %" / 100)),
                              Currency."Unit-Amount Rounding Precision");
                          IF SalesLine.Quantity <> 0 THEN BEGIN
                            SalesLine."Line Discount Amount" :=
                              ROUND(
                                SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                Currency."Amount Rounding Precision");
                            SalesLine.VALIDATE("Inv. Discount Amount",
                              ROUND(
                                SalesLine."Inv. Discount Amount" * (1 + (SalesLine."VAT %" / 100)),
                                Currency."Amount Rounding Precision"));
                          END;
                        END ELSE BEGIN
                          SalesLine."Unit Price" :=
                            ROUND(
                              SalesLine."Unit Price" / (1 + (SalesLine."VAT %" / 100)),
                              Currency."Unit-Amount Rounding Precision");
                          IF SalesLine.Quantity <> 0 THEN BEGIN
                            SalesLine."Line Discount Amount" :=
                              ROUND(
                                SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                Currency."Amount Rounding Precision");
                            SalesLine.VALIDATE("Inv. Discount Amount",
                              ROUND(
                                SalesLine."Inv. Discount Amount" / (1 + (SalesLine."VAT %" / 100)),
                                Currency."Amount Rounding Precision"));
                          END;
                        END;
                      SalesLine.MODIFY;
                    UNTIL SalesLine.NEXT = 0;
                  END;
                END;
            end;
        }
        field(37;"Invoice Disc. Code";Code[20])
        {
            Caption = 'Invoice Disc. Code';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Invoice Disc. Code"));
            end;
        }
        field(40;"Customer Disc. Group";Code[10])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Customer Disc. Group"));
            end;
        }
        field(41;"Language Code";Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FIELDCAPTION("Language Code"));
            end;
        }
        field(43;"Salesperson Code";Code[10])
        {
            Caption = 'Salesperson Code';
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate()
            var
                TempDocDim: Record "357" temporary;
                ApprovalEntry: Record "454";
                LocationRec: Record "14";
                DefaultDimension: Record "352";
            begin
                ApprovalEntry.SETRANGE("Table ID",DATABASE::"Sales Header");
                ApprovalEntry.SETRANGE("Document Type","Document Type");
                ApprovalEntry.SETRANGE("Document No.","No.");
                ApprovalEntry.SETFILTER(Status,'<>%1&<>%2',ApprovalEntry.Status::Canceled,ApprovalEntry.Status::Rejected);
                IF ApprovalEntry.FIND('-') THEN
                  ERROR(Text053,FIELDCAPTION("Salesperson Code"));

                TempDocDim.GetDimensions(DATABASE::"Sales Header","Document Type","No.",0,TempDocDim);

                CreateDim(
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");

                IF SalesLinesExist THEN
                  TempDocDim.UpdateAllLineDim(DATABASE::"Sales Header","Document Type","No.",TempDocDim);

                //APNT-HRU1.0 -
                IF "Sell-to Customer No." <> '' THEN BEGIN
                  IF LocationRec.GET("Location Code") THEN BEGIN
                    GLSetup.GET;
                    DefaultDimension.RESET;
                    DefaultDimension.SETRANGE("Table ID",15);
                    DefaultDimension.SETRANGE("Dimension Code",GLSetup."Shortcut Dimension 1 Code");
                    DefaultDimension.SETRANGE("Value Posting",DefaultDimension."Value Posting"::"Code Mandatory");
                    IF DefaultDimension.FINDFIRST() THEN BEGIN
                      LocationRec.TESTFIELD("Shortcut Dimension 1 Code");
                      VALIDATE("Shortcut Dimension 1 Code",LocationRec."Shortcut Dimension 1 Code");
                    END;
                  END ELSE
                    VALIDATE("Shortcut Dimension 1 Code",'');
                END;
                //APNT-HRU1.0 +
            end;
        }
        field(45;"Order Class";Code[10])
        {
            Caption = 'Order Class';
        }
        field(46;Comment;Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE (Document Type=FIELD(Document Type),
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
                TESTFIELD("Bal. Account No.",'');
                CustLedgEntry.SETCURRENTKEY("Customer No.",Open,Positive,"Due Date");
                CustLedgEntry.SETRANGE("Customer No.","Bill-to Customer No.");
                CustLedgEntry.SETRANGE(Open,TRUE);
                IF "Applies-to Doc. No." <> '' THEN BEGIN
                  CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                  CustLedgEntry.SETRANGE("Document No.","Applies-to Doc. No.");
                  IF CustLedgEntry.FINDFIRST THEN;
                  CustLedgEntry.SETRANGE("Document Type");
                  CustLedgEntry.SETRANGE("Document No.");
                END ELSE IF "Applies-to Doc. Type" <> 0 THEN BEGIN
                    CustLedgEntry.SETRANGE("Document Type","Applies-to Doc. Type");
                    IF CustLedgEntry.FINDFIRST THEN;
                    CustLedgEntry.SETRANGE("Document Type");
                  END ELSE IF Amount <> 0 THEN BEGIN
                      CustLedgEntry.SETRANGE(Positive,Amount < 0);
                      IF CustLedgEntry.FINDFIRST THEN;
                      CustLedgEntry.SETRANGE(Positive);
                    END;

                ApplyCustEntries.SetSales(Rec,CustLedgEntry,SalesHeader.FIELDNO("Applies-to Doc. No."));
                ApplyCustEntries.SETTABLEVIEW(CustLedgEntry);
                ApplyCustEntries.SETRECORD(CustLedgEntry);
                ApplyCustEntries.LOOKUPMODE(TRUE);
                IF ApplyCustEntries.RUNMODAL = ACTION::LookupOK THEN BEGIN
                  ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                  GenJnlApply.CheckAgainstApplnCurrency(
                    "Currency Code",CustLedgEntry."Currency Code",GenJnILine."Account Type"::Customer,TRUE);
                  "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                  "Applies-to Doc. No." := CustLedgEntry."Document No.";
                END;
                CLEAR(ApplyCustEntries);
            end;

            trigger OnValidate()
            begin
                IF "Applies-to Doc. No." <> '' THEN
                  TESTFIELD("Bal. Account No.",'');

                IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND (xRec."Applies-to Doc. No." <> '') AND
                   ("Applies-to Doc. No." <> '')
                THEN BEGIN
                  SetAmountToApply("Applies-to Doc. No.","Bill-to Customer No.");
                  SetAmountToApply(xRec."Applies-to Doc. No.","Bill-to Customer No.");
                END ELSE
                  IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND (xRec."Applies-to Doc. No." = '') THEN
                    SetAmountToApply("Applies-to Doc. No.","Bill-to Customer No.")
                  ELSE IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND ("Applies-to Doc. No." = '') THEN
                      SetAmountToApply(xRec."Applies-to Doc. No.","Bill-to Customer No.");
            end;
        }
        field(55;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account";

            trigger OnValidate()
            begin
                IF "Bal. Account No." <> '' THEN
                  CASE "Bal. Account Type" OF
                    "Bal. Account Type"::"G/L Account":
                      BEGIN
                        GLAcc.GET("Bal. Account No.");
                        GLAcc.CheckGLAcc;
                        GLAcc.TESTFIELD("Direct Posting",TRUE);
                      END;
                    "Bal. Account Type"::"Bank Account":
                      BEGIN
                        BankAcc.GET("Bal. Account No.");
                        BankAcc.TESTFIELD(Blocked,FALSE);
                        BankAcc.TESTFIELD("Currency Code","Currency Code");
                      END;
                  END;
            end;
        }
        field(57;Ship;Boolean)
        {
            Caption = 'Ship';
            Editable = false;
        }
        field(58;Invoice;Boolean)
        {
            Caption = 'Invoice';
        }
        field(60;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line".Amount WHERE (Document Type=FIELD(Document Type),
                                                         Document No.=FIELD(No.)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61;"Amount Including VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Amount Including VAT" WHERE (Document Type=FIELD(Document Type),
                                                                         Document No.=FIELD(No.)));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62;"Shipping No.";Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63;"Posting No.";Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64;"Last Shipping No.";Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Sales Shipment Header";
        }
        field(65;"Last Posting No.";Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(66;"Prepayment No.";Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(67;"Last Prepayment No.";Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(68;"Prepmt. Cr. Memo No.";Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(69;"Last Prepmt. Cr. Memo No.";Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Cr.Memo Header";
        }
        field(70;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(71;"Combine Shipments";Boolean)
        {
            Caption = 'Combine Shipments';
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

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" THEN
                  IF GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp,"Gen. Bus. Posting Group") THEN BEGIN
                    "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                    RecreateSalesLines(FIELDCAPTION("Gen. Bus. Posting Group"));
                  END;
            end;
        }
        field(75;"EU 3-Party Trade";Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76;"Transaction Type";Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Transaction Type"),FALSE);
            end;
        }
        field(77;"Transport Method";Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Transport Method"),FALSE);
            end;
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
                PostCode.LookUpCity("Sell-to City","Sell-to Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                IF "Date Received" = 0D THEN
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
                PostCode.LookUpPostCode("Bill-to City","Bill-to Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                IF "Date Received" = 0D THEN
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
                PostCode.LookUpPostCode("Sell-to City","Sell-to Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                IF "Date Received" = 0D THEN
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

            trigger OnValidate()
            begin
                VALIDATE("Ship-to Country/Region Code");
            end;
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
                PostCode.LookUpPostCode("Ship-to City","Ship-to Post Code",TRUE);
            end;

            trigger OnValidate()
            var
                lBOUtils: Codeunit "99001452";
                lSPOShippingZonePostCode: Record "10012726";
            begin
                IF "Date Received" = 0D THEN
                  PostCode.ValidatePostCode("Ship-to City","Ship-to Post Code");

                //LS -
                IF lBOUtils.IsSpecialOrderyPermitted AND ("Ship-to Post Code" <> '')THEN BEGIN
                  lSPOShippingZonePostCode.SETFILTER("Post Code","Ship-to Post Code");
                  IF lSPOShippingZonePostCode.FIND('-') THEN
                    "Retail Zones Code":= lSPOShippingZonePostCode."Retail Zone Code";
                END;
                //LS +
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

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Exit Point"),FALSE);
            end;
        }
        field(98;Correction;Boolean)
        {
            Caption = 'Correction';
        }
        field(99;"Document Date";Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                VALIDATE("Payment Terms Code");
                VALIDATE("Prepmt. Payment Terms Code");
            end;
        }
        field(100;"External Document No.";Code[20])
        {
            Caption = 'External Document No.';
            Description = 'LG-0016';

            trigger OnValidate()
            var
                SalesHeader: Record "36";
                SalesInvHeader: Record "112";
                Window: Dialog;
            begin
                //LG-0016
                TESTFIELD(Status,Status::Open);

                IF "External Document No." <> '' THEN BEGIN
                  Window.OPEN('Please wait\'+
                              'System is checking External Document No.');
                  SalesHeader.RESET;
                  SalesHeader.SETCURRENTKEY("External Document No.");
                  SalesHeader.SETRANGE("External Document No.","External Document No.");
                  IF SalesHeader.FINDFIRST THEN REPEAT
                    IF (SalesHeader."No." <> "No.") AND (SalesHeader."Sell-to Customer No." = "Sell-to Customer No.") THEN
                      IF SalesHeader."Document Type" IN [SalesHeader."Document Type"::Order,
                                                              SalesHeader."Document Type"::"Return Order",
                                                              SalesHeader."Document Type"::Invoice,
                                                              SalesHeader."Document Type"::"Credit Memo"] THEN
                        ERROR('External Document No. %1 already exist in Sales %2 %3.',"External Document No.",
                                          SalesHeader."Document Type",SalesHeader."No.");
                  UNTIL SalesHeader.NEXT = 0;

                  SalesInvHeader.RESET;
                  SalesInvHeader.SETCURRENTKEY("External Document No.");
                  SalesInvHeader.SETRANGE("External Document No.","External Document No.");
                  IF SalesInvHeader.FINDFIRST THEN
                    IF SalesInvHeader."Sell-to Customer No." = "Sell-to Customer No." THEN
                      ERROR('External Document No. %1 already exist in Posted Sales Invoice %2.',"External Document No.",
                                          SalesInvHeader."No.");
                  Window.CLOSE;
                END;
                //LG-0016
            end;
        }
        field(101;"Area";Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION(Area),FALSE);
            end;
        }
        field(102;"Transaction Specification";Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Transaction Specification"),FALSE);
            end;
        }
        field(104;"Payment Method Code";Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                PaymentMethod.INIT;
                IF "Payment Method Code" <> '' THEN
                  PaymentMethod.GET("Payment Method Code");
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                IF "Bal. Account No." <> '' THEN BEGIN
                  TESTFIELD("Applies-to Doc. No.",'');
                  TESTFIELD("Applies-to ID",'');
                END;
            end;
        }
        field(105;"Shipping Agent Code";Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."Shipping Agent Code" = "Shipping Agent Code" THEN
                  EXIT;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FIELDNO("Shipping Agent Code"));
                UpdateSalesLines(FIELDCAPTION("Shipping Agent Code"),CurrFieldNo <> 0);
            end;
        }
        field(106;"Package Tracking No.";Text[30])
        {
            Caption = 'Package Tracking No.';
        }
        field(107;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108;"Posting No. Series";Code[10])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  TestNoSeries;
                  IF NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode,"Posting No. Series") THEN
                    VALIDATE("Posting No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate()
            begin
                IF "Posting No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  TestNoSeries;
                  NoSeriesMgt.TestSeries(GetPostingNoSeriesCode,"Posting No. Series");
                END;
                TESTFIELD("Posting No.",'');
            end;
        }
        field(109;"Shipping No. Series";Code[10])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Shipment Nos.");
                  IF NoSeriesMgt.LookupSeries(SalesSetup."Posted Shipment Nos.","Shipping No. Series") THEN
                    VALIDATE("Shipping No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate()
            begin
                IF "Shipping No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Shipment Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Shipment Nos.","Shipping No. Series");
                END;
                TESTFIELD("Shipping No.",'');
            end;
        }
        field(114;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Tax Area Code"));
            end;
        }
        field(115;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Tax Liable"));
            end;
        }
        field(116;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" THEN
                  RecreateSalesLines(FIELDCAPTION("VAT Bus. Posting Group"));
            end;
        }
        field(117;Reserve;Option)
        {
            Caption = 'Reserve';
            OptionCaption = 'Never,Optional,Always';
            OptionMembers = Never,Optional,Always;
        }
        field(118;"Applies-to ID";Code[20])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                TempCustLedgEntry: Record "21";
            begin
                IF "Applies-to ID" <> '' THEN
                  TESTFIELD("Bal. Account No.",'');
                IF ("Applies-to ID" <> xRec."Applies-to ID") AND (xRec."Applies-to ID" <> '') THEN BEGIN
                  CustLedgEntry.SETCURRENTKEY("Customer No.",Open);
                  CustLedgEntry.SETRANGE("Customer No.","Bill-to Customer No.");
                  CustLedgEntry.SETRANGE(Open,TRUE);
                  CustLedgEntry.SETRANGE("Applies-to ID",xRec."Applies-to ID");
                  IF CustLedgEntry.FINDFIRST THEN
                    CustEntrySetApplID.SetApplId(CustLedgEntry,TempCustLedgEntry,0,0,'');
                  CustLedgEntry.RESET;
                END;
            end;
        }
        field(119;"VAT Base Discount %";Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                ChangeLogMgt: Codeunit "423";
                RecRef: RecordRef;
                xRecRef: RecordRef;
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "VAT Base Discount %" > GLSetup."VAT Tolerance %" THEN
                  ERROR(
                    Text007,
                    FIELDCAPTION("VAT Base Discount %"),
                    GLSetup.FIELDCAPTION("VAT Tolerance %"),
                    GLSetup.TABLECAPTION);

                IF ("VAT Base Discount %" = xRec."VAT Base Discount %") AND
                   (CurrFieldNo <> 0)
                THEN
                  EXIT;

                SalesLine.SETRANGE("Document Type","Document Type");
                SalesLine.SETRANGE("Document No.","No.");
                SalesLine.SETFILTER(Type,'<>%1',SalesLine.Type::" ");
                SalesLine.SETFILTER(Quantity,'<>0');
                DocDim.LOCKTABLE;
                SalesLine.LOCKTABLE;
                LOCKTABLE;
                IF SalesLine.FINDSET THEN BEGIN
                  xRecRef.GETTABLE(xRec);
                  MODIFY;
                  RecRef.GETTABLE(Rec);
                  ChangeLogMgt.LogModification(RecRef,xRecRef);
                  REPEAT
                    IF (SalesLine."Quantity Invoiced" <> SalesLine.Quantity) OR
                       ("Shipping Advice" <> "Shipping Advice"::Partial) OR
                       (SalesLine.Type <> SalesLine.Type::"Charge (Item)") OR
                       (CurrFieldNo <> 0)
                    THEN BEGIN
                      xRecRef.GETTABLE(SalesLine);
                      SalesLine.UpdateAmounts;
                      SalesLine.MODIFY;
                      RecRef.GETTABLE(SalesLine);
                      ChangeLogMgt.LogModification(RecRef,xRecRef);
                    END;
                  UNTIL SalesLine.NEXT = 0;
                END;
                SalesLine.RESET;
            end;
        }
        field(120;Status;Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval,Pending Prepayment';
            OptionMembers = Open,Released,"Pending Approval","Pending Prepayment";
        }
        field(121;"Invoice Discount Calculation";Option)
        {
            Caption = 'Invoice Discount Calculation';
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122;"Invoice Discount Value";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            Editable = false;
        }
        field(123;"Send IC Document";Boolean)
        {
            Caption = 'Send IC Document';

            trigger OnValidate()
            begin
                IF "Send IC Document" THEN BEGIN
                  IF "Bill-to IC Partner Code" = '' THEN
                    TESTFIELD("Sell-to IC Partner Code");
                  TESTFIELD("IC Direction","IC Direction"::Outgoing);
                END;
            end;
        }
        field(124;"IC Status";Option)
        {
            Caption = 'IC Status';
            OptionCaption = 'New,Pending,Sent';
            OptionMembers = New,Pending,Sent;
        }
        field(125;"Sell-to IC Partner Code";Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126;"Bill-to IC Partner Code";Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(129;"IC Direction";Option)
        {
            Caption = 'IC Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;

            trigger OnValidate()
            begin
                IF "IC Direction" = "IC Direction"::Incoming THEN
                  "Send IC Document" := FALSE;
            end;
        }
        field(130;"Prepayment %";Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateSalesLines(FIELDCAPTION("Prepayment %"),CurrFieldNo <> 0);
            end;
        }
        field(131;"Prepayment No. Series";Code[10])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Inv. Nos.");
                  IF NoSeriesMgt.LookupSeries(SalesSetup."Posted Prepmt. Inv. Nos.","Prepayment No. Series") THEN
                    VALIDATE("Prepayment No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate()
            begin
                IF "Prepayment No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Inv. Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Prepmt. Inv. Nos.","Prepayment No. Series");
                END;
                TESTFIELD("Prepayment No.",'');
            end;
        }
        field(132;"Compress Prepayment";Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(133;"Prepayment Due Date";Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(134;"Prepmt. Cr. Memo No. Series";Code[10])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Cr. Memo Nos.");
                  IF NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode,"Prepmt. Cr. Memo No.") THEN
                    VALIDATE("Prepmt. Cr. Memo No.");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate()
            begin
                IF "Prepmt. Cr. Memo No." <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Cr. Memo Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Prepmt. Cr. Memo Nos.","Prepmt. Cr. Memo No.");
                END;
                TESTFIELD("Prepmt. Cr. Memo No.",'');
            end;
        }
        field(135;"Prepmt. Posting Description";Text[50])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(138;"Prepmt. Pmt. Discount Date";Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(139;"Prepmt. Payment Terms Code";Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "3";
            begin
                IF ("Prepmt. Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                  PaymentTerms.GET("Prepmt. Payment Terms Code");
                  IF (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND
                     NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos")
                  THEN BEGIN
                    VALIDATE("Prepayment Due Date","Document Date");
                    VALIDATE("Prepmt. Pmt. Discount Date",0D);
                    VALIDATE("Prepmt. Payment Discount %",0);
                  END ELSE BEGIN
                    "Prepayment Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                    "Prepmt. Pmt. Discount Date" := CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                    VALIDATE("Prepmt. Payment Discount %",PaymentTerms."Discount %")
                  END;
                END ELSE BEGIN
                  VALIDATE("Prepayment Due Date","Document Date");
                  VALIDATE("Prepmt. Pmt. Discount Date",0D);
                  VALIDATE("Prepmt. Payment Discount %",0);
                END;
            end;
        }
        field(140;"Prepmt. Payment Discount %";Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "Payment Discount %" < GLSetup."VAT Tolerance %" THEN
                  "VAT Base Discount %" := "Payment Discount %"
                ELSE
                  "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                VALIDATE("VAT Base Discount %");
            end;
        }
        field(151;"Quote No.";Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(5043;"No. of Archived Versions";Integer)
        {
            CalcFormula = Max("Sales Header Archive"."Version No." WHERE (Document Type=FIELD(Document Type),
                                                                          No.=FIELD(No.),
                                                                          Doc. No. Occurrence=FIELD(Doc. No. Occurrence)));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048;"Doc. No. Occurrence";Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050;"Campaign No.";Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            var
                TempDocDim: Record "357" temporary;
                ChangeLogMgt: Codeunit "423";
                RecRef: RecordRef;
                xRecRef: RecordRef;
            begin
                xRecRef.GETTABLE(xRec);
                MODIFY;
                RecRef.GETTABLE(Rec);
                ChangeLogMgt.LogModification(RecRef,xRecRef);

                TempDocDim.GetDimensions(DATABASE::"Sales Header","Document Type","No.",0,TempDocDim);

                CreateDim(
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");

                IF SalesLinesExist THEN
                  TempDocDim.UpdateAllLineDim(DATABASE::"Sales Header","Document Type","No.",TempDocDim);
            end;
        }
        field(5051;"Sell-to Customer Template Code";Code[10])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Template";

            trigger OnValidate()
            var
                SellToCustTemplate: Record "5105";
            begin
                TESTFIELD("Document Type","Document Type"::Quote);
                TESTFIELD(Status,Status::Open);

                IF NOT InsertMode AND
                   ("Sell-to Customer Template Code" <> xRec."Sell-to Customer Template Code") AND
                   (xRec."Sell-to Customer Template Code" <> '')
                THEN BEGIN
                  IF HideValidationDialog THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(Text004,FALSE,FIELDCAPTION("Sell-to Customer Template Code"));
                  IF Confirmed THEN BEGIN
                    SalesLine.RESET;
                    SalesLine.SETRANGE("Document Type","Document Type");
                    SalesLine.SETRANGE("Document No.","No.");
                    IF "Sell-to Customer Template Code" = '' THEN BEGIN
                      IF NOT SalesLine.ISEMPTY THEN
                        ERROR(Text005,FIELDCAPTION("Sell-to Customer Template Code"));
                      INIT;
                      SalesSetup.GET;
                      InitRecord;
                      "No. Series" := xRec."No. Series";
                      IF xRec."Shipping No." <> '' THEN BEGIN
                        "Shipping No. Series" := xRec."Shipping No. Series";
                        "Shipping No." := xRec."Shipping No.";
                      END;
                      IF xRec."Posting No." <> '' THEN BEGIN
                        "Posting No. Series" := xRec."Posting No. Series";
                        "Posting No." := xRec."Posting No.";
                      END;
                      IF xRec."Return Receipt No." <> '' THEN BEGIN
                        "Return Receipt No. Series" := xRec."Return Receipt No. Series";
                        "Return Receipt No." := xRec."Return Receipt No.";
                      END;
                      IF xRec."Prepayment No." <> '' THEN BEGIN
                        "Prepayment No. Series" := xRec."Prepayment No. Series";
                        "Prepayment No." := xRec."Prepayment No.";
                      END;
                      IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
                        "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
                        "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
                      END;
                      EXIT;
                    END;
                  END ELSE BEGIN
                    "Sell-to Customer Template Code" := xRec."Sell-to Customer Template Code";
                    EXIT;
                  END;
                END;

                IF SellToCustTemplate.GET("Sell-to Customer Template Code") THEN BEGIN
                  SellToCustTemplate.TESTFIELD("Gen. Bus. Posting Group");
                  "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
                  "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
                  IF "Bill-to Customer No." = '' THEN
                    VALIDATE("Bill-to Customer Template Code","Sell-to Customer Template Code");
                END;

                IF NOT InsertMode AND
                   ((xRec."Sell-to Customer Template Code" <> "Sell-to Customer Template Code") OR
                    (xRec."Currency Code" <> "Currency Code"))
                THEN
                  RecreateSalesLines(FIELDCAPTION("Sell-to Customer Template Code"));
            end;
        }
        field(5052;"Sell-to Contact No.";Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record "5050";
                ContBusinessRelation: Record "5054";
            begin
                IF "Sell-to Customer No." <> '' THEN BEGIN
                  IF Cont.GET("Sell-to Contact No.") THEN
                    Cont.SETRANGE("Company No.",Cont."Company No.")
                  ELSE BEGIN
                    ContBusinessRelation.RESET;
                    ContBusinessRelation.SETCURRENTKEY("Link to Table","No.");
                    ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
                    ContBusinessRelation.SETRANGE("No.","Sell-to Customer No.");
                    IF ContBusinessRelation.FINDFIRST THEN
                      Cont.SETRANGE("Company No.",ContBusinessRelation."Contact No.")
                    ELSE
                      Cont.SETRANGE("No.",'');
                  END;
                END;

                IF "Sell-to Contact No." <> '' THEN
                  IF Cont.GET("Sell-to Contact No.") THEN ;
                IF FORM.RUNMODAL(0,Cont) = ACTION::LookupOK THEN BEGIN
                  xRec := Rec;
                  VALIDATE("Sell-to Contact No.",Cont."No.");
                END;
            end;

            trigger OnValidate()
            var
                ContBusinessRelation: Record "5054";
                Cont: Record "5050";
                Opportunity: Record "5092";
                ChangeLogMgt: Codeunit "423";
                RecRef: RecordRef;
                xRecRef: RecordRef;
            begin
                TESTFIELD(Status,Status::Open);

                IF ("Sell-to Contact No." <> xRec."Sell-to Contact No.") AND
                   (xRec."Sell-to Contact No." <> '')
                THEN BEGIN
                  IF ("Sell-to Contact No." = '') AND ("Opportunity No." <> '') THEN
                    ERROR(Text049,FIELDCAPTION("Sell-to Contact No."));
                  IF HideValidationDialog OR NOT GUIALLOWED THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(Text004,FALSE,FIELDCAPTION("Sell-to Contact No."));
                  IF Confirmed THEN BEGIN
                    SalesLine.RESET;
                    SalesLine.SETRANGE("Document Type","Document Type");
                    SalesLine.SETRANGE("Document No.","No.");
                    IF ("Sell-to Contact No." = '') AND ("Sell-to Customer No." = '') THEN BEGIN
                      IF NOT SalesLine.ISEMPTY THEN
                        ERROR(Text005,FIELDCAPTION("Sell-to Contact No."));
                      INIT;
                      SalesSetup.GET;
                      InitRecord;
                      "No. Series" := xRec."No. Series";
                      IF xRec."Shipping No." <> '' THEN BEGIN
                        "Shipping No. Series" := xRec."Shipping No. Series";
                        "Shipping No." := xRec."Shipping No.";
                      END;
                      IF xRec."Posting No." <> '' THEN BEGIN
                        "Posting No. Series" := xRec."Posting No. Series";
                        "Posting No." := xRec."Posting No.";
                      END;
                      IF xRec."Return Receipt No." <> '' THEN BEGIN
                        "Return Receipt No. Series" := xRec."Return Receipt No. Series";
                        "Return Receipt No." := xRec."Return Receipt No.";
                      END;
                      IF xRec."Prepayment No." <> '' THEN BEGIN
                        "Prepayment No. Series" := xRec."Prepayment No. Series";
                        "Prepayment No." := xRec."Prepayment No.";
                      END;
                      IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
                        "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
                        "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
                      END;
                      EXIT;
                    END;
                    IF "Opportunity No." <> '' THEN BEGIN
                      Opportunity.GET("Opportunity No.");
                      IF Opportunity."Contact No." <> "Sell-to Contact No." THEN BEGIN
                        xRecRef.GETTABLE(xRec);
                        MODIFY;
                        RecRef.GETTABLE(Rec);
                        ChangeLogMgt.LogModification(RecRef,xRecRef);
                        xRecRef.GETTABLE(Opportunity);
                        Opportunity.VALIDATE("Contact No.","Sell-to Contact No.");
                        Opportunity.MODIFY;
                        RecRef.GETTABLE(Opportunity);
                        ChangeLogMgt.LogModification(RecRef,xRecRef);
                      END
                    END;
                  END ELSE BEGIN
                    Rec := xRec;
                    EXIT;
                  END;
                END;

                IF ("Sell-to Customer No." <> '') AND ("Sell-to Contact No." <> '') THEN BEGIN
                  Cont.GET("Sell-to Contact No.");
                  ContBusinessRelation.RESET;
                  ContBusinessRelation.SETCURRENTKEY("Link to Table","No.");
                  ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
                  ContBusinessRelation.SETRANGE("No.","Sell-to Customer No.");
                  IF ContBusinessRelation.FINDFIRST THEN
                    IF ContBusinessRelation."Contact No." <> Cont."Company No." THEN
                      ERROR(Text038,Cont."No.",Cont.Name,"Sell-to Customer No.");
                END;

                UpdateSellToCust("Sell-to Contact No.");
            end;
        }
        field(5053;"Bill-to Contact No.";Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record "5050";
                ContBusinessRelation: Record "5054";
            begin
                IF "Bill-to Customer No." <> '' THEN BEGIN
                  IF Cont.GET("Bill-to Contact No.") THEN
                    Cont.SETRANGE("Company No.",Cont."Company No.")
                  ELSE BEGIN
                    ContBusinessRelation.RESET;
                    ContBusinessRelation.SETCURRENTKEY("Link to Table","No.");
                    ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
                    ContBusinessRelation.SETRANGE("No.","Bill-to Customer No.");
                    IF ContBusinessRelation.FINDFIRST THEN
                      Cont.SETRANGE("Company No.",ContBusinessRelation."Contact No.")
                    ELSE
                      Cont.SETRANGE("No.",'');
                  END;
                END;

                IF "Bill-to Contact No." <> '' THEN
                  IF Cont.GET("Bill-to Contact No.") THEN ;
                IF FORM.RUNMODAL(0,Cont) = ACTION::LookupOK THEN BEGIN
                  xRec := Rec;
                  VALIDATE("Bill-to Contact No.",Cont."No.");
                END;
            end;

            trigger OnValidate()
            var
                ContBusinessRelation: Record "5054";
                Cont: Record "5050";
            begin
                TESTFIELD(Status,Status::Open);

                IF ("Bill-to Contact No." <> xRec."Bill-to Contact No.") AND
                   (xRec."Bill-to Contact No." <> '')
                THEN BEGIN
                  IF HideValidationDialog THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(Text004,FALSE,FIELDCAPTION("Bill-to Contact No."));
                  IF Confirmed THEN BEGIN
                    SalesLine.RESET;
                    SalesLine.SETRANGE("Document Type","Document Type");
                    SalesLine.SETRANGE("Document No.","No.");
                    IF ("Bill-to Contact No." = '') AND ("Bill-to Customer No." = '') THEN BEGIN
                      IF NOT SalesLine.ISEMPTY THEN
                        ERROR(Text005,FIELDCAPTION("Bill-to Contact No."));
                      INIT;
                      SalesSetup.GET;
                      InitRecord;
                      "No. Series" := xRec."No. Series";
                      IF xRec."Shipping No." <> '' THEN BEGIN
                        "Shipping No. Series" := xRec."Shipping No. Series";
                        "Shipping No." := xRec."Shipping No.";
                      END;
                      IF xRec."Posting No." <> '' THEN BEGIN
                        "Posting No. Series" := xRec."Posting No. Series";
                        "Posting No." := xRec."Posting No.";
                      END;
                      IF xRec."Return Receipt No." <> '' THEN BEGIN
                        "Return Receipt No. Series" := xRec."Return Receipt No. Series";
                        "Return Receipt No." := xRec."Return Receipt No.";
                      END;
                      IF xRec."Prepayment No." <> '' THEN BEGIN
                        "Prepayment No. Series" := xRec."Prepayment No. Series";
                        "Prepayment No." := xRec."Prepayment No.";
                      END;
                      IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
                        "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
                        "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
                      END;
                      EXIT;
                    END;
                  END ELSE BEGIN
                    "Bill-to Contact No." := xRec."Bill-to Contact No.";
                    EXIT;
                  END;
                END;

                IF ("Bill-to Customer No." <> '') AND ("Bill-to Contact No." <> '') THEN BEGIN
                  Cont.GET("Bill-to Contact No.");
                  ContBusinessRelation.RESET;
                  ContBusinessRelation.SETCURRENTKEY("Link to Table","No.");
                  ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
                  ContBusinessRelation.SETRANGE("No.","Bill-to Customer No.");
                  IF ContBusinessRelation.FINDFIRST THEN
                    IF ContBusinessRelation."Contact No." <> Cont."Company No." THEN
                      ERROR(Text038,Cont."No.",Cont.Name,"Bill-to Customer No.");
                END;

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5054;"Bill-to Customer Template Code";Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Template";

            trigger OnValidate()
            var
                BillToCustTemplate: Record "5105";
                TempDocDim: Record "357" temporary;
            begin
                TESTFIELD("Document Type","Document Type"::Quote);
                TESTFIELD(Status,Status::Open);

                IF NOT InsertMode AND
                   ("Bill-to Customer Template Code" <> xRec."Bill-to Customer Template Code") AND
                   (xRec."Bill-to Customer Template Code" <> '')
                THEN BEGIN
                  IF HideValidationDialog THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(Text004,FALSE,FIELDCAPTION("Bill-to Customer Template Code"));
                  IF Confirmed THEN BEGIN
                    SalesLine.RESET;
                    SalesLine.SETRANGE("Document Type","Document Type");
                    SalesLine.SETRANGE("Document No.","No.");
                    IF "Bill-to Customer Template Code" = '' THEN BEGIN
                      IF NOT SalesLine.ISEMPTY THEN
                        ERROR(Text005,FIELDCAPTION("Bill-to Customer Template Code"));
                      INIT;
                      SalesSetup.GET;
                      InitRecord;
                      "No. Series" := xRec."No. Series";
                      IF xRec."Shipping No." <> '' THEN BEGIN
                        "Shipping No. Series" := xRec."Shipping No. Series";
                        "Shipping No." := xRec."Shipping No.";
                      END;
                      IF xRec."Posting No." <> '' THEN BEGIN
                        "Posting No. Series" := xRec."Posting No. Series";
                        "Posting No." := xRec."Posting No.";
                      END;
                      IF xRec."Return Receipt No." <> '' THEN BEGIN
                        "Return Receipt No. Series" := xRec."Return Receipt No. Series";
                        "Return Receipt No." := xRec."Return Receipt No.";
                      END;
                      IF xRec."Prepayment No." <> '' THEN BEGIN
                        "Prepayment No. Series" := xRec."Prepayment No. Series";
                        "Prepayment No." := xRec."Prepayment No.";
                      END;
                      IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
                        "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
                        "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
                      END;
                      EXIT;
                    END;
                  END ELSE BEGIN
                    "Bill-to Customer Template Code" := xRec."Bill-to Customer Template Code";
                    EXIT;
                  END;
                END;

                VALIDATE("Ship-to Code",'');
                IF BillToCustTemplate.GET("Bill-to Customer Template Code") THEN BEGIN
                  BillToCustTemplate.TESTFIELD("Customer Posting Group");
                  "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
                  "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
                  "Customer Price Group" := BillToCustTemplate."Customer Price Group";
                  "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
                  "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
                  VALIDATE("Payment Terms Code",BillToCustTemplate."Payment Terms Code");
                  VALIDATE("Payment Method Code",BillToCustTemplate."Payment Method Code");
                  "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";
                END;

                TempDocDim.GetDimensions(DATABASE::"Sales Header","Document Type","No.",0,TempDocDim);
                CreateDim(
                  DATABASE::"Customer Template","Bill-to Customer Template Code",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Responsibility Center","Responsibility Center");
                IF SalesLinesExist THEN
                  TempDocDim.UpdateAllLineDim(DATABASE::"Sales Header","Document Type","No.",TempDocDim);

                IF NOT InsertMode AND
                   (xRec."Sell-to Customer Template Code" = "Sell-to Customer Template Code") AND
                   (xRec."Bill-to Customer Template Code" <> "Bill-to Customer Template Code")
                THEN
                  RecreateSalesLines(FIELDCAPTION("Bill-to Customer Template Code"));
            end;
        }
        field(5055;"Opportunity No.";Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = IF (Document Type=FILTER(<>Order)) Opportunity.No. WHERE (Contact No.=FIELD(Sell-to Contact No.),
                                                                                      Closed=CONST(No))
                                                                                      ELSE IF (Document Type=CONST(Order)) Opportunity.No. WHERE (Contact No.=FIELD(Sell-to Contact No.),
                                                                                                                                                  Sales Document No.=FIELD(No.),
                                                                                                                                                  Sales Document Type=CONST(Order));

            trigger OnValidate()
            var
                Opportunity: Record "5092";
                SalesHeader: Record "36";
            begin
                IF xRec."Opportunity No." <> "Opportunity No." THEN BEGIN
                  IF "Opportunity No." <> '' THEN
                    IF Opportunity.GET("Opportunity No.") THEN BEGIN
                      Opportunity.TESTFIELD(Status,Opportunity.Status::"In Progress");
                      IF Opportunity."Sales Document No." <> '' THEN BEGIN
                        IF CONFIRM(Text048,FALSE,Opportunity."Sales Document No.",Opportunity."No.") THEN BEGIN
                          IF SalesHeader.GET("Document Type"::Quote,Opportunity."Sales Document No.") THEN BEGIN
                            SalesHeader."Opportunity No." := '';
                            SalesHeader.MODIFY;
                          END;
                          Opportunity."Sales Document Type" := Opportunity."Sales Document Type"::Quote;
                          Opportunity."Sales Document No." := "No.";
                          Opportunity.MODIFY;
                        END ELSE
                          "Opportunity No." := xRec."Opportunity No.";
                      END ELSE BEGIN
                        Opportunity."Sales Document Type" := Opportunity."Sales Document Type"::Quote;
                        Opportunity."Sales Document No." := "No.";
                        Opportunity.MODIFY;
                      END
                    END;
                  IF xRec."Opportunity No." <> '' THEN
                    IF Opportunity.GET(xRec."Opportunity No.") THEN BEGIN
                      Opportunity."Sales Document No." := '';
                      Opportunity."Sales Document Type" := Opportunity."Sales Document Type"::" ";
                      Opportunity.MODIFY;
                    END;
                END;
            end;
        }
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            var
                lLocationCode: Code[10];
                lStore: Record "99001470";
            begin
                TESTFIELD(Status,Status::Open);
                IF NOT UserMgt.CheckRespCenter(0,"Responsibility Center") THEN
                  ERROR(
                    Text027,
                    RespCenter.TABLECAPTION,UserMgt.GetSalesFilter);

                //LS -
                //"Location Code" := UserMgt.GetLocation(0,'',"Responsibility Center");
                IF "Store No." = '' THEN BEGIN
                  lLocationCode := UserMgt.GetLocation(0,'',"Responsibility Center");
                  IF lLocationCode = '' THEN
                    "Store No." := ''
                  ELSE BEGIN
                    lStore.FindStore(lLocationCode, lStore);
                    "Store No." := lStore."No.";
                    VALIDATE("Location Code", lLocationCode)
                  END
                END;
                //LS +

                IF "Location Code" <> '' THEN BEGIN
                  IF Location.GET("Location Code") THEN
                    "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                END ELSE BEGIN
                  IF InvtSetup.GET THEN
                    "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                END;

                UpdateShipToAddress;

                CreateDim(
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");

                IF xRec."Responsibility Center" <> "Responsibility Center" THEN BEGIN
                  RecreateSalesLines(FIELDCAPTION("Responsibility Center"));
                  "Assigned User ID" := '';
                END;
            end;
        }
        field(5750;"Shipping Advice";Option)
        {
            Caption = 'Shipping Advice';
            OptionCaption = 'Partial,Complete';
            OptionMembers = Partial,Complete;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                WhseSourceHeader.SalesHeaderVerifyChange(Rec,xRec);
            end;
        }
        field(5752;"Completely Shipped";Boolean)
        {
            CalcFormula = Min("Sales Line"."Completely Shipped" WHERE (Document Type=FIELD(Document Type),
                                                                       Document No.=FIELD(No.),
                                                                       Type=FILTER(<>' '),
                                                                       Location Code=FIELD(Location Filter)));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753;"Posting from Whse. Ref.";Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754;"Location Filter";Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5790;"Requested Delivery Date";Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF "Promised Delivery Date" <> 0D THEN
                  ERROR(
                    Text028,
                    FIELDCAPTION("Requested Delivery Date"),
                    FIELDCAPTION("Promised Delivery Date"));

                IF "Requested Delivery Date" <> xRec."Requested Delivery Date" THEN
                  UpdateSalesLines(FIELDCAPTION("Requested Delivery Date"),CurrFieldNo <> 0);
            end;
        }
        field(5791;"Promised Delivery Date";Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF "Promised Delivery Date" <> xRec."Promised Delivery Date" THEN
                  UpdateSalesLines(FIELDCAPTION("Promised Delivery Date"),CurrFieldNo <> 0);
            end;
        }
        field(5792;"Shipping Time";DateFormula)
        {
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF "Shipping Time" <> xRec."Shipping Time" THEN
                  UpdateSalesLines(FIELDCAPTION("Shipping Time"),CurrFieldNo <> 0);
            end;
        }
        field(5793;"Outbound Whse. Handling Time";DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                IF ("Outbound Whse. Handling Time" <> xRec."Outbound Whse. Handling Time") AND
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                THEN
                  UpdateSalesLines(FIELDCAPTION("Outbound Whse. Handling Time"),CurrFieldNo <> 0);
            end;
        }
        field(5794;"Shipping Agent Service Code";Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE (Shipping Agent Code=FIELD(Shipping Agent Code));

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                GetShippingTime(FIELDNO("Shipping Agent Service Code"));
                UpdateSalesLines(FIELDCAPTION("Shipping Agent Service Code"),CurrFieldNo <> 0);
            end;
        }
        field(5795;"Late Order Shipping";Boolean)
        {
            CalcFormula = Exist("Sales Line" WHERE (Document Type=FIELD(Document Type),
                                                    Sell-to Customer No.=FIELD(Sell-to Customer No.),
                                                    Document No.=FIELD(No.),
                                                    Shipment Date=FIELD(Date Filter),
                                                    Outstanding Quantity=FILTER(<>0)));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796;"Date Filter";Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800;Receive;Boolean)
        {
            Caption = 'Receive';
        }
        field(5801;"Return Receipt No.";Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        field(5802;"Return Receipt No. Series";Code[10])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Return Receipt Nos.");
                  IF NoSeriesMgt.LookupSeries(SalesSetup."Posted Return Receipt Nos.","Return Receipt No. Series") THEN
                    VALIDATE("Return Receipt No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate()
            begin
                IF "Return Receipt No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Return Receipt Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Return Receipt Nos.","Return Receipt No. Series");
                END;
                TESTFIELD("Return Receipt No.",'');
            end;
        }
        field(5803;"Last Return Receipt No.";Code[20])
        {
            Caption = 'Last Return Receipt No.';
            Editable = false;
            TableRelation = "Return Receipt Header";
        }
        field(7001;"Allow Line Disc.";Boolean)
        {
            Caption = 'Allow Line Disc.';

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Allow Line Disc."));
            end;
        }
        field(7200;"Get Shipment Used";Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        field(8725;Signature;BLOB)
        {
            Caption = 'Signature';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
            SubType = Bitmap;
        }
        field(9000;"Assigned User ID";Code[20])
        {
            Caption = 'Assigned User ID';
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                IF NOT UserMgt.CheckRespCenter2(0,"Responsibility Center","Assigned User ID") THEN
                  ERROR(
                    Text061,"Assigned User ID",
                    RespCenter.TABLECAPTION,UserMgt.GetSalesFilter2("Assigned User ID"));
            end;
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
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
        field(50208;"SO Lines Reversed";Boolean)
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
            CalcFormula = Sum("Sales Line"."Offer Amount" WHERE (Document Type=FIELD(Document Type),
                                                                 Document No.=FIELD(No.)));
            Description = 'APNT-HRU1.0';
            Editable = false;
            FieldClass = FlowField;
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
        field(50311;"Customer Consent";Boolean)
        {
            Description = 'MJK';

            trigger OnValidate()
            begin
                 IF NOT  "Transaction Posted" THEN  ERROR('Transaction Posted Must Be True');
            end;
        }
        field(50800;"eCOM Order";Boolean)
        {
            Description = 'eCom';
        }
        field(50801;"Magento Last Status";Text[100])
        {
            CalcFormula = Lookup("eCom Customer Order Status".MAG-Status WHERE (Entry No.=FIELD(Magento Last Entry No)));
            Description = 'eCom';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50802;"Magento Last Entry No";Integer)
        {
            CalcFormula = Max("eCom Customer Order Status"."Entry No." WHERE (Document ID=FIELD(No.)));
            Description = 'eCom';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50803;"NAV Last Status";Text[100])
        {
            CalcFormula = Lookup("eCom Customer Order Status".NAV-Status WHERE (Entry No.=FIELD(Magento Last Entry No)));
            Description = 'eCom';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50850;"eCom Original Sales Order No.";Code[20])
        {
            Description = 'eCom';
        }
        field(50851;"eCom Original Sales Invoice No";Code[20])
        {
            Description = 'eCom-CR';
        }
        field(10000700;"Batch No.";Code[10])
        {
            Caption = 'Batch No.';
        }
        field(10000701;"Store No.";Code[10])
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
                //APNT1.0
                VALIDATE("Location Code");
                //APNT1.0
            end;
        }
        field(10000709;"POS ID";Code[20])
        {
            Caption = 'POS ID';
        }
        field(10000710;"Posting Time";Time)
        {
            Caption = 'Posting Time';
        }
        field(10000711;"Cashier ID";Code[10])
        {
            Caption = 'Cashier ID';
        }
        field(10000771;"Only Two Dimensions";Boolean)
        {
            Caption = 'Only Two Dimensions';
        }
        field(10000780;"Not Show Dialog";Boolean)
        {
            Caption = 'Not Show Dialog';
            Editable = false;
        }
        field(10001000;"InStore-Created Entry";Boolean)
        {
            Caption = 'InStore-Created Entry';
            Description = 'LS6.1-04';
        }
        field(10001200;"Sales Type";Code[20])
        {
            Caption = 'Sales Type';
            TableRelation = "Sales Type".Code;
        }
        field(10001201;"POS Comment";Text[30])
        {
            Caption = 'POS Comment';
        }
        field(10001300;"Retail Status";Option)
        {
            Caption = 'Retail Status';
            OptionCaption = 'New,Sent,Part. receipt,Closed - ok,Closed - difference';
            OptionMembers = New,Sent,"Part. receipt","Closed - ok","Closed - difference";
        }
        field(10001301;"Receiving/Picking No.";Code[20])
        {
            Caption = 'Receiving/Picking No.';
            TableRelation = "Posted P/R Counting Header";
        }
        field(10001303;"xRetail Location Code";Code[10])
        {
            Caption = 'Retail Location Code';
        }
        field(10001350;"Ownership Send Date";Date)
        {
            Caption = 'Ownership Send Date';
            Description = 'LS6.1-04';

            trigger OnValidate()
            var
                lText000: Label 'This action is only valid at HO';
                lText001: Label '%1 can only be set later than %2';
                InStoreDistLocation: Record "10001351";
                InStoreHeader: Record "10001352";
                InStoreDocNo: Code[20];
                lText002: Label 'Action only valid for purchase requests';
                lText003: Label 'Action only valid for documents owned by HO';
                lText004: Label 'Action only valid for offline stores';
            begin
                IF "Ownership Send Date" <> 0D THEN BEGIN
                  IF NOT InStoreFunc.IsThisHO THEN
                    ERROR(lText000);
                  IF NOT InStoreDistLocation.GET(InStoreFunc.GetStoreByLocation("Location Code")) THEN
                    ERROR(lText004);
                  IF (InStoreDistLocation."Connection Method" <> InStoreDistLocation."Connection Method"::OffLine) THEN
                    ERROR(lText004);
                  IF "Ownership Send Date" <= TODAY THEN
                    ERROR(lText001,FIELDCAPTION("Ownership Send Date"),TODAY);
                  InStoreDocNo := InStoreFunc.GetSalesDocNo(Rec);
                  IF InStoreDocNo <> '' THEN BEGIN
                    InStoreHeader.GET(InStoreDocNo);
                    IF InStoreHeader."Status Code" <> 'REQUEST' THEN
                      ERROR(lText002);
                    IF InStoreHeader."Owner Dist. Location" <> InStoreFunc.GetHODistLocationCode THEN
                      ERROR(lText003);
                  END;
                END;
            end;
        }
        field(10012700;"Ring Back Date";Date)
        {
            Caption = 'Ring Back Date';
        }
        field(10012701;"Ship-To Telephone";Text[30])
        {
            Caption = 'Ship-To Telephone';
        }
        field(10012706;"General Comments";Text[250])
        {
            Caption = 'General Comments';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
        field(10012707;"Delivery Comments";Text[250])
        {
            Caption = 'Delivery Comments';
        }
        field(10012708;"Last Shipment Date";Date)
        {
            CalcFormula = Lookup("Sales Shipment Header"."Posting Date" WHERE (No.=FIELD(Last Shipping No.)));
            Caption = 'Last Shipment Date';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012709;"Order Amount";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Line Amount" WHERE (Document Type=FIELD(Document Type),
                                                                Document No.=FIELD(No.)));
            Caption = 'Order Amount';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012710;"Retail Special Order";Boolean)
        {
            Caption = 'Retail Special Order';
            Editable = false;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND NOT(xRec."Retail Special Order") THEN BEGIN
                  IF NOT("Prices Including VAT") THEN
                    VALIDATE("Prices Including VAT", TRUE);
                END;
                //LS +
            end;
        }
        field(10012711;"Customer Contact Date";Date)
        {
            Caption = 'Customer Contact Date';
        }
        field(10012715;"Special Order Origin";Option)
        {
            Caption = 'Special Order Origin';
            OptionCaption = 'Blank,POS,Sales Order';
            OptionMembers = Blank,POS,"Sales Order";
        }
        field(10012719;"Delivery Reference No";Text[30])
        {
            Caption = 'Delivery Reference No';
        }
        field(10012720;"SPO-Created Entry";Boolean)
        {
            Caption = 'SPO-Created Entry';
        }
        field(10012728;"Bill-to House No.";Text[30])
        {
            Caption = 'Bill-to House No.';
        }
        field(10012729;"Ship-to House No.";Text[30])
        {
            Caption = 'Ship-to House No.';
        }
        field(10012750;"Estimated Delivery Date";Date)
        {
            Caption = 'Estimated Delivery Date';
        }
        field(10012752;"Payment-At Order Entry-Limit";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Payment-At Order Entry-Limit" WHERE (Document Type=FIELD(Document Type),
                                                                                 Document No.=FIELD(No.),
                                                                                 Retail Special Order=CONST(Yes)));
            Caption = 'Payment-At Order Entry-Limit';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012753;"Payment-At Delivery-Limit";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Payment-At Delivery-Limit" WHERE (Document Type=FIELD(Document Type),
                                                                              Document No.=FIELD(No.),
                                                                              Retail Special Order=CONST(Yes)));
            Caption = 'Payment-At Delivery-Limit';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012754;"Total Payment";Decimal)
        {
            CalcFormula = Sum("SPO Payment Lines".Amount WHERE (Document Type=FIELD(Document Type),
                                                                Document No.=FIELD(No.)));
            Caption = 'Total Payment';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012755;"Phone No.";Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10012756;"Daytime Phone No.";Text[30])
        {
            Caption = 'Daytime Phone No.';
        }
        field(10012757;"Mobile Phone No.";Text[30])
        {
            Caption = 'Mobile Phone No.';
        }
        field(10012758;"E-Mail";Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }
        field(10012760;"Cont. Mail";Boolean)
        {
            Caption = 'Cont. Mail';
        }
        field(10012761;"Cont. Phone";Boolean)
        {
            Caption = 'Cont. Phone';
        }
        field(10012762;"Cont. E-mail";Boolean)
        {
            Caption = 'Cont. E-mail';
        }
        field(10012763;"Source Code";Code[10])
        {
            Caption = 'Source Code';
        }
        field(10012764;"Retail Zones Code";Code[10])
        {
            Caption = 'Retail Zones Code';
            TableRelation = "Retail Zone";
        }
        field(10012765;"Retail Zones Description";Text[30])
        {
            CalcFormula = Lookup("Retail Zone".Description WHERE (Code=FIELD(Retail Zones Code)));
            Caption = 'Retail Zones Description';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012767;"Non Refund Amount";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Non Refund Amount" WHERE (Document Type=FIELD(Document Type),
                                                                      Document No.=FIELD(No.)));
            Caption = 'Non Refund Amount';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012768;"Payment-At PurchaseOrder-Limit";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Payment-At PurchaseOrder-Limit" WHERE (Document Type=FIELD(Document Type),
                                                                                   Document No.=FIELD(No.)));
            Caption = 'Payment-At PurchaseOrder-Limit';
            Description = 'LS6.1-07';
            Editable = false;
            FieldClass = FlowField;
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
        field(99001450;"Statement No.";Code[20])
        {
            Caption = 'Statement No.';
        }
        field(99008500;"Date Received";Date)
        {
            Caption = 'Date Received';
        }
        field(99008501;"Time Received";Time)
        {
            Caption = 'Time Received';
        }
        field(99008502;"BizTalk Request for Sales Qte.";Boolean)
        {
            Caption = 'BizTalk Request for Sales Qte.';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
        field(99008503;"BizTalk Sales Order";Boolean)
        {
            Caption = 'BizTalk Sales Order';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
        field(99008509;"Date Sent";Date)
        {
            Caption = 'Date Sent';
        }
        field(99008510;"Time Sent";Time)
        {
            Caption = 'Time Sent';
        }
        field(99008513;"BizTalk Sales Quote";Boolean)
        {
            Caption = 'BizTalk Sales Quote';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
        field(99008514;"BizTalk Sales Order Cnfmn.";Boolean)
        {
            Caption = 'BizTalk Sales Order Cnfmn.';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
        field(99008518;"Customer Quote No.";Code[20])
        {
            Caption = 'Customer Quote No.';
            Description = 'APNT-HRU1.0 (disabled)';
            Enabled = false;
        }
        field(99008519;"Customer Order No.";Code[20])
        {
            Caption = 'Customer Order No.';
        }
        field(99008521;"BizTalk Document Sent";Boolean)
        {
            Caption = 'BizTalk Document Sent';
            Description = 'APNT-SUJ1.0(disabled to activate "Delivery Reference No" and "Ship-To Telephone")';
            Enabled = false;
        }
    }

    keys
    {
        key(Key1;"Document Type","No.")
        {
            Clustered = true;
        }
        key(Key2;"No.","Document Type")
        {
        }
        key(Key3;"Document Type","Sell-to Customer No.","No.")
        {
        }
        key(Key4;"Document Type","Combine Shipments","Bill-to Customer No.","Currency Code")
        {
        }
        key(Key5;"Sell-to Customer No.","External Document No.")
        {
        }
        key(Key6;"Document Type","Sell-to Contact No.")
        {
        }
        key(Key7;"Bill-to Contact No.")
        {
        }
        key(Key8;"Salesperson Code","Order Date")
        {
        }
        key(Key9;"Location Code","Order Date")
        {
        }
        key(Key10;"Ship-to Post Code")
        {
        }
        key(Key11;"Document Type","Sell-to Customer No.","Sell-to Contact No.")
        {
        }
        key(Key12;"Ownership Send Date")
        {
        }
        key(Key13;"External Document No.")
        {
        }
        key(Key14;"Sell-to Customer Name","Posting Date","Mobile Phone No.","Phone No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Opp: Record "5092";
        TempOpportunityEntry: Record "5093" temporary;
        WorkOrderLine: Record "33016825";
        WorkOrderMgt: Codeunit "33016800";
        PremiseMgtSetup: Record "33016826";
    begin
        IF NOT UserMgt.CheckRespCenter(0,"Responsibility Center") THEN
          ERROR(
            Text022,
            RespCenter.TABLECAPTION,UserMgt.GetSalesFilter);
        //DP6.01.01 START
        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Converted Sales. Doc No.","No.");
        WorkOrderLine.SETRANGE("Converted Sales. Doc Type","Document Type");
        IF WorkOrderLine.FINDSET THEN REPEAT
          WorkOrderLine."Converted Sales. Doc No." := '';
          WorkOrderLine."Converted Sales. Doc Line No." := 0;
          WorkOrderLine."Converted Sales. Doc Datetime" := 0DT;
          WorkOrderLine."Converted Sales. Doc Type" := 0;
          WorkOrderLine."Convert to Sales Doc Type" := 0;
          WorkOrderLine.MODIFY;
        UNTIL WorkOrderLine.NEXT = 0;

        PremiseMgtSetup.GET;
        IF PremiseMgtSetup."Revenue Sharing" THEN BEGIN
          IF "Document Type" = "Document Type"::Invoice THEN BEGIN
            CLEAR(WorkOrderMgt);
            WorkOrderMgt.ReverseClientRevenueInvoice("No.");
          END;
        END;
        //DP6.01.01 STOP

        IF ("Opportunity No." <> '') AND
           ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order])
        THEN BEGIN
          IF Opp.GET("Opportunity No.") THEN BEGIN
            IF ("Document Type" = "Document Type"::Order) THEN BEGIN
              IF NOT CONFIRM(Text040 + Text041 + Text042,TRUE) THEN
                ERROR(Text044);
              TempOpportunityEntry.INIT;
              TempOpportunityEntry.VALIDATE("Opportunity No.",Opp."No.");
              TempOpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
              TempOpportunityEntry."Contact No." := Opp."Contact No.";
              TempOpportunityEntry."Contact Company No." := Opp."Contact Company No.";
              TempOpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
              TempOpportunityEntry."Campaign No." := Opp."Campaign No.";
              TempOpportunityEntry."Action Taken" := TempOpportunityEntry."Action Taken"::Lost;
              TempOpportunityEntry.INSERT;
              TempOpportunityEntry.SETRANGE("Action Taken",TempOpportunityEntry."Action Taken"::Lost);
              FORM.RUNMODAL(FORM::"Close Opportunity",TempOpportunityEntry);
              IF Opp.GET("Opportunity No.") THEN
                IF Opp.Status <> Opp.Status::Lost THEN
                  ERROR(Text043);
            END;
            Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
            Opp."Sales Document No." := '';
            Opp.MODIFY;
            "Opportunity No." := '';
          END;
        END;

        SalesPost.DeleteHeader(
          Rec,SalesShptHeader,SalesInvHeader,SalesCrMemoHeader,ReturnRcptHeader,SalesInvHeaderPrepmt,SalesCrMemoHeaderPrepmt);
        VALIDATE("Applies-to ID",'');

        //LS -
        IF BOUtils.IsInStorePermitted THEN
          InStoreMgt.SendSalesDocDelete(Rec);
        //LS +

        DimMgt.DeleteDocDim(DATABASE::"Sales Header","Document Type","No.",0);

        ApprovalMgt.DeleteApprovalEntry(DATABASE::"Sales Header","Document Type","No.");
        SalesLine.RESET;
        SalesLine.LOCKTABLE;

        WhseRequest.SETRANGE("Source Type",DATABASE::"Sales Line");
        WhseRequest.SETRANGE("Source Subtype","Document Type");
        WhseRequest.SETRANGE("Source No.","No.");
        WhseRequest.DELETEALL(TRUE);

        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETRANGE(Type,SalesLine.Type::"Charge (Item)");

        DeleteSalesLines;
        SalesLine.SETRANGE(Type);
        DeleteSalesLines;

        SalesCommentLine.SETRANGE("Document Type","Document Type");
        SalesCommentLine.SETRANGE("No.","No.");
        SalesCommentLine.DELETEALL;

        IF (SalesShptHeader."No." <> '') OR
           (SalesInvHeader."No." <> '') OR
           (SalesCrMemoHeader."No." <> '') OR
           (ReturnRcptHeader."No." <> '') OR
           (SalesInvHeaderPrepmt."No." <> '') OR
           (SalesCrMemoHeaderPrepmt."No." <> '')
        THEN BEGIN
          DELETE;
          COMMIT;

          IF SalesShptHeader."No." <> '' THEN
            IF CONFIRM(
                 Text000,TRUE,
                 SalesShptHeader."No.")
            THEN BEGIN
              SalesShptHeader.SETRECFILTER;
              SalesShptHeader.PrintRecords(TRUE);
            END;

          IF SalesInvHeader."No." <> '' THEN
            IF CONFIRM(
                 Text001,TRUE,
                 SalesInvHeader."No.")
            THEN BEGIN
              SalesInvHeader.SETRECFILTER;
              SalesInvHeader.PrintRecords(TRUE);
            END;

          IF SalesCrMemoHeader."No." <> '' THEN
            IF CONFIRM(
                 Text002,TRUE,
                 SalesCrMemoHeader."No.")
            THEN BEGIN
              SalesCrMemoHeader.SETRECFILTER;
              SalesCrMemoHeader.PrintRecords(TRUE);
            END;

          IF ReturnRcptHeader."No." <> '' THEN
            IF CONFIRM(
                 Text023,TRUE,
                 ReturnRcptHeader."No.")
            THEN BEGIN
              ReturnRcptHeader.SETRECFILTER;
              ReturnRcptHeader.PrintRecords(TRUE);
            END;

          IF SalesInvHeaderPrepmt."No." <> '' THEN
            IF CONFIRM(
                 Text057,TRUE,
                 SalesInvHeader."No.")
            THEN BEGIN
              SalesInvHeaderPrepmt.SETRECFILTER;
              SalesInvHeaderPrepmt.PrintRecords(TRUE);
            END;

          IF SalesCrMemoHeaderPrepmt."No." <> '' THEN
            IF CONFIRM(
                 Text058,TRUE,
                 SalesCrMemoHeaderPrepmt."No.")
            THEN BEGIN
              SalesCrMemoHeaderPrepmt.SETRECFILTER;
              SalesCrMemoHeaderPrepmt.PrintRecords(TRUE);
            END;
        END;

        //APNT-HHT1.0
        CreateAction(2);
        //APNT-HHT1.0
    end;

    trigger OnInsert()
    var
        FromDateTime: DateTime;
        ToDateTime: DateTime;
    begin
        SalesSetup.GET;

        IF "No." = '' THEN BEGIN
          TestNoSeries;
          NoSeriesMgt.InitSeries(GetNoSeriesCode,xRec."No. Series","Posting Date","No.","No. Series");
        END;

        InitRecord;
        InsertMode := TRUE;

        IF GETFILTER("Sell-to Customer No.") <> '' THEN
          IF GETRANGEMIN("Sell-to Customer No.") = GETRANGEMAX("Sell-to Customer No.") THEN
            VALIDATE("Sell-to Customer No.",GETRANGEMIN("Sell-to Customer No."));

        IF GETFILTER("Sell-to Contact No.") <> '' THEN
          IF GETRANGEMIN("Sell-to Contact No.") = GETRANGEMAX("Sell-to Contact No.") THEN
            VALIDATE("Sell-to Contact No.",GETRANGEMIN("Sell-to Contact No."));

        "Doc. No. Occurrence" := ArchiveManagement.GetNextOccurrenceNo(DATABASE::"Sales Header","Document Type","No.");

        //LS -
        GetRetailSetup();
        IF RetailSetup."Only Two Dimensions" THEN
          "Only Two Dimensions" := RetailSetup."Only Two Dimensions";
        IF NOT "Only Two Dimensions" THEN
          DimMgt.InsertDocDim(
            DATABASE::"Sales Header","Document Type","No.",0,
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        //LS +

        //APNT-HHT1.0
        CreateAction(0);
        //APNT-HHT1.0
        //APNT-HRU1.0 -
        CLEAR(FromDateTime);
        CLEAR(ToDateTime);
        CompanyInfo.GET;
        "ISD Code":= CompanyInfo."Default ISD Code";
        "Created Date" := WORKDATE;
        "Created Time" := TIME;
        FromDateTime := CREATEDATETIME("Created Date","Created Time");
        IF SalesSetup."Unattended SO Time Frame (Min)" <> 0 THEN BEGIN
          "Cancellation Time" := "Created Time" + (60000* SalesSetup."Unattended SO Time Frame (Min)");
          ToDateTime := FromDateTime + (SalesSetup."Unattended SO Time Frame (Min)" * 60000);
        END ELSE BEGIN
          "Cancellation Time" := "Created Time" + (60000 * 30);
          ToDateTime := FromDateTime + (30 * 60000);
        END;
        "Cancellation Date" := DT2DATE(ToDateTime);
        //APNT-HRU1.0 +

        //T004720 -
        IF "HRU Document" THEN BEGIN
          InvtSetup.GET;
          InvtSetup.TESTFIELD("HRU Sales Reason Code");
          "Reason Code" := InvtSetup."HRU Sales Reason Code";
        END;
        //T004720 +
    end;

    trigger OnModify()
    begin
        //APNT-HHT1.0
        CreateAction(1);
        //APNT-HHT1.0
    end;

    trigger OnRename()
    begin
        ERROR(Text003,TABLECAPTION);
    end;

    var
        Text000: Label 'Do you want to print shipment %1?';
        Text001: Label 'Do you want to print invoice %1?';
        Text002: Label 'Do you want to print credit memo %1?';
        Text003: Label 'You cannot rename a %1.';
        Text004: Label 'Do you want to change %1?';
        Text005: Label 'You cannot reset %1 because the document still has one or more lines.';
        Text006: Label 'You cannot change %1 because the order is associated with one or more purchase orders.';
        Text007: Label '%1 cannot be greater than %2 in the %3 table.';
        Text008: Label 'Deleting this document will cause a gap in the number series for shipments. ';
        Text009: Label 'An empty shipment %1 will be created to fill this gap in the number series.\\';
        Text010: Label 'Do you want to continue?';
        Text011: Label 'Deleting this document will cause a gap in the number series for posted invoices. ';
        Text012: Label 'An empty posted invoice %1 will be created to fill this gap in the number series.\\';
        Text013: Label 'Deleting this document will cause a gap in the number series for posted credit memos. ';
        Text014: Label 'An empty posted credit memo %1 will be created to fill this gap in the number series.\\';
        Text015: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\\';
        Text017: Label 'You must delete the existing sales lines before you can change %1.';
        Text018: Label 'You have changed %1 on the sales header, but it has not been changed on the existing sales lines.\';
        Text019: Label 'You must update the existing sales lines manually.';
        Text020: Label 'The change may affect the exchange rate used in the price calculation of the sales lines.';
        Text021: Label 'Do you want to update the exchange rate?';
        Text022: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text023: Label 'Do you want to print return receipt %1?';
        Text024: Label 'You have modified the %1 field. Note that the recalculation of VAT may cause penny differences, so you must check the amounts afterwards. ';
        Text026: Label 'Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text027: Label 'Your identification is set up to process from %1 %2 only.';
        Text028: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text029: Label 'Deleting this document will cause a gap in the number series for return receipts. ';
        Text030: Label 'An empty return receipt %1 will be created to fill this gap in the number series.\\';
        Text031: Label 'You have modified %1.\\';
        Text032: Label 'Do you want to update the lines?';
        SalesSetup: Record "311";
        GLSetup: Record "98";
        GLAcc: Record "15";
        SalesHeader: Record "36";
        SalesLine: Record "37";
        CustLedgEntry: Record "21";
        Cust: Record "18";
        PaymentTerms: Record "3";
        PaymentMethod: Record "289";
        CurrExchRate: Record "330";
        SalesCommentLine: Record "44";
        ShipToAddr: Record "222";
        PostCode: Record "225";
        BankAcc: Record "270";
        SalesShptHeader: Record "110";
        SalesInvHeader: Record "112";
        SalesCrMemoHeader: Record "114";
        ReturnRcptHeader: Record "6660";
        SalesInvHeaderPrepmt: Record "112";
        SalesCrMemoHeaderPrepmt: Record "114";
        GenBusPostingGrp: Record "250";
        GenJnILine: Record "81";
        RespCenter: Record "5714";
        InvtSetup: Record "313";
        Location: Record "14";
        WhseRequest: Record "5765";
        ShippingAgentService: Record "5790";
        TempReqLine: Record "246" temporary;
        UserMgt: Codeunit "5700";
        NoSeriesMgt: Codeunit "396";
        CustCheckCreditLimit: Codeunit "312";
        TransferExtendedText: Codeunit "378";
        GenJnlApply: Codeunit "225";
        SalesPost: Codeunit "80";
        CustEntrySetApplID: Codeunit "101";
        DimMgt: Codeunit "408";
        ApprovalMgt: Codeunit "439";
        WhseSourceHeader: Codeunit "5781";
        ArchiveManagement: Codeunit "5063";
        SalesLineReserve: Codeunit "99000832";
        ApplyCustEntries: Form "232";
        CurrencyDate: Date;
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        Text035: Label 'You cannot Release Quote or Make Order unless you specify a customer on the quote.\\Do you want to create customer(s) now?';
        Text037: Label 'Contact %1 %2 is not related to customer %3.';
        Text038: Label 'Contact %1 %2 is related to a different company than customer %3.';
        Text039: Label 'Contact %1 %2 is not related to a customer.';
        ReservEntry: Record "337";
        TempReservEntry: Record "337" temporary;
        DocDim: Record "357";
        Text040: Label 'A won opportunity is linked to this order.\';
        Text041: Label 'It has to be changed to status Lost before the Order can be deleted.\';
        Text042: Label 'Do you want to change the status for this opportunity now?';
        Text043: Label 'Wizard Aborted';
        Text044: Label 'The status of the opportunity has not been changed. The program has aborted deleting the order.';
        SkipSellToContact: Boolean;
        SkipBillToContact: Boolean;
        Text045: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.';
        Text047: Label 'You cannot change %1 because reservation, item tracking, or order tracking exists on the sales order.';
        Text048: Label 'Sales quote %1 has already been assigned to opportunity %2. Would you like to reassign this quote?';
        Text049: Label 'The %1 field cannot be blank because this quote is linked to an opportunity.';
        InsertMode: Boolean;
        CompanyInfo: Record "79";
        Text050: Label 'If %1 is %2 in sales order no. %3, then all sales lines where type is %4 must use the same location.';
        HideCreditCheckDialogue: Boolean;
        Text051: Label 'The sales %1 %2 already exists.';
        Text052: Label 'The sales %1 %2 has item tracking. Do you want to delete it anyway?';
        Text053: Label 'You must cancel the approval process if you wish to change the %1.';
        Text054: Label 'The sales %1 %2 has item tracking. Do you want to delete it anyway?';
        Text055: Label 'Deleting this document will cause a gap in the number series for prepayment invoices. ';
        Text056: Label 'An empty prepayment invoice %1 will be created to fill this gap in the number series.\\';
        Text057: Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. ';
        Text058: Label 'An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\';
        Text061: Label '%1 is set up to process from %2 %3 only.';
        Text062: Label 'You cannot change %1 because the corresponding %2 %3 has been assigned to this %4.';
        Text063: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\';
        Text064: Label 'The warehouse shipment was not created because the Shipping Advice field is set to Complete, and item no. %1 is not available in location code %2.\\You can create the warehouse shipment by either changing the Shipping Advice field to Partial in sales order no. %3, or filling in the warehouse shipment document manually.';
        RetailSetup: Record "10000700";
        RetailSetupAlreadyRetrieved: Boolean;
        BOUtils: Codeunit "99001452";
        InStoreMgt: Codeunit "10001320";
        InStoreFunc: Codeunit "10001310";
        gintMAGLastEntryNo: Integer;
        gtxtMAGLastStatus: Text[100];
 
    procedure InitRecord()
    var
        lRetailUser: Record "10000742";
        lStore: Record "99001470";
    begin
        CASE "Document Type" OF
          "Document Type"::Quote,"Document Type"::Order:
            BEGIN
              NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Invoice Nos.");
              NoSeriesMgt.SetDefaultSeries("Shipping No. Series",SalesSetup."Posted Shipment Nos.");
              IF "Document Type" = "Document Type"::Order THEN BEGIN
                NoSeriesMgt.SetDefaultSeries("Prepayment No. Series",SalesSetup."Posted Prepmt. Inv. Nos.");
                NoSeriesMgt.SetDefaultSeries("Prepmt. Cr. Memo No. Series",SalesSetup."Posted Prepmt. Cr. Memo Nos.");
              END;
            END;
          "Document Type"::Invoice:
            BEGIN
              IF ("No. Series" <> '') AND
                 (SalesSetup."Invoice Nos." = SalesSetup."Posted Invoice Nos.")
              THEN
                "Posting No. Series" := "No. Series"
              ELSE
                NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Invoice Nos.");
              IF SalesSetup."Shipment on Invoice" THEN
                NoSeriesMgt.SetDefaultSeries("Shipping No. Series",SalesSetup."Posted Shipment Nos.");
            END;
          "Document Type"::"Return Order":
            BEGIN
              NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Credit Memo Nos.");
              NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series",SalesSetup."Posted Return Receipt Nos.");
            END;
          "Document Type"::"Credit Memo":
            BEGIN
              IF ("No. Series" <> '') AND
                 (SalesSetup."Credit Memo Nos." = SalesSetup."Posted Credit Memo Nos.")
              THEN
                "Posting No. Series" := "No. Series"
              ELSE
                NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Credit Memo Nos.");
              IF SalesSetup."Return Receipt on Credit Memo" THEN
                NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series",SalesSetup."Posted Return Receipt Nos.");
            END;
        END;

        IF "Document Type" IN ["Document Type"::Order,"Document Type"::Invoice,"Document Type"::Quote] THEN
          BEGIN
          "Shipment Date" := WORKDATE;
          "Order Date" := WORKDATE;
        END;
        IF "Document Type" = "Document Type"::"Return Order" THEN
          "Order Date" := WORKDATE;

        IF NOT ("Document Type" IN ["Document Type"::"Blanket Order","Document Type"::Quote]) AND
           ("Posting Date" = 0D)
        THEN
          "Posting Date" := WORKDATE;

        IF SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" THEN
          "Posting Date" := 0D;

        "Document Date" := WORKDATE;

        //LS -
        IF lRetailUser.GET(USERID) THEN BEGIN
          "Store No." := lRetailUser."Store No.";
          IF lRetailUser."Store No." <> '' THEN BEGIN
            lStore.GET(lRetailUser."Store No.");
            IF lRetailUser."Location Code" = '' THEN
              VALIDATE("Location Code",lStore."Location Code")
            ELSE
              VALIDATE("Location Code",lRetailUser."Location Code")
          END
        END
        ELSE BEGIN
          "Store No." := '';
          "Retail Special Order" := FALSE;
          VALIDATE("Location Code",UserMgt.GetLocation(0,Cust."Location Code","Responsibility Center"));
        END;
        //LS +

        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          GLSetup.GET;
          Correction := GLSetup."Mark Cr. Memos as Corrections";
        END;

        "Posting Description" := FORMAT("Document Type") + ' ' + "No.";

        Reserve := Reserve::Optional;

        IF InvtSetup.GET THEN
          VALIDATE("Outbound Whse. Handling Time",InvtSetup."Outbound Whse. Handling Time");

        "Responsibility Center" := UserMgt.GetRespCenter(0,"Responsibility Center");
    end;
 
    procedure AssistEdit(OldSalesHeader: Record "36"): Boolean
    var
        SalesHeader2: Record "36";
    begin
        WITH SalesHeader DO BEGIN
          COPY(Rec);
          SalesSetup.GET;
          TestNoSeries;
          IF NoSeriesMgt.SelectSeries(GetNoSeriesCode,OldSalesHeader."No. Series","No. Series") THEN BEGIN
            IF ("Sell-to Customer No." = '') AND ("Sell-to Contact No." = '') THEN BEGIN
              HideCreditCheckDialogue := FALSE;
              CheckCreditMaxBeforeInsert;
              HideCreditCheckDialogue := TRUE;
            END;
            NoSeriesMgt.SetSeries("No.");
            IF SalesHeader2.GET("Document Type","No.") THEN
              ERROR(Text051,LOWERCASE(FORMAT("Document Type")),"No.");
            Rec := SalesHeader;
            EXIT(TRUE);
          END;
        END;
    end;

    local procedure TestNoSeries(): Boolean
    begin
        CASE "Document Type" OF
          "Document Type"::Quote:
            SalesSetup.TESTFIELD("Quote Nos.");
          "Document Type"::Order:
            SalesSetup.TESTFIELD("Order Nos.");
          "Document Type"::Invoice:
            BEGIN
              SalesSetup.TESTFIELD("Invoice Nos.");
              SalesSetup.TESTFIELD("Posted Invoice Nos.");
            END;
          "Document Type"::"Return Order":
            SalesSetup.TESTFIELD("Return Order Nos.");
          "Document Type"::"Credit Memo":
            BEGIN
              SalesSetup.TESTFIELD("Credit Memo Nos.");
              SalesSetup.TESTFIELD("Posted Credit Memo Nos.");
            END;
          "Document Type"::"Blanket Order":
            SalesSetup.TESTFIELD("Blanket Order Nos.");
        END;
    end;

    local procedure GetNoSeriesCode(): Code[10]
    begin
        CASE "Document Type" OF
          "Document Type"::Quote:
            EXIT(SalesSetup."Quote Nos.");
          "Document Type"::Order:
            EXIT(SalesSetup."Order Nos.");
          "Document Type"::Invoice:
            EXIT(SalesSetup."Invoice Nos.");
          "Document Type"::"Return Order":
            EXIT(SalesSetup."Return Order Nos.");
          "Document Type"::"Credit Memo":
            EXIT(SalesSetup."Credit Memo Nos.");
          "Document Type"::"Blanket Order":
            EXIT(SalesSetup."Blanket Order Nos.");
        END;
    end;

    local procedure GetPostingNoSeriesCode(): Code[10]
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          EXIT(SalesSetup."Posted Credit Memo Nos.");
        EXIT(SalesSetup."Posted Invoice Nos.");
    end;

    local procedure TestNoSeriesDate(No: Code[20];NoSeriesCode: Code[10];NoCapt: Text[1024];NoSeriesCapt: Text[1024])
    var
        NoSeries: Record "308";
    begin
        IF (No <> '') AND (NoSeriesCode <> '') THEN BEGIN
          NoSeries.GET(NoSeriesCode);
          IF NoSeries."Date Order" THEN
            ERROR(
              Text045,
              FIELDCAPTION("Posting Date"),NoSeriesCapt,NoSeriesCode,
              NoSeries.FIELDCAPTION("Date Order"),NoSeries."Date Order","Document Type",
              NoCapt,No);
        END;
    end;
 
    procedure ConfirmDeletion(): Boolean
    begin
        SalesPost.TestDeleteHeader(
          Rec,SalesShptHeader,SalesInvHeader,SalesCrMemoHeader,ReturnRcptHeader,
          SalesInvHeaderPrepmt,SalesCrMemoHeaderPrepmt);
        IF SalesShptHeader."No." <> '' THEN
          IF NOT CONFIRM(
               Text008 +
               Text009 +
               Text010,TRUE,
               SalesShptHeader."No.")
          THEN
            EXIT;
        IF SalesInvHeader."No." <> '' THEN
          IF NOT CONFIRM(
               Text011 +
               Text012 +
               Text010,TRUE,
               SalesInvHeader."No.")
          THEN
            EXIT;
        IF SalesCrMemoHeader."No." <> '' THEN
          IF NOT CONFIRM(
               Text013 +
               Text014 +
               Text010,TRUE,
               SalesCrMemoHeader."No.")
          THEN
            EXIT;
        IF ReturnRcptHeader."No." <> '' THEN
          IF NOT CONFIRM(
               Text029 +
               Text030 +
               Text010,TRUE,
               ReturnRcptHeader."No.")
          THEN
            EXIT;
        IF "Prepayment No." <> '' THEN
          IF NOT CONFIRM(
               Text053 +
               Text054 +
               Text010,TRUE,
               SalesInvHeaderPrepmt.TABLENAME,
               SalesInvHeaderPrepmt."No.")
          THEN
            EXIT;
        IF "Prepmt. Cr. Memo No." <> '' THEN
          IF NOT CONFIRM(
               Text055 +
               Text056 +
               Text010,TRUE,
               SalesCrMemoHeaderPrepmt."No.")
          THEN
            EXIT;
        EXIT(TRUE);
    end;

    local procedure GetCust(CustNo: Code[20])
    begin
        IF NOT (("Document Type" = "Document Type"::Quote) AND (CustNo = '')) THEN BEGIN
          IF CustNo <> Cust."No." THEN
            Cust.GET(CustNo);
        END ELSE
          CLEAR(Cust);
    end;
 
    procedure SalesLinesExist(): Boolean
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        EXIT(SalesLine.FINDFIRST);
    end;
 
    procedure RecreateSalesLines(ChangedFieldName: Text[100])
    var
        SalesLineTmp: Record "37" temporary;
        ItemChargeAssgntSales: Record "5809";
        TempItemChargeAssgntSales: Record "5809" temporary;
        TempInteger: Record "2000000026" temporary;
        ChangeLogMgt: Codeunit "423";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ExtendedTextAdded: Boolean;
        ReCalculate: Boolean;
        VariantMatrix: Boolean;
        LastAttachedToLineNo: Integer;
        Item: Record "27";
        NextBaseLineNo: Integer;
    begin
        IF SalesLinesExist THEN BEGIN
          IF HideValidationDialog OR NOT GUIALLOWED THEN
            Confirmed := TRUE
          ELSE
            Confirmed :=
              CONFIRM(
                Text015 +
                Text004,FALSE,ChangedFieldName);
          IF Confirmed THEN BEGIN
            DocDim.LOCKTABLE;
            SalesLine.LOCKTABLE;
            ItemChargeAssgntSales.LOCKTABLE;
            ReservEntry.LOCKTABLE;
            xRecRef.GETTABLE(xRec);
            MODIFY;
            RecRef.GETTABLE(Rec);
        
            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type","Document Type");
            SalesLine.SETRANGE("Document No.","No.");
            IF SalesLine.FINDSET THEN BEGIN
              TempReservEntry.DELETEALL;
              REPEAT
                SalesLine.TESTFIELD("Job No.",'');
                SalesLine.TESTFIELD("Job Contract Entry No.",0);
                SalesLine.TESTFIELD("Quantity Shipped",0);
                SalesLine.TESTFIELD("Quantity Invoiced",0);
                SalesLine.TESTFIELD("Return Qty. Received",0);
                SalesLine.TESTFIELD("Shipment No.",'');
                SalesLine.TESTFIELD("Return Receipt No.",'');
                SalesLine.TESTFIELD("Blanket Order No.",'');
                SalesLine.TESTFIELD("Prepmt. Amt. Inv.",0);
                SalesLineTmp := SalesLine;
                IF SalesLine.Nonstock THEN BEGIN
                  SalesLine.Nonstock := FALSE;
                  SalesLine.MODIFY;
                END;
                SalesLineTmp.INSERT;
                RecreateReservEntry(SalesLine,0,TRUE);
                RecreateReqLine(SalesLine,0,TRUE);
              UNTIL SalesLine.NEXT = 0;
        
              IF "Location Code" <> xRec."Location Code" THEN
                IF NOT TempReservEntry.ISEMPTY THEN
                  ERROR(Text047,FIELDCAPTION("Location Code"));
        
              ItemChargeAssgntSales.SETRANGE("Document Type","Document Type");
              ItemChargeAssgntSales.SETRANGE("Document No.","No.");
              IF ItemChargeAssgntSales.FINDSET THEN BEGIN
                REPEAT
                  TempItemChargeAssgntSales.INIT;
                  TempItemChargeAssgntSales := ItemChargeAssgntSales;
                  TempItemChargeAssgntSales.INSERT;
                UNTIL ItemChargeAssgntSales.NEXT = 0;
                ItemChargeAssgntSales.DELETEALL;
              END;
        
              SalesLine.DELETEALL(TRUE);
              SalesLine.INIT;
              SalesLine."Line No." := 0;
              NextBaseLineNo := 0;  //LS
              SalesLineTmp.FINDSET;
              ExtendedTextAdded := FALSE;
              SalesLine.BlockDynamicTracking(TRUE);
              REPEAT
                //LS -
                /*
                IF SalesLineTmp."Attached to Line No." = 0 THEN BEGIN
                  SalesLine.INIT;
                  SalesLine."Line No." := SalesLine."Line No." + 10000;
                  SalesLine.VALIDATE(Type,SalesLineTmp.Type);
                  IF SalesLineTmp."No." = '' THEN BEGIN
                    SalesLine.VALIDATE(Description,SalesLineTmp.Description);
                    SalesLine.VALIDATE("Description 2",SalesLineTmp."Description 2");
                  END ELSE BEGIN
                    SalesLine.VALIDATE("No.",SalesLineTmp."No.");
                    IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                      SalesLine.VALIDATE("Unit of Measure Code",SalesLineTmp."Unit of Measure Code");
                      SalesLine.VALIDATE("Variant Code",SalesLineTmp."Variant Code");
                      IF SalesLineTmp.Quantity <> 0 THEN
                        SalesLine.VALIDATE(Quantity,SalesLineTmp.Quantity);
                      SalesLine."Purchase Order No." := SalesLineTmp."Purchase Order No.";
                      SalesLine."Purch. Order Line No." := SalesLineTmp."Purch. Order Line No.";
                      SalesLine."Drop Shipment" := SalesLine."Purch. Order Line No." <> 0;
                    END;
                  END;
                  */
        
                ReCalculate := FALSE;
                IF SalesLineTmp."Attached to Line No." = 0 THEN BEGIN
                  ReCalculate := TRUE;
                  LastAttachedToLineNo := 0;
                  IF (SalesLineTmp.Type = SalesLineTmp.Type::" ") AND (Item.GET(SalesLineTmp."No.")) THEN
                    VariantMatrix := TRUE
                  ELSE
                    VariantMatrix := FALSE;
                END ELSE
                  IF VariantMatrix THEN
                    ReCalculate := TRUE
                  ELSE
                    ReCalculate := FALSE;
                IF ReCalculate THEN BEGIN
                  IF (VariantMatrix) AND (SalesLineTmp."Attached to Line No." = 0) THEN BEGIN
                    SalesLine.INIT;
                    SalesLine := SalesLineTmp;
                    NextBaseLineNo := NextBaseLineNo + 10000;
                    SalesLine."Line No." := NextBaseLineNo;
                    SalesLine."Sell-to Customer No." := "Sell-to Customer No.";
                    LastAttachedToLineNo := SalesLine."Line No.";
                  END ELSE BEGIN
                  SalesLine.INIT;
                    IF VariantMatrix THEN
                      SalesLine."Line No." := SalesLine."Line No." + 10
                    ELSE BEGIN
                      NextBaseLineNo := NextBaseLineNo + 10000;
                      SalesLine."Line No." := NextBaseLineNo;
                    END;
                    SalesLine.VALIDATE(Type,SalesLineTmp.Type);
                  IF SalesLineTmp."No." = '' THEN BEGIN
                    SalesLine.VALIDATE(Description,SalesLineTmp.Description);
                    SalesLine.VALIDATE("Description 2",SalesLineTmp."Description 2");
                  END ELSE BEGIN
                    SalesLine.VALIDATE("No.",SalesLineTmp."No.");
                    IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                      SalesLine.VALIDATE("Unit of Measure Code",SalesLineTmp."Unit of Measure Code");
                      SalesLine.VALIDATE("Variant Code",SalesLineTmp."Variant Code");
                      IF SalesLineTmp.Quantity <> 0 THEN
                        SalesLine.VALIDATE(Quantity,SalesLineTmp.Quantity);
                      SalesLine."Purchase Order No." := SalesLineTmp."Purchase Order No.";
                      SalesLine."Purch. Order Line No." := SalesLineTmp."Purch. Order Line No.";
                      SalesLine."Drop Shipment" := SalesLine."Purch. Order Line No." <> 0;
                    END;
                  END;
                  SalesLine."Attached to Line No." := LastAttachedToLineNo;
                END;
                //LS +
        
                  SalesLine.INSERT;
                  ExtendedTextAdded := FALSE;
        
                  IF SalesLine.Type = SalesLine.Type::Item THEN BEGIN
                    ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type",SalesLineTmp."Document Type");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.",SalesLineTmp."Document No.");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.",SalesLineTmp."Line No.");
                    IF TempItemChargeAssgntSales.FINDSET THEN BEGIN
                      REPEAT
                        IF NOT TempItemChargeAssgntSales.MARK THEN BEGIN
                          TempItemChargeAssgntSales."Applies-to Doc. Line No." := SalesLine."Line No.";
                          TempItemChargeAssgntSales.Description := SalesLine.Description;
                          TempItemChargeAssgntSales.MODIFY;
                          TempItemChargeAssgntSales.MARK(TRUE);
                        END;
                      UNTIL TempItemChargeAssgntSales.NEXT = 0;
                    END;
                  END;
                  IF SalesLine.Type = SalesLine.Type::"Charge (Item)" THEN BEGIN
                    TempInteger.INIT;
                    TempInteger.Number := SalesLine."Line No.";
                    TempInteger.INSERT;
                  END;
                END ELSE
                  IF NOT ExtendedTextAdded THEN BEGIN
                    TransferExtendedText.SalesCheckIfAnyExtText(SalesLine,TRUE);
                    TransferExtendedText.InsertSalesExtText(SalesLine);
                    SalesLine.FINDLAST;
                    ExtendedTextAdded := TRUE;
                  END;
                RecreateReservEntry(SalesLineTmp,SalesLine."Line No.",FALSE);
                RecreateReqLine(SalesLineTmp,SalesLine."Line No.",FALSE);
                SynchronizeForReservations(SalesLine,SalesLineTmp);
              UNTIL SalesLineTmp.NEXT = 0;
        
              ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
              SalesLineTmp.SETRANGE(Type,SalesLine.Type::"Charge (Item)");
              IF SalesLineTmp.FINDSET THEN
                REPEAT
                  TempItemChargeAssgntSales.SETRANGE("Document Line No.",SalesLineTmp."Line No.");
                  IF TempItemChargeAssgntSales.FINDSET THEN BEGIN
                    REPEAT
                      TempInteger.FINDFIRST;
                      ItemChargeAssgntSales.INIT;
                      ItemChargeAssgntSales := TempItemChargeAssgntSales;
                      ItemChargeAssgntSales."Document Line No." := TempInteger.Number;
                      ItemChargeAssgntSales.VALIDATE("Unit Cost",0);
                      ItemChargeAssgntSales.INSERT;
                    UNTIL TempItemChargeAssgntSales.NEXT = 0;
                    TempInteger.DELETE;
                  END;
                UNTIL SalesLineTmp.NEXT = 0;
        
              SalesLineTmp.SETRANGE(Type);
              SalesLineTmp.DELETEALL;
              ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
              TempItemChargeAssgntSales.DELETEALL;
            END;
            ChangeLogMgt.LogModification(RecRef,xRecRef);
          END ELSE
            ERROR(
              Text017,ChangedFieldName);
        END;
        SalesLine.BlockDynamicTracking(FALSE);

    end;
 
    procedure MessageIfSalesLinesExist(ChangedFieldName: Text[100])
    begin
        IF SalesLinesExist AND NOT HideValidationDialog THEN
          MESSAGE(
            Text018 +
            Text019,
            ChangedFieldName);
    end;
 
    procedure PriceMessageIfSalesLinesExist(ChangedFieldName: Text[100])
    begin
        IF SalesLinesExist AND NOT HideValidationDialog THEN
          MESSAGE(
            Text018 +
            Text020,ChangedFieldName);
    end;

    local procedure UpdateCurrencyFactor()
    begin
        IF "Currency Code" <> '' THEN BEGIN
          IF ("Document Type" IN ["Document Type"::Quote,"Document Type"::"Blanket Order"]) AND
             ("Posting Date" = 0D)
          THEN
            CurrencyDate := WORKDATE
          ELSE
            CurrencyDate := "Posting Date";

          "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate,"Currency Code");
        END ELSE
          "Currency Factor" := 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        IF HideValidationDialog THEN
          Confirmed := TRUE
        ELSE
          Confirmed := CONFIRM(Text021,FALSE);
        IF Confirmed THEN
          VALIDATE("Currency Factor")
        ELSE
          "Currency Factor" := xRec."Currency Factor";
    end;
 
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;
 
    procedure UpdateSalesLines(ChangedFieldName: Text[100];AskQuestion: Boolean)
    var
        JobTransferLine: Codeunit "1004";
        ChangeLogMgt: Codeunit "423";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        Question: Text[250];
    begin
        IF NOT SalesLinesExist THEN
          EXIT;

        //APNT-T009913
        IF ("HRU Document" = TRUE) AND (ChangedFieldName = 'Promised Delivery Date') THEN BEGIN
          IF AskQuestion THEN BEGIN
            CASE ChangedFieldName OF
              FIELDCAPTION("Shipment Date"),
              FIELDCAPTION("Shipping Agent Code"),
              FIELDCAPTION("Shipping Agent Service Code"),
              FIELDCAPTION("Shipping Time"),
              FIELDCAPTION("Requested Delivery Date"),
              FIELDCAPTION("Promised Delivery Date"),
              FIELDCAPTION("Outbound Whse. Handling Time"):
                ConfirmResvDateConflict;
            END
          END;//APNT-T009913
        END ELSE BEGIN
          IF AskQuestion THEN BEGIN
            Question := STRSUBSTNO(
                Text031 +
                Text032,ChangedFieldName);
            IF GUIALLOWED THEN
              IF DIALOG.CONFIRM(Question,TRUE) THEN
                CASE ChangedFieldName OF
                  FIELDCAPTION("Shipment Date"),
                  FIELDCAPTION("Shipping Agent Code"),
                  FIELDCAPTION("Shipping Agent Service Code"),
                  FIELDCAPTION("Shipping Time"),
                  FIELDCAPTION("Requested Delivery Date"),
                  FIELDCAPTION("Promised Delivery Date"),
                  FIELDCAPTION("Outbound Whse. Handling Time"):
                    ConfirmResvDateConflict;
                END
              ELSE
                EXIT;
          END;
        END;
        DocDim.LOCKTABLE;
        SalesLine.LOCKTABLE;
        xRecRef.GETTABLE(xRec);
        MODIFY;
        RecRef.GETTABLE(Rec);
        ChangeLogMgt.LogModification(RecRef,xRecRef);

        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        IF SalesLine.FINDSET THEN
          REPEAT
            xRecRef.GETTABLE(SalesLine);
            CASE ChangedFieldName OF
              FIELDCAPTION("Shipment Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipment Date","Shipment Date");
              FIELDCAPTION("Currency Factor"):
                IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                  SalesLine.VALIDATE("Unit Price");
                  SalesLine.VALIDATE("Unit Cost (LCY)");
                  IF SalesLine."Job No." <> '' THEN
                    JobTransferLine.FromSalesHeaderToPlanningLine(SalesLine,Rec."Currency Code",Rec."Currency Factor");
                END;
              FIELDCAPTION("Transaction Type"):
                SalesLine.VALIDATE("Transaction Type","Transaction Type");
              FIELDCAPTION("Transport Method"):
                SalesLine.VALIDATE("Transport Method","Transport Method");
              FIELDCAPTION("Exit Point"):
                SalesLine.VALIDATE("Exit Point","Exit Point");
              FIELDCAPTION(Area):
                SalesLine.VALIDATE(Area,Area);
              FIELDCAPTION("Transaction Specification"):
                SalesLine.VALIDATE("Transaction Specification","Transaction Specification");
              FIELDCAPTION("Shipping Agent Code"):
                SalesLine.VALIDATE("Shipping Agent Code","Shipping Agent Code");
              FIELDCAPTION("Shipping Agent Service Code"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipping Agent Service Code","Shipping Agent Service Code");
              FIELDCAPTION("Shipping Time"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipping Time","Shipping Time");
              FIELDCAPTION("Prepayment %"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Prepayment %","Prepayment %");
              FIELDCAPTION("Requested Delivery Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Requested Delivery Date","Requested Delivery Date");
              FIELDCAPTION("Promised Delivery Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Promised Delivery Date","Promised Delivery Date");
              FIELDCAPTION("Outbound Whse. Handling Time"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Outbound Whse. Handling Time","Outbound Whse. Handling Time");
            END;
            SalesLineReserve.AssignForPlanning(SalesLine);
            SalesLine.MODIFY(TRUE);
            RecRef.GETTABLE(SalesLine);
            ChangeLogMgt.LogModification(RecRef,xRecRef);
          UNTIL SalesLine.NEXT = 0;
    end;
 
    procedure ConfirmResvDateConflict()
    var
        ResvEngMgt: Codeunit "99000831";
    begin
        IF ResvEngMgt.ResvExistsForSalesHeader(Rec) THEN
          IF NOT CONFIRM(Text063 + Text010,FALSE) THEN
            ERROR('');
    end;
 
    procedure CreateDim(Type1: Integer;No1: Code[20];Type2: Integer;No2: Code[20];Type3: Integer;No3: Code[20];Type4: Integer;No4: Code[20];Type5: Integer;No5: Code[20])
    var
        SourceCodeSetup: Record "242";
        TableID: array [10] of Integer;
        No: array [10] of Code[20];
    begin
        SourceCodeSetup.GET;
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
          TableID,No,SourceCodeSetup.Sales,
          "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        IF "No." <> '' THEN
          IF NOT "Only Two Dimensions" THEN  //LS
            DimMgt.UpdateDocDefaultDim(
              DATABASE::"Sales Header","Document Type","No.",0,
              "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    var
        ChangeLogMgt: Codeunit "423";
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        //LS -
        IF "Only Two Dimensions" THEN BEGIN
          SalesLine.RESET;
          SalesLine.SETRANGE("Document Type","Document Type");
          SalesLine.SETRANGE("Document No.","No.");
          IF SalesLine.FIND('-') THEN
            REPEAT
              IF FieldNumber = 1 THEN
                SalesLine."Shortcut Dimension 1 Code" := ShortcutDimCode;
              IF FieldNumber = 2 THEN
                SalesLine."Shortcut Dimension 2 Code" := ShortcutDimCode;
              SalesLine.MODIFY();
            UNTIL SalesLine.NEXT() = 0;
        END ELSE BEGIN
        //LS +
          IF "No." <> '' THEN BEGIN
            DimMgt.SaveDocDim(
              DATABASE::"Sales Header","Document Type","No.",0,FieldNumber,ShortcutDimCode);
            xRecRef.GETTABLE(xRec);
            //APNT-LD1.0
            //MODIFY;
            IF MODIFY THEN;
            //APNT-LD1.0
            RecRef.GETTABLE(Rec);
            ChangeLogMgt.LogModification(RecRef,xRecRef);
          END ELSE
            DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
        END; //LS
    end;
 
    procedure ShippedSalesLinesExist(): Boolean
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Quantity Shipped",'<>0');
        EXIT(SalesLine.FINDFIRST);
    end;
 
    procedure ReturnReceiptExist(): Boolean
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Return Qty. Received",'<>0');
        EXIT(SalesLine.FINDFIRST);
    end;

    local procedure DeleteSalesLines()
    begin
        IF SalesLine.FINDSET THEN BEGIN
          HandleItemTrackingDeletion;
          REPEAT
            SalesLine.SuspendStatusCheck(TRUE);
            SalesLine.DELETE(TRUE);
          UNTIL SalesLine.NEXT = 0;
        END;
    end;
 
    procedure HandleItemTrackingDeletion()
    var
        ReservEntry2: Record "337";
    begin
        WITH ReservEntry DO BEGIN
          RESET;
          SETCURRENTKEY(
            "Source ID","Source Ref. No.","Source Type","Source Subtype",
            "Source Batch Name","Source Prod. Order Line","Reservation Status");
          SETRANGE("Source Type",DATABASE::"Sales Line");
          SETRANGE("Source Subtype","Document Type");
          SETRANGE("Source ID","No.");
          SETRANGE("Source Batch Name",'');
          SETRANGE("Source Prod. Order Line",0);
          SETFILTER("Item Tracking",'> %1',"Item Tracking"::None);
          IF ISEMPTY THEN
            EXIT;

          IF HideValidationDialog OR NOT GUIALLOWED THEN
            Confirmed := TRUE
          ELSE
            Confirmed := CONFIRM(Text052,FALSE,LOWERCASE(FORMAT("Document Type")),"No.");

          IF NOT Confirmed THEN
            ERROR('');

          IF FINDSET THEN
            REPEAT
              ReservEntry2 := ReservEntry;
              ReservEntry2.ClearItemTrackingFields;
              ReservEntry2.MODIFY;
            UNTIL NEXT = 0;
        END;
    end;

    local procedure ClearItemAssgntSalesFilter(var TempItemChargeAssgntSales: Record "5809")
    begin
        TempItemChargeAssgntSales.SETRANGE("Document Line No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.");
    end;
 
    procedure CheckCustomerCreated(Prompt: Boolean): Boolean
    var
        Cont: Record "5050";
    begin
        IF ("Bill-to Customer No." <> '') AND ("Sell-to Customer No." <> '') THEN
          EXIT(TRUE);

        IF Prompt THEN
          IF NOT CONFIRM(Text035,TRUE) THEN
            EXIT(FALSE);

        IF "Sell-to Customer No." = '' THEN BEGIN
          TESTFIELD("Sell-to Contact No.");
          TESTFIELD("Sell-to Customer Template Code");
          Cont.GET("Sell-to Contact No.");
          Cont.CreateCustomer("Sell-to Customer Template Code");
          COMMIT;
          GET("Document Type"::Quote,"No.");
        END;

        IF "Bill-to Customer No." = '' THEN BEGIN
          TESTFIELD("Bill-to Contact No.");
          TESTFIELD("Bill-to Customer Template Code");
          Cont.GET("Bill-to Contact No.");
          Cont.CreateCustomer("Bill-to Customer Template Code");
          COMMIT;
          GET("Document Type"::Quote,"No.");
        END;

        EXIT(("Bill-to Customer No." <> '') AND ("Sell-to Customer No." <> ''));
    end;
 
    procedure RecreateReservEntry(OldSalesLine: Record "37";NewSourceRefNo: Integer;ToTemp: Boolean)
    begin
        IF ToTemp THEN BEGIN
          CLEAR(ReservEntry);
          ReservEntry.SETCURRENTKEY("Source ID","Source Ref. No.","Source Type","Source Subtype");
          ReservEntry.SETRANGE("Source ID",OldSalesLine."Document No.");
          ReservEntry.SETRANGE("Source Ref. No.",OldSalesLine."Line No.");
          ReservEntry.SETRANGE("Source Type",DATABASE::"Sales Line");
          ReservEntry.SETRANGE("Source Subtype",OldSalesLine."Document Type");
          IF ReservEntry.FINDSET THEN
            REPEAT
              TempReservEntry := ReservEntry;
              TempReservEntry.INSERT;
            UNTIL ReservEntry.NEXT = 0;
          ReservEntry.DELETEALL;
        END ELSE BEGIN
          CLEAR(TempReservEntry);
          TempReservEntry.SETCURRENTKEY("Source ID","Source Ref. No.","Source Type","Source Subtype");
          TempReservEntry.SETRANGE("Source Type",DATABASE::"Sales Line");
          TempReservEntry.SETRANGE("Source Subtype",OldSalesLine."Document Type");
          TempReservEntry.SETRANGE("Source ID",OldSalesLine."Document No.");
          TempReservEntry.SETRANGE("Source Ref. No.",OldSalesLine."Line No.");
          IF TempReservEntry.FINDSET THEN
            REPEAT
              ReservEntry := TempReservEntry;
              ReservEntry."Source Ref. No." := NewSourceRefNo;
              ReservEntry.INSERT;
            UNTIL TempReservEntry.NEXT = 0;
          TempReservEntry.DELETEALL;
        END;
    end;
 
    procedure RecreateReqLine(OldSalesLine: Record "37";NewSourceRefNo: Integer;ToTemp: Boolean)
    var
        ReqLine: Record "246";
    begin
        IF ToTemp THEN BEGIN
          ReqLine.SETCURRENTKEY("Order Promising ID","Order Promising Line ID","Order Promising Line No.");
          ReqLine.SETRANGE("Order Promising ID",OldSalesLine."Document No.");
          ReqLine.SETRANGE("Order Promising Line ID",OldSalesLine."Line No.");
          IF ReqLine.FINDSET THEN
            REPEAT
              TempReqLine := ReqLine;
              TempReqLine.INSERT;
            UNTIL ReqLine.NEXT = 0;
          ReqLine.DELETEALL;
        END ELSE BEGIN
          CLEAR(TempReqLine);
          TempReqLine.SETCURRENTKEY("Order Promising ID","Order Promising Line ID","Order Promising Line No.");
          TempReqLine.SETRANGE("Order Promising ID",OldSalesLine."Document No.");
          TempReqLine.SETRANGE("Order Promising Line ID",OldSalesLine."Line No.");
          IF TempReqLine.FINDSET THEN
            REPEAT
              ReqLine := TempReqLine;
              ReqLine."Order Promising Line ID" := NewSourceRefNo;
              ReqLine.INSERT;
            UNTIL TempReqLine.NEXT = 0;
          TempReqLine.DELETEALL;
        END;
    end;
 
    procedure UpdateSellToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "5054";
        Cust: Record "18";
    begin
        IF Cust.GET(CustomerNo) THEN BEGIN
          IF Cust."Primary Contact No." <> '' THEN
            "Sell-to Contact No." := Cust."Primary Contact No."
          ELSE BEGIN
            ContBusRel.RESET;
            ContBusRel.SETCURRENTKEY("Link to Table","No.");
            ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
            ContBusRel.SETRANGE("No.","Sell-to Customer No.");
            IF ContBusRel.FINDFIRST THEN
              "Sell-to Contact No." := ContBusRel."Contact No."
            ELSE
              "Sell-to Contact No." := '';
          END;
          "Sell-to Contact" := Cust.Contact;
        END;
    end;
 
    procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "5054";
        Cust: Record "18";
    begin
        IF Cust.GET(CustomerNo) THEN BEGIN
          IF Cust."Primary Contact No." <> '' THEN
            "Bill-to Contact No." := Cust."Primary Contact No."
          ELSE BEGIN
            ContBusRel.RESET;
            ContBusRel.SETCURRENTKEY("Link to Table","No.");
            ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
            ContBusRel.SETRANGE("No.","Bill-to Customer No.");
            IF ContBusRel.FINDFIRST THEN
              "Bill-to Contact No." := ContBusRel."Contact No."
            ELSE
              "Bill-to Contact No." := '';
          END;
          "Bill-to Contact" := Cust.Contact;
        END;
    end;
 
    procedure UpdateSellToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "5054";
        Customer: Record "18";
        Cont: Record "5050";
        CustTemplate: Record "5105";
        ContComp: Record "5050";
    begin
        IF Cont.GET(ContactNo) THEN
          "Sell-to Contact No." := Cont."No."
        ELSE BEGIN
          "Sell-to Contact" := '';
          EXIT;
        END;

        ContBusinessRelation.RESET;
        ContBusinessRelation.SETCURRENTKEY("Link to Table","Contact No.");
        ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
        ContBusinessRelation.SETRANGE("Contact No.",Cont."Company No.");
        IF ContBusinessRelation.FINDFIRST THEN BEGIN
          IF ("Sell-to Customer No." <> '') AND
             ("Sell-to Customer No." <> ContBusinessRelation."No.")
          THEN
            ERROR(Text037,Cont."No.",Cont.Name,"Sell-to Customer No.")
          ELSE IF "Sell-to Customer No." = '' THEN BEGIN
              SkipSellToContact := TRUE;
              VALIDATE("Sell-to Customer No.",ContBusinessRelation."No.");
              SkipSellToContact := FALSE;
            END;
        END ELSE BEGIN
          IF "Document Type" = "Document Type"::Quote THEN BEGIN
            Cont.TESTFIELD("Company No.");
            ContComp.GET(Cont."Company No.");
            "Sell-to Customer Name" := ContComp."Company Name";
            "Sell-to Customer Name 2" := ContComp."Name 2";
            "Ship-to Name" := ContComp."Company Name";
            "Ship-to Name 2" := ContComp."Name 2";
            "Ship-to Address" := ContComp.Address;
            "Ship-to Address 2" := ContComp."Address 2";
            "Ship-to City" := ContComp.City;
            "Ship-to Post Code" := ContComp."Post Code";
            "Ship-to County" := ContComp.County;
            VALIDATE("Ship-to Country/Region Code",ContComp."Country/Region Code");
            IF ("Sell-to Customer Template Code" = '') AND (NOT CustTemplate.ISEMPTY) THEN
              VALIDATE("Sell-to Customer Template Code",Cont.FindCustomerTemplate);
          END ELSE
            ERROR(Text039,Cont."No.",Cont.Name);
        END;

        IF Cont.Type = Cont.Type::Person THEN
          "Sell-to Contact" := Cont.Name
        ELSE
          IF Customer.GET("Sell-to Customer No.") THEN
            "Sell-to Contact" := Customer.Contact
          ELSE
            "Sell-to Contact" := '';

        IF "Document Type" = "Document Type"::Quote THEN BEGIN
          IF Customer.GET("Sell-to Customer No.") OR Customer.GET(ContBusinessRelation."No.") THEN BEGIN
            IF Customer."Copy Sell-to Addr. to Qte From" = Customer."Copy Sell-to Addr. to Qte From"::Company THEN BEGIN
              Cont.TESTFIELD("Company No.");
              Cont.GET(Cont."Company No.");
            END;
          END ELSE BEGIN
            Cont.TESTFIELD("Company No.");
            Cont.GET(Cont."Company No.");
          END;
          "Sell-to Address" := Cont.Address;
          "Sell-to Address 2" := Cont."Address 2";
          "Sell-to City" := Cont.City;
          "Sell-to Post Code" := Cont."Post Code";
          "Sell-to County" := Cont.County;
          "Sell-to Country/Region Code" := Cont."Country/Region Code";
        END;
        IF ("Sell-to Customer No." = "Bill-to Customer No.") OR
           ("Bill-to Customer No." = '')
        THEN
          VALIDATE("Bill-to Contact No.","Sell-to Contact No.");
    end;
 
    procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "5054";
        Cust: Record "18";
        Cont: Record "5050";
        CustTemplate: Record "5105";
        ContComp: Record "5050";
    begin
        IF Cont.GET(ContactNo) THEN BEGIN
          "Bill-to Contact No." := Cont."No.";
          IF Cont.Type = Cont.Type::Person THEN
            "Bill-to Contact" := Cont.Name
          ELSE
            IF Cust.GET("Bill-to Customer No.") THEN
              "Bill-to Contact" := Cust.Contact
            ELSE
              "Bill-to Contact" := '';
        END ELSE BEGIN
          "Bill-to Contact" := '';
          EXIT;
        END;

        ContBusinessRelation.RESET;
        ContBusinessRelation.SETCURRENTKEY("Link to Table","Contact No.");
        ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
        ContBusinessRelation.SETRANGE("Contact No.",Cont."Company No.");
        IF ContBusinessRelation.FINDFIRST THEN BEGIN
          IF "Bill-to Customer No." = '' THEN BEGIN
            SkipBillToContact := TRUE;
            VALIDATE("Bill-to Customer No.",ContBusinessRelation."No.");
            SkipBillToContact := FALSE;
            "Bill-to Customer Template Code" := '';
          END ELSE
            IF "Bill-to Customer No." <> ContBusinessRelation."No." THEN
              ERROR(Text037,Cont."No.",Cont.Name,"Bill-to Customer No.");
        END ELSE BEGIN
          IF "Document Type" = "Document Type"::Quote THEN BEGIN
            Cont.TESTFIELD("Company No.");
            ContComp.GET(Cont."Company No.");
            "Bill-to Name" := ContComp."Company Name";
            "Bill-to Name 2" := ContComp."Name 2";
            "Bill-to Address" := ContComp.Address;
            "Bill-to Address 2" := ContComp."Address 2";
            "Bill-to City" := ContComp.City;
            "Bill-to Post Code" := ContComp."Post Code";
            "Bill-to County" := ContComp.County;
            "Bill-to Country/Region Code" := ContComp."Country/Region Code";
            "VAT Registration No." := ContComp."VAT Registration No.";
            VALIDATE("Currency Code",ContComp."Currency Code");
            "Language Code" := ContComp."Language Code";
            IF ("Bill-to Customer Template Code" = '') AND (NOT CustTemplate.ISEMPTY) THEN
              VALIDATE("Bill-to Customer Template Code",Cont.FindCustomerTemplate);
          END ELSE
            ERROR(Text039,Cont."No.",Cont.Name);
        END;
    end;
 
    procedure GetShippingTime(CalledByFieldNo: Integer)
    begin
        IF (CalledByFieldNo <> CurrFieldNo) AND (CurrFieldNo <> 0) THEN
          EXIT;

        IF ShippingAgentService.GET("Shipping Agent Code","Shipping Agent Service Code") THEN
          "Shipping Time" := ShippingAgentService."Shipping Time"
        ELSE BEGIN
          GetCust("Sell-to Customer No.");
          "Shipping Time" := Cust."Shipping Time"
        END;
        IF NOT (CalledByFieldNo IN [FIELDNO("Shipping Agent Code"),FIELDNO("Shipping Agent Service Code")]) THEN
          VALIDATE("Shipping Time");
    end;
 
    procedure CheckCreditMaxBeforeInsert()
    var
        SalesHeader: Record "36";
        ContBusinessRelation: Record "5054";
        Cont: Record "5050";
        CustCheckCreditLimit: Codeunit "312";
    begin
        IF HideCreditCheckDialogue THEN
          EXIT;
        IF GETFILTER("Sell-to Customer No.") <> '' THEN BEGIN
          IF GETRANGEMIN("Sell-to Customer No.") = GETRANGEMAX("Sell-to Customer No.") THEN BEGIN
            Cust.GET(GETRANGEMIN("Sell-to Customer No."));
            IF Cust."Bill-to Customer No." <> '' THEN
              SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
            ELSE
              SalesHeader."Bill-to Customer No." := Cust."No.";
            CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
          END
        END ELSE
          IF GETFILTER("Sell-to Contact No.") <> '' THEN
            IF GETRANGEMIN("Sell-to Contact No.") = GETRANGEMAX("Sell-to Contact No.") THEN BEGIN
              Cont.GET(GETRANGEMIN("Sell-to Contact No."));
              ContBusinessRelation.RESET;
              ContBusinessRelation.SETCURRENTKEY("Link to Table","No.");
              ContBusinessRelation.SETRANGE("Link to Table",ContBusinessRelation."Link to Table"::Customer);
              ContBusinessRelation.SETRANGE("Contact No.",Cont."Company No.");
              IF ContBusinessRelation.FINDFIRST THEN BEGIN
                Cust.GET(ContBusinessRelation."No.");
                IF Cust."Bill-to Customer No." <> '' THEN
                  SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
                ELSE
                  SalesHeader."Bill-to Customer No." := Cust."No.";
                CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
              END;
            END;
    end;
 
    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "5765";
    begin
        TESTFIELD(Status,Status::Released);

        WhseRequest.RESET;
        WhseRequest.SETCURRENTKEY("Source Document","Source No.");
        CASE "Document Type" OF
          "Document Type"::Order:
            WhseRequest.SETRANGE("Source Document",WhseRequest."Source Document"::"Sales Order");
          "Document Type"::"Return Order":
            WhseRequest.SETRANGE("Source Document",WhseRequest."Source Document"::"Sales Return Order");
        END;
        WhseRequest.SETRANGE("Source No.","No.");
        REPORT.RUNMODAL(REPORT::"Create Invt. Put-away / Pick",TRUE,FALSE,WhseRequest);
    end;
 
    procedure CreateTodo()
    var
        TempTodo: Record "5080" temporary;
    begin
        TESTFIELD("Sell-to Contact No.");
        TempTodo.CreateToDoFromSalesHeader(Rec);
    end;

    local procedure UpdateShipToAddress()
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          IF "Location Code" <> '' THEN BEGIN
            Location.GET("Location Code");
            "Ship-to Name" := Location.Name;
            "Ship-to Name 2" := Location."Name 2";
            "Ship-to Address" := Location.Address;
            "Ship-to Address 2" := Location."Address 2";
            "Ship-to City" := Location.City;
            "Ship-to Post Code" := Location."Post Code";
            "Ship-to County" := Location.County;
            "Ship-to Country/Region Code" := Location."Country/Region Code";
            "Ship-to Contact" := Location.Contact;
          END ELSE BEGIN
            CompanyInfo.GET;
            "Ship-to Code" := '';
            "Ship-to Name" := CompanyInfo."Ship-to Name";
            "Ship-to Name 2" := CompanyInfo."Ship-to Name 2";
            "Ship-to Address" := CompanyInfo."Ship-to Address";
            "Ship-to Address 2" := CompanyInfo."Ship-to Address 2";
            "Ship-to City" := CompanyInfo."Ship-to City";
            "Ship-to Post Code" := CompanyInfo."Ship-to Post Code";
            "Ship-to County" := CompanyInfo."Ship-to County";
            "Ship-to Country/Region Code" := CompanyInfo."Ship-to Country/Region Code";
            "Ship-to Contact" := CompanyInfo."Ship-to Contact";
          END;
        END;
    end;
 
    procedure ShowDocDim()
    var
        DocDim: Record "357";
        DocDims: Form "546";
    begin
        DocDim.SETRANGE("Table ID",DATABASE::"Sales Header");
        DocDim.SETRANGE("Document Type","Document Type");
        DocDim.SETRANGE("Document No.","No.");
        DocDim.SETRANGE("Line No.",0);
        DocDims.SETTABLEVIEW(DocDim);
        DocDims.RUNMODAL;
        GET("Document Type","No.");
    end;
 
    procedure CheckLocation(ShowError: Boolean): Boolean
    var
        SalesLine: Record "37";
        SalesLine2: Record "37";
        CheckItemAvail: Form "342";
    begin
        IF NOT ("Shipping Advice" = "Shipping Advice"::Complete) THEN
          EXIT(FALSE);

        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETRANGE(Type,SalesLine.Type::Item);
        IF SalesLine.FINDSET THEN BEGIN
          SalesLine2.COPYFILTERS(SalesLine);
          SalesLine2.SETCURRENTKEY("Document Type","Document No.","Location Code");
          SalesLine2.SETFILTER("Location Code",'<> %1',SalesLine."Location Code");
          IF SalesLine2.FINDFIRST THEN BEGIN
            IF ShowError THEN
              ERROR(Text050,FIELDCAPTION("Shipping Advice"),"Shipping Advice","No.",SalesLine.Type);
            EXIT(TRUE);
          END;
          REPEAT
            IF CheckItemAvail.SalesLineShowWarning(SalesLine) THEN BEGIN
              IF ShowError THEN
                ERROR(Text064,SalesLine."No.",SalesLine."Location Code",SalesLine."Document No.");
              EXIT(TRUE);
            END;
          UNTIL SalesLine.NEXT = 0
        END;
    end;
 
    procedure SetAmountToApply(AppliesToDocNo: Code[20];CustomerNo: Code[20])
    var
        CustLedgEntry: Record "21";
    begin
        CustLedgEntry.SETCURRENTKEY("Document No.");
        CustLedgEntry.SETRANGE("Document No.",AppliesToDocNo);
        CustLedgEntry.SETRANGE("Customer No.",CustomerNo);
        CustLedgEntry.SETRANGE(Open,TRUE);
        IF CustLedgEntry.FINDFIRST THEN BEGIN
          IF CustLedgEntry."Amount to Apply" = 0 THEN  BEGIN
            CustLedgEntry.CALCFIELDS("Remaining Amount");
            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
          END ELSE
            CustLedgEntry."Amount to Apply" := 0;
          CustLedgEntry."Accepted Payment Tolerance" := 0;
          CustLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
          CODEUNIT.RUN(CODEUNIT::"Cust. Entry-Edit",CustLedgEntry);
        END;
    end;
 
    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "32";
        SalesLine: Record "37";
        SalesShptLine: Record "111";
        ReturnRcptLine: Record "6661";
        TempValueEntry: Record "5802" temporary;
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        TempValueEntry.RESET;
        TempValueEntry.DELETEALL;

        CASE "Document Type" OF
          "Document Type"::Order,"Document Type"::Invoice:
            BEGIN
              IF SalesLine.FINDSET THEN
                REPEAT
                  IF (SalesLine.Type = SalesLine.Type::Item) AND (SalesLine.Quantity <> 0) THEN
                    WITH SalesShptLine DO BEGIN
                      IF SalesLine."Shipment No." <> '' THEN BEGIN
                        SETRANGE("Document No.",SalesLine."Shipment No.");
                        SETRANGE("Line No.",SalesLine."Shipment Line No.");
                      END ELSE BEGIN
                        SETCURRENTKEY("Order No.","Order Line No.");
                        SETRANGE("Order No.",SalesLine."Document No.");
                        SETRANGE("Order Line No.",SalesLine."Line No.");
                      END;
                      SETRANGE(Correction,FALSE);
                      IF QtyType = QtyType::Invoicing THEN
                        SETFILTER("Qty. Shipped Not Invoiced",'<>0');

                      IF FINDSET THEN
                        REPEAT
                          FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                          IF ItemLedgEntry.FINDSET THEN
                            REPEAT
                              CreateTempAdjmtValueEntries(TempValueEntry,ItemLedgEntry."Entry No.");
                            UNTIL ItemLedgEntry.NEXT = 0;
                        UNTIL NEXT = 0;
                    END;
                UNTIL SalesLine.NEXT = 0;
            END;
          "Document Type"::"Return Order","Document Type"::"Credit Memo":
            BEGIN
              IF SalesLine.FINDSET THEN
                REPEAT
                  IF (SalesLine.Type = SalesLine.Type::Item) AND (SalesLine.Quantity <> 0) THEN
                    WITH ReturnRcptLine DO BEGIN
                      IF SalesLine."Return Receipt No." <> '' THEN BEGIN
                        SETRANGE("Document No.",SalesLine."Return Receipt No.");
                        SETRANGE("Line No.",SalesLine."Return Receipt Line No.");
                      END ELSE BEGIN
                        SETCURRENTKEY("Return Order No.","Return Order Line No.");
                        SETRANGE("Return Order No.",SalesLine."Document No.");
                        SETRANGE("Return Order Line No.",SalesLine."Line No.");
                      END;
                      SETRANGE(Correction,FALSE);
                      IF QtyType = QtyType::Invoicing THEN
                        SETFILTER("Return Qty. Rcd. Not Invd.",'<>0');

                      IF FINDSET THEN
                        REPEAT
                          FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                          IF ItemLedgEntry.FINDSET THEN
                            REPEAT
                              CreateTempAdjmtValueEntries(TempValueEntry,ItemLedgEntry."Entry No.");
                            UNTIL ItemLedgEntry.NEXT = 0;
                        UNTIL NEXT = 0;
                    END;
                UNTIL SalesLine.NEXT = 0;
            END;
        END;
        FORM.RUNMODAL(0,TempValueEntry);
    end;
 
    procedure CreateTempAdjmtValueEntries(var TempValueEntry: Record "5802" temporary;ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "5802";
    begin
        WITH ValueEntry DO BEGIN
          SETCURRENTKEY("Item Ledger Entry No.");
          SETRANGE("Item Ledger Entry No.",ItemLedgEntryNo);
          IF FINDSET THEN
            REPEAT
              IF Adjustment THEN BEGIN
                TempValueEntry := ValueEntry;
                IF TempValueEntry.INSERT THEN;
              END;
            UNTIL NEXT = 0;
        END;
    end;
 
    procedure GetPstdDocLinesToRevere()
    var
        SalesPostedDocLines: Form "5850";
    begin
        GetCust("Sell-to Customer No.");
        SalesPostedDocLines.SetToSalesHeader(Rec);
        SalesPostedDocLines.SETRECORD(Cust);
        SalesPostedDocLines.LOOKUPMODE := TRUE;
        IF SalesPostedDocLines.RUNMODAL = ACTION::LookupOK THEN
          SalesPostedDocLines.CopyLineToDoc;

        CLEAR(SalesPostedDocLines);
    end;
 
    procedure CalcInvDiscForHeader()
    var
        SalesInvDisc: Codeunit "60";
    begin
        SalesSetup.GET;
        IF SalesSetup."Calc. Inv. Discount" THEN
          SalesInvDisc.CalculateIncDiscForHeader(Rec);
    end;
 
    procedure SynchronizeForReservations(var NewSalesLine: Record "37";OldSalesLine: Record "37")
    begin
        NewSalesLine.CALCFIELDS("Reserved Quantity");
        IF NewSalesLine."Reserved Quantity" = 0 THEN
          EXIT;
        IF NewSalesLine."Location Code" <> OldSalesLine."Location Code" THEN
          NewSalesLine.VALIDATE("Location Code",OldSalesLine."Location Code");
        IF NewSalesLine."Bin Code" <> OldSalesLine."Bin Code" THEN
          NewSalesLine.VALIDATE("Bin Code",OldSalesLine."Bin Code");
        IF NewSalesLine.MODIFY THEN;
    end;
 
    procedure GetRetailSetup()
    begin
        //LS
        IF NOT RetailSetupAlreadyRetrieved THEN BEGIN
          RetailSetup.GET;
          RetailSetupAlreadyRetrieved := TRUE;
        END;
    end;
 
    procedure CreateAction(Type: Integer)
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActionsMgt: Codeunit "99001451";
    begin
        //APNT-HHT1.0
        //Type: 0 = INSERT, 1 = MODIFY, 2 = DELETE, 3 = RENAME
        RecRef.GETTABLE(Rec);
        xRecRef.GETTABLE(xRec);
        ActionsMgt.CreateActionsByRecRef(RecRef,xRecRef,Type);
        RecRef.CLOSE;
        xRecRef.CLOSE;
        //APNT-HHT1.0
    end;
 
    procedure UpdateSalesLineDate()
    var
        SalesLineRec: Record "37";
    begin
        //DP6.01.01 START
        SalesLineRec.RESET;
        SalesLineRec.SETRANGE("Document Type","Document Type");
        SalesLineRec.SETRANGE("Document No.","No.");
        IF SalesLineRec.FINDSET THEN
          REPEAT
            SalesLineRec."Agreement Posting Date" := "Posting Date";
            SalesLineRec.MODIFY;
          UNTIL SalesLineRec.NEXT = 0;
        //DP6.01.01 STOP
    end;
 
    procedure AssistEditAgrmtCrMemo(OldSalesHeader: Record "36"): Boolean
    var
        SalesHeader2: Record "36";
        PremiseMgtSetup: Record "33016826";
    begin
        //DP6.01.01 START
        WITH SalesHeader DO BEGIN
          COPY(Rec);
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Agreement Cr. Memo Nos.");
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup."Agreement Cr. Memo Nos.",OldSalesHeader."No. Series","No. Series") THEN BEGIN
            IF ("Sell-to Customer No." = '') AND ("Sell-to Contact No." = '') THEN BEGIN
              HideCreditCheckDialogue := FALSE;
              CheckCreditMaxBeforeInsert;
              HideCreditCheckDialogue := TRUE;
            END;
            NoSeriesMgt.SetSeries("No.");
            IF SalesHeader2.GET("Document Type","No.") THEN
              ERROR(Text051,LOWERCASE(FORMAT("Document Type")),"No.");
            Rec := SalesHeader;
            EXIT(TRUE);
          END;
        END;
        //DP6.01.01 STOP
    end;
 
    procedure GetLastEComStatusEntryNo(lcodDocumentId: Code[20];var lintEntryNo: Integer;var ltxtStatus: Text[100])
    var
        greceComCustOrdStatus: Record "50117";
    begin
        greceComCustOrdStatus.RESET();
        greceComCustOrdStatus.SETRANGE("Document ID", lcodDocumentId);
        IF greceComCustOrdStatus.FINDLAST() THEN BEGIN
          lintEntryNo := greceComCustOrdStatus."Entry No.";
          ltxtStatus := greceComCustOrdStatus."MAG-Status";
        END ELSE BEGIN
          lintEntryNo := 0;
          ltxtStatus := '';
        END;
    end;
}

