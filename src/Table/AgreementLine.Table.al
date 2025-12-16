table 33016816 "Agreement Line"
{
    // DP6.01.02 HK 19SEP2013 : Code added to update element line dimension
    // DP6.01.03 HK 06NOV2013 : Code added to validate Premise linked with Agreement header

    Caption = 'Agreement Line';
    DrillDownFormID = Form33016883;
    LookupFormID = Form33016883;

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
        }
        field(2; "Agreement Type"; Option)
        {
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Client No."; Code[20])
        {
            TableRelation = Customer;

            trigger OnValidate()
            var
                CustomerRec: Record Customer;
            begin
                TestStatusOpen;
                IF "Client No." <> '' THEN BEGIN
                    CustomerRec.GET("Client No.");
                    "Client Name" := CustomerRec.Name;
                    "Salesperson Code" := CustomerRec."Salesperson Code";
                    "Gen. Bus. Posting Group" := CustomerRec."Gen. Bus. Posting Group";
                    "VAT Bus. Posting Group" := CustomerRec."VAT Bus. Posting Group";
                    "Global Dimension 1 Code" := CustomerRec."Global Dimension 1 Code";
                    "Global Dimension 2 Code" := CustomerRec."Global Dimension 2 Code";
                    //"Currency Code" := CustomerRec."Currency Code";
                    "Payment Term Code" := CustomerRec."Payment Terms Code";
                END ELSE BEGIN
                    "Client Name" := '';
                    "Salesperson Code" := '';
                    "Gen. Bus. Posting Group" := '';
                    "VAT Bus. Posting Group" := '';
                    "Global Dimension 1 Code" := '';
                    "Global Dimension 2 Code" := '';
                    "Currency Code" := '';
                    "Payment Term Code" := '';
                END;
            end;
        }
        field(5; "Premise No."; Code[20])
        {
            TableRelation = Premise.No.;

            trigger OnLookup()
            var
                AgreementPremiseRec: Record "Agreement Premise Relation";
                PremiseRec: Record Premise;
                PremiseFrm: Form "33016803";
            begin
                AgreementPremiseRec.RESET;
                AgreementPremiseRec.SETRANGE("Agreement Type", "Agreement Type");
                AgreementPremiseRec.SETRANGE("Agreement No.", "Agreement No.");
                AgreementPremiseRec.SETFILTER("Premise No.", '<>%1', '');
                IF AgreementPremiseRec.FINDSET THEN
                    REPEAT
                        IF PremiseRec.GET(AgreementPremiseRec."Premise No.") THEN
                            PremiseRec.MARK(TRUE);
                    UNTIL AgreementPremiseRec.NEXT = 0;

                PremiseRec.MARKEDONLY(TRUE);
                CLEAR(PremiseFrm);
                PremiseFrm.SETTABLEVIEW(PremiseRec);
                PremiseFrm.LOOKUPMODE(TRUE);
                IF PremiseFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    PremiseFrm.GETRECORD(PremiseRec);
                    IF PremiseRec."No." <> '' THEN
                        VALIDATE("Premise No.", PremiseRec."No.");
                END;
            end;

            trigger OnValidate()
            var
                AgrmtPremiseRelation: Record "Agreement Premise Relation";
            begin
                TestStatusOpen;
                IF ("Premise No." <> xRec."Premise No.") AND ("Premise No." = '') THEN BEGIN
                    CALCFIELDS("Posted Invoice", "Unposted Invoice");
                    IF ("Posted Invoice" <> 0) OR ("Unposted Invoice" <> 0) THEN
                        ERROR(Text003, "Agreement Type", "Agreement No.", xRec."Premise No.");
                END;

                //DP6.01.03 START
                IF "Premise No." <> '' THEN BEGIN
                    AgrmtPremiseRelation.SETRANGE("Agreement Type", "Agreement Type");
                    AgrmtPremiseRelation.SETRANGE("Agreement No.", "Agreement No.");
                    AgrmtPremiseRelation.SETRANGE("Premise No.", "Premise No.");
                    IF AgrmtPremiseRelation.ISEMPTY THEN
                        ERROR(Text33016823, "Agreement No.", "Premise No.");
                END;
                //DP6.01.03 STOP

                ValidatePremise;
            end;
        }
        field(6; "Client Name"; Text[50])
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(7; "Salesperson Code"; Code[10])
        {
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(8;"Element Type";Code[20])
        {
            TableRelation = "Agreement Element".Code;

            trigger OnValidate()
            var
                RentElementRec: Record "Agreement Element";
            begin
                TestStatusOpen;

                IF ("Element Type" <> xRec."Element Type") AND (xRec."Element Type" <> '') THEN BEGIN
                  CALCFIELDS("Posted Invoice","Unposted Invoice");
                  IF ("Posted Invoice" <> 0) OR ("Unposted Invoice" <> 0) THEN
                    ERROR(Text006,xRec."Element Type","Agreement Type","Agreement No.","Line No.");
                END;

                IF "Element Type" <> '' THEN BEGIN
                  RentElementRec.GET("Element Type");
                  IF RentElementRec."Invoice G/L Account" = '' THEN
                    ERROR(Text001,RentElementRec.Code);
                  Description := RentElementRec.Description;
                  "Gen. Prod. Posting Group" := RentElementRec."Gen. Prod. Posting Group";
                  "VAT Prod. Posting Group" := RentElementRec."VAT Prod. Posting Group";
                  IF RentElementRec."No L/S Area Applicable" THEN
                    "No Leaseable/ Sale Area" := TRUE
                  ELSE
                    "No Leaseable/ Sale Area" := FALSE;
                END ELSE BEGIN
                  Description := '';
                  "Gen. Prod. Posting Group" := '';
                  "VAT Prod. Posting Group" := '';
                  "No Leaseable/ Sale Area" := FALSE;
                END;
                ValidateLineDate;

                CreateLineDimension; //DP6.01.02
            end;
        }
        field(9;Description;Text[50])
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(10;"No. of Invoices";Integer)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                ValidateUnitPrice;
                UpdateOriginalAmt;
                UpdateBalanceAmt;
            end;
        }
        field(11;"Posted Invoice";Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("Sales Invoice Line".Quantity WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                   Ref. Document No.=FIELD(Agreement No.),
                                                                   Ref. Document Line No.=FIELD(Line No.),
                                                                   Gen. Bus. Posting Group=FILTER(<>VAT-INV)));
            Caption = 'Posted Invoice';
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(12;"To be Invoice/Cr. Memo";Integer)
        {
            Editable = false;

            trigger OnValidate()
            var
                TotalInvoiced: Decimal;
                TotalCrMemo: Decimal;
            begin
                IF "To be Invoice/Cr. Memo" <> 0 THEN BEGIN
                  CALCFIELDS("Unposted Invoice","Posted Invoice","UnPosted Cr. Memo","Posted Cr. Memo");
                  TotalInvoiced := ("Unposted Invoice"+ "Posted Invoice") - ("UnPosted Cr. Memo" - "Posted Cr. Memo");
                  TotalCrMemo := "UnPosted Cr. Memo" + "Posted Cr. Memo";
                  IF "To be Invoice/Cr. Memo" > 0 THEN BEGIN
                    IF ("No. of Invoices") < ("To be Invoice/Cr. Memo" + TotalInvoiced) THEN
                       ERROR(Text001,("No. of Invoices" - TotalInvoiced),"Element Type","Agreement No.","Line No.");
                    VALIDATE("To be Invoice Amount","To be Invoice/Cr. Memo" * "Invoice Unit Price")
                  END ELSE BEGIN
                    IF "Posted Invoice" < (ABS("To be Invoice/Cr. Memo") + TotalCrMemo) THEN
                      ERROR(Text33016822,"Element Type","Agreement No.","Line No.");
                    VALIDATE("To be Cr. Memo Amt.","To be Invoice/Cr. Memo" * "Invoice Unit Price" * -1)
                  END;
                END ELSE BEGIN
                  "To be Invoice Amount" := 0;
                  "To be Cr. Memo Amt." := 0;
                END;
            end;
        }
        field(13;"Gen. Bus. Posting Group";Code[10])
        {
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(14;"Gen. Prod. Posting Group";Code[10])
        {
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(15;"VAT Bus. Posting Group";Code[10])
        {
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(16;"VAT Prod. Posting Group";Code[10])
        {
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(17;"Global Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                TestStatusOpen;
                ValidateShortcutDimCode(1,"Global Dimension 1 Code");
            end;
        }
        field(18;"Global Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                TestStatusOpen;
                ValidateShortcutDimCode(2,"Global Dimension 2 Code");
            end;
        }
        field(19;"Invoice Unit Price";Decimal)
        {

            trigger OnValidate()
            var
                AgreementElementRec: Record "Agreement Element";
            begin
                TestStatusOpen;
                ValidateUnitPrice;
                "To be Invoice Amount" := "To be Invoice/Cr. Memo" * "Invoice Unit Price";

                UpdateOriginalAmt;
                UpdateBalanceAmt;
            end;
        }
        field(20;"To be Invoice Amount";Decimal)
        {
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateBalanceAmt;
            end;
        }
        field(21;"Start Date";Date)
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(22;"End Date";Date)
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(23;"Posted Invoice Amt.";Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("Sales Invoice Line"."Line Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                        Ref. Document No.=FIELD(Agreement No.),
                                                                        Ref. Document Line No.=FIELD(Line No.),
                                                                        Gen. Bus. Posting Group=FILTER(<>VAT-INV)));
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(24;"Last Invoice Date";Date)
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(25;"Currency Code";Code[10])
        {
            TableRelation = Currency;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(26;"Source Code";Code[10])
        {
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(27;"Payment Term Code";Code[10])
        {
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(28;"Unit of Measure";Code[10])
        {
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(29;"Amount (LCY)";Decimal)
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(30;"Sales Representative";Code[20])
        {
            TableRelation = "Sales Representative".No.;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(31;"Payment Schd Line";Boolean)
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(32;"Original Amount";Decimal)
        {
            BlankZero = true;
            Editable = false;

            trigger OnValidate()
            var
                AgreementElementRec: Record "Agreement Element";
                AgreeHeader: Record "Agreement Header";
                Currency: Record Currency;
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                TestStatusOpen;
                AgreeHeader.GET("Agreement Type","Agreement No.");
                IF AgreeHeader."Currency Code" <> '' THEN BEGIN
                IF Currency.GET("Currency Code") THEN
                    "Currency Code":=AgreeHeader."Currency Code";
                  "Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        WORKDATE,AgreeHeader."Currency Code",
                        "Original Amount",AgreeHeader."Currency Factor"),
                      Currency."Unit-Amount Rounding Precision")
                END ELSE
                  "Amount (LCY)" := "Original Amount";
            end;
        }
        field(34;"Unit Price";Decimal)
        {

            trigger OnValidate()
            var
                AgreementElementRec: Record "Agreement Element";
            begin
                ValidateUnitPrice;
                UpdateOriginalAmt;
                UpdateBalanceAmt;
            end;
        }
        field(35;"Leasable/Salable Area";Decimal)
        {
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                IF "No Leaseable/ Sale Area" THEN
                  "Invoice Unit Price" := "Unit Price" * 1
                ELSE BEGIN
                  "Invoice Unit Price" :=  "Unit Price" * "Leasable/Salable Area";
                END;

                UpdateOriginalAmt;
                UpdateBalanceAmt;
            end;
        }
        field(36;"Signature Date";Date)
        {
        }
        field(37;"Unposted Invoice";Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("Sales Line".Quantity WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                           Ref. Document No.=FIELD(Agreement No.),
                                                           Ref. Document Line No.=FIELD(Line No.),
                                                           Document Type=FILTER(Invoice)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(38;"Balanced Amount";Decimal)
        {
            BlankZero = true;
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(39;"No Leaseable/ Sale Area";Boolean)
        {
        }
        field(40;"Premise Blocked";Boolean)
        {
            Editable = false;

            trigger OnValidate()
            var
                AgrmtHdr: Record "Agreement Header";
            begin
                AgrmtHdr.GET("Agreement Type","Agreement No.");
                IF "Premise Blocked" THEN BEGIN
                  AgrmtHdr.VALIDATE("Premise Blocked",TRUE);
                  AgrmtHdr.MODIFY;
                END ELSE BEGIN
                  CheckAgrHdrBlocked(AgrmtHdr,"Premise No.");
                END;
            end;
        }
        field(41;"UnPosted Cr. Memo";Decimal)
        {
            CalcFormula = Sum("Sales Line".Quantity WHERE (Document Type=FILTER(Credit Memo),
                                                           Ref. Document Type=FIELD(Agreement Type),
                                                           Ref. Document No.=FIELD(Agreement No.),
                                                           Ref. Document Line No.=FIELD(Line No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(42;"Posted Cr. Memo";Decimal)
        {
            CalcFormula = Sum("Sales Cr.Memo Line".Quantity WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                   Ref. Document No.=FIELD(Agreement No.),
                                                                   Ref. Document  Line No.=FIELD(Line No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(43;"UnPosted Cr. Memo Amt.";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Line Amount" WHERE (Document Type=FILTER(Credit Memo),
                                                                Ref. Document Type=FIELD(Agreement Type),
                                                                Ref. Document No.=FIELD(Agreement No.),
                                                                Ref. Document Line No.=FIELD(Line No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(44;"Posted Cr. Memo Amt.";Decimal)
        {
            CalcFormula = Sum("Sales Cr.Memo Line"."Line Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                        Ref. Document No.=FIELD(Agreement No.),
                                                                        Ref. Document  Line No.=FIELD(Line No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(45;"UnPosted Invoice Amt.";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Line Amount" WHERE (Document Type=FILTER(Invoice),
                                                                Ref. Document Type=FIELD(Agreement Type),
                                                                Ref. Document No.=FIELD(Agreement No.),
                                                                Ref. Document Line No.=FIELD(Line No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(46;"To be Cr. Memo Amt.";Decimal)
        {
            Editable = false;
        }
        field(47;"Posted VAT Invoice";Decimal)
        {
            CalcFormula = Sum("Sales Invoice Line".Quantity WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                   Ref. Document No.=FIELD(Agreement No.),
                                                                   Ref. Document Line No.=FIELD(Line No.),
                                                                   Gen. Bus. Posting Group=FILTER(VAT-INV)));
            Description = 'APNT-13953';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48;"Posted VAT Invoice Amount";Decimal)
        {
            CalcFormula = Sum("Sales Invoice Line"."Line Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                        Ref. Document No.=FIELD(Agreement No.),
                                                                        Ref. Document Line No.=FIELD(Line No.),
                                                                        Gen. Bus. Posting Group=FILTER(VAT-INV)));
            Description = 'APNT-13953';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Agreement Type","Agreement No.","Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Sales Representative","Signature Date")
        {
            SumIndexFields = "Original Amount","Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
        CALCFIELDS("Posted Invoice","Unposted Invoice");
        IF "Unposted Invoice" <> 0 THEN
          ERROR(Text005,"Agreement Type","Agreement No.");
        IF "Posted Invoice" <> 0 THEN
          ERROR(Text004,"Agreement Type","Agreement No.");

        DimMgt.DeleteDocDim(DATABASE::"Agreement Line","Agreement Type","Agreement No.","Line No.");
        DelScheduleLines(Rec);
    end;

    trigger OnInsert()
    var
        AgreementHeader: Record "Agreement Header";
        DocDim: Record "Document Dimension";
        Customer: Record Customer;
    begin
        TestStatusOpen;
        AgreementHeader.GET("Agreement Type","Agreement No.");
        "Payment Term Code" := AgreementHeader."Payment Terms Code";
        "Client No." := AgreementHeader."Client No.";
        "Client Name" := AgreementHeader."Client Name";
        "Salesperson Code" := AgreementHeader."Salesperson Code";

        PremiseMgt.GET;
        "Source Code" := PremiseMgt."Default Source Code";

        IF AgreementHeader."Client No." <> '' THEN BEGIN
          Customer.GET(AgreementHeader."Client No.");
          "Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
          "VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
          "Global Dimension 1 Code" := Customer."Global Dimension 1 Code";
          "Global Dimension 2 Code" := Customer."Global Dimension 2 Code";
        END;

        DocDim.LOCKTABLE;
        LOCKTABLE;
        DimMgt.InsertDocDim(
          DATABASE::"Agreement Line","Agreement Type","Agreement No.","Line No.",
          "Global Dimension 1 Code","Global Dimension 2 Code");

        "Start Date" := AgreementHeader."Agreement Start Date";
        "End Date" := AgreementHeader."Agreement End Date";
        "Sales Representative" := AgreementHeader."Sales Representative";
        "Signature Date" := AgreementHeader."Signature Date";
    end;

    trigger OnModify()
    var
        AgreementHeader: Record "Agreement Header";
    begin
        AgreementHeader.GET("Agreement Type","Agreement No.");

        ValidateLineDate;
    end;

    trigger OnRename()
    begin
        TestStatusOpen;
    end;

    var
        DimMgt: Codeunit "408";
        Text001: Label 'You can only create %1 Agreement Invoice(s) for Element Type %2 in Agreement No. %3 Line %4';
        Text002: Label 'All Agreement Invoice(s) created for Element Type %1 in Agreement No. %2 Line No. %3';
        Text003: Label 'Invoice(s) have been generated for Agreement Type : %1 Agreement No. : %2. You cannot remove Premise %3.';
        Text004: Label 'Posted Invoice(s) exists for Agreement Type %1 Agreement No. %2';
        Text005: Label 'Invoice(s) have been generated for Agreement Type %1 Agreement No.';
        Text006: Label 'Invoice(s) exists for Element Type %1 in Agreement Type %2 Agreement No. %3 Line No. %4';
        PremiseMgt: Record "Premise Management Setup";
        Text33016821: Label 'Value in Unit Price must be Positive';
        Text33016822: Label 'Credit Memo created foe all Invoices for Element Type %1 in Agreement No. %2 Line %3';
        Text33016823: Label 'Agreement %1 is not linked with Premise %2';
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        IF "Line No." <> 0 THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Agreement Line","Agreement Type","Agreement No.",
            "Line No.",FieldNumber,ShortcutDimCode);
          MODIFY;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowDimensions()
    var
        DocDim: Record "Document Dimension";
        DocDimensions: Form "546";
    begin
        TESTFIELD("Agreement No.");
        TESTFIELD("Line No.");
        DocDim.SETRANGE("Table ID",DATABASE::"Agreement Line");
        DocDim.SETRANGE("Document No.","Agreement No.");
        DocDim.SETRANGE("Line No.","Line No.");
        DocDimensions.SETTABLEVIEW(DocDim);
        DocDimensions.RUNMODAL;
    end;
 
    procedure TestStatusOpen()
    var
        AgreementHeader: Record "Agreement Header";
    begin
        IF AgreementHeader.GET("Agreement Type","Agreement No.") THEN
          AgreementHeader.TESTFIELD("Approval Status",AgreementHeader."Approval Status"::Open);
    end;
 
    procedure DelScheduleLines(var AgreeLines: Record "Agreement Line")
    var
        recPaySchLines: Record "Payment Schedule Lines";
    begin
        recPaySchLines.RESET;
        recPaySchLines.SETRANGE(recPaySchLines."Agreement Type",AgreeLines."Agreement Type");
        recPaySchLines.SETRANGE(recPaySchLines."Agreement No.",AgreeLines."Agreement No.");
        recPaySchLines.SETRANGE(recPaySchLines."Agreement Line No.",AgreeLines."Line No.");
        IF recPaySchLines.FINDSET THEN
           recPaySchLines.DELETEALL;
    end;
 
    procedure ValidateUnitPrice()
    var
        AgreementElementRec: Record "Agreement Element";
    begin
        TESTFIELD("Element Type");
        IF "Unit Price" < 0 THEN
          ERROR(Text33016821);
        ValidatePremise;

        IF "No Leaseable/ Sale Area" THEN
          "Invoice Unit Price" := "Unit Price" * 1
        ELSE BEGIN
          "Invoice Unit Price" :=  "Unit Price" * "Leasable/Salable Area";
        END;
    end;
 
    procedure ValidateLineDate()
    var
        AgreementHeader: Record "Agreement Header";
    begin
        AgreementHeader.GET("Agreement Type","Agreement No.");
        IF ("Start Date" = 0D) OR ("End Date" = 0D) THEN BEGIN
          "Start Date" := AgreementHeader."Agreement Start Date";
          "End Date" := AgreementHeader."Agreement End Date";
        END;
    end;
 
    procedure UpdateBalanceAmt()
    begin
        CALCFIELDS("Posted Invoice Amt.","UnPosted Invoice Amt.","UnPosted Cr. Memo Amt.","Posted Cr. Memo Amt.");
        "Balanced Amount" := "Original Amount" -
          (("Posted Invoice Amt." + "UnPosted Invoice Amt.") - ("UnPosted Cr. Memo Amt." + "Posted Cr. Memo Amt."));
    end;
 
    procedure CheckAgrHdrBlocked(AgrmtHeader: Record "Agreement Header";PremiseNo: Code[20])
    var
        AgrmtLine: Record "Agreement Line";
        AgreementHeaderRec: Record "Agreement Header";
    begin
        AgrmtLine.RESET;
        AgrmtLine.SETRANGE("Agreement Type",AgrmtHeader."Agreement Type");
        AgrmtLine.SETRANGE("Agreement No.",AgrmtHeader."No.");
        AgrmtLine.SETRANGE("Premise Blocked",TRUE);
        AgrmtLine.SETFILTER("Premise No.",'<>%1',PremiseNo);
        IF AgrmtLine.COUNT = 0 THEN BEGIN
          AgreementHeaderRec := AgrmtHeader;
          AgreementHeaderRec.VALIDATE("Premise Blocked",FALSE);
          AgreementHeaderRec.MODIFY;
        END;
    end;
 
    procedure ValidatePremise()
    var
        PremiseArea: Record Premise;
        ElementRec: Record "Agreement Element";
        AgrmtPremiseRelation: Record "Agreement Premise Relation";
        TotalPremiseArea: Decimal;
        PremiseLines: Record Premise;
    begin
        TotalPremiseArea := 0;
        IF "No Leaseable/ Sale Area" THEN BEGIN
          VALIDATE("Leasable/Salable Area",0);
           "Unit of Measure" := '';
        END ELSE BEGIN
          IF PremiseArea.GET("Premise No.") THEN BEGIN
            "Unit of Measure" := PremiseArea."Unit of Measure";
            ElementRec.GET("Element Type");
            IF ElementRec."Premise Specific L/S Area" THEN
              VALIDATE("Leasable/Salable Area",PremiseArea."Leasable/Salable Area")
            ELSE BEGIN
              AgrmtPremiseRelation.SETRANGE("Agreement Type","Agreement Type");
              AgrmtPremiseRelation.SETRANGE("Agreement No.","Agreement No.");
              IF AgrmtPremiseRelation.FINDSET THEN BEGIN
                REPEAT
                  PremiseLines.GET(AgrmtPremiseRelation."Premise No.");
                  TotalPremiseArea += PremiseLines."Leasable/Salable Area";
                UNTIL AgrmtPremiseRelation.NEXT = 0;
              END;
              VALIDATE("Leasable/Salable Area",TotalPremiseArea);
            END;
          END;
        END;
    end;
 
    procedure UpdateOriginalAmt()
    var
        ElementTypeRec: Record "Agreement Element";
    begin
        IF "Element Type" <> '' THEN
          ElementTypeRec.GET("Element Type");

        IF ElementTypeRec."No. of Invoices Not Applicable" THEN
          VALIDATE("Original Amount","Invoice Unit Price")
        ELSE
          VALIDATE("Original Amount","No. of Invoices" * "Invoice Unit Price");
    end;
 
    procedure CreateLineDimension()
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array [10] of Integer;
        No: array [10] of Code[20];
    begin
        //DP6.01.02 START
        TableID[1] := 33016812;
        No[1] := "Element Type";

        DimMgt.GetPreviousDocDefaultDim(
          DATABASE::"Agreement Header","Agreement Type","Agreement No.",0,
          DATABASE::Customer,"Global Dimension 1 Code","Global Dimension 2 Code");

        IF "Element Type" <> '' THEN BEGIN
          DimMgt.GetDefaultDim(
            TableID,No,SourceCodeSetup.Sales,
            "Global Dimension 1 Code","Global Dimension 2 Code");

          IF "Line No." <> 0 THEN
            DimMgt.UpdateDocDefaultDim(
              DATABASE::"Agreement Line","Agreement Type","Agreement No.","Line No.",
              "Global Dimension 1 Code","Global Dimension 2 Code");
        END;
        //DP6.01.02 STOP
    end;
}

