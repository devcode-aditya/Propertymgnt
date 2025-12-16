table 39 "Purchase Line"
{
    // LS = changes made by LS Retail
    // Code            Date      Name            Description
    // APNT-1.0        11.08.10  Tanweer         Added field
    // APNT-CO1.0      16.08.10  Tanweer         Added fields for Costing Customization
    // APNT-1.0        07.09.11  Tanweer         Added Barcode field and Code
    // APNT-VIQ1.0     13.09.11  Monica          Added Fields
    // APNT-1.0        07.10.12  Tanweer         Modified code to check Open Status for G/L Accounts
    // APNT-HHT1.0     01.11.12  Sujith          Added fields & Code for HHT Customization
    // APNT-T001586    13.10.13  Sujith          Renamed field from Box No.to Carton No. for HHT Customization
    // T002879         25.02.14  Shameema        Added key - "Document Type,Location Code"
    // 
    // DP = changes made by DVS
    // APNT-HRU1.0     10.03.14  Sangeeta        Added fields for HRU Customization.
    // APNT-SKIPDIM  07-03-2016  Shafi          Added code to skip dimension
    // APNT-T009914  23.03.16    Sujith         Added code for Bin Ledger customization.
    // APNT-WMS1.0 T015451     03.05.17    Shameema        Added changes for WMS Changes - CR
    // T034121       11.08.20    Deepak         Added field to handle the HHT Qty. to Receive Updated for Duplicate item selected in Order

    Caption = 'Purchase Line';
    DrillDownFormID = Form518;
    LookupFormID = Form518;
    PasteIsValid = false;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purchase Header".No. WHERE(Document Type=FIELD(Document Type));
        }
        field(4;"Line No.";Integer)
        {
            Caption = 'Line No.';
        }
        field(5;Type;Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,,"Fixed Asset","Charge (Item)";

            trigger OnValidate()
            begin
                GetPurchHeader;
                TestStatusOpen;

                TESTFIELD("Qty. Rcd. Not Invoiced",0);
                TESTFIELD("Quantity Received",0);
                TESTFIELD("Receipt No.",'');

                TESTFIELD("Return Qty. Shipped Not Invd.",0);
                TESTFIELD("Return Qty. Shipped",0);
                TESTFIELD("Return Shipment No.",'');

                TESTFIELD("Prepmt. Amt. Inv.",0);

                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION(Type),"Sales Order No.");
                IF "Special Order" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION(Type),"Special Order Sales No.");
                IF "Prod. Order No." <> '' THEN
                  ERROR(
                    Text044,
                    FIELDCAPTION(Type),FIELDCAPTION("Prod. Order No."),"Prod. Order No.");

                IF Type <> xRec.Type THEN BEGIN
                  IF Quantity <> 0 THEN BEGIN
                    ReservePurchLine.VerifyChange(Rec,xRec);
                    CALCFIELDS("Reserved Qty. (Base)");
                    TESTFIELD("Reserved Qty. (Base)",0);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                  END;
                  IF xRec.Type IN [Type::Item,Type::"Fixed Asset"] THEN BEGIN
                    IF Quantity <> 0 THEN
                      PurchHeader.TESTFIELD(Status,PurchHeader.Status::Open);
                    DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");
                  END;
                  IF xRec.Type = Type::"Charge (Item)" THEN
                    DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");
                END;
                TempPurchLine := Rec;
                DimMgt.DeleteDocDim(DATABASE::"Purchase Line","Document Type","Document No.","Line No.");
                INIT;
                Type := TempPurchLine.Type;
                "System-Created Entry" := TempPurchLine."System-Created Entry";
                VALIDATE("FA Posting Type");

                IF Type = Type::Item THEN
                  "Allow Item Charge Assignment" := TRUE
                ELSE
                  "Allow Item Charge Assignment" := FALSE;
            end;
        }
        field(6;"No.";Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type=CONST(" ")) "Standard Text"
                            ELSE IF (Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Type=CONST(Item)) Item
                            ELSE IF (Type=CONST(3)) Resource
                            ELSE IF (Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Type=CONST("Charge (Item)")) "Item Charge";

            trigger OnValidate()
            var
                ICPartner: Record "413";
                ItemCrossReference: Record "5717";
                PrepmtMgt: Codeunit "441";
                BOUtils: Codeunit "99001452";
                ItemRec: Record "27";
                ItemUoM: Record "5404";
                CompInfo: Record "79";
            begin
                TestStatusOpen;
                TESTFIELD("Qty. Rcd. Not Invoiced",0);
                TESTFIELD("Quantity Received",0);
                TESTFIELD("Receipt No.",'');

                TESTFIELD("Prepmt. Amt. Inv.",0);

                TESTFIELD("Return Qty. Shipped Not Invd.",0);
                TESTFIELD("Return Qty. Shipped",0);
                TESTFIELD("Return Shipment No.",'');

                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("No."),"Sales Order No.");

                IF "Special Order" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("No."),"Special Order Sales No.");

                IF "Prod. Order No." <> '' THEN
                  ERROR(
                    Text044,
                    FIELDCAPTION(Type),FIELDCAPTION("Prod. Order No."),"Prod. Order No.");

                //LS -
                IF ("Document Type" = "Document Type"::Order) AND
                   (Type = Type::Item)
                THEN
                  IF BOUtils.IsBlockPurchasing("No.",TODAY) THEN
                    ERROR(
                      Text10000700,
                      FIELDCAPTION("No."),"No.");
                //LS +

                IF "No." <> xRec."No." THEN BEGIN
                  IF (Quantity <> 0) AND ItemExists(xRec."No.") THEN BEGIN
                    ReservePurchLine.VerifyChange(Rec,xRec);
                    CALCFIELDS("Reserved Qty. (Base)");
                    TESTFIELD("Reserved Qty. (Base)",0);
                    IF Type = Type::Item THEN
                      WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                  END;
                  IF Type = Type::Item THEN
                    DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");
                  IF Type = Type::"Charge (Item)" THEN
                    DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");
                END;
                TempPurchLine := Rec;
                INIT;
                Type := TempPurchLine.Type;
                "No." := TempPurchLine."No.";
                IF "No." = '' THEN
                  EXIT;
                IF Type <> Type::" " THEN
                  Quantity := TempPurchLine.Quantity;

                "System-Created Entry" := TempPurchLine."System-Created Entry";
                GetPurchHeader;
                PurchHeader.TESTFIELD("Buy-from Vendor No.");

                "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                "Currency Code" := PurchHeader."Currency Code";
                "Expected Receipt Date" := PurchHeader."Expected Receipt Date";
                "Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
                "Location Code" := PurchHeader."Location Code";
                "Transaction Type" := PurchHeader."Transaction Type";
                "Transport Method" := PurchHeader."Transport Method";
                "Pay-to Vendor No." := PurchHeader."Pay-to Vendor No.";
                "Gen. Bus. Posting Group" := PurchHeader."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := PurchHeader."VAT Bus. Posting Group";
                "Entry Point" := PurchHeader."Entry Point";
                Area := PurchHeader.Area;
                "Transaction Specification" := PurchHeader."Transaction Specification";
                "Tax Area Code" := PurchHeader."Tax Area Code";
                "Tax Liable" := PurchHeader."Tax Liable";
                IF NOT "System-Created Entry" AND ("Document Type" = "Document Type"::Order) AND (Type <> Type::" ") THEN
                  "Prepayment %" := PurchHeader."Prepayment %";
                "Prepayment Tax Area Code" := PurchHeader."Tax Area Code";
                "Prepayment Tax Liable" := PurchHeader."Tax Liable";
                "Responsibility Center" := PurchHeader."Responsibility Center";

                "Requested Receipt Date" := PurchHeader."Requested Receipt Date";
                "Promised Receipt Date" := PurchHeader."Promised Receipt Date";
                "Inbound Whse. Handling Time" := PurchHeader."Inbound Whse. Handling Time";
                "Order Date" := PurchHeader."Order Date";
                UpdateLeadTimeFields;
                UpdateDates;

                CASE Type OF
                  Type::" ":
                    BEGIN
                      StdTxt.GET("No.");
                      Description := StdTxt.Description;
                      "Allow Item Charge Assignment" := FALSE;
                    END;
                  Type::"G/L Account":
                    BEGIN
                      GLAcc.GET("No.");
                      GLAcc.CheckGLAcc;
                      IF NOT "System-Created Entry" THEN
                        GLAcc.TESTFIELD("Direct Posting",TRUE);
                      Description := GLAcc.Name;
                      "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                      "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                      "Tax Group Code" := GLAcc."Tax Group Code";
                      "Allow Invoice Disc." := FALSE;
                      "Allow Item Charge Assignment" := FALSE;
                    END;
                  Type::Item:
                    BEGIN
                      GetItem;
                      GetGLSetup;
                      Item.TESTFIELD(Blocked,FALSE);
                      Item.TESTFIELD("Inventory Posting Group");
                      Item.TESTFIELD("Gen. Prod. Posting Group");

                      "Posting Group" := Item."Inventory Posting Group";
                      Description := Item.Description;
                      "Description 2" := Item."Description 2";
                      "Unit Price (LCY)" := Item."Unit Price";
                      "Units per Parcel" := Item."Units per Parcel";
                      "Indirect Cost %" := Item."Indirect Cost %";
                      "Overhead Rate" := Item."Overhead Rate";
                      "Allow Invoice Disc." := Item."Allow Invoice Disc.";
                      "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                      "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                      "Tax Group Code" := Item."Tax Group Code";
                      Nonstock := Item."Created From Nonstock Item";
                      Division := Item."Division Code";  //LS
                      "Item Category Code" := Item."Item Category Code";
                      "Product Group Code" := Item."Product Group Code";
                      "Allow Item Charge Assignment" := TRUE;
                      PrepmtMgt.SetPurchPrepaymentPct(Rec,PurchHeader."Posting Date");

                      IF Item."Price Includes VAT" THEN BEGIN
                        IF NOT VATPostingSetup.GET(
                             Item."VAT Bus. Posting Gr. (Price)",Item."VAT Prod. Posting Group")
                        THEN
                          VATPostingSetup.INIT;
                        CASE VATPostingSetup."VAT Calculation Type" OF
                          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            VATPostingSetup."VAT %" := 0;
                          VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            ERROR(
                              Text002,
                              VATPostingSetup.FIELDCAPTION("VAT Calculation Type"),
                              VATPostingSetup."VAT Calculation Type");
                        END;
                        "Unit Price (LCY)" :=
                          ROUND("Unit Price (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                            GLSetup."Unit-Amount Rounding Precision");
                      END;

                      IF PurchHeader."Language Code" <> '' THEN
                        GetItemTranslation;

                      //APNT-1.0
                      //"Unit of Measure Code" := Item."Purch. Unit of Measure";
                      IF Barcode = '' THEN
                        Barcode := Item.DefaultBarcode;
                      IF Barcode <> '' THEN BEGIN
                        Barcodes.GET(Barcode);
                        "Unit of Measure Code" := Barcodes."Unit of Measure Code";
                      END ELSE
                        "Unit of Measure Code" := Item."Purch. Unit of Measure";
                      //APNT-1.0
                    END;
                  Type::"3":
                    ERROR(Text003);
                  Type::"Fixed Asset":
                    BEGIN
                      FA.GET("No.");
                      FA.TESTFIELD(Inactive,FALSE);
                      FA.TESTFIELD(Blocked,FALSE);
                      GetFAPostingGroup;
                      Description := FA.Description;
                      "Description 2" := FA."Description 2";
                      "Allow Invoice Disc." := FALSE;
                      "Allow Item Charge Assignment" := FALSE;
                    END;
                  Type::"Charge (Item)":
                    BEGIN
                      ItemCharge.GET("No.");
                      Description := ItemCharge.Description;
                      "Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
                      "VAT Prod. Posting Group" := ItemCharge."VAT Prod. Posting Group";
                      "Tax Group Code" := ItemCharge."Tax Group Code";
                      "Allow Invoice Disc." := FALSE;
                      "Allow Item Charge Assignment" := FALSE;
                      "Indirect Cost %" := 0;
                      "Overhead Rate" := 0;
                    END;
                END;

                VALIDATE("Prepayment %");

                IF Type <> Type::" " THEN BEGIN
                  IF Type <> Type::"Fixed Asset" THEN
                    VALIDATE("VAT Prod. Posting Group");
                  Quantity := xRec.Quantity;
                  VALIDATE("Unit of Measure Code");
                  IF Quantity <> 0 THEN BEGIN
                    InitOutstanding;
                    IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
                      InitQtyToShip
                    ELSE
                      InitQtyToReceive;
                  END;
                  UpdateWithWarehouseReceive;
                  UpdateDirectUnitCost(FIELDNO("No."));
                  "Job No." := xRec."Job No.";
                  "Job Line Type" := xRec."Job Line Type";
                  IF xRec."Job Task No." <> '' THEN
                    VALIDATE("Job Task No.",xRec."Job Task No.");
                END;

                //APNT-SKIPDIM
                CLEAR(CompInfo);
                CompInfo.GET();
                IF NOT CompInfo."Skip Dimension for Purchase"  THEN
                  CreateDim(
                    DimMgt.TypeToTableID3(Type),"No.",
                    DATABASE::Job,"Job No.",
                    DATABASE::"Responsibility Center","Responsibility Center",
                    DATABASE::"Work Center","Work Center No.");
                //APNT-SKIPDIM

                DistIntegration.EnterPurchaseItemCrossRef(Rec);

                GetDefaultBin;

                PurchHeader.GET("Document Type","Document No.");
                IF PurchHeader."Send IC Document" THEN
                  CASE Type OF
                    Type::" ",Type::"Charge (Item)":
                      BEGIN
                        "IC Partner Ref. Type" := Type;
                        "IC Partner Reference" := "No.";
                      END;
                    Type::"G/L Account":
                      BEGIN
                        "IC Partner Ref. Type" := Type;
                        "IC Partner Reference" := GLAcc."Default IC Partner G/L Acc. No";
                      END;
                    Type::Item:
                      BEGIN
                        ICPartner.GET(PurchHeader."Buy-from IC Partner Code");
                        CASE ICPartner."Outbound Purch. Item No. Type" OF
                          ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                            VALIDATE("IC Partner Ref. Type","IC Partner Ref. Type"::"Common Item No.");
                          ICPartner."Outbound Purch. Item No. Type"::"Internal No.":
                            BEGIN
                              "IC Partner Ref. Type" := "IC Partner Ref. Type"::Item;
                              "IC Partner Reference" := "No.";
                            END;
                          ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                            BEGIN
                              VALIDATE("IC Partner Ref. Type","IC Partner Ref. Type"::"Cross Reference");
                              ItemCrossReference.SETRANGE("Cross-Reference Type",
                                ItemCrossReference."Cross-Reference Type"::Vendor);
                              ItemCrossReference.SETRANGE("Cross-Reference Type No.",
                                "Buy-from Vendor No.");
                              ItemCrossReference.SETRANGE("Item No.","No.");
                              IF ItemCrossReference.FINDFIRST THEN
                                "IC Partner Reference" := ItemCrossReference."Cross-Reference No.";
                            END;
                          ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                            BEGIN
                              "IC Partner Ref. Type" := "IC Partner Ref. Type"::"Vendor Item No.";
                              "IC Partner Reference" := "Vendor Item No.";
                            END;
                        END;
                      END;
                    Type::"Fixed Asset":
                      BEGIN
                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                        "IC Partner Reference" := '';
                      END;
                  END;

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(TRUE);
                  UpdatePricesFromJobJnlLine;
                END;

                //APNT-1.0
                IF ItemRec.GET("No.") THEN
                  Packing := ItemRec.Packing;
                //APNT-1.0

                //APNT-CO1.0
                IF Type = Type::Item THEN BEGIN
                  IF ItemUoM.GET("No.","Unit of Measure Code") THEN BEGIN
                    "Total Cubage" := Quantity * ItemUoM.Cubage;
                  END;
                END;
                //APNT-CO1.0
            end;
        }
        field(7;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE (Use As In-Transit=CONST(No));

            trigger OnLookup()
            var
                lPurchaseHeader: Record "38";
                lBOUtils: Codeunit "99001452";
                tmpCode: Code[10];
            begin
                //LS -
                IF lPurchaseHeader.GET("Document Type","Document No.") THEN BEGIN
                  tmpCode := lBOUtils.LookupLocation(lPurchaseHeader."Store No.", "Location Code");
                  IF (xRec."Location Code" <> tmpCode) AND (tmpCode <> '') THEN
                    VALIDATE("Location Code", tmpCode);
                END;
                //LS +
            end;

            trigger OnValidate()
            var
                PurchaseLineLocal: Record "39";
                lBOUtils: Codeunit "99001452";
            begin
                TestStatusOpen;

                //LS -
                GetPurchHeader;
                lBOUtils.StoreLocationOk(PurchHeader."Store No.", "Location Code");
                //LS +

                IF xRec."Location Code" <> "Location Code" THEN BEGIN
                  TESTFIELD("Qty. Rcd. Not Invoiced",0);
                  TESTFIELD("Receipt No.",'');

                  TESTFIELD("Return Qty. Shipped Not Invd.",0);
                  TESTFIELD("Return Shipment No.",'');
                END;

                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Location Code"),"Sales Order No.");
                IF "Special Order" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Location Code"),"Special Order Sales No.");

                IF "Location Code" <> xRec."Location Code" THEN
                  InitItemAppl;

                IF (xRec."Location Code" <> "Location Code") AND (Quantity <> 0) THEN BEGIN
                  ReservePurchLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                  UpdateWithWarehouseReceive;
                END;
                "Bin Code" := '';

                IF Type = Type::Item THEN
                  UpdateDirectUnitCost(FIELDNO("Location Code"));

                IF "Location Code" = '' THEN BEGIN
                  IF InvtSetup.GET THEN
                    "Inbound Whse. Handling Time" := InvtSetup."Inbound Whse. Handling Time";
                END ELSE
                  IF Location.GET("Location Code") THEN
                    "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";

                UpdateLeadTimeFields;
                UpdateDates;

                GetDefaultBin;

                //LS -
                IF (Type = Type::" ") AND ("No." <> '') AND (Item.GET("No.")) AND
                   ("Location Code" <> xRec."Location Code")
                THEN BEGIN
                  PurchaseLineLocal.RESET;
                  PurchaseLineLocal.SETRANGE("Document Type","Document Type");
                  PurchaseLineLocal.SETRANGE("Document No.","Document No.");
                  PurchaseLineLocal.SETRANGE(Type,PurchaseLineLocal.Type::Item);
                  PurchaseLineLocal.SETRANGE("No.","No.");
                  PurchaseLineLocal.SETRANGE("Attached to Line No.","Line No.");
                  IF PurchaseLineLocal.FIND('-') THEN REPEAT
                    PurchaseLineLocal.VALIDATE("Location Code","Location Code");
                    PurchaseLineLocal.MODIFY;
                  UNTIL PurchaseLineLocal.NEXT = 0;
                END;
                //LS +
            end;
        }
        field(8;"Posting Group";Code[10])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type=CONST(Item)) "Inventory Posting Group"
                            ELSE IF (Type=CONST(Fixed Asset)) "FA Posting Group";
        }
        field(10;"Expected Receipt Date";Date)
        {
            Caption = 'Expected Receipt Date';

            trigger OnValidate()
            begin
                IF NOT TrackingBlocked THEN
                  CheckDateConflict.PurchLineCheck(Rec,CurrFieldNo <> 0);

                IF "Expected Receipt Date" <> 0D THEN
                  VALIDATE(
                    "Planned Receipt Date",
                    CalendarMgmt.CalcDateBOC2(InternalLeadTimeDays("Expected Receipt Date"),"Expected Receipt Date",
                      CalChange."Source Type"::Location,"Location Code",'',
                      CalChange."Source Type"::Vendor,"Buy-from Vendor No.",'',TRUE))
                ELSE
                  VALIDATE("Planned Receipt Date","Expected Receipt Date");
            end;
        }
        field(11;Description;Text[50])
        {
            Caption = 'Description';
        }
        field(12;"Description 2";Text[50])
        {
            Caption = 'Description 2';
        }
        field(13;"Unit of Measure";Text[10])
        {
            Caption = 'Unit of Measure';
        }
        field(15;Quantity;Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            var
                ItemUoM: Record "5404";
            begin
                TestStatusOpen;

                IF "Drop Shipment" AND ("Document Type" <> "Document Type"::Invoice) THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION(Quantity),"Sales Order No.");
                "Quantity (Base)" := CalcBaseQty(Quantity);
                IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
                  IF (Quantity * "Return Qty. Shipped" < 0) OR
                     ((ABS(Quantity) < ABS("Return Qty. Shipped")) AND ("Return Shipment No." = '')) THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text004,FIELDCAPTION("Return Qty. Shipped")));
                  IF ("Quantity (Base)" * "Return Qty. Shipped (Base)" < 0) OR
                     ((ABS("Quantity (Base)") < ABS("Return Qty. Shipped (Base)")) AND ("Return Shipment No." = ''))
                  THEN
                    FIELDERROR("Quantity (Base)",STRSUBSTNO(Text004,FIELDCAPTION("Return Qty. Shipped (Base)")));
                END ELSE BEGIN
                  IF (Quantity * "Quantity Received" < 0) OR
                     ((ABS(Quantity) < ABS("Quantity Received")) AND ("Receipt No." = ''))
                  THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text004,FIELDCAPTION("Quantity Received")));
                  IF ("Quantity (Base)" * "Qty. Received (Base)" < 0) OR
                     ((ABS("Quantity (Base)") < ABS("Qty. Received (Base)")) AND ("Receipt No." = ''))
                  THEN
                    FIELDERROR("Quantity (Base)",STRSUBSTNO(Text004,FIELDCAPTION("Qty. Received (Base)")));
                END;

                IF (Type = Type::"Charge (Item)") AND (CurrFieldNo <> 0) THEN BEGIN
                  IF ((Quantity = 0) AND ("Qty. to Assign" <> 0)) THEN
                    FIELDERROR("Qty. to Assign",STRSUBSTNO(Text011,FIELDCAPTION(Quantity),Quantity));
                  IF (Quantity * "Qty. Assigned" < 0) OR (ABS(Quantity) < ABS("Qty. Assigned")) THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text004,FIELDCAPTION("Qty. Assigned")));
                END;

                IF (xRec.Quantity <> Quantity) OR (xRec."Quantity (Base)" <> "Quantity (Base)") OR
                   (Rec."No." = xRec."No.")
                THEN BEGIN
                  InitOutstanding;
                  IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
                    InitQtyToShip
                  ELSE
                    InitQtyToReceive;
                END;
                IF (Quantity * xRec.Quantity < 0) OR (Quantity = 0) THEN
                  InitItemAppl;

                IF Type = Type::Item THEN
                  UpdateDirectUnitCost(FIELDNO(Quantity))
                ELSE
                  VALIDATE("Line Discount %");

                IF (xRec.Quantity <> Quantity) OR (xRec."Quantity (Base)" <> "Quantity (Base)") THEN BEGIN
                  ReservePurchLine.VerifyQuantity(Rec,xRec);
                  UpdateWithWarehouseReceive;
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                  CheckApplToItemLedgEntry;
                END;

                IF (xRec.Quantity <> Quantity) AND (Quantity = 0) AND
                   ((Amount <> 0) OR ("Amount Including VAT" <> 0) OR ("VAT Base Amount" <> 0))
                THEN BEGIN
                  Amount := 0;
                  "Amount Including VAT" := 0;
                  "VAT Base Amount" := 0;
                END;
                SetDefaultQuantity;

                IF ("Document Type" = "Document Type"::Invoice) AND ("Prepayment %" <> 0) THEN
                  UpdatePrePaymentAmounts;

                //APNT-CO1.0
                IF Type = Type::Item THEN BEGIN
                  IF ItemUoM.GET("No.","Unit of Measure Code") THEN BEGIN
                    "Total Cubage" := Quantity * ItemUoM.Cubage;
                  END;
                END;
                //APNT-CO1.0
            end;
        }
        field(16;"Outstanding Quantity";Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(17;"Qty. to Invoice";Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF "Qty. to Invoice" = MaxQtyToInvoice THEN
                  InitQtyToInvoice
                ELSE
                  "Qty. to Invoice (Base)" := CalcBaseQty("Qty. to Invoice");
                IF ("Qty. to Invoice" * Quantity < 0) OR (ABS("Qty. to Invoice") > ABS(MaxQtyToInvoice)) THEN
                  ERROR(
                    Text006,
                    MaxQtyToInvoice);
                IF ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) OR (ABS("Qty. to Invoice (Base)") > ABS(MaxQtyToInvoiceBase)) THEN
                  ERROR(
                    Text007,
                    MaxQtyToInvoiceBase);
                "VAT Difference" := 0;
                CalcInvDiscToInvoice;
                CalcPrepaymentToDeduct;
            end;
        }
        field(18;"Qty. to Receive";Decimal)
        {
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF (CurrFieldNo <> 0) AND
                   (Type = Type::Item) AND
                   ("Qty. to Receive" <> 0) AND
                   (NOT "Drop Shipment")
                THEN
                  CheckWarehouse;

                IF "Qty. to Receive" = Quantity - "Quantity Received" THEN
                  InitQtyToReceive
                ELSE BEGIN
                  "Qty. to Receive (Base)" := CalcBaseQty("Qty. to Receive");
                  InitQtyToInvoice;
                END;
                IF ("Qty. to Receive" * Quantity < 0) OR
                   (ABS("Qty. to Receive") > ABS("Outstanding Quantity")) OR
                   (Quantity * "Outstanding Quantity" < 0)
                THEN
                  ERROR(
                    Text008,
                    "Outstanding Quantity");
                IF ("Qty. to Receive (Base)" * "Quantity (Base)" < 0) OR
                   (ABS("Qty. to Receive (Base)") > ABS("Outstanding Qty. (Base)")) OR
                   ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                THEN
                  ERROR(
                    Text009,
                    "Outstanding Qty. (Base)");

                IF (CurrFieldNo <> 0) AND (Type = Type::Item) AND ("Qty. to Receive" < 0) THEN
                  CheckApplToItemLedgEntry;
            end;
        }
        field(22;"Direct Unit Cost";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FIELDNO("Direct Unit Cost"));
            Caption = 'Direct Unit Cost';

            trigger OnValidate()
            begin
                VALIDATE("Line Discount %");
            end;
        }
        field(23;"Unit Cost (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TESTFIELD("No.");
                TESTFIELD(Quantity);

                IF "Prod. Order No." <> '' THEN
                  ERROR(
                    Text99000000,
                    FIELDCAPTION("Unit Cost (LCY)"));

                IF CurrFieldNo = FIELDNO("Unit Cost (LCY)") THEN
                  IF Type = Type::Item THEN BEGIN
                    GetItem;
                    IF Item."Costing Method" = Item."Costing Method"::Standard THEN
                      ERROR(
                        Text010,
                        FIELDCAPTION("Unit Cost (LCY)"),Item.FIELDCAPTION("Costing Method"),Item."Costing Method");
                  END;

                UnitCostCurrency := "Unit Cost (LCY)";
                GetPurchHeader;
                IF PurchHeader."Currency Code" <> '' THEN BEGIN
                  PurchHeader.TESTFIELD("Currency Factor");
                  GetGLSetup;
                  UnitCostCurrency :=
                    ROUND(
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        GetDate,"Currency Code",
                        "Unit Cost (LCY)",PurchHeader."Currency Factor"),
                      GLSetup."Unit-Amount Rounding Precision");
                END;

                IF ("Direct Unit Cost" <> 0) AND
                   ("Direct Unit Cost" <> ("Line Discount Amount" / Quantity))
                THEN
                  "Indirect Cost %" :=
                    ROUND(
                      (UnitCostCurrency - "Direct Unit Cost" + "Line Discount Amount" / Quantity) /
                      ("Direct Unit Cost" - "Line Discount Amount" / Quantity) * 100,0.00001)
                ELSE
                  "Indirect Cost %" := 0;

                UpdateSalesCost;

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Unit Cost (LCY)","Unit Cost (LCY)");
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(25;"VAT %";Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(27;"Line Discount %";Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetPurchHeader;
                "Line Discount Amount" :=
                  ROUND(
                    ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") *
                    "Line Discount %" / 100,
                    Currency."Amount Rounding Precision");
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts;
                UpdateUnitCost;
            end;
        }
        field(28;"Line Discount Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TESTFIELD(Quantity);
                IF ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") <> 0 THEN
                  "Line Discount %" :=
                    ROUND(
                      "Line Discount Amount" /
                      ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") * 100,
                      0.00001)
                ELSE
                  "Line Discount %" := 0;
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts;
                UpdateUnitCost;
            end;
        }
        field(29;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader;
                Amount := ROUND(Amount,Currency."Amount Rounding Precision");
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "VAT Base Amount" :=
                        ROUND(Amount * (1 - PurchHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                      "Amount Including VAT" :=
                        ROUND(Amount + "VAT Base Amount" * "VAT %" / 100,Currency."Amount Rounding Precision");
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    IF Amount <> 0 THEN
                      FIELDERROR(Amount,
                        STRSUBSTNO(
                          Text011,FIELDCAPTION("VAT Calculation Type"),
                          "VAT Calculation Type"));
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      PurchHeader.TESTFIELD("VAT Base Discount %",0);
                      "VAT Base Amount" := Amount;
                      IF "Use Tax" THEN
                        "Amount Including VAT" := "VAT Base Amount"
                      ELSE BEGIN
                        "Amount Including VAT" :=
                          Amount +
                          ROUND(
                            SalesTaxCalculate.CalculateTax(
                              "Tax Area Code","Tax Group Code","Tax Liable",PurchHeader."Posting Date",
                              "VAT Base Amount","Quantity (Base)",PurchHeader."Currency Factor"),
                            Currency."Amount Rounding Precision");
                        IF "VAT Base Amount" <> 0 THEN
                          "VAT %" :=
                            ROUND(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount",0.00001)
                        ELSE
                          "VAT %" := 0;
                      END;
                    END;
                END;

                InitOutstandingAmount;
                UpdateUnitCost;
            end;
        }
        field(30;"Amount Including VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader;
                "Amount Including VAT" := ROUND("Amount Including VAT",Currency."Amount Rounding Precision");
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      Amount :=
                        ROUND(
                          "Amount Including VAT" /
                          (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                          Currency."Amount Rounding Precision");
                      "VAT Base Amount" :=
                        ROUND(Amount * (1 - PurchHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    BEGIN
                      Amount := 0;
                      "VAT Base Amount" := 0;
                    END;
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      PurchHeader.TESTFIELD("VAT Base Discount %",0);
                      IF "Use Tax" THEN BEGIN
                        Amount := "Amount Including VAT";
                        "VAT Base Amount" := Amount;
                      END ELSE BEGIN
                        Amount :=
                          ROUND(
                            SalesTaxCalculate.ReverseCalculateTax(
                              "Tax Area Code","Tax Group Code","Tax Liable",PurchHeader."Posting Date",
                              "Amount Including VAT","Quantity (Base)",PurchHeader."Currency Factor"),
                            Currency."Amount Rounding Precision");
                        "VAT Base Amount" := Amount;
                        IF "VAT Base Amount" <> 0 THEN
                          "VAT %" :=
                            ROUND(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount",0.00001)
                        ELSE
                          "VAT %" := 0;
                      END;
                    END;
                END;

                InitOutstandingAmount;
                UpdateUnitCost;
            end;
        }
        field(31;"Unit Price (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
        }
        field(32;"Allow Invoice Disc.";Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF ("Allow Invoice Disc." <> xRec."Allow Invoice Disc.") AND
                   (NOT "Allow Invoice Disc.")
                THEN BEGIN
                  "Inv. Discount Amount" := 0;
                  "Inv. Disc. Amount to Invoice" := 0;
                  UpdateAmounts;
                  UpdateUnitCost;
                END;
            end;
        }
        field(34;"Gross Weight";Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0:5;
        }
        field(35;"Net Weight";Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0:5;
        }
        field(36;"Units per Parcel";Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0:5;
        }
        field(37;"Unit Volume";Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0:5;
        }
        field(38;"Appl.-to Item Entry";Integer)
        {
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry;
            end;

            trigger OnValidate()
            begin
                IF "Appl.-to Item Entry" <> 0 THEN
                  "Location Code" := CheckApplToItemLedgEntry;
            end;
        }
        field(40;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(41;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(45;"Job No.";Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                Job: Record "167";
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                VALIDATE("Job Task No.",'');
                IF "Job No." = '' THEN BEGIN
                  CreateDim(
                    DATABASE::Job,"Job No.",
                    DimMgt.TypeToTableID3(Type),"No.",
                    DATABASE::"Responsibility Center","Responsibility Center",
                    DATABASE::"Work Center","Work Center No.");
                  EXIT;
                END;

                IF NOT (Type IN [Type::Item,Type::"G/L Account"]) THEN
                  FIELDERROR("Job No.",STRSUBSTNO(Text012,FIELDCAPTION(Type),Type));
                Job.GET("Job No.");
                Job.TestBlocked;
                "Job Currency Code" := Job."Currency Code";

                CreateDim(
                  DATABASE::Job,"Job No.",
                  DimMgt.TypeToTableID3(Type),"No.",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Work Center","Work Center No.");
            end;
        }
        field(54;"Indirect Cost %";Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0:5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TESTFIELD("No.");
                TestStatusOpen;

                IF Type = Type::"Charge (Item)" THEN
                  TESTFIELD("Indirect Cost %",0);

                IF (Type = Type::Item) AND ("Prod. Order No." = '') THEN BEGIN
                  GetItem;
                  IF Item."Costing Method" = Item."Costing Method"::Standard THEN
                    ERROR(
                      Text010,
                      FIELDCAPTION("Indirect Cost %"),Item.FIELDCAPTION("Costing Method"),Item."Costing Method");
                END;

                UpdateUnitCost;
            end;
        }
        field(57;"Outstanding Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record "4";
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                IF PurchHeader."Currency Code" <> '' THEN
                  "Outstanding Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Outstanding Amount",PurchHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Outstanding Amount (LCY)" :=
                    ROUND("Outstanding Amount",Currency2."Amount Rounding Precision");
            end;
        }
        field(58;"Qty. Rcd. Not Invoiced";Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(59;"Amt. Rcd. Not Invoiced";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record "4";
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                IF PurchHeader."Currency Code" <> '' THEN
                  "Amt. Rcd. Not Invoiced (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Amt. Rcd. Not Invoiced",PurchHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Amt. Rcd. Not Invoiced (LCY)" :=
                    ROUND("Amt. Rcd. Not Invoiced",Currency2."Amount Rounding Precision");
            end;
        }
        field(60;"Quantity Received";Decimal)
        {
            Caption = 'Quantity Received';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(61;"Quantity Invoiced";Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(63;"Receipt No.";Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        field(64;"Receipt Line No.";Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        field(67;"Profit %";Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(68;"Pay-to Vendor No.";Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(69;"Inv. Discount Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateAmounts;
                UpdateUnitCost;
                CalcInvDiscToInvoice;
            end;
        }
        field(70;"Vendor Item No.";Text[20])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                IF PurchHeader."Send IC Document" AND
                   ("IC Partner Ref. Type" = "IC Partner Ref. Type"::"Vendor Item No.")
                THEN
                  "IC Partner Reference" := "Vendor Item No.";
            end;
        }
        field(71;"Sales Order No.";Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            TableRelation = IF (Drop Shipment=CONST(Yes)) "Sales Header".No. WHERE (Document Type=CONST(Order));

            trigger OnValidate()
            begin
                IF (xRec."Sales Order No." <> "Sales Order No.") AND (Quantity <> 0) THEN BEGIN
                  ReservePurchLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                END;
            end;
        }
        field(72;"Sales Order Line No.";Integer)
        {
            Caption = 'Sales Order Line No.';
            Editable = false;
            TableRelation = IF (Drop Shipment=CONST(Yes)) "Sales Line"."Line No." WHERE (Document Type=CONST(Order),
                                                                                         Document No.=FIELD(Sales Order No.));

            trigger OnValidate()
            begin
                IF (xRec."Sales Order Line No." <> "Sales Order Line No.") AND (Quantity <> 0) THEN BEGIN
                  ReservePurchLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                END;
            end;
        }
        field(73;"Drop Shipment";Boolean)
        {
            Caption = 'Drop Shipment';
            Editable = false;

            trigger OnValidate()
            begin
                IF (xRec."Drop Shipment" <> "Drop Shipment") AND (Quantity <> 0) THEN BEGIN
                  ReservePurchLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                END;
                IF "Drop Shipment" THEN BEGIN
                  "Bin Code" := '';
                  EVALUATE("Inbound Whse. Handling Time",'<0D>');
                  VALIDATE("Inbound Whse. Handling Time");
                  InitOutstanding;
                  InitQtyToReceive;
                END;
            end;
        }
        field(74;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                IF xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" THEN
                  IF GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp,"Gen. Bus. Posting Group") THEN
                    VALIDATE("VAT Bus. Posting Group",GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(75;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" THEN
                  IF GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp,"Gen. Prod. Posting Group") THEN
                    VALIDATE("VAT Prod. Posting Group",GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(77;"VAT Calculation Type";Option)
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(78;"Transaction Type";Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79;"Transport Method";Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80;"Attached to Line No.";Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Purchase Line"."Line No." WHERE (Document Type=FIELD(Document Type),
                                                              Document No.=FIELD(Document No.));
        }
        field(81;"Entry Point";Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82;"Area";Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83;"Transaction Specification";Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(86;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(87;"Tax Group Code";Code[10])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateAmounts;
            end;
        }
        field(88;"Use Tax";Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(89;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                VALIDATE("VAT Prod. Posting Group");
            end;
        }
        field(90;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                VATPostingSetup.GET("VAT Bus. Posting Group","VAT Prod. Posting Group");
                "VAT Difference" := 0;
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Reverse Charge VAT",
                  "VAT Calculation Type"::"Sales Tax":
                    "VAT %" := 0;
                  "VAT Calculation Type"::"Full VAT":
                    BEGIN
                      TESTFIELD(Type,Type::"G/L Account");
                      VATPostingSetup.TESTFIELD("Purchase VAT Account");
                      TESTFIELD("No.",VATPostingSetup."Purchase VAT Account");
                    END;
                END;
                IF PurchHeader."Prices Including VAT" AND (Type = Type::Item) THEN
                  "Direct Unit Cost" :=
                    ROUND(
                      "Direct Unit Cost" * (100 + "VAT %") / (100 + xRec."VAT %"),
                      Currency."Unit-Amount Rounding Precision");
                UpdateAmounts;
            end;
        }
        field(91;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92;"Outstanding Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            Editable = false;
        }
        field(93;"Amt. Rcd. Not Invoiced (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced (LCY)';
            Editable = false;
        }
        field(95;"Reserved Quantity";Decimal)
        {
            CalcFormula = Sum("Reservation Entry".Quantity WHERE (Source ID=FIELD(Document No.),
                                                                  Source Ref. No.=FIELD(Line No.),
                                                                  Source Type=CONST(39),
                                                                  Source Subtype=FIELD(Document Type),
                                                                  Reservation Status=CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(97;"Blanket Order No.";Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Purchase Header".No. WHERE (Document Type=CONST(Blanket Order));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                TESTFIELD("Quantity Received",0);
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Quantity Received",0);
                IF "Blanket Order No." = '' THEN
                  "Blanket Order Line No." := 0
                ELSE
                  VALIDATE("Blanket Order Line No.");
            end;
        }
        field(98;"Blanket Order Line No.";Integer)
        {
            Caption = 'Blanket Order Line No.';
            TableRelation = "Purchase Line"."Line No." WHERE (Document Type=CONST(Blanket Order),
                                                              Document No.=FIELD(Blanket Order No.));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Quantity Received",0);
                IF "Blanket Order Line No." <> 0 THEN BEGIN
                  PurchLine2.GET("Document Type"::"Blanket Order","Blanket Order No.","Blanket Order Line No.");
                  PurchLine2.TESTFIELD(Type,Type);
                  PurchLine2.TESTFIELD("No.","No.");
                  PurchLine2.TESTFIELD("Pay-to Vendor No.","Pay-to Vendor No.");
                  PurchLine2.TESTFIELD("Buy-from Vendor No.","Buy-from Vendor No.");
                END;
            end;
        }
        field(99;"VAT Base Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100;"Unit Cost";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101;"System-Created Entry";Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103;"Line Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Line Amount"));
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                TESTFIELD(Type);
                TESTFIELD(Quantity);
                TESTFIELD("Direct Unit Cost");

                GetPurchHeader;
                "Line Amount" := ROUND("Line Amount",Currency."Amount Rounding Precision");
                VALIDATE(
                  "Line Discount Amount",ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") - "Line Amount");
            end;
        }
        field(104;"VAT Difference";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(105;"Inv. Disc. Amount to Invoice";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            Editable = false;
        }
        field(106;"VAT Identifier";Code[10])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107;"IC Partner Ref. Type";Option)
        {
            Caption = 'IC Partner Ref. Type';
            OptionCaption = ' ,G/L Account,Item,,,Charge (Item),Cross Reference,Common Item No.,Vendor Item No.';
            OptionMembers = " ","G/L Account",Item,,,"Charge (Item)","Cross Reference","Common Item No.","Vendor Item No.";

            trigger OnValidate()
            begin
                IF "IC Partner Code" <> '' THEN
                  "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                IF "IC Partner Ref. Type" <> xRec."IC Partner Ref. Type" THEN
                  "IC Partner Reference" := '';
                IF "IC Partner Ref. Type" = "IC Partner Ref. Type"::"Common Item No." THEN
                  BEGIN
                  IF Item."No." <> "No." THEN
                    Item.GET("No.");
                  "IC Partner Reference" := Item."Common Item No.";
                END;
            end;
        }
        field(108;"IC Partner Reference";Code[20])
        {
            Caption = 'IC Partner Reference';

            trigger OnLookup()
            var
                ICGLAccount: Record "410";
                ItemCrossReference: Record "5717";
                ItemVendorCatalog: Record "99";
            begin
                IF "No." <> '' THEN
                  CASE "IC Partner Ref. Type" OF
                    "IC Partner Ref. Type"::"G/L Account":
                      BEGIN
                        IF ICGLAccount.GET("IC Partner Reference") THEN;
                        IF FORM.RUNMODAL(FORM::"IC G/L Account List",ICGLAccount) = ACTION::LookupOK THEN
                          VALIDATE("IC Partner Reference",ICGLAccount."No.");
                      END;
                    "IC Partner Ref. Type"::Item:
                      BEGIN
                        IF Item.GET("IC Partner Reference") THEN;
                        IF FORM.RUNMODAL(FORM::"Item List",Item) = ACTION::LookupOK THEN
                          VALIDATE("IC Partner Reference",Item."No.");
                      END;
                    "IC Partner Ref. Type"::"Cross Reference":
                      BEGIN
                        GetPurchHeader;
                        ItemCrossReference.RESET;
                        ItemCrossReference.SETCURRENTKEY("Cross-Reference Type","Cross-Reference Type No.");
                        ItemCrossReference.SETFILTER(
                          "Cross-Reference Type",'%1|%2',
                          ItemCrossReference."Cross-Reference Type"::Vendor,
                          ItemCrossReference."Cross-Reference Type"::" ");
                        ItemCrossReference.SETFILTER("Cross-Reference Type No.",'%1|%2',PurchHeader."Buy-from Vendor No.",'');
                        IF FORM.RUNMODAL(FORM::"Cross Reference List",ItemCrossReference) = ACTION::LookupOK THEN
                          VALIDATE("IC Partner Reference",ItemCrossReference."Cross-Reference No.");
                      END;
                    "IC Partner Ref. Type"::"Vendor Item No.":
                      BEGIN
                        GetPurchHeader;
                        ItemVendorCatalog.SETCURRENTKEY("Vendor No.");
                        ItemVendorCatalog.SETRANGE("Vendor No.",PurchHeader."Buy-from Vendor No.");
                        IF FORM.RUNMODAL(FORM::"Vendor Item Catalog",ItemVendorCatalog) = ACTION::LookupOK THEN
                          VALIDATE("IC Partner Reference",ItemVendorCatalog."Vendor Item No.");
                      END;
                  END;
            end;
        }
        field(109;"Prepayment %";Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                GenPostingSetup: Record "252";
                GLAcc: Record "15";
            begin
                IF ("Prepayment %" <> 0) AND (Type <> Type::" ") THEN BEGIN
                  TESTFIELD("Document Type","Document Type"::Order);
                  TESTFIELD("No.");
                  GenPostingSetup.GET("Gen. Bus. Posting Group","Gen. Prod. Posting Group");
                  IF GenPostingSetup."Purch. Prepayments Account" <> '' THEN BEGIN
                    GLAcc.GET(GenPostingSetup."Purch. Prepayments Account");
                    VATPostingSetup.GET("VAT Bus. Posting Group",GLAcc."VAT Prod. Posting Group");
                  END ELSE
                    CLEAR(VATPostingSetup);
                  "Prepayment VAT %" := VATPostingSetup."VAT %";
                  "Prepmt. VAT Calc. Type" := VATPostingSetup."VAT Calculation Type";
                  "Prepayment VAT Identifier" := VATPostingSetup."VAT Identifier";
                  CASE "Prepmt. VAT Calc. Type" OF
                    "VAT Calculation Type"::"Reverse Charge VAT",
                    "VAT Calculation Type"::"Sales Tax":
                      "Prepayment VAT %" := 0;
                    "VAT Calculation Type"::"Full VAT":
                      FIELDERROR("Prepmt. VAT Calc. Type",STRSUBSTNO(Text036,"Prepmt. VAT Calc. Type"));
                  END;
                  "Prepayment Tax Group Code" := GLAcc."Tax Group Code";
                END;

                TestStatusOpen;

                IF Type <> Type::" " THEN
                  UpdateAmounts;
            end;
        }
        field(110;"Prepmt. Line Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                TESTFIELD("Line Amount");
                IF "Prepmt. Line Amount" < "Prepmt. Amt. Inv." THEN
                  FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text038,"Prepmt. Amt. Inv."));
                IF "Prepmt. Line Amount" > "Line Amount" THEN
                  FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text039,"Line Amount"));
                IF Quantity <> 0 THEN
                  VALIDATE("Prepayment %",ROUND("Prepmt. Line Amount" /
                      ("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity) * 100,0.00001))
                ELSE
                  VALIDATE("Prepayment %",ROUND("Prepmt. Line Amount" * 100 / "Line Amount",0.00001));
            end;
        }
        field(111;"Prepmt. Amt. Inv.";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            Editable = false;
        }
        field(112;"Prepmt. Amt. Incl. VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            Editable = false;
        }
        field(113;"Prepayment Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            Editable = false;
        }
        field(114;"Prepmt. VAT Base Amt.";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            Editable = false;
        }
        field(115;"Prepayment VAT %";Decimal)
        {
            Caption = 'Prepayment VAT %';
            DecimalPlaces = 0:5;
            Editable = false;
            MinValue = 0;
        }
        field(116;"Prepmt. VAT Calc. Type";Option)
        {
            Caption = 'Prepmt. VAT Calc. Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(117;"Prepayment VAT Identifier";Code[10])
        {
            Caption = 'Prepayment VAT Identifier';
            Editable = false;
        }
        field(118;"Prepayment Tax Area Code";Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(119;"Prepayment Tax Liable";Boolean)
        {
            Caption = 'Prepayment Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(120;"Prepayment Tax Group Code";Code[10])
        {
            Caption = 'Prepayment Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateAmounts;
            end;
        }
        field(121;"Prepmt Amt to Deduct";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            MinValue = 0;

            trigger OnValidate()
            begin
                IF "Prepmt Amt to Deduct" > "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" THEN
                  FIELDERROR(
                    "Prepmt Amt to Deduct",
                    STRSUBSTNO(Text039,"Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                IF "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Prepmt Amt Deducted" THEN
                  FIELDERROR(
                    "Prepmt Amt to Deduct",
                    STRSUBSTNO(Text039,"Qty. to Invoice" * "Prepmt Amt Deducted"));
            end;
        }
        field(122;"Prepmt Amt Deducted";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            Editable = false;
        }
        field(123;"Prepayment Line";Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(124;"Prepmt. Amount Inv. Incl. VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            Editable = false;
        }
        field(129;"Prepmt. Amount Inv. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. (LCY)';
            Editable = false;
        }
        field(130;"IC Partner Code";Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";

            trigger OnValidate()
            begin
                IF "IC Partner Code" <> '' THEN BEGIN
                  TESTFIELD(Type,Type::"G/L Account");
                  GetPurchHeader;
                  PurchHeader.TESTFIELD("Buy-from IC Partner Code",'');
                  PurchHeader.TESTFIELD("Pay-to IC Partner Code",'');
                  VALIDATE("IC Partner Ref. Type","IC Partner Ref. Type"::"G/L Account");
                END;
            end;
        }
        field(135;"Prepayment VAT Difference";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment VAT Difference';
            Editable = false;
        }
        field(136;"Prepmt VAT Diff. to Deduct";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. to Deduct';
            Editable = false;
        }
        field(137;"Prepmt VAT Diff. Deducted";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. Deducted';
            Editable = false;
        }
        field(1001;"Job Task No.";Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE (Job No.=FIELD(Job No.));

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF "Job Task No." = '' THEN BEGIN
                  CLEAR(JobJnlLine);
                  "Job Line Type" := "Job Line Type"::" ";
                  UpdatePricesFromJobJnlLine;
                  EXIT;
                END;

                JobSetCurrencyFactor;
                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(TRUE);
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1002;"Job Line Type";Option)
        {
            Caption = 'Job Line Type';
            OptionCaption = ' ,Schedule,Contract,Both Schedule and Contract';
            OptionMembers = " ",Schedule,Contract,"Both Schedule and Contract";

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);
            end;
        }
        field(1003;"Job Unit Price";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price';

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Unit Price","Job Unit Price");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1004;"Job Total Price";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price';
            Editable = false;
        }
        field(1005;"Job Line Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount';

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Line Amount","Job Line Amount");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1006;"Job Line Discount Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Discount Amount';

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Line Discount Amount","Job Line Discount Amount");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1007;"Job Line Discount %";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Line Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Line Discount %","Job Line Discount %");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1008;"Job Unit Price (LCY)";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Unit Price (LCY)","Job Unit Price (LCY)");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1009;"Job Total Price (LCY)";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price (LCY)';
            Editable = false;
        }
        field(1010;"Job Line Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Line Amount (LCY)","Job Line Amount (LCY)");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1011;"Job Line Disc. Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Receipt No.",'');
                IF "Document Type" = "Document Type"::Order THEN
                  TESTFIELD("Quantity Received",0);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(FALSE);
                  JobJnlLine.VALIDATE("Line Discount Amount (LCY)","Job Line Disc. Amount (LCY)");
                  UpdatePricesFromJobJnlLine;
                END;
            end;
        }
        field(1012;"Job Currency Factor";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Currency Factor';
        }
        field(1013;"Job Currency Code";Code[20])
        {
            Caption = 'Job Currency Code';
        }
        field(5401;"Prod. Order No.";Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order".No. WHERE (Status=CONST(Released));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Prod. Order No."),"Sales Order No.");

                AddOnIntegrMgt.ValidateProdOrderOnPurchLine(Rec);
            end;
        }
        field(5402;"Variant Code";Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type=CONST(Item)) "Item Variant".Code WHERE (Item No.=FIELD(No.));

            trigger OnValidate()
            begin
                IF "Variant Code" <> '' THEN
                  TESTFIELD(Type,Type::Item);
                TestStatusOpen;

                IF xRec."Variant Code" <> "Variant Code" THEN BEGIN
                  TESTFIELD("Qty. Rcd. Not Invoiced",0);
                  TESTFIELD("Receipt No.",'');

                  TESTFIELD("Return Qty. Shipped Not Invd.",0);
                  TESTFIELD("Return Shipment No.",'');
                END;

                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Variant Code"),"Sales Order No.");

                IF Type = Type::Item THEN
                  UpdateDirectUnitCost(FIELDNO("Variant Code"));

                IF (xRec."Variant Code" <> "Variant Code") AND (Quantity <> 0) THEN BEGIN
                  ReservePurchLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                  InitItemAppl;
                END;

                UpdateLeadTimeFields;
                UpdateDates;
                GetDefaultBin;
                DistIntegration.EnterPurchaseItemCrossRef(Rec);

                IF JobTaskIsSet THEN BEGIN
                  CreateTempJobJnlLine(TRUE);
                  UpdatePricesFromJobJnlLine;
                END
            end;
        }
        field(5403;"Bin Code";Code[20])
        {
            Caption = 'Bin Code';

            trigger OnLookup()
            var
                WMSManagement: Codeunit "7302";
                BinCode: Code[20];
            begin
                IF (("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND (Quantity < 0)) OR
                   (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND (Quantity >= 0))
                THEN
                  BinCode := WMSManagement.BinContentLookUp("Location Code","No.","Variant Code",'',"Bin Code")
                ELSE
                  BinCode := WMSManagement.BinLookUp("Location Code","No.","Variant Code",'');

                IF BinCode <> '' THEN
                  VALIDATE("Bin Code",BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "7302";
            begin
                IF "Bin Code" <> '' THEN
                  IF (("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND (Quantity < 0)) OR
                     (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND (Quantity >= 0))
                  THEN
                    WMSManagement.FindBinContent("Location Code","Bin Code","No.","Variant Code",'')
                  ELSE
                    WMSManagement.FindBin("Location Code","Bin Code",'');

                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Bin Code"),"Sales Order No.");

                TESTFIELD(Type,Type::Item);
                TESTFIELD("Location Code");

                IF "Bin Code" <> '' THEN BEGIN
                  GetLocation("Location Code");
                  Location.TESTFIELD("Bin Mandatory");
                  CheckWarehouse;
                END;
            end;
        }
        field(5404;"Qty. per Unit of Measure";Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0:5;
            Editable = false;
            InitValue = 1;
        }
        field(5407;"Unit of Measure Code";Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type=CONST(Item)) "Item Unit of Measure".Code WHERE (Item No.=FIELD(No.))
                            ELSE "Unit of Measure";

            trigger OnValidate()
            var
                UnitOfMeasureTranslation: Record "5402";
            begin
                TestStatusOpen;
                TESTFIELD("Quantity Received",0);
                TESTFIELD("Qty. Received (Base)",0);
                TESTFIELD("Qty. Rcd. Not Invoiced",0);
                IF "Drop Shipment" THEN
                  ERROR(
                    Text001,
                    FIELDCAPTION("Unit of Measure Code"),"Sales Order No.");

                IF (xRec."Unit of Measure" <> "Unit of Measure") AND (Quantity <> 0) THEN
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
                UpdateDirectUnitCost(FIELDNO("Unit of Measure Code"));
                IF "Unit of Measure Code" = '' THEN
                  "Unit of Measure" := ''
                ELSE BEGIN
                  UnitOfMeasure.GET("Unit of Measure Code");
                  "Unit of Measure" := UnitOfMeasure.Description;
                  GetPurchHeader;
                  IF PurchHeader."Language Code" <> '' THEN BEGIN
                    UnitOfMeasureTranslation.SETRANGE(Code,"Unit of Measure Code");
                    UnitOfMeasureTranslation.SETRANGE("Language Code",PurchHeader."Language Code");
                    IF UnitOfMeasureTranslation.FINDFIRST THEN
                      "Unit of Measure" := UnitOfMeasureTranslation.Description;
                  END;
                END;
                DistIntegration.EnterPurchaseItemCrossRef(Rec);
                IF "Prod. Order No." = '' THEN BEGIN
                  IF (Type = Type::Item) AND ("No." <> '') THEN BEGIN
                    GetItem;
                    "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item,"Unit of Measure Code");
                    "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                    "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                    "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                    "Units per Parcel" := ROUND(Item."Units per Parcel" / "Qty. per Unit of Measure",0.00001);
                    IF "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" THEN
                      InitItemAppl;
                    UpdateUOMQtyPerStockQty;
                  END ELSE
                    "Qty. per Unit of Measure" := 1;
                END ELSE
                  "Qty. per Unit of Measure" := 0;

                VALIDATE(Quantity);
            end;
        }
        field(5415;"Quantity (Base)";Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE(Quantity,"Quantity (Base)");
                UpdateDirectUnitCost(FIELDNO("Quantity (Base)"));
            end;
        }
        field(5416;"Outstanding Qty. (Base)";Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5417;"Qty. to Invoice (Base)";Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE("Qty. to Invoice","Qty. to Invoice (Base)");
            end;
        }
        field(5418;"Qty. to Receive (Base)";Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE("Qty. to Receive","Qty. to Receive (Base)");
            end;
        }
        field(5458;"Qty. Rcd. Not Invoiced (Base)";Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5460;"Qty. Received (Base)";Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5461;"Qty. Invoiced (Base)";Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5495;"Reserved Qty. (Base)";Decimal)
        {
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE (Source Type=CONST(39),
                                                                           Source Subtype=FIELD(Document Type),
                                                                           Source ID=FIELD(Document No.),
                                                                           Source Ref. No.=FIELD(Line No.),
                                                                           Reservation Status=CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600;"FA Posting Date";Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601;"FA Posting Type";Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,Maintenance';
            OptionMembers = " ","Acquisition Cost",Maintenance;

            trigger OnValidate()
            begin
                IF Type = Type::"Fixed Asset" THEN BEGIN
                  TESTFIELD("Job No.",'');
                  IF "FA Posting Type" = "FA Posting Type"::" " THEN
                    "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                  GetFAPostingGroup
                END ELSE BEGIN
                  "Depreciation Book Code" := '';
                  "FA Posting Date" := 0D;
                  "Salvage Value" := 0;
                  "Depr. until FA Posting Date" := FALSE;
                  "Depr. Acquisition Cost" := FALSE;
                  "Maintenance Code" := '';
                  "Insurance No." := '';
                  "Budgeted FA No." := '';
                  "Duplicate in Depreciation Book" := '';
                  "Use Duplication List" := FALSE;
                END;
            end;
        }
        field(5602;"Depreciation Book Code";Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                GetFAPostingGroup;
            end;
        }
        field(5603;"Salvage Value";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
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
        }
        field(5610;"Insurance No.";Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611;"Budgeted FA No.";Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                IF "Budgeted FA No." <> '' THEN BEGIN
                  FA.GET("Budgeted FA No.");
                  FA.TESTFIELD("Budgeted Asset",TRUE);
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
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DimMgt.TypeToTableID3(Type),"No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::"Work Center","Work Center No.");
            end;
        }
        field(5705;"Cross-Reference No.";Code[20])
        {
            Caption = 'Cross-Reference No.';

            trigger OnLookup()
            begin
                CrossReferenceNoLookUp;
            end;

            trigger OnValidate()
            var
                ReturnedCrossRef: Record "5717";
            begin
                GetPurchHeader;
                "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";

                ReturnedCrossRef.INIT;
                IF "Cross-Reference No." <> '' THEN BEGIN
                  DistIntegration.ICRLookupPurchaseItem(Rec,ReturnedCrossRef);
                  VALIDATE("No.",ReturnedCrossRef."Item No.");
                  SetVendorItemNo;
                  IF ReturnedCrossRef."Variant Code" <> '' THEN
                    VALIDATE("Variant Code",ReturnedCrossRef."Variant Code");
                  IF ReturnedCrossRef."Unit of Measure" <> '' THEN
                    VALIDATE("Unit of Measure Code",ReturnedCrossRef."Unit of Measure");
                  UpdateDirectUnitCost(FIELDNO("Cross-Reference No."));
                END;

                "Unit of Measure (Cross Ref.)" := ReturnedCrossRef."Unit of Measure";
                "Cross-Reference Type" := ReturnedCrossRef."Cross-Reference Type";
                "Cross-Reference Type No." := ReturnedCrossRef."Cross-Reference Type No.";
                "Cross-Reference No." := ReturnedCrossRef."Cross-Reference No.";

                IF ReturnedCrossRef.Description <> '' THEN
                  Description := ReturnedCrossRef.Description;

                IF PurchHeader."Send IC Document" AND (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing) THEN BEGIN
                  "IC Partner Ref. Type" := "IC Partner Ref. Type"::"Cross Reference";
                  "IC Partner Reference" := "Cross-Reference No.";
                END;
            end;
        }
        field(5706;"Unit of Measure (Cross Ref.)";Code[10])
        {
            Caption = 'Unit of Measure (Cross Ref.)';
            TableRelation = IF (Type=CONST(Item)) "Item Unit of Measure".Code WHERE (Item No.=FIELD(No.));
        }
        field(5707;"Cross-Reference Type";Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";
        }
        field(5708;"Cross-Reference Type No.";Code[30])
        {
            Caption = 'Cross-Reference Type No.';
        }
        field(5709;"Item Category Code";Code[10])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710;Nonstock;Boolean)
        {
            Caption = 'Nonstock';
        }
        field(5711;"Purchasing Code";Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;

            trigger OnValidate()
            begin
                IF PurchasingCode.GET("Purchasing Code") THEN BEGIN
                  "Drop Shipment" := PurchasingCode."Drop Shipment";
                  "Special Order" := PurchasingCode."Special Order";
                END ELSE
                  "Drop Shipment" := FALSE;
                VALIDATE("Drop Shipment","Drop Shipment");
            end;
        }
        field(5712;"Product Group Code";Code[10])
        {
            Caption = 'Product Group Code';
            TableRelation = "Product Group".Code WHERE (Item Category Code=FIELD(Item Category Code));
        }
        field(5713;"Special Order";Boolean)
        {
            Caption = 'Special Order';

            trigger OnValidate()
            begin
                IF (xRec."Special Order" <> "Special Order") AND (Quantity <> 0) THEN
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
            end;
        }
        field(5714;"Special Order Sales No.";Code[20])
        {
            Caption = 'Special Order Sales No.';
            TableRelation = IF (Special Order=CONST(Yes)) "Sales Header".No. WHERE (Document Type=CONST(Order));

            trigger OnValidate()
            begin
                IF (xRec."Special Order Sales No." <> "Special Order Sales No.") AND (Quantity <> 0) THEN
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
            end;
        }
        field(5715;"Special Order Sales Line No.";Integer)
        {
            Caption = 'Special Order Sales Line No.';
            TableRelation = IF (Special Order=CONST(Yes)) "Sales Line"."Line No." WHERE (Document Type=CONST(Order),
                                                                                         Document No.=FIELD(Special Order Sales No.));

            trigger OnValidate()
            begin
                IF (xRec."Special Order Sales Line No." <> "Special Order Sales Line No.") AND (Quantity <> 0) THEN
                  WhseValidateSourceLine.PurchaseLineVerifyChange(Rec,xRec);
            end;
        }
        field(5750;"Whse. Outstanding Qty. (Base)";Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("Warehouse Receipt Line"."Qty. Outstanding (Base)" WHERE (Source Type=CONST(39),
                                                                                        Source Subtype=FIELD(Document Type),
                                                                                        Source No.=FIELD(Document No.),
                                                                                        Source Line No.=FIELD(Line No.)));
            Caption = 'Whse. Outstanding Qty. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752;"Completely Received";Boolean)
        {
            Caption = 'Completely Received';
            Editable = false;
        }
        field(5790;"Requested Receipt Date";Date)
        {
            Caption = 'Requested Receipt Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF (CurrFieldNo <> 0) AND
                   ("Promised Receipt Date" <> 0D)
                THEN
                  ERROR(
                    Text023,
                    FIELDCAPTION("Requested Receipt Date"),
                    FIELDCAPTION("Promised Receipt Date"));

                IF "Requested Receipt Date" <> 0D THEN
                  VALIDATE("Order Date",
                    CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"),"Requested Receipt Date",
                      CalChange."Source Type"::Location,"Location Code",'',
                      CalChange."Source Type"::Vendor,"Buy-from Vendor No.",'',TRUE))
                ELSE
                  IF "Requested Receipt Date" <> xRec."Requested Receipt Date" THEN
                    GetUpdateBasicDates;
            end;
        }
        field(5791;"Promised Receipt Date";Date)
        {
            Caption = 'Promised Receipt Date';

            trigger OnValidate()
            begin
                IF CurrFieldNo <> 0 THEN
                  IF "Promised Receipt Date" <> 0D THEN
                    VALIDATE("Planned Receipt Date","Promised Receipt Date")
                  ELSE
                    VALIDATE("Requested Receipt Date")
                ELSE
                  VALIDATE("Planned Receipt Date","Promised Receipt Date");
            end;
        }
        field(5792;"Lead Time Calculation";DateFormula)
        {
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Requested Receipt Date" <> 0D THEN BEGIN
                  VALIDATE("Planned Receipt Date");
                END ELSE
                  GetUpdateBasicDates;
            end;
        }
        field(5793;"Inbound Whse. Handling Time";DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF ("Promised Receipt Date" <> 0D) OR
                   ("Requested Receipt Date" <> 0D)
                THEN
                  VALIDATE("Planned Receipt Date")
                ELSE
                  VALIDATE("Expected Receipt Date");
            end;
        }
        field(5794;"Planned Receipt Date";Date)
        {
            Caption = 'Planned Receipt Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Promised Receipt Date" <> 0D THEN BEGIN
                  IF "Planned Receipt Date" <> 0D THEN
                    "Expected Receipt Date" :=
                      CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"),"Planned Receipt Date",
                        CalChange."Source Type"::Location,"Location Code",'',
                        CalChange."Source Type"::Location,"Location Code",'',FALSE)
                  ELSE
                    "Expected Receipt Date" := "Planned Receipt Date";
                  IF NOT TrackingBlocked THEN
                    CheckDateConflict.PurchLineCheck(Rec,CurrFieldNo <> 0);
                END ELSE
                  IF "Planned Receipt Date" <> 0D THEN BEGIN
                    "Order Date" :=
                      CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"),"Planned Receipt Date",
                        CalChange."Source Type"::Location,"Location Code",'',
                        CalChange."Source Type"::Vendor,"Buy-from Vendor No.",'',TRUE);
                    "Expected Receipt Date" :=
                      CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"),"Planned Receipt Date",
                        CalChange."Source Type"::Location,"Location Code",'',
                        CalChange."Source Type"::Location,"Location Code",'',FALSE)
                  END ELSE
                    GetUpdateBasicDates;
            end;
        }
        field(5795;"Order Date";Date)
        {
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF (CurrFieldNo <> 0) AND
                   ("Document Type" = "Document Type"::Order) AND
                   ("Order Date" < WORKDATE) AND
                   ("Order Date" <> 0D)
                THEN
                  MESSAGE(
                    Text018,
                    FIELDCAPTION("Order Date"),"Order Date",WORKDATE);

                IF "Order Date" <> 0D THEN
                  "Planned Receipt Date" :=
                    CalendarMgmt.CalcDateBOC(AdjustDateFormula("Lead Time Calculation"),"Order Date",
                      CalChange."Source Type"::Vendor,"Buy-from Vendor No.",'',
                      CalChange."Source Type"::Location,"Location Code",'',TRUE);

                IF "Planned Receipt Date" <> 0D THEN
                  "Expected Receipt Date" :=
                    CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"),"Planned Receipt Date",
                      CalChange."Source Type"::Location,"Location Code",'',
                      CalChange."Source Type"::Location,"Location Code",'',FALSE)
                ELSE
                  "Expected Receipt Date" := "Planned Receipt Date";

                IF NOT TrackingBlocked THEN
                  CheckDateConflict.PurchLineCheck(Rec,CurrFieldNo <> 0);
            end;
        }
        field(5800;"Allow Item Charge Assignment";Boolean)
        {
            Caption = 'Allow Item Charge Assignment';
            InitValue = true;

            trigger OnValidate()
            begin
                CheckItemChargeAssgnt;
            end;
        }
        field(5801;"Qty. to Assign";Decimal)
        {
            CalcFormula = Sum("Item Charge Assignment (Purch)"."Qty. to Assign" WHERE (Document Type=FIELD(Document Type),
                                                                                       Document No.=FIELD(Document No.),
                                                                                       Document Line No.=FIELD(Line No.)));
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5802;"Qty. Assigned";Decimal)
        {
            CalcFormula = Sum("Item Charge Assignment (Purch)"."Qty. Assigned" WHERE (Document Type=FIELD(Document Type),
                                                                                      Document No.=FIELD(Document No.),
                                                                                      Document Line No.=FIELD(Line No.)));
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5803;"Return Qty. to Ship";Decimal)
        {
            Caption = 'Return Qty. to Ship';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                IF (CurrFieldNo <> 0) AND
                   (Type = Type::Item) AND
                   ("Return Qty. to Ship" <> 0) AND
                   (NOT "Drop Shipment")
                THEN
                  CheckWarehouse;

                IF "Return Qty. to Ship" = Quantity - "Return Qty. Shipped" THEN
                  InitQtyToShip
                ELSE BEGIN
                  "Return Qty. to Ship (Base)" := CalcBaseQty("Return Qty. to Ship");
                  InitQtyToInvoice;
                END;
                IF ("Return Qty. to Ship" * Quantity < 0) OR
                   (ABS("Return Qty. to Ship") > ABS("Outstanding Quantity")) OR
                   (Quantity * "Outstanding Quantity" < 0)
                THEN
                  ERROR(
                    Text020,
                    "Outstanding Quantity");
                IF ("Return Qty. to Ship (Base)" * "Quantity (Base)" < 0) OR
                   (ABS("Return Qty. to Ship (Base)") > ABS("Outstanding Qty. (Base)")) OR
                   ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                THEN
                  ERROR(
                    Text021,
                    "Outstanding Qty. (Base)");

                IF (CurrFieldNo <> 0) AND (Type = Type::Item) AND ("Return Qty. to Ship" > 0) THEN
                  CheckApplToItemLedgEntry;
            end;
        }
        field(5804;"Return Qty. to Ship (Base)";Decimal)
        {
            Caption = 'Return Qty. to Ship (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE("Return Qty. to Ship","Return Qty. to Ship (Base)");
            end;
        }
        field(5805;"Return Qty. Shipped Not Invd.";Decimal)
        {
            Caption = 'Return Qty. Shipped Not Invd.';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5806;"Ret. Qty. Shpd Not Invd.(Base)";Decimal)
        {
            Caption = 'Ret. Qty. Shpd Not Invd.(Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5807;"Return Shpd. Not Invd.";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd.';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record "4";
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                IF PurchHeader."Currency Code" <> '' THEN
                  "Return Shpd. Not Invd. (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Return Shpd. Not Invd.",PurchHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Return Shpd. Not Invd. (LCY)" :=
                    ROUND("Return Shpd. Not Invd.",Currency2."Amount Rounding Precision");
            end;
        }
        field(5808;"Return Shpd. Not Invd. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809;"Return Qty. Shipped";Decimal)
        {
            Caption = 'Return Qty. Shipped';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5810;"Return Qty. Shipped (Base)";Decimal)
        {
            Caption = 'Return Qty. Shipped (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(6600;"Return Shipment No.";Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        field(6601;"Return Shipment Line No.";Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
        field(6608;"Return Reason Code";Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";

            trigger OnValidate()
            begin
                IF "Return Reason Code" = '' THEN
                  UpdateDirectUnitCost(FIELDNO("Return Reason Code"));

                IF ReturnReason.GET("Return Reason Code") THEN BEGIN
                  IF ReturnReason."Default Location Code" <> '' THEN
                    VALIDATE("Location Code",ReturnReason."Default Location Code");
                  IF ReturnReason."Inventory Value Zero" THEN
                    VALIDATE("Direct Unit Cost",0)
                  ELSE
                    UpdateDirectUnitCost(FIELDNO("Return Reason Code"));
                END;
            end;
        }
        field(50000;Packing;Text[30])
        {
        }
        field(50001;"Total Cubage";Decimal)
        {
            Description = 'CO1.0';
        }
        field(50002;"Indirect Cost % - Cubage";Decimal)
        {
            DecimalPlaces = 0:5;
            Description = 'CO1.0';
            MinValue = 0;
        }
        field(50003;"Indirect Cost % - Others";Decimal)
        {
            DecimalPlaces = 0:5;
            Description = 'CO1.0';
        }
        field(50004;Barcode;Code[20])
        {
            Description = 'APNT-1.0';
            TableRelation = IF (Type=CONST(Item),
                                No.=FILTER('')) Barcodes
                                ELSE IF (Type=CONST(Item),
                                         No.=FILTER(<>'')) Barcodes WHERE (Item No.=FIELD(No.));

            trigger OnValidate()
            begin
                //APNT-1.0
                IF Type = Type::Item THEN BEGIN
                  Barcodes.GET(Barcode);
                  BarcodeNo := Barcode;
                  VALIDATE("No.",Barcodes."Item No.");
                  Barcode := BarcodeNo;
                  Barcodes.GET(Barcode);
                  VALIDATE("Unit of Measure Code",Barcodes."Unit of Measure Code");
                  VALIDATE("Variant Code",Barcodes."Variant Code");
                END;
                //APNT-1.0
            end;
        }
        field(50005;ESDI;Option)
        {
            Description = 'APNT-HRU1.0';
            OptionCaption = 'Ok,Excess,Short,Damaged,Incomplete';
            OptionMembers = Ok,Excess,Short,Damaged,Incomplete;
        }
        field(50021;"Vendor Invoiced Qty.";Decimal)
        {
            Description = 'APNT-VIQ1.0';

            trigger OnValidate()
            begin
                //APNT-VIQ1.0 -
                "Vendor Invoiced Amount":= "Vendor Invoiced Qty."*"Direct Unit Cost";
                //APNT-VIQ1.0 +
            end;
        }
        field(50022;"Vendor Invoiced Amount";Decimal)
        {
            Description = 'APNT-VIQ1.0';
        }
        field(50023;"Sales Order Ref. No.";Code[20])
        {
            Description = 'APNT-WMS1.0 - T015451';
        }
        field(50100;"HHT Line";Boolean)
        {
            Description = 'HHT1.0';
        }
        field(50101;"Carton No.";Code[20])
        {
            Description = 'HHT1.0/ T001586 - Renamed field from Box No.to Carton No.';
        }
        field(50105;"HHT Qty. to Receive Updated";Boolean)
        {
            Description = 'T034121';
        }
        field(10000720;Division;Code[10])
        {
            Caption = 'Division';
            TableRelation = Division;
        }
        field(10001300;"Original Quantity";Decimal)
        {
            Caption = 'Original Quantity';
        }
        field(10001301;"Original Quantity (base)";Decimal)
        {
            Caption = 'Original Quantity (base)';
        }
        field(10012200;"Reserved For Location Code";Code[10])
        {
            Caption = 'Reserved For Location Code';
            TableRelation = Location;
        }
        field(10012712;"Configuration ID";Code[30])
        {
            Caption = 'Configuration ID';
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
            TableRelation = IF (Ref. Document Type=FILTER(Sale|Lease)) "Agreement Header".No.
                            ELSE IF (Ref. Document Type=FILTER(Work Order)) "Work Order Header".No.;
        }
        field(33016802;"Ref. Document Line No.";Integer)
        {
            Description = 'DP6.01.01';
        }
        field(99000750;"Routing No.";Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(99000751;"Operation No.";Code[10])
        {
            Caption = 'Operation No.';
            TableRelation = "Prod. Order Routing Line"."Operation No." WHERE (Status=CONST(Released),
                                                                              Prod. Order No.=FIELD(Prod. Order No.),
                                                                              Routing No.=FIELD(Routing No.));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "5409";
            begin
                IF "Operation No." = '' THEN
                  EXIT;

                TESTFIELD(Type,Type::Item);
                TESTFIELD("Prod. Order No.");
                TESTFIELD("Routing No.");

                ProdOrderRtngLine.GET(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.",
                  "Operation No.");

                ProdOrderRtngLine.TESTFIELD(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
                VALIDATE("Work Center No.",ProdOrderRtngLine."No.");
                VALIDATE("Direct Unit Cost",ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752;"Work Center No.";Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                IF Type = Type::"Charge (Item)" THEN
                  TESTFIELD("Work Center No.",'');
                IF "Work Center No." = '' THEN
                  EXIT;

                WorkCenter.GET("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                "VAT Prod. Posting Group" := '';
                IF GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp,"Gen. Prod. Posting Group") THEN
                  "VAT Prod. Posting Group" := GenProdPostingGrp."Def. VAT Prod. Posting Group";
                VALIDATE("VAT Prod. Posting Group");

                "Overhead Rate" := WorkCenter."Overhead Rate";
                VALIDATE("Indirect Cost %",WorkCenter."Indirect Cost %");

                CreateDim(
                  DATABASE::"Work Center","Work Center No.",
                  DimMgt.TypeToTableID3(Type),"No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::"Responsibility Center","Responsibility Center");
            end;
        }
        field(99000753;Finished;Boolean)
        {
            Caption = 'Finished';
        }
        field(99000754;"Prod. Order Line No.";Integer)
        {
            Caption = 'Prod. Order Line No.';
            TableRelation = "Prod. Order Line"."Line No." WHERE (Status=FILTER(Released..),
                                                                 Prod. Order No.=FIELD(Prod. Order No.));
        }
        field(99000755;"Overhead Rate";Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                VALIDATE("Indirect Cost %");
            end;
        }
        field(99000756;"MPS Order";Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000757;"Planning Flexibility";Option)
        {
            Caption = 'Planning Flexibility';
            OptionCaption = 'Unlimited,None';
            OptionMembers = Unlimited,"None";

            trigger OnValidate()
            begin
                IF "Planning Flexibility" <> xRec."Planning Flexibility" THEN
                  ReservePurchLine.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000758;"Safety Lead Time";DateFormula)
        {
            Caption = 'Safety Lead Time';

            trigger OnValidate()
            begin
                VALIDATE("Inbound Whse. Handling Time");
            end;
        }
        field(99000759;"Routing Reference No.";Integer)
        {
            Caption = 'Routing Reference No.';
        }
    }

    keys
    {
        key(Key1;"Document Type","Document No.","Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
            SumIndexFields = Amount,"Amount Including VAT";
        }
        key(Key2;"Document No.","Line No.","Document Type")
        {
        }
        key(Key3;"Document Type",Type,"No.","Variant Code","Drop Shipment","Location Code","Expected Receipt Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4;"Document Type","Pay-to Vendor No.","Currency Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Outstanding Amount","Amt. Rcd. Not Invoiced","Outstanding Amount (LCY)","Amt. Rcd. Not Invoiced (LCY)";
        }
        key(Key5;"Document Type","Blanket Order No.","Blanket Order Line No.")
        {
        }
        key(Key6;"Document Type",Type,"Prod. Order No.","Prod. Order Line No.","Routing No.","Operation No.")
        {
        }
        key(Key7;"Document Type","Document No.","Location Code")
        {
        }
        key(Key8;"Document Type","Receipt No.","Receipt Line No.")
        {
        }
        key(Key9;Type,"No.","Variant Code","Drop Shipment","Location Code","Document Type","Expected Receipt Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key10;"Document Type","Buy-from Vendor No.")
        {
        }
        key(Key11;"Document Type","Job No.","Job Task No.")
        {
            SumIndexFields = "Outstanding Amount (LCY)","Amt. Rcd. Not Invoiced (LCY)";
        }
        key(Key12;"Document Type","Location Code")
        {
            SumIndexFields = "Outstanding Amount (LCY)","Amt. Rcd. Not Invoiced (LCY)",Amount,"Amount Including VAT";
        }
        key(Key13;Division,"Item Category Code","Product Group Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DocDim: Record "357";
        PurchCommentLine: Record "43";
        TransferLine: Record "5741";
        TransferLine2: Record "5741";
        TransferHeader: Record "5740";
        WorkOrderLine: Record "33016825";
    begin

        TestStatusOpen;

        //DP01.00 START
        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Converted Purch. Doc No.","Document No.");
        WorkOrderLine.SETRANGE("Converted Purch. Doc Type","Document Type");
        WorkOrderLine.SETRANGE("Document Line No.","Line No.");
        IF WorkOrderLine.FINDSET THEN REPEAT
          WorkOrderLine."Converted Purch. Doc No." := '';
          WorkOrderLine."Converted Purch. Doc Line No." := 0;
          WorkOrderLine."Converted Purch. Doc Datetime" := 0DT;
          WorkOrderLine."Converted Purch. Doc Type" := 0;
          WorkOrderLine."Convert to Purch. Doc Type" := 0;
          WorkOrderLine.MODIFY;
        UNTIL WorkOrderLine.NEXT = 0;
        //DP01.00 STOP

        IF NOT StatusCheckSuspended AND (PurchHeader.Status = PurchHeader.Status::Released) AND
           (Type IN [Type::"G/L Account",Type::"Charge (Item)"])
        THEN
          VALIDATE(Quantity,0);

        DocDim.LOCKTABLE;
        IF (Quantity <> 0) AND ItemExists("No.") THEN BEGIN
          ReservePurchLine.DeleteLine(Rec);
          IF "Receipt No." = '' THEN
            TESTFIELD("Qty. Rcd. Not Invoiced",0);
          IF "Return Shipment No." = '' THEN
            TESTFIELD("Return Qty. Shipped Not Invd.",0);

          CALCFIELDS("Reserved Qty. (Base)");
          TESTFIELD("Reserved Qty. (Base)",0);
          WhseValidateSourceLine.PurchaseLineDelete(Rec);
        END;

        IF ("Document Type" = "Document Type"::Order) AND (Quantity <> "Quantity Invoiced") THEN
          TESTFIELD("Prepmt. Amt. Inv.",0);

        IF "Sales Order Line No." <> 0 THEN BEGIN
          LOCKTABLE;
          SalesOrderLine.LOCKTABLE;
          SalesOrderLine.GET(SalesOrderLine."Document Type"::Order,"Sales Order No.","Sales Order Line No.");
          SalesOrderLine."Purchase Order No." := '';
          SalesOrderLine."Purch. Order Line No." := 0;
          SalesOrderLine.MODIFY;
        END;

        IF "Special Order Sales Line No." <> 0 THEN BEGIN
          LOCKTABLE;
          SalesOrderLine.LOCKTABLE;
          IF "Document Type" = "Document Type"::Order THEN BEGIN
            SalesOrderLine.GET(SalesOrderLine."Document Type"::Order,"Special Order Sales No.","Special Order Sales Line No.");
            SalesOrderLine."Special Order Purchase No." := '';
            SalesOrderLine."Special Order Purch. Line No." := 0;
            SalesOrderLine.MODIFY;
          END ELSE BEGIN
            IF SalesOrderLine.GET(SalesOrderLine."Document Type"::Order,"Special Order Sales No.","Special Order Sales Line No.") THEN
              BEGIN
              SalesOrderLine."Special Order Purchase No." := '';
              SalesOrderLine."Special Order Purch. Line No." := 0;
              SalesOrderLine.MODIFY;
            END;
          END;
        END;

        NonstockItemMgt.DelNonStockPurch(Rec);

        IF "Document Type" = "Document Type"::"Blanket Order" THEN BEGIN
          PurchLine2.RESET;
          PurchLine2.SETCURRENTKEY("Document Type","Blanket Order No.","Blanket Order Line No.");
          PurchLine2.SETRANGE("Blanket Order No.","Document No.");
          PurchLine2.SETRANGE("Blanket Order Line No.","Line No.");
          IF PurchLine2.FINDFIRST THEN
            PurchLine2.TESTFIELD("Blanket Order Line No.",0);
        END;

        IF Type = Type::Item THEN
          DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");

        IF Type = Type::"Charge (Item)" THEN
          DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");

        PurchLine2.RESET;
        PurchLine2.SETRANGE("Document Type","Document Type");
        PurchLine2.SETRANGE("Document No.","Document No.");
        PurchLine2.SETRANGE("Attached to Line No.","Line No.");
        PurchLine2.DELETEALL(TRUE);
        DimMgt.DeleteDocDim(DATABASE::"Purchase Line","Document Type","Document No.","Line No.");

        PurchCommentLine.SETRANGE("Document Type","Document Type");
        PurchCommentLine.SETRANGE("No.","Document No.");
        PurchCommentLine.SETRANGE("Document Line No.","Line No.");
        IF NOT PurchCommentLine.ISEMPTY THEN
          PurchCommentLine.DELETEALL;

        //LS -
        IF Type = Type::Item THEN BEGIN
          TransferLine.RESET;
          TransferLine.SETCURRENTKEY("Transfer Type","Purchase Order No.","Transfer-to Code","Item No.","Variant Code");
          TransferLine.SETFILTER("Transfer Type",'%1|%2',
            TransferLine."Transfer Type"::"Planned Cross Docking",TransferLine."Transfer Type"::"Buyer's Push");
          TransferLine.SETRANGE("Purchase Order No.","Document No.");
          TransferLine.SETRANGE("Item No.","No.");
          TransferLine.SETFILTER("Variant Code",'%1',"Variant Code");
          IF TransferLine.FINDSET THEN REPEAT
            TransferLine.DELETE(TRUE);
            TransferLine2.SETRANGE("Document No.",TransferLine."Document No.");
            IF NOT TransferLine2.FINDFIRST THEN BEGIN
              TransferHeader.GET(TransferLine."Document No.");
              TransferHeader.DELETE(TRUE);
            END;
          UNTIL TransferLine.NEXT = 0;
        //APNT-T009914
        DeleteBinDocs(Rec);
        //APNT-T009914
        END;
        //LS +
    end;

    trigger OnInsert()
    var
        DocDim: Record "357";
    begin
        TestStatusOpen;
        IF Quantity <> 0 THEN
          ReservePurchLine.VerifyQuantity(Rec,xRec);

        DocDim.LOCKTABLE;
        LOCKTABLE;
        PurchHeader."No." := '';

        //LS -
        GetPurchHeader();
        IF NOT PurchHeader."Only Two Dimensions" THEN
        //LS +
          DimMgt.InsertDocDim(
            DATABASE::"Purchase Line","Document Type","Document No.","Line No.",
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        IF ("Document Type" = "Document Type"::"Blanket Order") AND
           ((Type <> xRec.Type) OR ("No." <> xRec."No."))
        THEN BEGIN
          PurchLine2.RESET;
          PurchLine2.SETCURRENTKEY("Document Type","Blanket Order No.","Blanket Order Line No.");
          PurchLine2.SETRANGE("Blanket Order No.","Document No.");
          PurchLine2.SETRANGE("Blanket Order Line No.","Line No.");
          IF PurchLine2.FINDSET THEN
            REPEAT
              PurchLine2.TESTFIELD(Type,Type);
              PurchLine2.TESTFIELD("No.","No.");
            UNTIL PurchLine2.NEXT = 0;
        END;

        IF ((Quantity <> 0) OR (xRec.Quantity <> 0)) AND ItemExists(xRec."No.") THEN
          ReservePurchLine.VerifyChange(Rec,xRec);
    end;

    trigger OnRename()
    begin
        ERROR(Text000,TABLECAPTION);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change %1 because the order line is associated with sales order %2.';
        Text002: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text003: Label 'You cannot purchase resources.';
        Text004: Label 'must not be less than %1';
        Text006: Label 'You cannot invoice more than %1 units.';
        Text007: Label 'You cannot invoice more than %1 base units.';
        Text008: Label 'You cannot receive more than %1 units.';
        Text009: Label 'You cannot receive more than %1 base units.';
        Text010: Label 'You cannot change %1 when %2 is %3.';
        Text011: Label ' must be 0 when %1 is %2';
        Text012: Label 'must not be specified when %1 = %2';
        Text014: Label 'Change %1 from %2 to %3?';
        Text016: Label '%1 is required for %2 = %3.';
        Text017: Label '\The entered information will be disregarded by warehouse operations.';
        Text018: Label '%1 %2 is earlier than the work date %3.';
        Text020: Label 'You cannot return more than %1 units.';
        Text021: Label 'You cannot return more than %1 base units.';
        Text022: Label 'You cannot change %1, if item charge is already posted.';
        Text023: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text029: Label 'must be positive.';
        Text030: Label 'must be negative.';
        Text031: Label 'You cannot define item tracking on this line because it is linked to production order %1.';
        Text032: Label '%1 must not be greater than %2.';
        Text033: Label 'Warehouse ';
        Text034: Label 'Inventory ';
        Text035: Label '%1 units for %2 %3 have already been returned or transferred. Therefore, only %4 units can be returned.';
        Text036: Label 'You must cancel the existing approval for this document to be able to change the %1 field.';
        Text037: Label 'cannot be %1.';
        Text038: Label 'cannot be less than %1.';
        Text039: Label 'cannot be more than %1.';
        Text99000000: Label 'You cannot change %1 when the purchase order is associated to a production order.';
        PurchHeader: Record "38";
        PurchLine2: Record "39";
        TempPurchLine: Record "39";
        GLAcc: Record "15";
        Item: Record "27";
        Currency: Record "4";
        CurrExchRate: Record "330";
        ItemTranslation: Record "30";
        SalesOrderLine: Record "37";
        VATPostingSetup: Record "325";
        StdTxt: Record "7";
        FA: Record "5600";
        FADeprBook: Record "5612";
        FASetup: Record "5603";
        GenBusPostingGrp: Record "250";
        GenProdPostingGrp: Record "251";
        ReservEntry: Record "337";
        UnitOfMeasure: Record "204";
        ItemCharge: Record "5800";
        ItemChargeAssgntPurch: Record "5805";
        SKU: Record "5700";
        WorkCenter: Record "99000754";
        PurchasingCode: Record "5721";
        InvtSetup: Record "313";
        Location: Record "14";
        GLSetup: Record "98";
        ReturnReason: Record "6635";
        ItemVend: Record "99";
        CalChange: Record "7602";
        JobJnlLine: Record "210" temporary;
        Reservation: Form "498";
        ItemAvailByDate: Form "157";
        ItemAvailByVar: Form "5414";
        ItemAvailByLoc: Form "492";
        SalesTaxCalculate: Codeunit "398";
        ReservEngineMgt: Codeunit "99000831";
        ReservePurchLine: Codeunit "99000834";
        UOMMgt: Codeunit "5402";
        AddOnIntegrMgt: Codeunit "5403";
        DimMgt: Codeunit "408";
        DistIntegration: Codeunit "5702";
        NonstockItemMgt: Codeunit "5703";
        WhseValidateSourceLine: Codeunit "5777";
        LeadTimeMgt: Codeunit "5404";
        PurchPriceCalcMgt: Codeunit "7010";
        CalendarMgmt: Codeunit "7600";
        CheckDateConflict: Codeunit "99000815";
        TrackingBlocked: Boolean;
        StatusCheckSuspended: Boolean;
        GLSetupRead: Boolean;
        UnitCostCurrency: Decimal;
        UpdateFromVAT: Boolean;
        Text042: Label 'You cannot return more than the %1 units that you have received for %2 %3.';
        Text043: Label 'must be positive when %1 is not 0.';
        Text044: Label 'You cannot change %1 because this purchase order is associated with %2 %3.';
        Text10000700: Label '%1 %2  is Blocked for Purchasing';
        Barcodes: Record "99001451";
        BarcodeNo: Code[20];
 
    procedure InitOutstanding()
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          "Outstanding Quantity" := Quantity - "Return Qty. Shipped";
          "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Shipped (Base)";
          "Return Qty. Shipped Not Invd." := "Return Qty. Shipped" - "Quantity Invoiced";
          "Ret. Qty. Shpd Not Invd.(Base)" := "Return Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        END ELSE BEGIN
          "Outstanding Quantity" := Quantity - "Quantity Received";
          "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Received (Base)";
          "Qty. Rcd. Not Invoiced" := "Quantity Received" - "Quantity Invoiced";
          "Qty. Rcd. Not Invoiced (Base)" := "Qty. Received (Base)" - "Qty. Invoiced (Base)";
        END;
        "Completely Received" := (Quantity <> 0) AND ("Outstanding Quantity" = 0);
        InitOutstandingAmount;
    end;
 
    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        IF Quantity = 0 THEN BEGIN
          "Outstanding Amount" := 0;
          "Outstanding Amount (LCY)" := 0;
          "Amt. Rcd. Not Invoiced" := 0;
          "Amt. Rcd. Not Invoiced (LCY)" := 0;
          "Return Shpd. Not Invd." := 0;
          "Return Shpd. Not Invd. (LCY)" := 0;
        END ELSE BEGIN
          GetPurchHeader;
          IF PurchHeader.Status = PurchHeader.Status::Released THEN
            AmountInclVAT := "Amount Including VAT"
          ELSE
            IF PurchHeader."Prices Including VAT" THEN
              AmountInclVAT := "Line Amount" - "Inv. Discount Amount"
            ELSE
              IF "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" THEN BEGIN
                IF "Use Tax" THEN
                  AmountInclVAT := "Line Amount" - "Inv. Discount Amount"
                ELSE
                  AmountInclVAT :=
                    "Line Amount" - "Inv. Discount Amount" +
                    ROUND(
                      SalesTaxCalculate.CalculateTax(
                        "Tax Area Code","Tax Group Code","Tax Liable",PurchHeader."Posting Date",
                        "Line Amount" - "Inv. Discount Amount","Quantity (Base)",PurchHeader."Currency Factor"),
                      Currency."Amount Rounding Precision")
              END ELSE
                AmountInclVAT :=
                  ROUND(
                    ("Line Amount" - "Inv. Discount Amount") *
                    (1 + "VAT %" / 100 * (1 - PurchHeader."VAT Base Discount %" / 100)),
                    Currency."Amount Rounding Precision");
          VALIDATE(
            "Outstanding Amount",
            ROUND(
              AmountInclVAT * "Outstanding Quantity" / Quantity,
              Currency."Amount Rounding Precision"));
          IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
            VALIDATE(
              "Return Shpd. Not Invd.",
              ROUND(
                AmountInclVAT * "Return Qty. Shipped Not Invd." / Quantity,
                Currency."Amount Rounding Precision"))
          ELSE
            VALIDATE(
              "Amt. Rcd. Not Invoiced",
              ROUND(
                AmountInclVAT * "Qty. Rcd. Not Invoiced" / Quantity,
                Currency."Amount Rounding Precision"));
        END;
    end;
 
    procedure InitQtyToReceive()
    begin
        "Qty. to Receive" := "Outstanding Quantity";
        "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";

        InitQtyToInvoice;
    end;
 
    procedure InitQtyToShip()
    begin
        "Return Qty. to Ship" := "Outstanding Quantity";
        "Return Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        InitQtyToInvoice;
    end;
 
    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;
        CalcInvDiscToInvoice;
        IF PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice THEN
          CalcPrepaymentToDeduct;
    end;

    local procedure InitItemAppl()
    begin
        "Appl.-to Item Entry" := 0;
    end;
 
    procedure MaxQtyToInvoice(): Decimal
    begin
        IF "Prepayment Line" THEN
          EXIT(1);
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          EXIT("Return Qty. Shipped" + "Return Qty. to Ship" - "Quantity Invoiced")
        ELSE
          EXIT("Quantity Received" + "Qty. to Receive" - "Quantity Invoiced");
    end;
 
    procedure MaxQtyToInvoiceBase(): Decimal
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          EXIT("Return Qty. Shipped (Base)" + "Return Qty. to Ship (Base)" - "Qty. Invoiced (Base)")
        ELSE
          EXIT("Qty. Received (Base)" + "Qty. to Receive (Base)" - "Qty. Invoiced (Base)");
    end;
 
    procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetPurchHeader;
        OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
        IF Quantity = 0 THEN
          VALIDATE("Inv. Disc. Amount to Invoice",0)
        ELSE
          VALIDATE(
            "Inv. Disc. Amount to Invoice",
            ROUND(
              "Inv. Discount Amount" * "Qty. to Invoice" / Quantity,
              Currency."Amount Rounding Precision"));

        IF OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" THEN BEGIN
          IF PurchHeader.Status = PurchHeader.Status::Released THEN
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
          "VAT Difference" := 0;
        END;
    end;

    local procedure CalcBaseQty(Qty: Decimal): Decimal
    begin
        IF "Prod. Order No." = '' THEN
          TESTFIELD("Qty. per Unit of Measure");
        EXIT(ROUND(Qty * "Qty. per Unit of Measure",0.00001));
    end;

    local procedure SelectItemEntry()
    var
        ItemLedgEntry: Record "32";
    begin
        ItemLedgEntry.SETCURRENTKEY("Item No.",Open);
        ItemLedgEntry.SETRANGE("Item No.","No.");
        ItemLedgEntry.SETRANGE(Open,TRUE);
        ItemLedgEntry.SETRANGE(Positive,TRUE);
        IF "Location Code" <> '' THEN
          ItemLedgEntry.SETRANGE("Location Code","Location Code");
        ItemLedgEntry.SETRANGE("Variant Code","Variant Code");

        IF FORM.RUNMODAL(FORM::"Item Ledger Entries",ItemLedgEntry) = ACTION::LookupOK THEN
          VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No.");
    end;
 
    procedure SetPurchHeader(NewPurchHeader: Record "38")
    begin
        PurchHeader := NewPurchHeader;

        IF PurchHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE BEGIN
          PurchHeader.TESTFIELD("Currency Factor");
          Currency.GET(PurchHeader."Currency Code");
          Currency.TESTFIELD("Amount Rounding Precision");
        END;
    end;

    local procedure GetPurchHeader()
    begin
        TESTFIELD("Document No.");
        IF ("Document Type" <> PurchHeader."Document Type") OR ("Document No." <> PurchHeader."No.") THEN BEGIN
          PurchHeader.GET("Document Type","Document No.");
          IF PurchHeader."Currency Code" = '' THEN
            Currency.InitRoundingPrecision
          ELSE BEGIN
            PurchHeader.TESTFIELD("Currency Factor");
            Currency.GET(PurchHeader."Currency Code");
            Currency.TESTFIELD("Amount Rounding Precision");
          END;
        END;
    end;

    local procedure GetItem()
    begin
        TESTFIELD("No.");
        IF Item."No." <> "No." THEN
          Item.GET("No.");
    end;

    local procedure UpdateDirectUnitCost(CalledByFieldNo: Integer)
    begin
        IF ((CalledByFieldNo <> CurrFieldNo) AND (CurrFieldNo <> 0)) OR
           ("Prod. Order No." <> '')
        THEN
          EXIT;

        IF Type = Type::Item THEN BEGIN
          GetPurchHeader;
          PurchPriceCalcMgt.FindPurchLinePrice(PurchHeader,Rec,CalledByFieldNo);
          PurchPriceCalcMgt.FindPurchLineLineDisc(PurchHeader,Rec);
          VALIDATE("Direct Unit Cost");

          IF CalledByFieldNo IN [FIELDNO("No."),FIELDNO("Variant Code"),FIELDNO("Location Code")] THEN
          SetVendorItemNo;
        END;
    end;
 
    procedure UpdateUnitCost()
    var
        DiscountAmountPerQty: Decimal;
    begin
        GetPurchHeader;
        GetGLSetup;
        IF Quantity = 0 THEN
          DiscountAmountPerQty := 0
        ELSE
          DiscountAmountPerQty :=
            ROUND(("Line Discount Amount" + "Inv. Discount Amount") / Quantity,
              GLSetup."Unit-Amount Rounding Precision");

        IF PurchHeader."Prices Including VAT" THEN
          "Unit Cost" :=
            ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) / (1 + "VAT %" / 100) +
            GetOverheadRateFCY
        ELSE
          "Unit Cost" :=
            ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) +
            GetOverheadRateFCY;

        IF PurchHeader."Currency Code" <> '' THEN BEGIN
          PurchHeader.TESTFIELD("Currency Factor");
          "Unit Cost (LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
              GetDate,"Currency Code",
              "Unit Cost",PurchHeader."Currency Factor");
        END ELSE
          "Unit Cost (LCY)" := "Unit Cost";

        IF (Type = Type::Item) AND ("Prod. Order No." = '') THEN BEGIN
          GetItem;
          IF Item."Costing Method" = Item."Costing Method"::Standard THEN BEGIN
            IF GetSKU THEN
              "Unit Cost (LCY)" := SKU."Unit Cost" * "Qty. per Unit of Measure"
            ELSE
              "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
          END;
        END;

        "Unit Cost (LCY)" := ROUND("Unit Cost (LCY)",GLSetup."Unit-Amount Rounding Precision");
        IF PurchHeader."Currency Code" <> '' THEN
          Currency.TESTFIELD("Unit-Amount Rounding Precision");
        "Unit Cost" := ROUND("Unit Cost",Currency."Unit-Amount Rounding Precision");

        UpdateSalesCost;

        IF JobTaskIsSet AND NOT UpdateFromVAT THEN BEGIN
          CreateTempJobJnlLine(FALSE);
          JobJnlLine.VALIDATE("Unit Cost (LCY)","Unit Cost (LCY)");
          UpdatePricesFromJobJnlLine;
        END;
    end;
 
    procedure UpdateAmounts()
    begin
        IF CurrFieldNo <> FIELDNO("Allow Invoice Disc.") THEN
          TESTFIELD(Type);
        GetPurchHeader;

        IF "Line Amount" <> xRec."Line Amount" THEN
          "VAT Difference" := 0;
        IF "Line Amount" <> ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") - "Line Discount Amount" THEN BEGIN
          "Line Amount" :=
            ROUND(Quantity * "Direct Unit Cost",Currency."Amount Rounding Precision") - "Line Discount Amount";
          "VAT Difference" := 0;
        END;

        IF "Prepayment %" <> 0 THEN BEGIN
          IF Quantity < 0 THEN
            FIELDERROR(Quantity,STRSUBSTNO(Text043,FIELDCAPTION("Prepayment %")));
          IF "Direct Unit Cost" < 0 THEN
            FIELDERROR("Direct Unit Cost",STRSUBSTNO(Text043,FIELDCAPTION("Prepayment %")));
        END;
        IF PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice THEN BEGIN
          "Prepayment VAT Difference" := 0;
          IF "Quantity Invoiced" = 0 THEN BEGIN
            "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100,Currency."Amount Rounding Precision");
            IF "Prepmt. Line Amount" < "Prepmt. Amt. Inv." THEN
              FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text037,"Prepmt. Amt. Inv."));
          END ELSE BEGIN
            IF "Prepayment %" <> 0 THEN
              "Prepmt. Line Amount" := "Prepmt. Amt. Inv." +
                ROUND("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity * "Prepayment %" / 100,
                  Currency."Amount Rounding Precision")
            ELSE
              "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100,Currency."Amount Rounding Precision");
            IF "Prepmt. Line Amount" > "Line Amount" THEN
              FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text037,"Prepmt. Line Amount"));
          END;
        END;
        IF PurchHeader.Status = PurchHeader.Status::Released THEN
          UpdateVATAmounts;

        InitOutstandingAmount;

        IF Type = Type::"Charge (Item)" THEN
          UpdateItemChargeAssgnt;
    end;

    local procedure UpdateVATAmounts()
    var
        PurchLine2: Record "39";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalQuantityBase: Decimal;
    begin
        PurchLine2.SETRANGE("Document Type","Document Type");
        PurchLine2.SETRANGE("Document No.","Document No.");
        PurchLine2.SETFILTER("Line No.",'<>%1',"Line No.");
        IF "Line Amount" = 0 THEN
          IF xRec."Line Amount" >= 0 THEN
            PurchLine2.SETFILTER(Amount,'>%1',0)
          ELSE
            PurchLine2.SETFILTER(Amount,'<%1',0)
        ELSE
          IF "Line Amount" > 0 THEN
            PurchLine2.SETFILTER(Amount,'>%1',0)
          ELSE
            PurchLine2.SETFILTER(Amount,'<%1',0);
        PurchLine2.SETRANGE("VAT Identifier","VAT Identifier");
        PurchLine2.SETRANGE("Tax Group Code","Tax Group Code");

        IF "Line Amount" = "Inv. Discount Amount" THEN BEGIN
          Amount := 0;
          "VAT Base Amount" := 0;
          "Amount Including VAT" := 0;
          IF "Line No." <> 0 THEN
            IF MODIFY THEN
              IF PurchLine2.FINDLAST THEN BEGIN
                PurchLine2.UpdateAmounts;
                PurchLine2.MODIFY;
              END;
        END ELSE BEGIN
          TotalLineAmount := 0;
          TotalInvDiscAmount := 0;
          TotalAmount := 0;
          TotalAmountInclVAT := 0;
          TotalQuantityBase := 0;
          IF ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") OR
             (("VAT Calculation Type" IN
               ["VAT Calculation Type"::"Normal VAT","VAT Calculation Type"::"Reverse Charge VAT"]) AND ("VAT %" <> 0))
          THEN
            IF PurchLine2.FINDSET THEN
              REPEAT
                TotalLineAmount := TotalLineAmount + PurchLine2."Line Amount";
                TotalInvDiscAmount := TotalInvDiscAmount + PurchLine2."Inv. Discount Amount";
                TotalAmount := TotalAmount + PurchLine2.Amount;
                TotalAmountInclVAT := TotalAmountInclVAT + PurchLine2."Amount Including VAT";
                TotalQuantityBase := TotalQuantityBase + PurchLine2."Quantity (Base)";
              UNTIL PurchLine2.NEXT = 0;

          IF PurchHeader."Prices Including VAT" THEN
            CASE "VAT Calculation Type" OF
              "VAT Calculation Type"::"Normal VAT",
              "VAT Calculation Type"::"Reverse Charge VAT":
                BEGIN
                  Amount :=
                    ROUND(
                      (TotalLineAmount - TotalInvDiscAmount + "Line Amount" - "Inv. Discount Amount") / (1 + "VAT %" / 100),
                      Currency."Amount Rounding Precision") -
                    TotalAmount;
                  "VAT Base Amount" :=
                    ROUND(
                      Amount * (1 - PurchHeader."VAT Base Discount %" / 100),
                      Currency."Amount Rounding Precision");
                  "Amount Including VAT" :=
                    TotalLineAmount + "Line Amount" -
                    ROUND(
                      (TotalAmount + Amount) * (PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                      Currency."Amount Rounding Precision",Currency.VATRoundingDirection) -
                    TotalAmountInclVAT;
                END;
              "VAT Calculation Type"::"Full VAT":
                BEGIN
                  Amount := 0;
                  "VAT Base Amount" := 0;
                END;
              "VAT Calculation Type"::"Sales Tax":
                BEGIN
                  PurchHeader.TESTFIELD("VAT Base Discount %",0);
                  "Amount Including VAT" :=
                    ROUND("Line Amount" - "Inv. Discount Amount",Currency."Amount Rounding Precision");
                  IF "Use Tax" THEN
                    Amount := "Amount Including VAT"
                  ELSE
                    Amount :=
                      ROUND(
                        SalesTaxCalculate.ReverseCalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable",PurchHeader."Posting Date",
                          TotalAmountInclVAT + "Amount Including VAT",TotalQuantityBase + "Quantity (Base)",
                          PurchHeader."Currency Factor"),
                        Currency."Amount Rounding Precision") -
                      TotalAmount;
                  "VAT Base Amount" := Amount;
                  IF "VAT Base Amount" <> 0 THEN
                    "VAT %" :=
                      ROUND(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount",0.00001)
                  ELSE
                    "VAT %" := 0;
                END;
            END
          ELSE
            CASE "VAT Calculation Type" OF
              "VAT Calculation Type"::"Normal VAT",
              "VAT Calculation Type"::"Reverse Charge VAT":
                BEGIN
                  Amount := ROUND("Line Amount" - "Inv. Discount Amount",Currency."Amount Rounding Precision");
                  "VAT Base Amount" :=
                    ROUND(Amount * (1 - PurchHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                  "Amount Including VAT" :=
                    TotalAmount + Amount +
                    ROUND(
                      (TotalAmount + Amount) * (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                      Currency."Amount Rounding Precision",Currency.VATRoundingDirection) -
                    TotalAmountInclVAT;
                END;
              "VAT Calculation Type"::"Full VAT":
                BEGIN
                  Amount := 0;
                  "VAT Base Amount" := 0;
                  "Amount Including VAT" := "Line Amount" - "Inv. Discount Amount";
                END;
              "VAT Calculation Type"::"Sales Tax":
                BEGIN
                  Amount := ROUND("Line Amount" - "Inv. Discount Amount",Currency."Amount Rounding Precision");
                  "VAT Base Amount" := Amount;
                  IF "Use Tax" THEN
                    "Amount Including VAT" := Amount
                  ELSE
                    "Amount Including VAT" :=
                      TotalAmount + Amount +
                      ROUND(
                        SalesTaxCalculate.CalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable",PurchHeader."Posting Date",
                          (TotalAmount + Amount),(TotalQuantityBase + "Quantity (Base)"),
                          PurchHeader."Currency Factor"),
                        Currency."Amount Rounding Precision") -
                      TotalAmountInclVAT;
                  IF "VAT Base Amount" <> 0 THEN
                    "VAT %" :=
                      ROUND(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount",0.00001)
                  ELSE
                    "VAT %" := 0;
                END;
            END;
        END;
    end;

    local procedure UpdateSalesCost()
    begin
        CASE TRUE OF
          "Sales Order Line No." <> 0 :
            // Drop Shipment
            SalesOrderLine.GET(
              SalesOrderLine."Document Type"::Order,
              "Sales Order No.",
              "Sales Order Line No.");
          "Special Order Sales Line No." <> 0 :
            // Special Order
            BEGIN
              IF NOT
                SalesOrderLine.GET(
                  SalesOrderLine."Document Type"::Order,
                  "Special Order Sales No.",
                  "Special Order Sales Line No.")
              THEN
                EXIT;
             END;
          ELSE
            EXIT;
        END;
        SalesOrderLine."Unit Cost (LCY)" := "Unit Cost (LCY)" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine."Unit Cost" := "Unit Cost" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine.VALIDATE("Unit Cost (LCY)");
        IF NOT RECORDLEVELLOCKING THEN
          LOCKTABLE(TRUE,TRUE);
        SalesOrderLine.MODIFY;
    end;

    local procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "15";
        FAPostingGr: Record "5606";
    begin
        IF (Type <> Type::"Fixed Asset") OR ("No." = '') THEN
          EXIT;
        IF "Depreciation Book Code" = '' THEN BEGIN
          FASetup.GET;
          "Depreciation Book Code" := FASetup."Default Depr. Book";
          IF NOT FADeprBook.GET("No.","Depreciation Book Code") THEN
            "Depreciation Book Code" := '';
          IF "Depreciation Book Code" = '' THEN
            EXIT;
        END;
        IF "FA Posting Type" = "FA Posting Type"::" " THEN
          "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
        FADeprBook.GET("No.","Depreciation Book Code");
        FADeprBook.TESTFIELD("FA Posting Group");
        FAPostingGr.GET(FADeprBook."FA Posting Group");
        IF "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" THEN BEGIN
          FAPostingGr.TESTFIELD("Acquisition Cost Account");
          LocalGLAcc.GET(FAPostingGr."Acquisition Cost Account");
        END ELSE BEGIN
          FAPostingGr.TESTFIELD("Maintenance Expense Account");
          LocalGLAcc.GET(FAPostingGr."Maintenance Expense Account");
        END;
        LocalGLAcc.CheckGLAcc;
        LocalGLAcc.TESTFIELD("Gen. Prod. Posting Group");
        "Posting Group" := FADeprBook."FA Posting Group";
        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
        "Tax Group Code" := LocalGLAcc."Tax Group Code";
        VALIDATE("VAT Prod. Posting Group",LocalGLAcc."VAT Prod. Posting Group");
    end;
 
    procedure UpdateUOMQtyPerStockQty()
    begin
        GetItem;
        "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
        "Unit Price (LCY)" := Item."Unit Price" * "Qty. per Unit of Measure";
        GetPurchHeader;
        IF PurchHeader."Currency Code" <> '' THEN
          "Unit Cost" :=
            CurrExchRate.ExchangeAmtLCYToFCY(
              GetDate,PurchHeader."Currency Code",
              "Unit Cost (LCY)",PurchHeader."Currency Factor")
        ELSE
          "Unit Cost" := "Unit Cost (LCY)";
        UpdateDirectUnitCost(FIELDNO("Unit of Measure Code"));
    end;
 
    procedure ShowReservation()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("Prod. Order No.",'');
        TESTFIELD("No.");
        CLEAR(Reservation);
        Reservation.SetPurchLine(Rec);
        Reservation.RUNMODAL;
    end;
 
    procedure ShowReservationEntries(Modal: Boolean)
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry,TRUE);
        ReservePurchLine.FilterReservFor(ReservEntry,Rec);
        IF Modal THEN
          FORM.RUNMODAL(FORM::"Reservation Entries",ReservEntry)
        ELSE
          FORM.RUN(FORM::"Reservation Entries",ReservEntry);
    end;
 
    procedure GetDate(): Date
    begin
        IF ("Document Type" IN ["Document Type"::"Blanket Order","Document Type"::Quote]) AND
           (PurchHeader."Posting Date" = 0D)
        THEN
          EXIT(WORKDATE);
        EXIT(PurchHeader."Posting Date");
    end;
 
    procedure Signed(Value: Decimal): Decimal
    begin
        CASE "Document Type" OF
          "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice,
          "Document Type"::"Blanket Order":
            EXIT(Value);
          "Document Type"::"Return Order",
          "Document Type"::"Credit Memo":
            EXIT(-Value);
        END;
    end;
 
    procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin)
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        Item.RESET;
        Item.GET("No.");
        Item.SETRANGE("No.","No.");
        Item.SETRANGE("Date Filter",0D,"Expected Receipt Date");

        CASE AvailabilityType OF
          AvailabilityType::Date:
            BEGIN
              Item.SETRANGE("Variant Filter","Variant Code");
              Item.SETRANGE("Location Filter","Location Code");
              CLEAR(ItemAvailByDate);
              ItemAvailByDate.LOOKUPMODE(TRUE);
              ItemAvailByDate.SETRECORD(Item);
              ItemAvailByDate.SETTABLEVIEW(Item);
              IF ItemAvailByDate.RUNMODAL = ACTION::LookupOK THEN
                IF "Expected Receipt Date" <> ItemAvailByDate.GetLastDate THEN
                  IF CONFIRM(
                       Text014,TRUE,FIELDCAPTION("Expected Receipt Date"),
                       "Expected Receipt Date",ItemAvailByDate.GetLastDate)
                  THEN
                    VALIDATE("Expected Receipt Date",ItemAvailByDate.GetLastDate);
            END;
          AvailabilityType::Variant:
            BEGIN
              Item.SETRANGE("Location Filter","Location Code");
              CLEAR(ItemAvailByVar);
              ItemAvailByVar.LOOKUPMODE(TRUE);
              ItemAvailByVar.SETRECORD(Item);
              ItemAvailByVar.SETTABLEVIEW(Item);
              IF ItemAvailByVar.RUNMODAL = ACTION::LookupOK THEN
                IF "Variant Code" <> ItemAvailByVar.GetLastVariant THEN
                  IF CONFIRM(
                       Text014,TRUE,FIELDCAPTION("Variant Code"),"Variant Code",
                       ItemAvailByVar.GetLastVariant)
                  THEN
                    VALIDATE("Variant Code",ItemAvailByVar.GetLastVariant);
            END;
          AvailabilityType::Location:
            BEGIN
              Item.SETRANGE("Variant Filter","Variant Code");
              CLEAR(ItemAvailByLoc);
              ItemAvailByLoc.LOOKUPMODE(TRUE);
              ItemAvailByLoc.SETRECORD(Item);
              ItemAvailByLoc.SETTABLEVIEW(Item);
              IF ItemAvailByLoc.RUNMODAL = ACTION::LookupOK THEN
                IF "Location Code" <> ItemAvailByLoc.GetLastLocation THEN
                  IF CONFIRM(
                       Text014,TRUE,FIELDCAPTION("Location Code"),"Location Code",
                       ItemAvailByLoc.GetLastLocation)
                  THEN
                    VALIDATE("Location Code",ItemAvailByLoc.GetLastLocation);
            END;
        END;
    end;
 
    procedure BlanketOrderLookup()
    begin
        PurchLine2.RESET;
        PurchLine2.SETCURRENTKEY("Document Type",Type,"No.");
        PurchLine2.SETRANGE("Document Type","Document Type"::"Blanket Order");
        PurchLine2.SETRANGE(Type,Type);
        PurchLine2.SETRANGE("No.","No.");
        PurchLine2.SETRANGE("Pay-to Vendor No.","Pay-to Vendor No.");
        PurchLine2.SETRANGE("Buy-from Vendor No.","Buy-from Vendor No.");
        IF FORM.RUNMODAL(FORM::"Purchase Lines",PurchLine2) = ACTION::LookupOK THEN BEGIN
          PurchLine2.TESTFIELD("Document Type","Document Type"::"Blanket Order");
          "Blanket Order No." := PurchLine2."Document No.";
          VALIDATE("Blanket Order Line No.",PurchLine2."Line No.");
        END;
    end;
 
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        ReservePurchLine.Block(SetBlock);
    end;
 
    procedure ShowDimensions()
    var
        DocDim: Record "357";
        DocDimensions: Form "546";
    begin
        TESTFIELD("Document No.");
        TESTFIELD("Line No.");
        DocDim.SETRANGE("Table ID",DATABASE::"Purchase Line");
        DocDim.SETRANGE("Document Type","Document Type");
        DocDim.SETRANGE("Document No.","Document No.");
        DocDim.SETRANGE("Line No.","Line No.");
        DocDimensions.SETTABLEVIEW(DocDim);
        DocDimensions.RUNMODAL;
    end;
 
    procedure OpenItemTrackingLines()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        IF "Prod. Order No." <> '' THEN
          ERROR(Text031,"Prod. Order No.");

        TESTFIELD("Quantity (Base)");

        ReservePurchLine.CallItemTracking(Rec);
    end;
 
    procedure CreateDim(Type1: Integer;No1: Code[20];Type2: Integer;No2: Code[20];Type3: Integer;No3: Code[20];Type4: Integer;No4: Code[20])
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
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        //LS -
        GetPurchHeader();
        IF PurchHeader."Only Two Dimensions" THEN
          BEGIN
            "Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
          END
        ELSE
        //LS +
          DimMgt.GetPreviousDocDefaultDim(
            DATABASE::"Purchase Header","Document Type","Document No.",0,
            DATABASE::Vendor,"Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        DimMgt.GetDefaultDim(
          TableID,No,SourceCodeSetup.Purchases,
          "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");

        //LS -
        IF NOT PurchHeader."Only Two Dimensions" THEN
        //LS +
          IF "Line No." <> 0 THEN
            DimMgt.UpdateDocDefaultDim(
              DATABASE::"Purchase Line","Document Type","Document No.","Line No.",
              "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);

        //LS -
        GetPurchHeader();
        IF NOT PurchHeader."Only Two Dimensions" THEN
        //LS +
          IF "Line No." <> 0 THEN BEGIN
            DimMgt.SaveDocDim(
              DATABASE::"Purchase Line","Document Type","Document No.",
              "Line No.",FieldNumber,ShortcutDimCode);
            MODIFY;
          END ELSE
            DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);
        IF "Line No." <> 0 THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Purchase Line","Document Type","Document No.",
            "Line No.",FieldNumber,ShortcutDimCode);
          MODIFY;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowShortcutDimCode(var ShortcutDimCode: array [8] of Code[20])
    begin
        IF "Line No." <> 0 THEN
          DimMgt.ShowDocDim(
            DATABASE::"Purchase Line","Document Type","Document No.",
            "Line No.",ShortcutDimCode)
        ELSE
          DimMgt.ShowTempDim(ShortcutDimCode);
    end;

    local procedure GetSKU(): Boolean
    begin
        TESTFIELD("No.");
        IF (SKU."Location Code" = "Location Code") AND
           (SKU."Item No." = "No.") AND
           (SKU."Variant Code" = "Variant Code")
        THEN
          EXIT(TRUE);
        IF SKU.GET("Location Code","No.","Variant Code") THEN
          EXIT(TRUE)
        ELSE
          EXIT(FALSE);
    end;
 
    procedure ShowItemChargeAssgnt()
    var
        ItemChargeAssgnts: Form "5805";
        AssignItemChargePurch: Codeunit "5805";
    begin
        GET("Document Type","Document No.","Line No.");
        TESTFIELD(Type,Type::"Charge (Item)");
        TESTFIELD("No.");
        TESTFIELD(Quantity);

        ItemChargeAssgntPurch.RESET;
        ItemChargeAssgntPurch.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.","Document No.");
        ItemChargeAssgntPurch.SETRANGE("Document Line No.","Line No.");
        ItemChargeAssgntPurch.SETRANGE("Item Charge No.","No.");
        IF NOT ItemChargeAssgntPurch.FINDLAST THEN BEGIN
          ItemChargeAssgntPurch."Document Type" := "Document Type";
          ItemChargeAssgntPurch."Document No." := "Document No.";
          ItemChargeAssgntPurch."Document Line No." := "Line No.";
          ItemChargeAssgntPurch."Item Charge No." := "No.";
          GetPurchHeader;
          IF ("Inv. Discount Amount" = 0) AND (NOT PurchHeader."Prices Including VAT") THEN
            ItemChargeAssgntPurch."Unit Cost" := "Unit Cost"
          ELSE
            IF PurchHeader."Prices Including VAT" THEN
              ItemChargeAssgntPurch."Unit Cost" :=
                ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity / (1 + "VAT %" / 100),
                  Currency."Unit-Amount Rounding Precision")
            ELSE
              ItemChargeAssgntPurch."Unit Cost" :=
                ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity,
                  Currency."Unit-Amount Rounding Precision");
        END;

        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch,"Return Shipment No.")
        ELSE
          AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch,"Receipt No.");
        CLEAR(AssignItemChargePurch);
        COMMIT;

        ItemChargeAssgnts.Initialize(Rec,ItemChargeAssgntPurch."Unit Cost");
        ItemChargeAssgnts.RUNMODAL;
        CALCFIELDS("Qty. to Assign");
    end;
 
    procedure UpdateItemChargeAssgnt()
    var
        ShareOfVAT: Decimal;
    begin
        CALCFIELDS("Qty. Assigned");
        IF "Quantity Invoiced" > "Qty. Assigned" THEN
          ERROR(Text032,FIELDCAPTION("Quantity Invoiced"),FIELDCAPTION("Qty. Assigned"));
        ItemChargeAssgntPurch.RESET;
        ItemChargeAssgntPurch.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.","Document No.");
        ItemChargeAssgntPurch.SETRANGE("Document Line No.","Line No.");
        IF (CurrFieldNo <> 0) AND ("Unit Cost" <> xRec."Unit Cost") THEN BEGIN
          ItemChargeAssgntPurch.SETFILTER("Qty. Assigned",'<>0');
          IF ItemChargeAssgntPurch.FINDFIRST THEN
            ERROR(Text022,
              FIELDCAPTION("Unit Cost"));
          ItemChargeAssgntPurch.SETRANGE("Qty. Assigned");
        END;

        IF (CurrFieldNo <> 0) AND (Quantity <> xRec.Quantity) THEN BEGIN
          ItemChargeAssgntPurch.SETFILTER("Qty. Assigned",'<>0');
          IF ItemChargeAssgntPurch.FINDFIRST THEN
            ERROR(Text022,
              FIELDCAPTION(Quantity));
          ItemChargeAssgntPurch.SETRANGE("Qty. Assigned");
        END;

        IF ItemChargeAssgntPurch.FINDSET THEN BEGIN
          GetPurchHeader;
          REPEAT
            ShareOfVAT := 1;
            IF PurchHeader."Prices Including VAT" THEN
              ShareOfVAT := 1 + "VAT %" / 100;
            IF ItemChargeAssgntPurch."Unit Cost" <> ROUND(
                 ("Line Amount" - "Inv. Discount Amount") / Quantity / ShareOfVAT,
                 Currency."Unit-Amount Rounding Precision")
            THEN BEGIN
              ItemChargeAssgntPurch."Unit Cost" :=
                ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity / ShareOfVAT,
                  Currency."Unit-Amount Rounding Precision");
              ItemChargeAssgntPurch.VALIDATE("Qty. to Assign");
              ItemChargeAssgntPurch.MODIFY;
            END;
          UNTIL ItemChargeAssgntPurch.NEXT = 0;
          CALCFIELDS("Qty. to Assign");
        END;
    end;

    local procedure DeleteItemChargeAssgnt(DocType: Option;DocNo: Code[20];DocLineNo: Integer)
    begin
        ItemChargeAssgntPurch.SETCURRENTKEY(
          "Applies-to Doc. Type","Applies-to Doc. No.","Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type",DocType);
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.",DocNo);
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.",DocLineNo);
        IF NOT ItemChargeAssgntPurch.ISEMPTY THEN
          ItemChargeAssgntPurch.DELETEALL(TRUE);
    end;

    local procedure DeleteChargeChargeAssgnt(DocType: Option;DocNo: Code[20];DocLineNo: Integer)
    begin
        IF "Quantity Invoiced" <> 0 THEN BEGIN
          CALCFIELDS("Qty. Assigned");
          TESTFIELD("Qty. Assigned","Quantity Invoiced");
        END;
        ItemChargeAssgntPurch.RESET;
        ItemChargeAssgntPurch.SETRANGE("Document Type",DocType);
        ItemChargeAssgntPurch.SETRANGE("Document No.",DocNo);
        ItemChargeAssgntPurch.SETRANGE("Document Line No.",DocLineNo);
        IF NOT ItemChargeAssgntPurch.ISEMPTY THEN
          ItemChargeAssgntPurch.DELETEALL;
    end;
 
    procedure CheckItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "5805";
    begin
        ItemChargeAssgntPurch.SETCURRENTKEY(
          "Applies-to Doc. Type","Applies-to Doc. No.","Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type","Document Type");
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.","Document No.");
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.","Line No.");
        ItemChargeAssgntPurch.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.","Document No.");
        IF ItemChargeAssgntPurch.FINDSET THEN BEGIN
          TESTFIELD("Allow Item Charge Assignment");
          REPEAT
            ItemChargeAssgntPurch.TESTFIELD("Qty. to Assign",0);
          UNTIL ItemChargeAssgntPurch.NEXT = 0;
        END;
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "2000000041";
    begin
        Field.GET(DATABASE::"Purchase Line",FieldNumber);
        EXIT(Field."Field Caption");
    end;

    local procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        IF NOT PurchHeader.GET("Document Type","Document No.") THEN BEGIN
          PurchHeader."No." := '';
          PurchHeader.INIT;
        END;
        IF PurchHeader."Prices Including VAT" THEN
          EXIT('2,1,' + GetFieldCaption(FieldNumber))
        ELSE
          EXIT('2,0,' + GetFieldCaption(FieldNumber));
    end;

    local procedure TestStatusOpen()
    begin
        IF StatusCheckSuspended THEN
          EXIT;
        GetPurchHeader;
        //APNT-1.0 - Commented base code and added custom code as per LG's request through mail
        /*
        IF Type IN [Type::Item,Type::"Fixed Asset"] THEN
          PurchHeader.TESTFIELD(Status,PurchHeader.Status::Open);
        */
        IF Type IN [Type::"G/L Account",Type::Item,Type::"Fixed Asset"] THEN
          PurchHeader.TESTFIELD(Status,PurchHeader.Status::Open);
        //APNT-1.0

    end;
 
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;
 
    procedure UpdateLeadTimeFields()
    var
        StartingDate: Date;
    begin
        IF Type = Type::Item THEN BEGIN
          GetPurchHeader;
          IF "Document Type" IN
             ["Document Type"::Quote,"Document Type"::Order]
          THEN
            StartingDate := PurchHeader."Order Date"
          ELSE
            StartingDate := PurchHeader."Posting Date";

          EVALUATE("Lead Time Calculation",
            LeadTimeMgt.PurchaseLeadTime(
              "No.","Location Code","Variant Code",
              "Buy-from Vendor No."));
          IF FORMAT("Lead Time Calculation") = '' THEN
            "Lead Time Calculation" := PurchHeader."Lead Time Calculation";
          EVALUATE("Safety Lead Time",LeadTimeMgt.SafetyLeadTime("No.","Location Code","Variant Code"));
        END;
    end;
 
    procedure GetUpdateBasicDates()
    begin
        GetPurchHeader;
        IF PurchHeader."Expected Receipt Date" <> 0D THEN
          VALIDATE("Expected Receipt Date",PurchHeader."Expected Receipt Date")
        ELSE
          VALIDATE("Order Date",PurchHeader."Order Date");
    end;
 
    procedure UpdateDates()
    begin
        IF "Promised Receipt Date" <> 0D THEN
          VALIDATE("Promised Receipt Date")
        ELSE
          IF "Requested Receipt Date" <> 0D THEN
            VALIDATE("Requested Receipt Date")
          ELSE
            GetUpdateBasicDates;
    end;
 
    procedure InternalLeadTimeDays(PurchDate: Date): Text[30]
    var
        SafetyLeadTime: DateFormula;
        TotalDays: DateFormula;
    begin
        IF FORMAT("Safety Lead Time") = '' THEN
          EVALUATE(SafetyLeadTime,'<0D>')
        ELSE
          SafetyLeadTime := "Safety Lead Time";
        IF NOT (COPYSTR(FORMAT(SafetyLeadTime),1,1) IN ['+','-']) THEN
          EVALUATE(SafetyLeadTime,'+' + FORMAT(SafetyLeadTime));
        EVALUATE(TotalDays,
          '<' +
          FORMAT(CALCDATE(FORMAT("Inbound Whse. Handling Time") +
              FORMAT(SafetyLeadTime),PurchDate) - PurchDate) +
          'D>');
        EXIT(FORMAT(TotalDays));
    end;
 
    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping;var PurchHeader: Record "38";var PurchLine: Record "39";var VATAmountLine: Record "290")
    var
        TempVATAmountLineRemainder: Record "290" temporary;
        Currency: Record "4";
        ChangeLogMgt: Codeunit "423";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
    begin
        IF QtyType = QtyType::Shipping THEN
          EXIT;
        IF PurchHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE
          Currency.GET(PurchHeader."Currency Code");

        TempVATAmountLineRemainder.DELETEALL;

        WITH PurchLine DO BEGIN
          SETRANGE("Document Type",PurchHeader."Document Type");
          SETRANGE("Document No.",PurchHeader."No.");
          LOCKTABLE;
          IF FINDSET THEN
            REPEAT
              IF NOT ZeroAmountLine(QtyType) THEN BEGIN
                VATAmountLine.GET("VAT Identifier","VAT Calculation Type","Tax Group Code","Use Tax","Line Amount" >= 0);
                IF VATAmountLine.Modified THEN BEGIN
                  xRecRef.GETTABLE(PurchLine);
                  IF NOT TempVATAmountLineRemainder.GET(
                       "VAT Identifier","VAT Calculation Type","Tax Group Code","Use Tax","Line Amount" >= 0)
                  THEN BEGIN
                    TempVATAmountLineRemainder := VATAmountLine;
                    TempVATAmountLineRemainder.INIT;
                    TempVATAmountLineRemainder.INSERT;
                  END;

                  IF QtyType = QtyType::General THEN
                    LineAmountToInvoice := "Line Amount"
                  ELSE
                    LineAmountToInvoice :=
                      ROUND("Line Amount" * "Qty. to Invoice" / Quantity,Currency."Amount Rounding Precision");

                  IF "Allow Invoice Disc." THEN BEGIN
                    IF VATAmountLine."Inv. Disc. Base Amount" = 0 THEN
                      InvDiscAmount := 0
                    ELSE BEGIN
                      IF QtyType = QtyType::General THEN
                        LineAmountToInvoice := "Line Amount"
                      ELSE
                        LineAmountToInvoice :=
                          ROUND("Line Amount" * "Qty. to Invoice" / Quantity,Currency."Amount Rounding Precision");
                      TempVATAmountLineRemainder."Invoice Discount Amount" :=
                        TempVATAmountLineRemainder."Invoice Discount Amount" +
                        VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice /
                        VATAmountLine."Inv. Disc. Base Amount";
                      InvDiscAmount :=
                        ROUND(
                          TempVATAmountLineRemainder."Invoice Discount Amount",Currency."Amount Rounding Precision");
                      TempVATAmountLineRemainder."Invoice Discount Amount" :=
                        TempVATAmountLineRemainder."Invoice Discount Amount" - InvDiscAmount;
                    END;
                    IF QtyType = QtyType::General THEN BEGIN
                      "Inv. Discount Amount" := InvDiscAmount;
                      CalcInvDiscToInvoice;
                    END ELSE
                      "Inv. Disc. Amount to Invoice" := InvDiscAmount;
                  END ELSE
                    InvDiscAmount := 0;
                  IF QtyType = QtyType::General THEN
                    IF PurchHeader."Prices Including VAT" THEN BEGIN
                      IF (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount" = 0) OR
                         ("Line Amount" = 0)
                      THEN BEGIN
                        VATAmount := 0;
                        NewAmountIncludingVAT := 0;
                      END ELSE BEGIN
                        VATAmount :=
                          TempVATAmountLineRemainder."VAT Amount" +
                          VATAmountLine."VAT Amount" *
                          ("Line Amount" - "Inv. Discount Amount") /
                          (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount");
                        NewAmountIncludingVAT :=
                          TempVATAmountLineRemainder."Amount Including VAT" +
                          VATAmountLine."Amount Including VAT" *
                          ("Line Amount" - "Inv. Discount Amount") /
                          (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount");
                      END;
                      NewAmount :=
                        ROUND(NewAmountIncludingVAT,Currency."Amount Rounding Precision") -
                        ROUND(VATAmount,Currency."Amount Rounding Precision");
                      NewVATBaseAmount :=
                        ROUND(
                          NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                          Currency."Amount Rounding Precision");
                    END ELSE BEGIN
                      IF "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" THEN BEGIN
                        VATAmount := "Line Amount" - "Inv. Discount Amount";
                        NewAmount := 0;
                        NewVATBaseAmount := 0;
                      END ELSE BEGIN
                        NewAmount := "Line Amount" - "Inv. Discount Amount";
                        NewVATBaseAmount :=
                          ROUND(
                            NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                            Currency."Amount Rounding Precision");
                        IF VATAmountLine."VAT Base" = 0 THEN
                          VATAmount := 0
                        ELSE
                          VATAmount :=
                            TempVATAmountLineRemainder."VAT Amount" +
                            VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                      END;
                      NewAmountIncludingVAT := NewAmount + ROUND(VATAmount,Currency."Amount Rounding Precision");
                    END
                  ELSE BEGIN
                    IF (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") = 0 THEN
                      VATDifference := 0
                    ELSE
                      VATDifference :=
                        TempVATAmountLineRemainder."VAT Difference" +
                        VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) /
                        (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount");
                    IF LineAmountToInvoice = 0 THEN
                      "VAT Difference" := 0
                    ELSE
                      "VAT Difference" := ROUND(VATDifference,Currency."Amount Rounding Precision");
                  END;

                  IF (QtyType = QtyType::General) AND (PurchHeader.Status = PurchHeader.Status::Released) THEN BEGIN
                    Amount := NewAmount;
                    "Amount Including VAT" := ROUND(NewAmountIncludingVAT,Currency."Amount Rounding Precision");
                    "VAT Base Amount" := NewVATBaseAmount;
                  END;
                  InitOutstanding;
                  IF NOT ((Type = Type::"Charge (Item)") AND ("Quantity Invoiced" <> "Qty. Assigned")) THEN BEGIN
                    SetUpdateFromVAT(TRUE);
                    UpdateUnitCost;
                  END;
                  IF Type = Type::"Charge (Item)" THEN
                    UpdateItemChargeAssgnt;
                  MODIFY;
                  RecRef.GETTABLE(PurchLine);
                  ChangeLogMgt.LogModification(RecRef,xRecRef);

                  TempVATAmountLineRemainder."Amount Including VAT" :=
                    NewAmountIncludingVAT - ROUND(NewAmountIncludingVAT,Currency."Amount Rounding Precision");
                  TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                  TempVATAmountLineRemainder."VAT Difference" := VATDifference - "VAT Difference";
                  TempVATAmountLineRemainder.MODIFY;
                END;
              END;
            UNTIL NEXT = 0;
        END;
    end;
 
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping;var PurchHeader: Record "38";var PurchLine: Record "39";var VATAmountLine: Record "290")
    var
        PrevVatAmountLine: Record "290";
        Currency: Record "4";
        Vendor: Record "23";
        VendorPostingGroup: Record "93";
        PurchSetup: Record "312";
        SalesTaxCalculate: Codeunit "398";
        QtyToHandle: Decimal;
        RoundingLineInserted: Boolean;
        TotalVATAmount: Decimal;
    begin
        IF PurchHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE
          Currency.GET(PurchHeader."Currency Code");

        VATAmountLine.DELETEALL;

        WITH PurchLine DO BEGIN
          SETRANGE("Document Type",PurchHeader."Document Type");
          SETRANGE("Document No.",PurchHeader."No.");
          PurchSetup.GET;
          IF PurchSetup."Invoice Rounding" THEN BEGIN
            Vendor.GET(PurchHeader."Pay-to Vendor No.");
            VendorPostingGroup.GET(Vendor."Vendor Posting Group");
          END;
          IF FINDSET THEN
            REPEAT
              IF NOT ZeroAmountLine(QtyType) THEN BEGIN
                IF (Type = Type::"G/L Account") AND NOT "Prepayment Line" THEN
                  RoundingLineInserted := ("No." = VendorPostingGroup."Invoice Rounding Account") OR RoundingLineInserted;
                IF "VAT Calculation Type" IN
                   ["VAT Calculation Type"::"Reverse Charge VAT","VAT Calculation Type"::"Sales Tax"]
                THEN
                  "VAT %" := 0;
                IF NOT VATAmountLine.GET(
                     "VAT Identifier","VAT Calculation Type","Tax Group Code","Use Tax","Line Amount" >= 0)
                THEN BEGIN
                  VATAmountLine.INIT;
                  VATAmountLine."VAT Identifier" := "VAT Identifier";
                  VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                  VATAmountLine."Tax Group Code" := "Tax Group Code";
                  VATAmountLine."Use Tax" := "Use Tax";
                  VATAmountLine."VAT %" := "VAT %";
                  VATAmountLine.Modified := TRUE;
                  VATAmountLine.Positive := "Line Amount" >= 0;
                  VATAmountLine.INSERT;
                END;
                CASE QtyType OF
                  QtyType::General:
                    BEGIN
                      VATAmountLine.Quantity := VATAmountLine.Quantity + "Quantity (Base)";
                      VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + "Line Amount";
                      IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" :=
                          VATAmountLine."Inv. Disc. Base Amount" + "Line Amount";
                      VATAmountLine."Invoice Discount Amount" :=
                        VATAmountLine."Invoice Discount Amount" + "Inv. Discount Amount";
                      VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference";
                      IF "Prepayment Line" THEN
                        VATAmountLine."Includes Prepayment" := TRUE;
                      VATAmountLine.MODIFY;
                    END;
                  QtyType::Invoicing:
                    BEGIN
                      CASE TRUE OF
                        ("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND
                        (NOT PurchHeader.Receive) AND PurchHeader.Invoice AND (NOT "Prepayment Line"):
                          BEGIN
                            IF "Receipt No." = '' THEN BEGIN
                              QtyToHandle := GetAbsMin("Qty. to Invoice","Qty. Rcd. Not Invoiced");
                              VATAmountLine.Quantity :=
                                VATAmountLine.Quantity + GetAbsMin("Qty. to Invoice (Base)","Qty. Rcd. Not Invoiced (Base)");
                            END ELSE BEGIN
                              QtyToHandle := "Qty. to Invoice";
                              VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Invoice (Base)";
                            END;
                          END;
                        ("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND
                        (NOT PurchHeader.Ship) AND PurchHeader.Invoice:
                          BEGIN
                            QtyToHandle := GetAbsMin("Qty. to Invoice","Return Qty. Shipped Not Invd.");
                            VATAmountLine.Quantity :=
                              VATAmountLine.Quantity + GetAbsMin("Qty. to Invoice (Base)","Ret. Qty. Shpd Not Invd.(Base)");
                          END;
                        ELSE
                          BEGIN
                          QtyToHandle := "Qty. to Invoice";
                          VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Invoice (Base)";
                        END;
                      END;
                      VATAmountLine."Line Amount" :=
                        VATAmountLine."Line Amount" +
                        (ROUND(QtyToHandle * "Direct Unit Cost" - ("Line Discount Amount" * QtyToHandle / Quantity),
                        Currency."Amount Rounding Precision"));
                      IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" :=
                          VATAmountLine."Inv. Disc. Base Amount" +
                          (ROUND(QtyToHandle * "Direct Unit Cost" - ("Line Discount Amount" * QtyToHandle / Quantity),
                          Currency."Amount Rounding Precision"));
                      IF (PurchHeader."Invoice Discount Calculation" <> PurchHeader."Invoice Discount Calculation"::Amount) THEN
                        VATAmountLine."Invoice Discount Amount" :=
                          VATAmountLine."Invoice Discount Amount" +
                          ROUND("Inv. Discount Amount" * QtyToHandle / Quantity,Currency."Amount Rounding Precision")
                      ELSE
                        VATAmountLine."Invoice Discount Amount" :=
                          VATAmountLine."Invoice Discount Amount" + "Inv. Disc. Amount to Invoice";
                      VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference";
                      IF "Prepayment Line" THEN
                        VATAmountLine."Includes Prepayment" := TRUE;
                      VATAmountLine.MODIFY;
                    END;
                  QtyType::Shipping:
                    BEGIN
                      IF "Document Type" IN
                         ["Document Type"::"Return Order","Document Type"::"Credit Memo"]
                      THEN BEGIN
                        QtyToHandle := "Return Qty. to Ship";
                        VATAmountLine.Quantity := VATAmountLine.Quantity + "Return Qty. to Ship (Base)";
                      END ELSE BEGIN
                        QtyToHandle := "Qty. to Receive";
                        VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Receive (Base)";
                      END;
                      VATAmountLine."Line Amount" :=
                        VATAmountLine."Line Amount" +
                        (ROUND(QtyToHandle * "Direct Unit Cost" - ("Line Discount Amount" * QtyToHandle / Quantity),
                        Currency."Amount Rounding Precision"));
                      IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" :=
                          VATAmountLine."Inv. Disc. Base Amount" +
                          (ROUND(QtyToHandle * "Direct Unit Cost" - ("Line Discount Amount" * QtyToHandle / Quantity),
                          Currency."Amount Rounding Precision"));
                      VATAmountLine."Invoice Discount Amount" :=
                        VATAmountLine."Invoice Discount Amount" +
                        ROUND("Inv. Discount Amount" * QtyToHandle / Quantity,Currency."Amount Rounding Precision");
                      VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference";
                      IF "Prepayment Line" THEN
                        VATAmountLine."Includes Prepayment" := TRUE;
                      VATAmountLine.MODIFY;
                    END;
                END;
                TotalVATAmount := TotalVATAmount + "Amount Including VAT" - Amount;
              END;
            UNTIL NEXT = 0;
        END;

        WITH VATAmountLine DO
          IF FINDSET THEN
            REPEAT
              IF (PrevVatAmountLine."VAT Identifier" <> "VAT Identifier") OR
                 (PrevVatAmountLine."VAT Calculation Type" <> "VAT Calculation Type") OR
                 (PrevVatAmountLine."Tax Group Code" <> "Tax Group Code") OR
                 (PrevVatAmountLine."Use Tax" <> "Use Tax")
              THEN
                PrevVatAmountLine.INIT;
              IF PurchHeader."Prices Including VAT" THEN BEGIN
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "VAT Base" :=
                        ROUND(
                          ("Line Amount" - "Invoice Discount Amount") / (1 + "VAT %" / 100),
                          Currency."Amount Rounding Precision") - "VAT Difference";
                      "VAT Amount" :=
                        "VAT Difference" +
                        ROUND(
                          PrevVatAmountLine."VAT Amount" +
                          ("Line Amount" - "Invoice Discount Amount" - "VAT Base" - "VAT Difference") *
                          (1 - PurchHeader."VAT Base Discount %" / 100),
                          Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Amount Including VAT" := "VAT Base" + "VAT Amount";
                      IF Positive THEN
                        PrevVatAmountLine.INIT
                      ELSE BEGIN
                        PrevVatAmountLine := VATAmountLine;
                        PrevVatAmountLine."VAT Amount" :=
                          ("Line Amount" - "Invoice Discount Amount" - "VAT Base" - "VAT Difference") *
                          (1 - PurchHeader."VAT Base Discount %" / 100);
                        PrevVatAmountLine."VAT Amount" :=
                          PrevVatAmountLine."VAT Amount" -
                          ROUND(PrevVatAmountLine."VAT Amount",Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      END;
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    BEGIN
                      "VAT Base" := 0;
                      "VAT Amount" := "VAT Difference" + "Line Amount" - "Invoice Discount Amount";
                      "Amount Including VAT" := "VAT Amount";
                    END;
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount";
                      IF "Use Tax" THEN
                        "VAT Base" := "Amount Including VAT"
                      ELSE
                        "VAT Base" :=
                          ROUND(
                            SalesTaxCalculate.ReverseCalculateTax(
                              PurchHeader."Tax Area Code","Tax Group Code",PurchHeader."Tax Liable",
                              PurchHeader."Posting Date","Amount Including VAT",Quantity,PurchHeader."Currency Factor"),
                            Currency."Amount Rounding Precision");
                      "VAT Amount" := "VAT Difference" + "Amount Including VAT" - "VAT Base";
                      IF "VAT Base" = 0 THEN
                        "VAT %" := 0
                      ELSE
                        "VAT %" := ROUND(100 * "VAT Amount" / "VAT Base",0.00001);
                    END;
                END;
              END ELSE BEGIN
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "VAT Base" := "Line Amount" - "Invoice Discount Amount";
                      "VAT Amount" :=
                        "VAT Difference" +
                        ROUND(
                          PrevVatAmountLine."VAT Amount" +
                          "VAT Base" * "VAT %" / 100 * (1 - PurchHeader."VAT Base Discount %" / 100),
                          Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount" + "VAT Amount";
                      IF Positive THEN
                        PrevVatAmountLine.INIT
                      ELSE BEGIN
                        PrevVatAmountLine := VATAmountLine;
                        PrevVatAmountLine."VAT Amount" :=
                          "VAT Base" * "VAT %" / 100 * (1 - PurchHeader."VAT Base Discount %" / 100);
                        PrevVatAmountLine."VAT Amount" :=
                          PrevVatAmountLine."VAT Amount" -
                          ROUND(PrevVatAmountLine."VAT Amount",Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      END;
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    BEGIN
                      "VAT Base" := 0;
                      "VAT Amount" := "VAT Difference" + "Line Amount" - "Invoice Discount Amount";
                      "Amount Including VAT" := "VAT Amount";
                    END;
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      "VAT Base" := "Line Amount" - "Invoice Discount Amount";
                      IF "Use Tax" THEN
                        "VAT Amount" := 0
                      ELSE
                        "VAT Amount" :=
                          SalesTaxCalculate.CalculateTax(
                            PurchHeader."Tax Area Code","Tax Group Code",PurchHeader."Tax Liable",
                            PurchHeader."Posting Date","VAT Base",Quantity,PurchHeader."Currency Factor");
                      IF "VAT Base" = 0 THEN
                        "VAT %" := 0
                      ELSE
                        "VAT %" := ROUND(100 * "VAT Amount" / "VAT Base",0.00001);
                      "VAT Amount" :=
                        "VAT Difference" +
                        ROUND("VAT Amount",Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Amount Including VAT" := "VAT Base" + "VAT Amount";
                    END;
                END;
              END;
              IF RoundingLineInserted THEN
                TotalVATAmount := TotalVATAmount - "VAT Amount";
              "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
              MODIFY;
            UNTIL NEXT = 0;

        IF RoundingLineInserted AND (TotalVATAmount <> 0) THEN
          IF VATAmountLine.GET(PurchLine."VAT Identifier",PurchLine."VAT Calculation Type",
               PurchLine."Tax Group Code",PurchLine."Use Tax",PurchLine."Line Amount" >= 0)
          THEN BEGIN
            VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + TotalVATAmount;
            VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + TotalVATAmount;
            VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + TotalVATAmount;
            VATAmountLine.MODIFY;
          END;
    end;
 
    procedure UpdateWithWarehouseReceive()
    begin
        IF Type = Type::Item THEN
          CASE TRUE OF
            ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND (Quantity >= 0):
              IF Location.RequireReceive("Location Code") THEN
                VALIDATE("Qty. to Receive",0)
              ELSE
                VALIDATE("Qty. to Receive","Outstanding Quantity");
            ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND (Quantity < 0):
              IF Location.RequireShipment("Location Code") THEN
                VALIDATE("Qty. to Receive",0)
              ELSE
                VALIDATE("Qty. to Receive","Outstanding Quantity");
            ("Document Type" = "Document Type"::"Return Order") AND (Quantity >= 0):
              IF Location.RequireShipment("Location Code") THEN
                VALIDATE("Return Qty. to Ship",0)
              ELSE
                VALIDATE("Return Qty. to Ship","Outstanding Quantity");
            ("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0):
              IF Location.RequireReceive("Location Code") THEN
                VALIDATE("Return Qty. to Ship",0)
              ELSE
                VALIDATE("Return Qty. to Ship","Outstanding Quantity");
          END;
    end;

    local procedure CheckWarehouse()
    var
        Location2: Record "14";
        WhseSetup: Record "5769";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[50];
    begin
        GetLocation("Location Code");
        IF "Location Code" = '' THEN BEGIN
          WhseSetup.GET;
          Location2."Require Shipment" := WhseSetup."Require Shipment";
          Location2."Require Pick" := WhseSetup."Require Pick";
          Location2."Require Receive" := WhseSetup."Require Receive";
          Location2."Require Put-away" := WhseSetup."Require Put-away";
        END ELSE
          Location2 := Location;

        DialogText := Text033;
        IF ("Document Type" IN ["Document Type"::Order,"Document Type"::"Return Order"]) AND
           Location2."Directed Put-away and Pick"
        THEN BEGIN
          ShowDialog := ShowDialog::Error;
          IF (("Document Type" = "Document Type"::Order) AND (Quantity >= 0)) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0))
          THEN
            DialogText :=
              DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Receive"))
          ELSE
            DialogText :=
              DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Shipment"));
        END ELSE BEGIN
          IF (("Document Type" = "Document Type"::Order) AND (Quantity >= 0) AND
              (Location2."Require Receive" OR Location2."Require Put-away")) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0) AND
              (Location2."Require Receive" OR Location2."Require Put-away"))
          THEN BEGIN
            IF WhseValidateSourceLine.WhseLinesExist(
                 DATABASE::"Purchase Line",
                 "Document Type",
                 "Document No.",
                 "Line No.",
                 0,
                 Quantity)
            THEN
              ShowDialog := ShowDialog::Error
            ELSE
              IF Location2."Require Receive" THEN
                ShowDialog := ShowDialog::Message;
            IF Location2."Require Receive" THEN
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Receive"))
            ELSE BEGIN
              DialogText := Text034;
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Put-away"));
            END;
          END;

          IF (("Document Type" = "Document Type"::Order) AND (Quantity < 0) AND
              (Location2."Require Shipment" OR Location2."Require Pick")) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity >= 0) AND
              (Location2."Require Shipment" OR Location2."Require Pick"))
          THEN BEGIN
            IF WhseValidateSourceLine.WhseLinesExist(
                 DATABASE::"Purchase Line",
                 "Document Type",
                 "Document No.",
                 "Line No.",
                 0,
                 Quantity)
            THEN
              ShowDialog := ShowDialog::Error
            ELSE
              IF Location2."Require Shipment" THEN
                ShowDialog := ShowDialog::Message;
            IF Location2."Require Shipment" THEN
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Shipment"))
            ELSE BEGIN
              DialogText := Text034;
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Pick"));
            END;
          END;
        END;

        CASE ShowDialog OF
          ShowDialog::Message:
            MESSAGE(Text016 + Text017,DialogText,FIELDCAPTION("Line No."),"Line No.");
          ShowDialog::Error:
            ERROR(Text016,DialogText,FIELDCAPTION("Line No."),"Line No.")
        END
    end;

    local procedure GetOverheadRateFCY(): Decimal
    var
        QtyPerUOM: Decimal;
    begin
        IF "Prod. Order No." = '' THEN
          QtyPerUOM := "Qty. per Unit of Measure"
        ELSE BEGIN
          GetItem;
          QtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item,"Unit of Measure Code");
        END;

        EXIT(
          CurrExchRate.ExchangeAmtLCYToFCY(
            GetDate,"Currency Code","Overhead Rate" * QtyPerUOM,PurchHeader."Currency Factor"));
    end;
 
    procedure GetItemTranslation()
    begin
        GetPurchHeader;
        IF ItemTranslation.GET("No.","Variant Code",PurchHeader."Language Code") THEN BEGIN
          Description := ItemTranslation.Description;
          "Description 2" := ItemTranslation."Description 2";
        END;
    end;

    local procedure GetGLSetup()
    begin
        IF NOT GLSetupRead THEN
          GLSetup.GET;
        GLSetupRead := TRUE;
    end;
 
    procedure AdjustDateFormula(DateFormulatoAdjust: DateFormula): Text[30]
    begin
        IF FORMAT(DateFormulatoAdjust) <> '' THEN
          EXIT(FORMAT(DateFormulatoAdjust));
        EVALUATE(DateFormulatoAdjust,'<0D>');
        EXIT(FORMAT(DateFormulatoAdjust));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        IF LocationCode = '' THEN
          CLEAR(Location)
        ELSE
          IF Location.Code <> LocationCode THEN
            Location.GET(LocationCode);
    end;
 
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "6500";
    begin
        EXIT(ItemTrackingMgt.ComposeRowID(DATABASE::"Purchase Line","Document Type",
            "Document No.",'',0,"Line No."));
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "7302";
    begin
        IF Type <> Type::Item THEN
          EXIT;

        IF (Quantity * xRec.Quantity > 0) AND
           ("No." = xRec."No.") AND
           ("Location Code" = xRec."Location Code") AND
           ("Variant Code" = xRec."Variant Code")
        THEN
          EXIT;

        "Bin Code" := '';
        IF "Drop Shipment" THEN
          EXIT;

        IF ("Location Code" <> '') AND ("No." <> '') THEN BEGIN
          GetLocation("Location Code");
          IF Location."Bin Mandatory" AND NOT Location."Directed Put-away and Pick" THEN
            WMSManagement.GetDefaultBin("No.","Variant Code","Location Code","Bin Code");
        END;
    end;
 
    procedure CrossReferenceNoLookUp()
    var
        ItemCrossReference: Record "5717";
    begin
        IF Type = Type::Item THEN BEGIN
          GetPurchHeader;
          ItemCrossReference.RESET;
          ItemCrossReference.SETCURRENTKEY("Cross-Reference Type","Cross-Reference Type No.");
          ItemCrossReference.SETFILTER(
            "Cross-Reference Type",'%1|%2',
            ItemCrossReference."Cross-Reference Type"::Vendor,
            ItemCrossReference."Cross-Reference Type"::" ");
          ItemCrossReference.SETFILTER("Cross-Reference Type No.",'%1|%2',PurchHeader."Buy-from Vendor No.",'');
          IF FORM.RUNMODAL(FORM::"Cross Reference List",ItemCrossReference) = ACTION::LookupOK THEN BEGIN
            VALIDATE("Cross-Reference No.",ItemCrossReference."Cross-Reference No.");
            PurchPriceCalcMgt.FindPurchLinePrice(PurchHeader,Rec,FIELDNO("Cross-Reference No."));
            PurchPriceCalcMgt.FindPurchLineLineDisc(PurchHeader,Rec);
            VALIDATE("Direct Unit Cost");
          END;
        END;
    end;
 
    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record "27";
    begin
        IF Type = Type::Item THEN
          IF NOT Item2.GET(ItemNo) THEN
            EXIT(FALSE);
        EXIT(TRUE);
    end;

    local procedure GetAbsMin(QtyToHandle: Decimal;QtyHandled: Decimal): Decimal
    begin
        IF ABS(QtyHandled) < ABS(QtyToHandle) THEN
          EXIT(QtyHandled)
        ELSE
          EXIT(QtyToHandle);
    end;

    local procedure CheckApplToItemLedgEntry(): Code[10]
    var
        ItemLedgEntry: Record "32";
        ApplyRec: Record "339";
        QtyBase: Decimal;
        RemainingQty: Decimal;
        ReturnedQty: Decimal;
        RemainingtobeReturnedQty: Decimal;
    begin
        IF "Appl.-to Item Entry" = 0 THEN
          EXIT;

        IF "Receipt No." <> '' THEN
          EXIT;

        TESTFIELD(Type,Type::Item);
        TESTFIELD(Quantity);
        IF Signed(Quantity) > 0 THEN
          TESTFIELD("Prod. Order No.",'');
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          IF Quantity < 0 THEN
            FIELDERROR(Quantity,Text029);
        END ELSE BEGIN
          IF Quantity > 0 THEN
            FIELDERROR(Quantity,Text030);
        END;
        ItemLedgEntry.GET("Appl.-to Item Entry");
        ItemLedgEntry.TESTFIELD(Positive,TRUE);

        ItemLedgEntry.TESTFIELD("Item No.","No.");
        ItemLedgEntry.TESTFIELD("Variant Code","Variant Code");
        CASE TRUE OF
          CurrFieldNo = Rec.FIELDNO(Quantity):
            QtyBase := "Quantity (Base)";
          "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]:
            QtyBase := "Return Qty. to Ship (Base)";
          ELSE BEGIN
            QtyBase := "Qty. to Receive (Base)";
            ItemLedgEntry.TESTFIELD(Open,TRUE);
          END;
        END;

        IF ABS(QtyBase) > ItemLedgEntry.Quantity THEN
          ERROR(
            Text042,
            ItemLedgEntry.Quantity,ItemLedgEntry.FIELDCAPTION("Document No."),
            ItemLedgEntry."Document No.");

        IF ABS(QtyBase) > ItemLedgEntry."Remaining Quantity" THEN BEGIN
          RemainingQty := ItemLedgEntry."Remaining Quantity";
          ReturnedQty := ApplyRec.Returned(ItemLedgEntry."Entry No.");
          RemainingtobeReturnedQty := ItemLedgEntry.Quantity - ReturnedQty;
          IF NOT ("Qty. per Unit of Measure" = 0) THEN BEGIN
            RemainingQty := ROUND(RemainingQty / "Qty. per Unit of Measure",0.00001);
            ReturnedQty :=  ROUND(ReturnedQty / "Qty. per Unit of Measure",0.00001);
            RemainingtobeReturnedQty :=  ROUND(RemainingtobeReturnedQty / "Qty. per Unit of Measure",0.00001);
          END;

          IF ("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND
             (RemainingtobeReturnedQty < ABS(QtyBase))
          THEN
            ERROR(
              Text035,
              ReturnedQty,ItemLedgEntry.FIELDCAPTION("Document No."),
              ItemLedgEntry."Document No.",RemainingtobeReturnedQty);
        END;

        EXIT(ItemLedgEntry."Location Code");
    end;
 
    procedure CalcPrepaymentToDeduct()
    begin
        IF (Quantity - "Quantity Invoiced") <> 0 THEN BEGIN
          GetPurchHeader;
          IF PurchHeader."Prices Including VAT" THEN
            "Prepmt Amt to Deduct" :=
              ROUND(
                ROUND(
                  ROUND(
                    ROUND("Direct Unit Cost" * "Qty. to Invoice",Currency."Amount Rounding Precision") *
                    (1 - ("Line Discount %" / 100)),Currency."Amount Rounding Precision") *
                  ("Prepayment %" / 100) / (1 + ("VAT %" / 100)),Currency."Amount Rounding Precision") *
                (1 + ("VAT %" / 100)),Currency."Amount Rounding Precision")
          ELSE
            "Prepmt Amt to Deduct" :=
              ROUND(
                ROUND(
                  ROUND("Direct Unit Cost" * "Qty. to Invoice",Currency."Amount Rounding Precision") *
                  (1 - ("Line Discount %" / 100)),Currency."Amount Rounding Precision") *
                "Prepayment %" / 100,Currency."Amount Rounding Precision")
        END ELSE
          "Prepmt Amt to Deduct" := 0
    end;
 
    procedure JobTaskIsSet(): Boolean
    begin
        EXIT(("Job No." <> '') AND ("Job Task No." <> '') AND (Type IN [Type::"G/L Account",Type::Item]));
    end;
 
    procedure CreateTempJobJnlLine(GetPrices: Boolean)
    begin
        GetPurchHeader;
        CLEAR(JobJnlLine);
        JobJnlLine.DontCheckStdCost;
        JobJnlLine.VALIDATE("Job No.","Job No.");
        JobJnlLine.VALIDATE("Job Task No.","Job Task No.");
        JobJnlLine.VALIDATE("Posting Date",PurchHeader."Posting Date");
        JobJnlLine.SetCurrencyFactor("Job Currency Factor");
        IF Type = Type::"G/L Account" THEN
          JobJnlLine.VALIDATE(Type,JobJnlLine.Type::"G/L Account")
        ELSE
          JobJnlLine.VALIDATE(Type,JobJnlLine.Type::Item);
        JobJnlLine.VALIDATE("No.","No.");
        JobJnlLine.VALIDATE("Variant Code","Variant Code");
        JobJnlLine.VALIDATE("Unit of Measure Code","Unit of Measure Code");
        JobJnlLine.VALIDATE(Quantity,Quantity);

        IF NOT GetPrices THEN BEGIN
          IF xRec.FIND THEN BEGIN
            JobJnlLine."Unit Cost (LCY)" := xRec."Unit Cost (LCY)";
            JobJnlLine."Unit Price" := xRec."Job Unit Price";
            JobJnlLine."Line Amount" := xRec."Job Line Amount";
            JobJnlLine."Line Discount %" := xRec."Job Line Discount %";
            JobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
          END ELSE BEGIN
            JobJnlLine."Unit Cost (LCY)" := "Unit Cost (LCY)";
            JobJnlLine."Unit Price" := "Job Unit Price";
            JobJnlLine."Line Amount" := "Job Line Amount";
            JobJnlLine."Line Discount %" := "Job Line Discount %";
            JobJnlLine."Line Discount Amount" := "Job Line Discount Amount";
          END;
          JobJnlLine.VALIDATE("Unit Price");
        END ELSE BEGIN
          JobJnlLine.VALIDATE("Unit Cost (LCY)","Unit Cost (LCY)");
        END;
    end;
 
    procedure UpdatePricesFromJobJnlLine()
    begin
        "Job Unit Price" := JobJnlLine."Unit Price";
        "Job Total Price" := JobJnlLine."Total Price";
        "Job Unit Price (LCY)" := JobJnlLine."Unit Price (LCY)";
        "Job Total Price (LCY)" := JobJnlLine."Total Price (LCY)";
        "Job Line Amount (LCY)" := JobJnlLine."Line Amount (LCY)";
        "Job Line Disc. Amount (LCY)" := JobJnlLine."Line Discount Amount (LCY)";
        "Job Line Amount" := JobJnlLine."Line Amount";
        "Job Line Discount %" := JobJnlLine."Line Discount %";
        "Job Line Discount Amount" := JobJnlLine."Line Discount Amount";
    end;
 
    procedure JobSetCurrencyFactor()
    begin
        GetPurchHeader;
        CLEAR(JobJnlLine);
        JobJnlLine.VALIDATE("Job No.","Job No.");
        JobJnlLine.VALIDATE("Job Task No.","Job Task No.");
        JobJnlLine.VALIDATE("Posting Date",PurchHeader."Posting Date");
        "Job Currency Factor" := JobJnlLine."Currency Factor";
    end;
 
    procedure SetUpdateFromVAT(UpdateFromVAT2: Boolean)
    begin
        UpdateFromVAT := UpdateFromVAT2;
    end;
 
    procedure InitQtyToReceive2()
    begin
        "Qty. to Receive" := "Outstanding Quantity";
        "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";

        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;

        CalcInvDiscToInvoice;

        CalcPrepaymentToDeduct;
    end;
 
    procedure ShowLineComments()
    var
        PurchCommentLine: Record "43";
        PurchCommentSheet: Form "66";
    begin
        TESTFIELD("Document No.");
        TESTFIELD("Line No.");
        PurchCommentLine.SETRANGE("Document Type","Document Type");
        PurchCommentLine.SETRANGE("No.","Document No.");
        PurchCommentLine.SETRANGE("Document Line No.","Line No.");
        PurchCommentSheet.SETTABLEVIEW(PurchCommentLine);
        PurchCommentSheet.RUNMODAL;
    end;
 
    procedure SetDefaultQuantity()
    var
        PurchSetup: Record "312";
    begin
        PurchSetup.GET;
        IF PurchSetup."Default Qty. to Ship/Rcv." = PurchSetup."Default Qty. to Ship/Rcv."::Blank THEN BEGIN
          IF ("Document Type" = "Document Type"::Order) OR ("Document Type" = "Document Type"::Quote) THEN BEGIN
            "Qty. to Receive" := 0;
            "Qty. to Receive (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
          END;
          IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
            "Return Qty. to Ship" := 0;
            "Return Qty. to Ship (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
          END;
        END;
    end;

    local procedure UpdatePrePaymentAmounts()
    var
        ReceiptLine: Record "121";
        PurchOrderLine: Record "39";
    begin
        IF NOT ReceiptLine.GET("Receipt No.","Receipt Line No.") THEN BEGIN
          "Prepmt Amt to Deduct" := 0;
          "Prepmt VAT Diff. to Deduct" := 0;
        END ELSE BEGIN
          IF PurchOrderLine.GET(PurchOrderLine."Document Type"::Order,ReceiptLine."Order No.",ReceiptLine."Order Line No.") THEN BEGIN
            "Prepmt Amt to Deduct" :=
              ROUND((PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted") *
                     Quantity / (PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced"),Currency."Amount Rounding Precision");
            "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
          END ELSE BEGIN
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
          END
        END;

        GetPurchHeader;
        IF PurchHeader."Prices Including VAT" THEN BEGIN
          "Prepmt. Line Amount" := ROUND("Prepmt Amt to Deduct" * (1 + ("Prepayment VAT %" / 100)),Currency."Amount Rounding Precision");
          "Prepmt. Amt. Incl. VAT" := "Prepmt. Line Amount";
        END ELSE BEGIN
          "Prepmt. Line Amount" := "Prepmt Amt to Deduct";
          "Prepmt. Amt. Incl. VAT" := ROUND("Prepmt Amt to Deduct" * (1 + ("Prepayment VAT %" / 100)),Currency."Amount Rounding Precision"
        );
        END;
        "Prepmt. Amt. Inv." := "Prepmt. Line Amount";
        "Prepayment Amount" := "Prepmt Amt to Deduct";
        "Prepmt. VAT Base Amt." := "Prepmt Amt to Deduct";
        "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Line Amount";
        "Prepmt Amt Deducted" := 0;
    end;
 
    procedure SetVendorItemNo()
    begin
        GetItem;
        ItemVend.INIT;
        ItemVend."Vendor No." := "Buy-from Vendor No.";
        ItemVend."Variant Code" := "Variant Code";
        Item.FindItemVend(ItemVend,"Location Code");
        VALIDATE("Vendor Item No.",ItemVend."Vendor Item No.");
    end;
 
    procedure ZeroAmountLine(QtyType: Option General,Invoicing,Shipping): Boolean
    begin
        IF Type = Type::" " THEN
          EXIT(TRUE);
        IF Quantity = 0 THEN
          EXIT(TRUE);
        IF ("Direct Unit Cost" = 0) OR ("Line Discount %" = 100) THEN
          EXIT(TRUE);
        IF QtyType = QtyType::Invoicing THEN
          IF "Qty. to Invoice" = 0 THEN
            EXIT(TRUE);
        EXIT(FALSE);
    end;
 
    procedure SetReleasedQuantity(PurchHeader: Record "38")
    var
        PurchLine: Record "39";
    begin
        //LS
        WITH PurchLine DO BEGIN
          SETRANGE("Document Type",PurchHeader."Document Type");
          SETRANGE("Document No.",PurchHeader."No.");
          IF FINDSET THEN
            REPEAT
              "Original Quantity" := Quantity;
              "Original Quantity (base)" := "Quantity (Base)";
              MODIFY;
            UNTIL NEXT = 0;
        END;
    end;
 
    procedure ShowLineBincodes()
    var
        DocumentBin: Record "50082";
        DocumentBinList: Form "50138";
    begin
        //APNT-T009914
        TESTFIELD(Barcode);
        TESTFIELD("Line No.");
        DocumentBin.SETRANGE(Type,DocumentBin.Type::GRN);
        DocumentBin.SETRANGE("Document Type",DocumentBin."Document Type"::Order);
        DocumentBin.SETRANGE("Document No.","Document No.");
        DocumentBin.SETRANGE("Document Line No.","Line No.");
        DocumentBin.SETRANGE("Barcode No.",Barcode);
        DocumentBin.SETRANGE("Location Code","Location Code");
        DocumentBinList.SETTABLEVIEW(DocumentBin);
        DocumentBinList.RUNMODAL;
        //APNT-T009914
    end;
 
    procedure DeleteBinDocs(PurchLine: Record "39")
    var
        RecDocumentBin: Record "50082";
    begin
        //APNT-T009914
        RecDocumentBin.RESET;
        RecDocumentBin.SETRANGE(Type,RecDocumentBin.Type::GRN);
        RecDocumentBin.SETRANGE("Document No.",PurchLine."Document No.");
        RecDocumentBin.SETRANGE("Barcode No.",Barcode);
        IF RecDocumentBin.FINDFIRST THEN
          RecDocumentBin.DELETEALL;
        //APNT-T009914
    end;
 
    procedure DiscardCarton()
    var
        Info: Dialog;
        BoxNo: Code[20];
        PurchLine: Record "39";
        HHTTransactions: Record "50035";
        Barcodes: Record "99001451";
        CDM: Codeunit "412";
        LogFileName: Text[250];
        LineNo: Integer;
        LogOpen: Integer;
        RemainingQty: Decimal;
        Window: Dialog;
        LogFile: File;
        CreatedHdr: Boolean;
        HHTTransactionList: Form "50086";
        HHTTransHdr: Record "50056";
    begin
        GetPurchHeader;
        PurchHeader.TESTFIELD(Status,PurchHeader.Status::Open);
        IF NOT CONFIRM('Do you want to Discard Carton No.?') THEN
          EXIT;

        PurchLine.RESET;
        PurchLine.SETRANGE("Document No.","Document No.");
        PurchLine.SETRANGE("Line No.","Line No.");
        IF PurchLine.FINDFIRST THEN BEGIN
          REPEAT
            HHTTransactions.RESET;
            HHTTransactions.SETRANGE("Transaction Type",'TRO');
            HHTTransactions.SETRANGE("Transaction No.","Document No.");
            HHTTransactions.SETRANGE(Closed,FALSE);
            HHTTransactions.SETRANGE("Box No.",PurchLine."Carton No.");
            HHTTransactions.SETRANGE(Discarded,FALSE);
            IF HHTTransactions.FINDFIRST THEN REPEAT
              HHTTransactions.Discarded := TRUE;
              HHTTransactions."Discarded By" := USERID;
              HHTTransactions."Discarded Date" := WORKDATE;
              HHTTransactions."Discarded Time" := TIME;
              HHTTransactions.MODIFY;
            UNTIL HHTTransactions.NEXT = 0;
            PurchLine.DELETE(TRUE);
          UNTIL PurchLine.NEXT = 0;
        END ELSE
          ERROR('Box No. %1 not found.',BoxNo);
    end;
}

