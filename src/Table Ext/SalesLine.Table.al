table 37 "Sales Line"
{
    // LS = changes made by LS Retail
    // Code          Date      Name            Description
    // APNT-1.0      11.08.10  Tanweer         Added field
    // APNT-1.0      06.08.11  Sangeeta        Added field
    // APNT-PL1.0    07.09.11  Magbul          Added field and Code for Packing List Customization
    //                                          Added Key No.17,18
    // APNT-1.0      15.11.11  Sangeeta        Added field 50006
    // APNT-HHT1.0   01.11.12  Sujith          Added code & fields for HHT Customization
    // DP = changes made by DVS
    // APNT-HRU1.0   23.12.13  Sangeeta        Added code for HRU Customization.
    // APNT-HRU1.0   29.01.14  Sangeeta        Added code for HRU Customization.
    // APNT-T003685  19.05.14  Ashish          Added code for HRU Cust.
    // T009525       30.12.14  Tanweer         Added Key No. 21 as per the request from Sandeep Patil
    // T006051       27.01.15  Sangeeta        Added code to validate dimension from location.
    // T006421       26.02.15  Tanweer         Removed 'SALE' Filter from "Pick Location" field as per the request from LG
    // T006051_1     28.06.15  Sangeeta        Added code to validate dimension from location.
    // APNT-BLDISC   13.10.15  Sangeeta        Added code for Block Discount Setup.
    // APNT-T009914  23.03.16  Sujith          Added code for Bin Ledger customization.
    // GC-LALS       05.09.19  Ganesh          validation added for transation posted in line discount filed
    // GC-LALS       15.09.19  Ganesh          validation added for "Qty to ship  " in transation posted docuemetns
    // APNT-T030380  05Jan20   Ajay            Changes for CRF_19_0247 - 106924 - Palms- Cancellation Marker.
    // 20200214      14-Feb-20 KPS             Code added in "Quantity - OnValidate()"
    // APNT-eCom     17.12.20  Sujith          Added code eCom integration
    // eCom-CR       25.02.21  Sujith          Added field for eCommerce integration CR

    Caption = 'Sales Line';
    DrillDownFormID = Form516;
    LookupFormID = Form516;
    PasteIsValid = false;

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
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header".No. WHERE(Document Type=FIELD(Document Type));
        }
        field(4;"Line No.";Integer)
        {
            Caption = 'Line No.';
        }
        field(5;Type;Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";

            trigger OnValidate()
            begin
                TestJobPlanningLine;
                TestStatusOpen;
                GetSalesHeader;

                TESTFIELD("Qty. Shipped Not Invoiced",0);
                TESTFIELD("Quantity Shipped",0);
                TESTFIELD("Shipment No.",'');

                TESTFIELD("Return Qty. Rcd. Not Invd.",0);
                TESTFIELD("Return Qty. Received",0);
                TESTFIELD("Return Receipt No.",'');

                TESTFIELD("Prepmt. Amt. Inv.",0);

                CheckAssocPurchOrder(FIELDCAPTION(Type));

                IF Type <> xRec.Type THEN BEGIN
                  IF Quantity <> 0 THEN BEGIN
                    CALCFIELDS("Reserved Qty. (Base)");
                    TESTFIELD("Reserved Qty. (Base)",0);
                    ReserveSalesLine.VerifyChange(Rec,xRec);
                    WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                  END;
                  IF xRec.Type IN [Type::Item,Type::"Fixed Asset"] THEN BEGIN
                    IF Quantity <> 0 THEN
                      SalesHeader.TESTFIELD(Status,SalesHeader.Status::Open);
                    DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");
                  END;
                  IF xRec.Type = Type::"Charge (Item)" THEN
                    DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");
                END;
                AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);
                TempSalesLine := Rec;
                DimMgt.DeleteDocDim(DATABASE::"Sales Line","Document Type","Document No.","Line No.");
                INIT;
                Type := TempSalesLine.Type;
                "System-Created Entry" := TempSalesLine."System-Created Entry";

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
                            ELSE IF (Type=CONST(Resource)) Resource
                            ELSE IF (Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Type=CONST("Charge (Item)")) "Item Charge";

            trigger OnValidate()
            var
                ICPartner: Record "413";
                ItemCrossReference: Record "5717";
                PrepaymentMgt: Codeunit "441";
                ItemRec: Record "27";
            begin
                TestJobPlanningLine;
                TestStatusOpen;
                CheckItemAvailable(FIELDNO("No."));

                CheckWMSExported;  //APNT-T030380

                IF (xRec."No." <> "No.") AND (Quantity <> 0) THEN BEGIN
                  CALCFIELDS("Reserved Qty. (Base)");
                  TESTFIELD("Reserved Qty. (Base)",0);
                  IF Type = Type::Item THEN
                    WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                END;
                TESTFIELD("Qty. Shipped Not Invoiced",0);
                TESTFIELD("Quantity Shipped",0);
                TESTFIELD("Shipment No.",'');

                TESTFIELD("Prepmt. Amt. Inv.",0);

                TESTFIELD("Return Qty. Rcd. Not Invd.",0);
                TESTFIELD("Return Qty. Received",0);
                TESTFIELD("Return Receipt No.",'');

                CheckAssocPurchOrder(FIELDCAPTION("No."));
                AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);
                TempSalesLine := Rec;
                INIT;
                Type := TempSalesLine.Type;
                "No." := TempSalesLine."No.";
                //APNT-HRU2.0
                IF SalesHeader."HRU Document" THEN
                  VALIDATE("Delivery Method","Delivery Method"::Showroom);
                //APNT-HRU2.0
                IF "No." = '' THEN
                  EXIT;
                IF Type <> Type::" " THEN
                  Quantity := TempSalesLine.Quantity;

                "System-Created Entry" := TempSalesLine."System-Created Entry";
                GetSalesHeader;
                IF SalesHeader."Document Type" = SalesHeader."Document Type"::Quote THEN BEGIN
                  IF (SalesHeader."Sell-to Customer No." = '') AND
                     (SalesHeader."Sell-to Customer Template Code" = '')
                  THEN
                    ERROR(
                      Text031,
                      SalesHeader.FIELDCAPTION("Sell-to Customer No."),
                      SalesHeader.FIELDCAPTION("Sell-to Customer Template Code"));
                  IF (SalesHeader."Bill-to Customer No." = '') AND
                     (SalesHeader."Bill-to Customer Template Code" = '')
                  THEN
                    ERROR(
                      Text031,
                      SalesHeader.FIELDCAPTION("Bill-to Customer No."),
                      SalesHeader.FIELDCAPTION("Bill-to Customer Template Code"));
                END ELSE
                  SalesHeader.TESTFIELD("Sell-to Customer No.");

                "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                "Currency Code" := SalesHeader."Currency Code";
                //LS -
                "Location Code" := SalesHeader."Location Code";
                //VALIDATE("Location Code", SalesHeader."Location Code");
                "Retail Special Order" := SalesHeader."Retail Special Order";
                //LS +
                "Customer Price Group" := SalesHeader."Customer Price Group";
                "Customer Disc. Group" := SalesHeader."Customer Disc. Group";
                "Allow Line Disc." := SalesHeader."Allow Line Disc.";
                "Transaction Type" := SalesHeader."Transaction Type";
                "Transport Method" := SalesHeader."Transport Method";
                "Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
                "Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";
                "Exit Point" := SalesHeader."Exit Point";
                Area := SalesHeader.Area;
                "Transaction Specification" := SalesHeader."Transaction Specification";
                "Tax Area Code" := SalesHeader."Tax Area Code";
                "Tax Liable" := SalesHeader."Tax Liable";
                IF NOT "System-Created Entry" AND ("Document Type" = "Document Type"::Order) AND (Type <> Type::" ") THEN
                  "Prepayment %" := SalesHeader."Prepayment %";
                "Prepayment Tax Area Code" := SalesHeader."Tax Area Code";
                "Prepayment Tax Liable" := SalesHeader."Tax Liable";
                "Responsibility Center" := SalesHeader."Responsibility Center";

                "Shipping Agent Code" := SalesHeader."Shipping Agent Code";
                "Shipping Agent Service Code" := SalesHeader."Shipping Agent Service Code";
                "Outbound Whse. Handling Time" := SalesHeader."Outbound Whse. Handling Time";
                "Shipping Time" := SalesHeader."Shipping Time";
                CALCFIELDS("Substitution Available");

                "Promised Delivery Date" := SalesHeader."Promised Delivery Date";
                "Requested Delivery Date" := SalesHeader."Requested Delivery Date";
                "Shipment Date" :=
                  CalendarMgmt.CalcDateBOC(
                    '',
                    SalesHeader."Shipment Date",
                    CalChange."Source Type"::Location,
                    "Location Code",
                    '',
                    CalChange."Source Type"::"Shipping Agent",
                    "Shipping Agent Code",
                    "Shipping Agent Service Code",
                    FALSE);
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
                      //LS -
                      IF ("No." <> xRec."No.") AND (xRec."No." <> '') THEN BEGIN
                        DeleteSPOLines;
                      END;
                      //LS  +
                      GetItem;
                      Item.TESTFIELD(Blocked,FALSE);
                      Item.TESTFIELD("Inventory Posting Group");
                      Item.TESTFIELD("Gen. Prod. Posting Group");

                      "Posting Group" := Item."Inventory Posting Group";
                      Description := Item.Description;
                      "Description 2" := Item."Description 2";
                      GetUnitCost;
                      "Allow Invoice Disc." := Item."Allow Invoice Disc.";
                      "Units per Parcel" := Item."Units per Parcel";
                      "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                      //APNT-HRU1.0 -
                      InvtSetup.GET;
                      IF SalesHeader."HRU Document" THEN
                        "Gen. Prod. Posting Group" := InvtSetup."Rev. Gen. Prod. Posting Group";
                      //APNT-HRU1.0 +
                      "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                      "Tax Group Code" := Item."Tax Group Code";
                      Division := Item."Division Code";  //LS
                      "Item Category Code" := Item."Item Category Code";
                      "Product Group Code" := Item."Product Group Code";
                      Nonstock := Item."Created From Nonstock Item";
                      "Profit %" := Item."Profit %";
                      "Allow Item Charge Assignment" := TRUE;
                      PrepaymentMgt.SetSalesPrepaymentPct(Rec,SalesHeader."Posting Date");

                      IF SalesHeader."Language Code" <> '' THEN
                        GetItemTranslation;

                      IF Item.Reserve = Item.Reserve::Optional THEN
                        Reserve := SalesHeader.Reserve
                      ELSE
                        Reserve := Item.Reserve;

                      //APNT-1.0
                      //"Unit of Measure Code" := Item."Sales Unit of Measure";
                      IF Barcode = '' THEN
                        Barcode := Item.DefaultBarcode;
                      IF Barcode <> '' THEN BEGIN
                        Barcodes.GET(Barcode);
                        "Unit of Measure Code" := Barcodes."Unit of Measure Code";
                      END ELSE
                        "Unit of Measure Code" := Item."Sales Unit of Measure";
                      //APNT-1.0
                    END;
                  Type::Resource:
                    BEGIN
                      Res.GET("No.");
                      Res.TESTFIELD(Blocked,FALSE);
                      Res.TESTFIELD("Gen. Prod. Posting Group");
                      Description := Res.Name;
                      "Description 2" := Res."Name 2";
                      "Unit of Measure Code" := Res."Base Unit of Measure";
                      "Unit Cost (LCY)" := Res."Unit Cost";
                      "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
                      "VAT Prod. Posting Group" := Res."VAT Prod. Posting Group";
                      "Tax Group Code" := Res."Tax Group Code";
                      "Allow Item Charge Assignment" := FALSE;
                      FindResUnitCost;
                    END;
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
                    END;
                END;

                VALIDATE("Prepayment %");

                IF Type <> Type::" " THEN BEGIN
                  IF Type <> Type::"Fixed Asset" THEN
                    VALIDATE("VAT Prod. Posting Group");
                  VALIDATE("Unit of Measure Code");
                  IF Quantity <> 0 THEN BEGIN
                    InitOutstanding;
                    IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
                      InitQtyToReceive
                    ELSE
                      InitQtyToShip;
                    UpdateWithWarehouseShip;
                  END;
                  UpdateUnitPrice(FIELDNO("No."));
                END;

                IF "No." <> xRec."No." THEN BEGIN
                  IF Type = Type::Item THEN
                    IF (Quantity <> 0) AND ItemExists(xRec."No.") THEN BEGIN
                      ReserveSalesLine.VerifyChange(Rec,xRec);
                      WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                    END;
                  DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");
                  IF Type = Type::"Charge (Item)" THEN
                    DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");
                END;

                CreateDim(
                  DimMgt.TypeToTableID3(Type),"No.",
                  DATABASE::Job,"Job No.",
                  DATABASE::"Responsibility Center","Responsibility Center");
                GetItemCrossRef(FIELDNO("No."));

                GetDefaultBin;

                SalesHeader.GET("Document Type","Document No.");
                IF SalesHeader."Bill-to IC Partner Code" <> '' THEN
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
                        IF SalesHeader."Sell-to IC Partner Code" <> '' THEN
                          ICPartner.GET(SalesHeader."Sell-to IC Partner Code")
                        ELSE
                          ICPartner.GET(SalesHeader."Bill-to IC Partner Code");
                        CASE ICPartner."Outbound Sales Item No. Type" OF
                          ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                            VALIDATE("IC Partner Ref. Type","IC Partner Ref. Type"::"Common Item No.");
                          ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                            BEGIN
                              "IC Partner Ref. Type" := "IC Partner Ref. Type"::Item;
                              "IC Partner Reference" := "No.";
                            END;
                          ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                            BEGIN
                              VALIDATE("IC Partner Ref. Type","IC Partner Ref. Type"::"Cross Reference");
                              ItemCrossReference.SETRANGE("Cross-Reference Type",
                                ItemCrossReference."Cross-Reference Type"::Customer);
                              ItemCrossReference.SETRANGE("Cross-Reference Type No.",
                                "Sell-to Customer No.");
                              ItemCrossReference.SETRANGE("Item No.","No.");
                              IF ItemCrossReference.FINDFIRST THEN
                                "IC Partner Reference" := ItemCrossReference."Cross-Reference No.";
                            END;
                        END;
                      END;
                    Type::"Fixed Asset":
                      BEGIN
                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                        "IC Partner Reference" := '';
                      END;
                    Type::Resource:
                      BEGIN
                        Resource.GET("No.");
                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                        "IC Partner Reference" := Resource."IC Partner Purch. G/L Acc. No.";
                      END;
                  END;

                //APNT-1.0
                IF ItemRec.GET("No.") THEN
                  Packing := ItemRec.Packing;
                //APNT-1.0
            end;
        }
        field(7;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE (Use As In-Transit=CONST(No));

            trigger OnLookup()
            var
                lSalesHeader: Record "36";
                lBOUtils: Codeunit "99001452";
                tmpCode: Code[10];
            begin
                //LS -
                IF lSalesHeader.GET("Document Type", "Document No.") THEN BEGIN
                  tmpCode := lBOUtils.LookupLocation(lSalesHeader."Store No.", "Location Code");
                  IF (xRec."Location Code" <> tmpCode) AND (tmpCode <> '') THEN
                    VALIDATE("Location Code", tmpCode);
                END;
                //LS +
            end;

            trigger OnValidate()
            var
                lBOUtils: Codeunit "99001452";
                lStoreLocation: Record "10001416";
                lSpecialOrderUtils: Codeunit "10012702";
                LocationRec: Record "14";
                GLSetup: Record "98";
                DefaultDimension: Record "352";
                SalesLine: Record "37";
            begin
                TestJobPlanningLine;
                TestStatusOpen;
                CheckAssocPurchOrder(FIELDCAPTION("Location Code"));

                IF xRec."Location Code" <> "Location Code" THEN BEGIN
                  TESTFIELD("Reserved Quantity",0);
                  TESTFIELD("Qty. Shipped Not Invoiced",0);
                  TESTFIELD("Shipment No.",'');
                  TESTFIELD("Return Qty. Rcd. Not Invd.",0);
                  TESTFIELD("Return Receipt No.",'');
                END;

                GetSalesHeader;
                //LS -
                //APNT-HRU1.0 -
                IF SalesHeader."HRU Document" = FALSE THEN
                //APNT-HRU1.0 +
                  lBOUtils.StoreLocationOk(SalesHeader."Store No.", "Location Code");
                //LS +

                //LS -
                IF lStoreLocation.GET(SalesHeader."Store No.","Location Code") THEN
                  "Retail Special Order" := lStoreLocation."Special Order Location"
                ELSE
                  "Retail Special Order" := FALSE;

                IF "Retail Special Order" AND (Type = Type::Item) THEN
                  IF NOT(lSpecialOrderUtils.DefaultSPOFieldValuesSalesLine(Rec,SalesHeader,"Location Code",FALSE)) THEN
                    MESSAGE(LSText04,SalesHeader."Store No.");
                //LS +

                "Shipment Date" :=
                  CalendarMgmt.CalcDateBOC(
                    '',
                    SalesHeader."Shipment Date",
                    CalChange."Source Type"::Location,
                    "Location Code",
                    '',
                    CalChange."Source Type"::"Shipping Agent",
                    "Shipping Agent Code",
                    "Shipping Agent Service Code",
                    FALSE);

                IF Reserve <> Reserve::Always THEN
                  CheckItemAvailable(FIELDNO("Location Code"));

                IF NOT "Drop Shipment" THEN BEGIN
                  IF "Location Code" = '' THEN BEGIN
                    IF InvtSetup.GET THEN
                      "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                  END ELSE
                    IF Location.GET("Location Code") THEN
                      "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                END ELSE
                  EVALUATE("Outbound Whse. Handling Time",'<0D>');

                UpdateDates;

                IF "Location Code" <> xRec."Location Code" THEN BEGIN
                  InitItemAppl(TRUE);
                  "Bin Code" := '';
                  GetDefaultBin;
                  IF Quantity <> 0 THEN BEGIN
                    IF NOT "Drop Shipment" THEN
                      UpdateWithWarehouseShip;
                    ReserveSalesLine.VerifyChange(Rec,xRec);
                    WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                  END;
                END;

                IF Type = Type::Item THEN
                  GetUnitCost;

                //APNT-HRU1.0 -
                IF "Line No." <> 0 THEN
                  "Pick Location" := "Location Code";
                //APNT-HRU1.0 +

                //APNT-T006051 -
                IF SalesLine.GET("Document Type","Document No.","Line No.") THEN BEGIN
                  IF ("Sell-to Customer No." <> '') AND ("Line No." <> 0) THEN BEGIN
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
                END;
                //APNT-T006051 +
            end;
        }
        field(8;"Posting Group";Code[10])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type=CONST(Item)) "Inventory Posting Group"
                            ELSE IF (Type=CONST(Fixed Asset)) "FA Posting Group";
        }
        field(10;"Shipment Date";Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "99000815";
            begin
                TestStatusOpen;
                IF CurrFieldNo <> 0 THEN
                  AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);

                IF "Shipment Date" <> 0D THEN BEGIN
                  IF Reserve <> Reserve::Always THEN
                    IF CurrFieldNo IN [
                                       FIELDNO("Planned Shipment Date"),
                                       FIELDNO("Planned Delivery Date"),
                                       FIELDNO("Shipment Date"),
                                       FIELDNO("Shipping Time"),
                                       FIELDNO("Outbound Whse. Handling Time"),
                                       FIELDNO("Requested Delivery Date")]
                    THEN
                      CheckItemAvailable(FIELDNO("Shipment Date"));

                  IF ("Shipment Date" < WORKDATE) AND (Type <> Type::" ") THEN
                    IF NOT (HideValidationDialog OR HasBeenShown) AND GUIALLOWED THEN BEGIN
                      MESSAGE(
                        Text014,
                        FIELDCAPTION("Shipment Date"),"Shipment Date",WORKDATE);
                      HasBeenShown := TRUE;
                    END;
                END;

                IF (xRec."Shipment Date" <> "Shipment Date") AND
                   (Quantity <> 0) AND
                   (Reserve <> Reserve::Never) AND
                   NOT StatusCheckSuspended
                THEN
                  CheckDateConflict.SalesLineCheck(Rec,CurrFieldNo <> 0);

                IF "Shipment Date" <> 0D THEN BEGIN
                  IF NOT PlannedShipmentDateCalculated THEN
                    "Planned Shipment Date" :=
                      CalendarMgmt.CalcDateBOC(
                        FORMAT(
                          "Outbound Whse. Handling Time"),
                        "Shipment Date",
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        CalChange."Source Type"::Location,
                        "Location Code",
                        '',
                        TRUE);
                  IF NOT PlannedDeliveryDateCalculated THEN
                    "Planned Delivery Date" :=
                      CalendarMgmt.CalcDateBOC(
                        FORMAT("Shipping Time"),
                        "Planned Shipment Date",
                        CalChange."Source Type"::Customer,
                        "Sell-to Customer No.",
                        '',
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        TRUE);
                END;
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
                ItemLedgEntry: Record "32";
                lSPOUtil: Codeunit "10012702";
                lSalesLine: Record "37" temporary;
            begin
                TestStatusOpen;

                CheckAssocPurchOrder(FIELDCAPTION(Quantity));

                //APNT-T030380
                IF (Quantity <> xRec.Quantity) AND (xRec.Quantity <> 0) THEN
                  IF NOT SalesHeader."HRU Document" THEN  // 20200214 Added by KPS on 14-Feb-2020
                    CheckWMSExported;
                //APNT-T030380

                "Quantity (Base)" := CalcBaseQty(Quantity);

                IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
                  IF (Quantity * "Return Qty. Received" < 0) OR
                     ((ABS(Quantity) < ABS("Return Qty. Received")) AND ("Return Receipt No." = '')) THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text003,FIELDCAPTION("Return Qty. Received")));
                  IF ("Quantity (Base)" * "Return Qty. Received (Base)" < 0) OR
                     ((ABS("Quantity (Base)") < ABS("Return Qty. Received (Base)")) AND ("Return Receipt No." = ''))
                  THEN
                    FIELDERROR("Quantity (Base)",STRSUBSTNO(Text003,FIELDCAPTION("Return Qty. Received (Base)")));
                END ELSE BEGIN
                  IF (Quantity * "Quantity Shipped" < 0) OR
                     ((ABS(Quantity) < ABS("Quantity Shipped")) AND ("Shipment No." = ''))
                  THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text003,FIELDCAPTION("Quantity Shipped")));
                  IF ("Quantity (Base)" * "Qty. Shipped (Base)" < 0) OR
                     ((ABS("Quantity (Base)") < ABS("Qty. Shipped (Base)")) AND ("Shipment No." = ''))
                  THEN
                    FIELDERROR("Quantity (Base)",STRSUBSTNO(Text003,FIELDCAPTION("Qty. Shipped (Base)")));
                END;

                IF (Type = Type::"Charge (Item)") AND (CurrFieldNo <> 0) THEN BEGIN
                  IF ((Quantity = 0) AND ("Qty. to Assign" <> 0)) THEN
                    FIELDERROR("Qty. to Assign",STRSUBSTNO(Text009,FIELDCAPTION(Quantity),Quantity));
                  IF (Quantity * "Qty. Assigned" < 0) OR (ABS(Quantity) < ABS("Qty. Assigned")) THEN
                    FIELDERROR(Quantity,STRSUBSTNO(Text003,FIELDCAPTION("Qty. Assigned")));
                END;

                AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);
                IF (xRec.Quantity <> Quantity) OR (xRec."Quantity (Base)" <> "Quantity (Base)") THEN BEGIN
                  InitOutstanding;
                  IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
                    InitQtyToReceive
                  ELSE
                    InitQtyToShip;
                END;
                IF Reserve <> Reserve::Always THEN
                  CheckItemAvailable(FIELDNO(Quantity));
                IF (Quantity * xRec.Quantity < 0) OR (Quantity = 0) THEN
                  InitItemAppl(FALSE);

                IF Type = Type::Item THEN BEGIN
                  UpdateUnitPrice(FIELDNO(Quantity));
                  IF (xRec.Quantity <> Quantity) OR (xRec."Quantity (Base)" <> "Quantity (Base)") THEN BEGIN
                    ReserveSalesLine.VerifyQuantity(Rec,xRec);
                    IF NOT "Drop Shipment" THEN
                      UpdateWithWarehouseShip;
                    WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                    IF ("Quantity (Base)" * xRec."Quantity (Base)" <= 0) AND ("No." <> '') THEN BEGIN
                      GetItem;
                      IF (Item."Costing Method" = Item."Costing Method"::Standard) AND NOT IsShipment THEN
                        GetUnitCost;
                    END;
                  END;
                  IF (Quantity = "Quantity Invoiced") AND (CurrFieldNo <> 0) THEN
                    CheckItemChargeAssgnt;
                  CheckApplFromItemLedgEntry(ItemLedgEntry);
                END ELSE
                  VALIDATE("Line Discount %");

                IF (xRec.Quantity <> Quantity) AND (Quantity = 0) AND
                   ((Amount <> 0) OR ("Amount Including VAT" <> 0) OR ("VAT Base Amount" <> 0))
                THEN BEGIN
                  Amount := 0;
                  "Amount Including VAT" := 0;
                  "VAT Base Amount" := 0;
                END;
                SetDefaultQuantity;

                //LS -
                IF (Quantity <> xRec.Quantity) AND "Retail Special Order" AND (Type = Type::Item) THEN BEGIN
                  lSalesLine := Rec;
                  IF lSPOUtil.DefaultSPOFieldValuesSalesLine(lSalesLine,SalesHeader,"Store Sales Location",FALSE) THEN BEGIN
                    "Payment-At Order Entry-Limit" := lSalesLine."Payment-At Order Entry-Limit";
                    "Payment-At Delivery-Limit" := lSalesLine."Payment-At Delivery-Limit";
                    "Payment-At PurchaseOrder-Limit" := lSalesLine."Payment-At PurchaseOrder-Limit";
                    "Return Policy" := lSalesLine."Return Policy";
                    "Non Refund Amount" := lSalesLine."Non Refund Amount";
                  END
                  ELSE
                    MESSAGE(LSText04,SalesHeader."Store No.");
                END;
                //LS +

                IF ("Document Type" = "Document Type"::Invoice) AND ("Prepayment %" <> 0) THEN
                  UpdatePrePaymentAmounts;


                //GC150919++
                RecComp.GET;
                IF RecComp.Name = 'Homes R Us Trading LLC' THEN
                BEGIN
                  CLEAR(SalesHeaderNew);
                  IF SalesHeaderNew.GET("Document Type","Document No.") THEN
                  BEGIN
                    IF (SalesHeaderNew."HRU Document") AND SalesHeaderNew."Transaction Posted" THEN
                        VALIDATE("Qty. to Ship",0);
                  END;
                END;
                //GC150919--
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
                IF ("Qty. to Invoice" * Quantity < 0) OR
                   (ABS("Qty. to Invoice") > ABS(MaxQtyToInvoice))
                THEN
                  ERROR(
                    Text005,
                    MaxQtyToInvoice);
                IF ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) OR
                   (ABS("Qty. to Invoice (Base)") > ABS(MaxQtyToInvoiceBase))
                THEN
                  ERROR(
                    Text006,
                    MaxQtyToInvoiceBase);
                "VAT Difference" := 0;
                CalcInvDiscToInvoice;
                CalcPrepaymentToDeduct;
            end;
        }
        field(18;"Qty. to Ship";Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "32";
            begin
                IF (CurrFieldNo <> 0) AND
                   (Type = Type::Item) AND
                   ("Qty. to Ship" <> 0) AND
                   (NOT "Drop Shipment")
                THEN
                  CheckWarehouse;

                IF "Qty. to Ship" = "Outstanding Quantity" THEN
                  InitQtyToShip
                ELSE BEGIN
                  "Qty. to Ship (Base)" := CalcBaseQty("Qty. to Ship");
                  CheckServItemCreation;
                  InitQtyToInvoice;
                END;
                IF ("Qty. to Ship" * Quantity < 0) OR
                   (ABS("Qty. to Ship") > ABS("Outstanding Quantity")) OR
                   (Quantity * "Outstanding Quantity" < 0)
                THEN
                  ERROR(
                    Text007,
                    "Outstanding Quantity");
                IF ("Qty. to Ship (Base)" * "Quantity (Base)" < 0) OR
                   (ABS("Qty. to Ship (Base)") > ABS("Outstanding Qty. (Base)")) OR
                   ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                THEN
                  ERROR(
                    Text008,
                    "Outstanding Qty. (Base)");

                IF (CurrFieldNo <> 0) AND (Type = Type::Item) AND ("Qty. to Ship" < 0) THEN
                  CheckApplFromItemLedgEntry(ItemLedgEntry);
            end;
        }
        field(22;"Unit Price";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FIELDNO("Unit Price"));
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                TestStatusOpen;
                VALIDATE("Line Discount %");
            end;
        }
        field(23;"Unit Cost (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            begin
                IF "Unit Cost (LCY)" <> xRec."Unit Cost (LCY)" THEN
                  CheckAssocPurchOrder(FIELDCAPTION("Unit Cost (LCY)"));

                IF (CurrFieldNo = FIELDNO("Unit Cost (LCY)")) AND
                   (Type = Type::Item) AND ("No." <> '') AND ("Quantity (Base)" <> 0)
                THEN BEGIN
                  GetItem;
                  IF (Item."Costing Method" = Item."Costing Method"::Standard) AND NOT IsShipment THEN BEGIN
                    IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
                      ERROR(
                        Text037,
                        FIELDCAPTION("Unit Cost (LCY)"),Item.FIELDCAPTION("Costing Method"),
                        Item."Costing Method",FIELDCAPTION(Quantity));
                    ERROR(
                      Text038,
                      FIELDCAPTION("Unit Cost (LCY)"),Item.FIELDCAPTION("Costing Method"),
                      Item."Costing Method",FIELDCAPTION(Quantity));
                  END;
                END;

                GetSalesHeader;
                IF SalesHeader."Currency Code" <> '' THEN BEGIN
                  Currency.TESTFIELD("Unit-Amount Rounding Precision");
                  "Unit Cost" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        GetDate,SalesHeader."Currency Code",
                        "Unit Cost (LCY)",SalesHeader."Currency Factor"),
                      Currency."Unit-Amount Rounding Precision")
                END ELSE
                  "Unit Cost" := "Unit Cost (LCY)";
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
            var
                SalesSetup: Record "311";
            begin
                TestStatusOpen;
                //APNT-BLDISC -
                IF ("Line Discount %" <> 0) OR ("Line Discount Amount" <> 0) THEN BEGIN
                  SalesSetup.GET;
                  IF SalesSetup."Block Line Discount" THEN BEGIN
                    Item.GET("No.");
                    //GC-050919++
                    //Item.TESTFIELD("No Discount Allowed",FALSE);
                    CLEAR(RecSH);
                    IF RecSH.GET("Document Type","Document No.") THEN
                    BEGIN
                      RecComp.GET;
                      IF RecComp.Name = 'Homes R Us Trading LLC' THEN BEGIN
                        IF NOT RecSH."eCOM Order" THEN BEGIN //APNT-eCom
                          IF NOT RecSH."Transaction Posted" THEN
                           Item.TESTFIELD("No Discount Allowed",FALSE);
                        END;
                      END;
                    END;
                      //gc050919---
                  END;
                END;
                //APNT-BLDISC +
                "Line Discount Amount" :=
                  ROUND(
                    ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") *
                    "Line Discount %" / 100,Currency."Amount Rounding Precision");
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts;

                "Offer No." := '';  //LS
            end;
        }
        field(28;"Line Discount Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            var
                SalesSetup: Record "311";
                SalesHeader: Record "36";
            begin
                TestStatusOpen;
                TESTFIELD(Quantity);
                //APNT-BLDISC -
                IF ("Line Discount Amount" <> 0) OR ("Line Discount %" <> 0) THEN BEGIN
                  SalesSetup.GET;
                  IF SalesSetup."Block Line Discount" THEN BEGIN
                    //APNT-eCom
                    CLEAR(SalesHeader);
                    IF SalesHeader.GET("Document Type","Document No.") THEN BEGIN
                      IF NOT SalesHeader."eCOM Order" THEN BEGIN
                    //APNT-eCom
                        Item.GET("No.");
                        Item.TESTFIELD("No Discount Allowed",FALSE);
                      END;
                    END;
                  END;
                END;
                //APNT-BLDISC +
                IF ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") <> 0 THEN
                  "Line Discount %" :=
                    ROUND(
                      "Line Discount Amount" / ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") * 100,
                      0.00001)
                ELSE
                  "Line Discount %" := 0;
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts;
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
                Amount := ROUND(Amount,Currency."Amount Rounding Precision");
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      "VAT Base Amount" :=
                        ROUND(Amount * (1 - SalesHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                      "Amount Including VAT" :=
                        ROUND(Amount + "VAT Base Amount" * "VAT %" / 100,Currency."Amount Rounding Precision");
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    IF Amount <> 0 THEN
                      FIELDERROR(Amount,
                        STRSUBSTNO(
                          Text009,FIELDCAPTION("VAT Calculation Type"),
                          "VAT Calculation Type"));
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      SalesHeader.TESTFIELD("VAT Base Discount %",0);
                      "VAT Base Amount" := ROUND(Amount,Currency."Amount Rounding Precision");
                      "Amount Including VAT" :=
                        Amount +
                        SalesTaxCalculate.CalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable",SalesHeader."Posting Date",
                          "VAT Base Amount","Quantity (Base)",SalesHeader."Currency Factor");
                      IF "VAT Base Amount" <> 0 THEN
                        "VAT %" :=
                          ROUND(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount",0.00001)
                      ELSE
                        "VAT %" := 0;
                      "Amount Including VAT" := ROUND("Amount Including VAT",Currency."Amount Rounding Precision");
                    END;
                END;

                InitOutstandingAmount;
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
                "Amount Including VAT" := ROUND("Amount Including VAT",Currency."Amount Rounding Precision");
                CASE "VAT Calculation Type" OF
                  "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                    BEGIN
                      Amount :=
                        ROUND(
                          "Amount Including VAT" /
                          (1 + (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                          Currency."Amount Rounding Precision");
                      "VAT Base Amount" :=
                        ROUND(Amount * (1 - SalesHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                    END;
                  "VAT Calculation Type"::"Full VAT":
                    BEGIN
                      Amount := 0;
                      "VAT Base Amount" := 0;
                    END;
                  "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                      SalesHeader.TESTFIELD("VAT Base Discount %",0);
                      Amount :=
                        SalesTaxCalculate.ReverseCalculateTax(
                          "Tax Area Code","Tax Group Code","Tax Liable",SalesHeader."Posting Date",
                          "Amount Including VAT","Quantity (Base)",SalesHeader."Currency Factor");
                      IF Amount <> 0 THEN
                        "VAT %" :=
                          ROUND(100 * ("Amount Including VAT" - Amount) / Amount,0.00001)
                      ELSE
                        "VAT %" := 0;
                      Amount := ROUND(Amount,Currency."Amount Rounding Precision");
                      "VAT Base Amount" := Amount;
                    END;
                END;

                InitOutstandingAmount;
            end;
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
                SelectItemEntry(FIELDNO("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "32";
            begin
                IF "Appl.-to Item Entry" <> 0 THEN BEGIN
                  AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);

                  TESTFIELD(Type,Type::Item);
                  TESTFIELD(Quantity);
                  IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
                    IF Quantity > 0 THEN
                      FIELDERROR(Quantity,Text030);
                  END ELSE BEGIN
                    IF Quantity < 0 THEN
                      FIELDERROR(Quantity,Text029);
                  END;
                  ItemLedgEntry.GET("Appl.-to Item Entry");
                  ItemLedgEntry.TESTFIELD(Positive,TRUE);
                  VALIDATE("Unit Cost (LCY)",CalcUnitCost(ItemLedgEntry));

                  "Location Code" := ItemLedgEntry."Location Code";
                  IF NOT ItemLedgEntry.Open THEN MESSAGE(Text042,"Appl.-to Item Entry");
                END;
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
        field(42;"Customer Price Group";Code[10])
        {
            Caption = 'Customer Price Group';
            Editable = false;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                IF Type = Type::Item THEN
                  UpdateUnitPrice(FIELDNO("Customer Price Group"));
            end;
        }
        field(45;"Job No.";Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;
        }
        field(52;"Work Type Code";Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            begin
                IF Type = Type::Resource THEN BEGIN
                  TestStatusOpen;
                  IF WorkType.GET("Work Type Code") THEN
                    VALIDATE("Unit of Measure Code",WorkType."Unit of Measure Code");
                  UpdateUnitPrice(FIELDNO("Work Type Code"));
                  VALIDATE("Unit Price");
                  FindResUnitCost;
                END;
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
                GetSalesHeader;
                Currency2.InitRoundingPrecision;
                IF SalesHeader."Currency Code" <> '' THEN
                  "Outstanding Amount (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Outstanding Amount",SalesHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Outstanding Amount (LCY)" :=
                    ROUND("Outstanding Amount",Currency2."Amount Rounding Precision");
            end;
        }
        field(58;"Qty. Shipped Not Invoiced";Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(59;"Shipped Not Invoiced";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record "4";
            begin
                GetSalesHeader;
                Currency2.InitRoundingPrecision;
                IF SalesHeader."Currency Code" <> '' THEN
                  "Shipped Not Invoiced (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Shipped Not Invoiced",SalesHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Shipped Not Invoiced (LCY)" :=
                    ROUND("Shipped Not Invoiced",Currency2."Amount Rounding Precision");
            end;
        }
        field(60;"Quantity Shipped";Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(61;"Quantity Invoiced";Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(63;"Shipment No.";Code[20])
        {
            Caption = 'Shipment No.';
            Editable = false;
        }
        field(64;"Shipment Line No.";Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        field(67;"Profit %";Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(68;"Bill-to Customer No.";Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(69;"Inv. Discount Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                CalcInvDiscToInvoice;
                UpdateAmounts;
            end;
        }
        field(71;"Purchase Order No.";Code[20])
        {
            Caption = 'Purchase Order No.';
            Editable = false;
            TableRelation = IF (Drop Shipment=CONST(Yes)) "Purchase Header".No. WHERE (Document Type=CONST(Order));

            trigger OnValidate()
            begin
                IF (xRec."Purchase Order No." <> "Purchase Order No.") AND (Quantity <> 0) THEN BEGIN
                  ReserveSalesLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                END;
            end;
        }
        field(72;"Purch. Order Line No.";Integer)
        {
            Caption = 'Purch. Order Line No.';
            Editable = false;
            TableRelation = IF (Drop Shipment=CONST(Yes)) "Purchase Line"."Line No." WHERE (Document Type=CONST(Order),
                                                                                            Document No.=FIELD(Purchase Order No.));

            trigger OnValidate()
            begin
                IF (xRec."Purch. Order Line No." <> "Purch. Order Line No.") AND (Quantity <> 0) THEN BEGIN
                  ReserveSalesLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                END;
            end;
        }
        field(73;"Drop Shipment";Boolean)
        {
            Caption = 'Drop Shipment';
            Editable = true;

            trigger OnValidate()
            begin
                TESTFIELD("Document Type","Document Type"::Order);
                TESTFIELD(Type,Type::Item);
                TESTFIELD("Quantity Shipped",0);
                TESTFIELD("Job No.",'');

                IF "Drop Shipment" THEN
                  TESTFIELD("Special Order",FALSE);

                CheckAssocPurchOrder(FIELDCAPTION("Drop Shipment"));

                IF "Drop Shipment" THEN
                  "Bin Code" := '';

                IF Reserve <> Reserve::Always THEN
                  CheckItemAvailable(FIELDNO("Drop Shipment"));

                AddOnIntegrMgt.CheckReceiptOrderStatus(Rec);
                IF (xRec."Drop Shipment" <> "Drop Shipment") AND (Quantity <> 0) THEN BEGIN
                  IF NOT "Drop Shipment" THEN
                    UpdateWithWarehouseShip
                  ELSE
                    InitQtyToShip;
                  WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                  ReserveSalesLine.VerifyChange(Rec,xRec);
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
                TESTFIELD("Job Contract Entry No.",0);
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
            TableRelation = "Sales Line"."Line No." WHERE (Document Type=FIELD(Document Type),
                                                           Document No.=FIELD(Document No.));
        }
        field(81;"Exit Point";Code[10])
        {
            Caption = 'Exit Point';
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
                      VATPostingSetup.TESTFIELD("Sales VAT Account");
                      TESTFIELD("No.",VATPostingSetup."Sales VAT Account");
                    END;
                END;
                IF SalesHeader."Prices Including VAT" AND (Type IN [Type::Item,Type::Resource]) THEN
                  "Unit Price" :=
                    ROUND(
                      "Unit Price" * (100 + "VAT %") / (100 + xRec."VAT %"),
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
        field(93;"Shipped Not Invoiced (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
        }
        field(95;"Reserved Quantity";Decimal)
        {
            CalcFormula = -Sum("Reservation Entry".Quantity WHERE (Source ID=FIELD(Document No.),
                                                                   Source Ref. No.=FIELD(Line No.),
                                                                   Source Type=CONST(37),
                                                                   Source Subtype=FIELD(Document Type),
                                                                   Reservation Status=CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(96;Reserve;Option)
        {
            Caption = 'Reserve';
            OptionCaption = 'Never,Optional,Always';
            OptionMembers = Never,Optional,Always;

            trigger OnValidate()
            begin
                IF Reserve <> Reserve::Never THEN BEGIN
                  TESTFIELD(Type,Type::Item);
                  TESTFIELD("No.");
                END;
                CALCFIELDS("Reserved Qty. (Base)");
                IF (Reserve = Reserve::Never) AND ("Reserved Qty. (Base)" > 0) THEN
                  TESTFIELD("Reserved Qty. (Base)",0);

                IF xRec.Reserve = Reserve::Always THEN BEGIN
                  GetItem;
                  IF Item.Reserve = Item.Reserve::Always THEN
                    TESTFIELD(Reserve,Reserve::Always);
                END;
            end;
        }
        field(97;"Blanket Order No.";Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header".No. WHERE (Document Type=CONST(Blanket Order));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                TESTFIELD("Quantity Shipped",0);
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Quantity Shipped",0);
                IF "Blanket Order No." = '' THEN
                  "Blanket Order Line No." := 0
                ELSE
                  VALIDATE("Blanket Order Line No.");
            end;
        }
        field(98;"Blanket Order Line No.";Integer)
        {
            Caption = 'Blanket Order Line No.';
            TableRelation = "Sales Line"."Line No." WHERE (Document Type=CONST(Blanket Order),
                                                           Document No.=FIELD(Blanket Order No.));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Quantity Shipped",0);
                IF "Blanket Order Line No." <> 0 THEN BEGIN
                  SalesLine2.GET("Document Type"::"Blanket Order","Blanket Order No.","Blanket Order Line No.");
                  SalesLine2.TESTFIELD(Type,Type);
                  SalesLine2.TESTFIELD("No.","No.");
                  SalesLine2.TESTFIELD("Bill-to Customer No.","Bill-to Customer No.");
                  SalesLine2.TESTFIELD("Sell-to Customer No.","Sell-to Customer No.");
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
                TESTFIELD("Unit Price");
                GetSalesHeader;
                "Line Amount" := ROUND("Line Amount",Currency."Amount Rounding Precision");
                VALIDATE(
                  "Line Discount Amount",ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") - "Line Amount");
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
            OptionCaption = ' ,G/L Account,Item,,,Charge (Item),Cross Reference,Common Item No.';
            OptionMembers = " ","G/L Account",Item,,,"Charge (Item)","Cross Reference","Common Item No.";

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
                        ItemCrossReference.RESET;
                        ItemCrossReference.SETCURRENTKEY("Cross-Reference Type","Cross-Reference Type No.");
                        ItemCrossReference.SETFILTER(
                          "Cross-Reference Type",'%1|%2',
                          ItemCrossReference."Cross-Reference Type"::Customer,
                          ItemCrossReference."Cross-Reference Type"::" ");
                        ItemCrossReference.SETFILTER("Cross-Reference Type No.",'%1|%2',"Sell-to Customer No.",'');
                        IF FORM.RUNMODAL(FORM::"Cross Reference List",ItemCrossReference) = ACTION::LookupOK THEN
                          VALIDATE("IC Partner Reference",ItemCrossReference."Cross-Reference No.");
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
                  IF CurrFieldNo = FIELDNO("Prepayment %") THEN
                    IF "System-Created Entry" THEN
                      FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text045,0));
                  IF "System-Created Entry" THEN
                    "Prepayment %" := 0;
                  GenPostingSetup.GET("Gen. Bus. Posting Group","Gen. Prod. Posting Group");
                  IF GenPostingSetup."Sales Prepayments Account" <> '' THEN BEGIN
                    GLAcc.GET(GenPostingSetup."Sales Prepayments Account");
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
                      FIELDERROR("Prepmt. VAT Calc. Type",STRSUBSTNO(Text041,"Prepmt. VAT Calc. Type"));
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
                  FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text044,"Prepmt. Amt. Inv."));
                IF "Prepmt. Line Amount" > "Line Amount" THEN
                  FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text043,"Line Amount"));
                IF "System-Created Entry" THEN
                  FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text045,0));
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
                    STRSUBSTNO(Text045,"Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                IF "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Prepmt Amt Deducted" THEN
                  FIELDERROR(
                    "Prepmt Amt to Deduct",
                    STRSUBSTNO(Text045,"Qty. to Invoice" * "Prepmt Amt Deducted"));
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
                  GetSalesHeader;
                  SalesHeader.TESTFIELD("Sell-to IC Partner Code",'');
                  SalesHeader.TESTFIELD("Bill-to IC Partner Code",'');
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
            Editable = false;
            TableRelation = "Job Task"."Job Task No." WHERE (Job No.=FIELD(Job No.));
        }
        field(1002;"Job Contract Entry No.";Integer)
        {
            Caption = 'Job Contract Entry No.';
            Editable = false;

            trigger OnValidate()
            var
                JobPlanningLine: Record "1003";
            begin
                JobPlanningLine.SETCURRENTKEY("Job Contract Entry No.");
                JobPlanningLine.SETRANGE("Job Contract Entry No.","Job Contract Entry No.");
                JobPlanningLine.FINDFIRST;
                CreateDim(
                  DimMgt.TypeToTableID3(Type),"No.",
                  DATABASE::Job,JobPlanningLine."Job No.",
                  DATABASE::"Responsibility Center","Responsibility Center");
            end;
        }
        field(5402;"Variant Code";Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type=CONST(Item)) "Item Variant".Code WHERE (Item No.=FIELD(No.));

            trigger OnValidate()
            begin
                TESTFIELD("Job Contract Entry No.",0);
                IF "Variant Code" <> '' THEN
                  TESTFIELD(Type,Type::Item);
                TestStatusOpen;
                CheckAssocPurchOrder(FIELDCAPTION("Variant Code"));

                IF xRec."Variant Code" <> "Variant Code" THEN BEGIN
                  TESTFIELD("Qty. Shipped Not Invoiced",0);
                  TESTFIELD("Shipment No.",'');

                  TESTFIELD("Return Qty. Rcd. Not Invd.",0);
                  TESTFIELD("Return Receipt No.",'');
                  InitItemAppl(FALSE);
                END;

                IF Reserve <> Reserve::Always THEN
                  CheckItemAvailable(FIELDNO("Variant Code"));

                IF Type = Type::Item THEN BEGIN
                  GetUnitCost;
                  UpdateUnitPrice(FIELDNO("Variant Code"));
                END;

                IF (xRec."Variant Code" <> "Variant Code") AND (Quantity <> 0) THEN BEGIN
                  ReserveSalesLine.VerifyChange(Rec,xRec);
                  WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                END;

                GetItemCrossRef(FIELDNO("Variant Code"));
                GetDefaultBin;
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
                IF (("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND (Quantity >= 0)) OR
                   (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND (Quantity < 0))
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
                  IF (("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND (Quantity >= 0)) OR
                     (("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND (Quantity < 0))
                  THEN
                    WMSManagement.FindBinContent("Location Code","Bin Code","No.","Variant Code",'')
                  ELSE
                    WMSManagement.FindBin("Location Code","Bin Code",'');

                IF "Drop Shipment" THEN
                  CheckAssocPurchOrder(FIELDCAPTION("Bin Code"));

                TESTFIELD("Location Code");

                IF (Type = Type::Item) AND ("Bin Code" <> '') THEN BEGIN
                  TESTFIELD("Drop Shipment",FALSE);
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
        field(5405;Planned;Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5407;"Unit of Measure Code";Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type=CONST(Item)) "Item Unit of Measure".Code WHERE (Item No.=FIELD(No.))
                            ELSE IF (Type=CONST(Resource)) "Resource Unit of Measure".Code WHERE (Resource No.=FIELD(No.))
                            ELSE "Unit of Measure";

            trigger OnValidate()
            var
                UnitOfMeasureTranslation: Record "5402";
                ResUnitofMeasure: Record "205";
            begin
                TESTFIELD("Job Contract Entry No.",0);
                TestStatusOpen;
                TESTFIELD("Quantity Shipped",0);
                TESTFIELD("Qty. Shipped (Base)",0);
                CheckAssocPurchOrder(FIELDCAPTION("Unit of Measure Code"));

                IF "Unit of Measure Code" = '' THEN
                  "Unit of Measure" := ''
                ELSE BEGIN
                  IF NOT UnitOfMeasure.GET("Unit of Measure Code") THEN
                    UnitOfMeasure.INIT;
                  "Unit of Measure" := UnitOfMeasure.Description;
                  GetSalesHeader;
                  IF SalesHeader."Language Code" <> '' THEN BEGIN
                    UnitOfMeasureTranslation.SETRANGE(Code,"Unit of Measure Code");
                    UnitOfMeasureTranslation.SETRANGE("Language Code",SalesHeader."Language Code");
                    IF UnitOfMeasureTranslation.FINDFIRST THEN
                      "Unit of Measure" := UnitOfMeasureTranslation.Description;
                  END;
                END;
                GetItemCrossRef(FIELDNO("Unit of Measure Code"));
                CASE Type OF
                  Type::Item:
                    BEGIN
                      GetItem;
                      GetUnitCost;
                      UpdateUnitPrice(FIELDNO("Unit of Measure Code"));
                      IF Reserve <> Reserve::Always THEN
                        CheckItemAvailable(FIELDNO("Unit of Measure Code"));
                      "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                      "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                      "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                      "Units per Parcel" := ROUND(Item."Units per Parcel" / "Qty. per Unit of Measure",0.00001);
                      IF (xRec."Unit of Measure Code" <> "Unit of Measure Code") AND (Quantity <> 0) THEN
                        WhseValidateSourceLine.SalesLineVerifyChange(Rec,xRec);
                      IF "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" THEN
                        InitItemAppl(FALSE);
                    END;
                  Type::Resource:
                    BEGIN
                      IF "Unit of Measure Code" = '' THEN BEGIN
                        GetResource;
                        "Unit of Measure Code" := Resource."Base Unit of Measure";
                      END;
                      ResUnitofMeasure.GET("No.","Unit of Measure Code");
                      "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                      UpdateUnitPrice(FIELDNO("Unit of Measure Code"));
                      FindResUnitCost;
                    END;
                  Type::"G/L Account",Type::"Fixed Asset",Type::"Charge (Item)",Type::" ":
                    "Qty. per Unit of Measure" := 1;
                END;
                VALIDATE(Quantity);
            end;
        }
        field(5415;"Quantity (Base)";Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Job Contract Entry No.",0);
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE(Quantity,"Quantity (Base)");
                UpdateUnitPrice(FIELDNO("Quantity (Base)"));
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
        field(5418;"Qty. to Ship (Base)";Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE("Qty. to Ship","Qty. to Ship (Base)");
            end;
        }
        field(5458;"Qty. Shipped Not Invd. (Base)";Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5460;"Qty. Shipped (Base)";Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
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
            CalcFormula = -Sum("Reservation Entry"."Quantity (Base)" WHERE (Source ID=FIELD(Document No.),
                                                                            Source Ref. No.=FIELD(Line No.),
                                                                            Source Type=CONST(37),
                                                                            Source Subtype=FIELD(Document Type),
                                                                            Reservation Status=CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure");
                CALCFIELDS("Reserved Quantity");
                Planned := "Reserved Quantity" = "Outstanding Quantity";
            end;
        }
        field(5600;"FA Posting Date";Date)
        {
            Caption = 'FA Posting Date';
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
        field(5605;"Depr. until FA Posting Date";Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
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
                  DATABASE::Job,"Job No.");
            end;
        }
        field(5701;"Out-of-Stock Substitution";Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
            Editable = false;
        }
        field(5702;"Substitution Available";Boolean)
        {
            CalcFormula = Exist("Item Substitution" WHERE (Type=CONST(Item),
                                                           No.=FIELD(No.),
                                                           Substitute Type=CONST(Item)));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5703;"Originally Ordered No.";Code[20])
        {
            Caption = 'Originally Ordered No.';
            TableRelation = IF (Type=CONST(Item)) Item;
        }
        field(5704;"Originally Ordered Var. Code";Code[10])
        {
            Caption = 'Originally Ordered Var. Code';
            TableRelation = IF (Type=CONST(Item)) "Item Variant".Code WHERE (Item No.=FIELD(Originally Ordered No.));
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
                GetSalesHeader;
                "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                ReturnedCrossRef.INIT;
                IF "Cross-Reference No." <> '' THEN BEGIN
                  DistIntegration.ICRLookupSalesItem(Rec,ReturnedCrossRef);
                  IF "No." <> ReturnedCrossRef."Item No." THEN
                    VALIDATE("No.",ReturnedCrossRef."Item No.");
                  IF ReturnedCrossRef."Variant Code" <> '' THEN
                    VALIDATE("Variant Code",ReturnedCrossRef."Variant Code");

                  IF ReturnedCrossRef."Unit of Measure" <> '' THEN
                    VALIDATE("Unit of Measure Code",ReturnedCrossRef."Unit of Measure");
                END;

                "Unit of Measure (Cross Ref.)" := ReturnedCrossRef."Unit of Measure";
                "Cross-Reference Type" := ReturnedCrossRef."Cross-Reference Type";
                "Cross-Reference Type No." := ReturnedCrossRef."Cross-Reference Type No.";
                "Cross-Reference No." := ReturnedCrossRef."Cross-Reference No.";

                IF ReturnedCrossRef.Description <> '' THEN
                  Description := ReturnedCrossRef.Description;

                UpdateUnitPrice(FIELDNO("Cross-Reference No."));

                IF SalesHeader."Send IC Document" AND (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing) THEN BEGIN
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
            Editable = false;
        }
        field(5711;"Purchasing Code";Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;

            trigger OnValidate()
            begin
                TestStatusOpen;
                TESTFIELD(Type,Type::Item);
                CheckAssocPurchOrder(FIELDCAPTION(Type));

                IF PurchasingCode.GET("Purchasing Code") THEN BEGIN
                  "Drop Shipment" := PurchasingCode."Drop Shipment";
                  "Special Order" := PurchasingCode."Special Order";
                  IF "Drop Shipment" OR "Special Order" THEN BEGIN
                    Reserve := Reserve::Never;
                    VALIDATE(Quantity,Quantity);
                    IF "Drop Shipment" THEN BEGIN
                      EVALUATE("Outbound Whse. Handling Time",'<0D>');
                      EVALUATE("Shipping Time",'<0D>');
                      UpdateDates;
                      "Bin Code" := '';
                    END;
                  END;
                END ELSE BEGIN
                  "Drop Shipment" := FALSE;
                  "Special Order" := FALSE;

                  GetItem;
                  IF Item.Reserve = Item.Reserve::Optional THEN BEGIN
                    GetSalesHeader;
                    Reserve := SalesHeader.Reserve;
                  END ELSE
                    Reserve := Item.Reserve;
                END;

                IF ("Purchasing Code" <> xRec."Purchasing Code") AND
                   (NOT "Drop Shipment") AND
                   ("Drop Shipment" <> xRec."Drop Shipment")
                THEN BEGIN
                  IF "Location Code" = '' THEN BEGIN
                    IF InvtSetup.GET THEN
                      "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                  END ELSE
                    IF Location.GET("Location Code") THEN
                      "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                  IF ShippingAgentServices.GET("Shipping Agent Code","Shipping Agent Service Code") THEN
                    "Shipping Time" := ShippingAgentServices."Shipping Time"
                  ELSE BEGIN
                    GetSalesHeader;
                    "Shipping Time" := SalesHeader."Shipping Time";
                  END;
                  UpdateDates;
                END;
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
            Editable = false;
        }
        field(5714;"Special Order Purchase No.";Code[20])
        {
            Caption = 'Special Order Purchase No.';
            TableRelation = IF (Special Order=CONST(Yes)) "Purchase Header".No. WHERE (Document Type=CONST(Order));
        }
        field(5715;"Special Order Purch. Line No.";Integer)
        {
            Caption = 'Special Order Purch. Line No.';
            TableRelation = IF (Special Order=CONST(Yes)) "Purchase Line"."Line No." WHERE (Document Type=CONST(Order),
                                                                                            Document No.=FIELD(Special Order Purchase No.));
        }
        field(5750;"Whse. Outstanding Qty. (Base)";Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE (Source Type=CONST(37),
                                                                                         Source Subtype=FIELD(Document Type),
                                                                                         Source No.=FIELD(Document No.),
                                                                                         Source Line No.=FIELD(Line No.)));
            Caption = 'Whse. Outstanding Qty. (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752;"Completely Shipped";Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5790;"Requested Delivery Date";Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF ("Requested Delivery Date" <> xRec."Requested Delivery Date") AND
                   ("Promised Delivery Date" <> 0D)
                THEN
                  ERROR(
                    Text028,
                    FIELDCAPTION("Requested Delivery Date"),
                    FIELDCAPTION("Promised Delivery Date"));

                IF "Requested Delivery Date" <> 0D THEN
                  VALIDATE("Planned Delivery Date","Requested Delivery Date")
                ELSE BEGIN
                  GetSalesHeader;
                  VALIDATE("Shipment Date",SalesHeader."Shipment Date");
                END;
            end;
        }
        field(5791;"Promised Delivery Date";Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Promised Delivery Date" <> 0D THEN
                  VALIDATE("Planned Delivery Date","Promised Delivery Date")
                ELSE
                  VALIDATE("Requested Delivery Date");
            end;
        }
        field(5792;"Shipping Time";DateFormula)
        {
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateDates;
            end;
        }
        field(5793;"Outbound Whse. Handling Time";DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateDates;
            end;
        }
        field(5794;"Planned Delivery Date";Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Planned Delivery Date" <> 0D THEN BEGIN
                  PlannedDeliveryDateCalculated := TRUE;

                  IF FORMAT("Shipping Time") <> '' THEN
                    VALIDATE(
                      "Planned Shipment Date",
                      CalendarMgmt.CalcDateBOC2(
                        FORMAT("Shipping Time"),
                        "Planned Delivery Date",
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        CalChange."Source Type"::Customer,
                        "Sell-to Customer No.",
                        '',
                        TRUE))
                  ELSE
                    VALIDATE(
                      "Planned Shipment Date",
                      CalendarMgmt.CalcDateBOC(
                        FORMAT(''),
                        "Planned Delivery Date",
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        CalChange."Source Type"::Customer,
                        "Sell-to Customer No.",
                        '',
                        TRUE));

                  IF "Planned Shipment Date" > "Planned Delivery Date" THEN
                    "Planned Delivery Date" := "Planned Shipment Date";
                END;
            end;
        }
        field(5795;"Planned Shipment Date";Date)
        {
            Caption = 'Planned Shipment Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Planned Shipment Date" <> 0D THEN BEGIN
                  PlannedShipmentDateCalculated := TRUE;

                  IF FORMAT("Outbound Whse. Handling Time") <> '' THEN
                    VALIDATE(
                      "Shipment Date",
                      CalendarMgmt.CalcDateBOC2(
                        FORMAT("Outbound Whse. Handling Time"),
                        "Planned Shipment Date",
                        CalChange."Source Type"::Location,
                        "Location Code",
                        '',
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        FALSE))
                  ELSE
                    VALIDATE(
                      "Shipment Date",
                      CalendarMgmt.CalcDateBOC(
                        FORMAT(FORMAT('')),
                        "Planned Shipment Date",
                        CalChange."Source Type"::Location,
                        "Location Code",
                        '',
                        CalChange."Source Type"::"Shipping Agent",
                        "Shipping Agent Code",
                        "Shipping Agent Service Code",
                        FALSE));
                END;
            end;
        }
        field(5796;"Shipping Agent Code";Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Shipping Agent Code" <> xRec."Shipping Agent Code" THEN
                  VALIDATE("Shipping Agent Service Code",'');
            end;
        }
        field(5797;"Shipping Agent Service Code";Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE (Shipping Agent Code=FIELD(Shipping Agent Code));

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Shipping Agent Service Code" <> xRec."Shipping Agent Service Code" THEN
                  EVALUATE("Shipping Time",'<>');

                IF "Drop Shipment" THEN BEGIN
                  EVALUATE("Shipping Time",'<0D>');
                  UpdateDates;
                END ELSE BEGIN
                  IF ShippingAgentServices.GET("Shipping Agent Code","Shipping Agent Service Code") THEN
                    "Shipping Time" := ShippingAgentServices."Shipping Time"
                  ELSE BEGIN
                    GetSalesHeader;
                    "Shipping Time" := SalesHeader."Shipping Time";
                  END;
                END;

                IF ShippingAgentServices."Shipping Time" <> xRec."Shipping Time" THEN
                  VALIDATE("Shipping Time","Shipping Time");
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
            CalcFormula = Sum("Item Charge Assignment (Sales)"."Qty. to Assign" WHERE (Document Type=FIELD(Document Type),
                                                                                       Document No.=FIELD(Document No.),
                                                                                       Document Line No.=FIELD(Line No.)));
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5802;"Qty. Assigned";Decimal)
        {
            CalcFormula = Sum("Item Charge Assignment (Sales)"."Qty. Assigned" WHERE (Document Type=FIELD(Document Type),
                                                                                      Document No.=FIELD(Document No.),
                                                                                      Document Line No.=FIELD(Line No.)));
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5803;"Return Qty. to Receive";Decimal)
        {
            Caption = 'Return Qty. to Receive';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "32";
            begin
                IF (CurrFieldNo <> 0) AND
                   (Type = Type::Item) AND
                   ("Return Qty. to Receive" <> 0) AND
                   (NOT "Drop Shipment")
                THEN
                  CheckWarehouse;

                IF "Return Qty. to Receive" = Quantity - "Return Qty. Received" THEN
                  InitQtyToReceive
                ELSE BEGIN
                  "Return Qty. to Receive (Base)" := CalcBaseQty("Return Qty. to Receive");
                  InitQtyToInvoice;
                END;
                IF ("Return Qty. to Receive" * Quantity < 0) OR
                   (ABS("Return Qty. to Receive") > ABS("Outstanding Quantity")) OR
                   (Quantity * "Outstanding Quantity" < 0)
                THEN
                  ERROR(
                    Text020,
                    "Outstanding Quantity");
                IF ("Return Qty. to Receive (Base)" * "Quantity (Base)" < 0) OR
                   (ABS("Return Qty. to Receive (Base)") > ABS("Outstanding Qty. (Base)")) OR
                   ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                THEN
                  ERROR(
                    Text021,
                    "Outstanding Qty. (Base)");

                IF (CurrFieldNo <> 0) AND (Type = Type::Item) AND ("Return Qty. to Receive" > 0) THEN
                  CheckApplFromItemLedgEntry(ItemLedgEntry);
            end;
        }
        field(5804;"Return Qty. to Receive (Base)";Decimal)
        {
            Caption = 'Return Qty. to Receive (Base)';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                TESTFIELD("Qty. per Unit of Measure",1);
                VALIDATE("Return Qty. to Receive","Return Qty. to Receive (Base)");
            end;
        }
        field(5805;"Return Qty. Rcd. Not Invd.";Decimal)
        {
            Caption = 'Return Qty. Rcd. Not Invd.';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5806;"Ret. Qty. Rcd. Not Invd.(Base)";Decimal)
        {
            Caption = 'Ret. Qty. Rcd. Not Invd.(Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5807;"Return Rcd. Not Invd.";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Rcd. Not Invd.';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record "4";
            begin
                GetSalesHeader;
                Currency2.InitRoundingPrecision;
                IF SalesHeader."Currency Code" <> '' THEN
                  "Return Rcd. Not Invd. (LCY)" :=
                    ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        GetDate,"Currency Code",
                        "Return Rcd. Not Invd.",SalesHeader."Currency Factor"),
                      Currency2."Amount Rounding Precision")
                ELSE
                  "Return Rcd. Not Invd. (LCY)" :=
                    ROUND("Return Rcd. Not Invd.",Currency2."Amount Rounding Precision");
            end;
        }
        field(5808;"Return Rcd. Not Invd. (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Return Rcd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809;"Return Qty. Received";Decimal)
        {
            Caption = 'Return Qty. Received';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5810;"Return Qty. Received (Base)";Decimal)
        {
            Caption = 'Return Qty. Received (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5811;"Appl.-from Item Entry";Integer)
        {
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FIELDNO("Appl.-from Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "32";
            begin
                IF "Appl.-from Item Entry" <> 0 THEN BEGIN
                  CheckApplFromItemLedgEntry(ItemLedgEntry);
                  VALIDATE("Unit Cost (LCY)",CalcUnitCost(ItemLedgEntry));
                END;
            end;
        }
        field(5909;"BOM Item No.";Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
        }
        field(6600;"Return Receipt No.";Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        field(6601;"Return Receipt Line No.";Integer)
        {
            Caption = 'Return Receipt Line No.';
            Editable = false;
        }
        field(6608;"Return Reason Code";Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason" WHERE (Blocked=FILTER(No));

            trigger OnValidate()
            begin
                IF "Return Reason Code" = '' THEN
                  UpdateUnitPrice(FIELDNO("Return Reason Code"));

                IF ReturnReason.GET("Return Reason Code") THEN BEGIN
                  IF ReturnReason."Default Location Code" <> '' THEN
                    VALIDATE("Location Code",ReturnReason."Default Location Code");
                  IF ReturnReason."Inventory Value Zero" THEN BEGIN
                    VALIDATE("Unit Cost (LCY)",0);
                    VALIDATE("Unit Price",0);
                  END ELSE
                    IF "Unit Price" = 0 THEN
                      UpdateUnitPrice(FIELDNO("Return Reason Code"));
                END;
            end;
        }
        field(7001;"Allow Line Disc.";Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(7002;"Customer Disc. Group";Code[10])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                IF Type = Type::Item THEN
                  UpdateUnitPrice(FIELDNO("Customer Disc. Group"))
            end;
        }
        field(50000;Packing;Text[30])
        {
            Description = 'APNT-1.0';
        }
        field(50001;"Carton No.";Code[20])
        {
            Description = 'APNT-1.0';
        }
        field(50003;Barcode;Code[20])
        {
            Description = 'APNT-1.0';
            TableRelation = IF (Type=CONST(Item),
                                No.=FILTER('')) Barcodes
                                ELSE IF (Type=CONST(Item),
                                         No.=FILTER(<>'')) Barcodes WHERE (Item No.=FIELD(No.));

            trigger OnValidate()
            begin
                CheckWMSExported;  //APNT-T030380
                //APNT-1.0
                IF Type = Type::Item THEN BEGIN
                  Barcodes.GET(Barcode);
                  BarcodeNo := Barcode;
                  VALIDATE("No.",Barcodes."Item No.");
                  Barcode := BarcodeNo;
                  Barcodes.GET(Barcode);
                  //APNT-Lals
                  IF COMPANYNAME<> 'LTC Catering' THEN BEGIN
                  VALIDATE("Unit of Measure Code",Barcodes."Unit of Measure Code");//Opened MJ10JAN19
                  VALIDATE("Variant Code",Barcodes."Variant Code"); //Opened MJ 10JAN19
                  END;
                  //APNT-Lals

                  //129757 ---
                  IF COMPANYNAME = 'Base Intergrow Trading Co WLL' THEN BEGIN
                    IF (Quantity = 0) THEN BEGIN
                      VALIDATE(Quantity,1);
                      UpdateUnitPrice(FIELDNO(Barcode));
                    END;
                  END;
                  //129757 +++

                  //IF COMPANYNAME <> 'LTC Catering' THEN
                  //  VALIDATE("Unit of Measure Code",Barcodes."Unit of Measure Code");
                  //APNT-Lals
                  //VALIDATE("Variant Code",Barcodes."Variant Code");
                END;
                //APNT-1.0
            end;
        }
        field(50005;"Markup %";Decimal)
        {
            Description = 'APNT-1.0';
        }
        field(50006;"Suggested Sales Price";Decimal)
        {
            Description = 'APNT-1.0';
        }
        field(50100;"HHT Line";Boolean)
        {
            Description = 'HHT1.0';
        }
        field(50101;"Box No.";Code[20])
        {
            Description = 'HHT1.0';
        }
        field(50200;"Delivery Method";Option)
        {
            Description = 'APNT-HRU1.0';
            OptionCaption = 'Showroom,Warehouse,Interbranch';
            OptionMembers = Showroom,Warehouse,Interbranch;

            trigger OnValidate()
            var
                RemarksSL: Record "37";
            begin
                TestStatusOpen;

                //APNT-HRU1.0
                CLEAR("Offer Price");
                CLEAR("Offer Amount");
                //APNT-HRU1.0

                IF "Delivery Method" <> xRec."Delivery Method" THEN
                  CLEAR("Pick Location");


                IF ("Delivery Method" = "Delivery Method"::Showroom) OR ("Delivery Method" = "Delivery Method"::Interbranch) THEN BEGIN
                  CLEAR("Delivery By location");
                END;

                IF ("Delivery Method" = "Delivery Method"::Showroom) THEN BEGIN
                  "Pick Location" := SalesHeader."Location Code"; //APNT-HRU2.0
                  "Delivery By location" := "Pick Location";
                END;

                IF ("Delivery Method" = "Delivery Method"::Warehouse) OR ("Delivery Method" = "Delivery Method"::Interbranch) THEN BEGIN
                  CLEAR("Pick Location");
                  CLEAR("Delivery By location");
                END;

                VALIDATE("Pick Location"); //APNT-HRU2.0
            end;
        }
        field(50201;"Pick Location";Code[10])
        {
            Description = 'APNT-HRU1.0,6421';
            TableRelation = IF (Delivery Method=CONST(Warehouse),
                                Document Type=CONST(Return Order)) Location WHERE (Brand Code=FILTER(RETURN))
                                ELSE IF (Delivery Method=CONST(Interbranch)) Location WHERE (Location Type=CONST(Store))
                                ELSE IF (Delivery Method=CONST(Showroom)) Location WHERE (Brand Code=FILTER(SALE))
                                ELSE IF (Delivery Method=CONST(Warehouse),
                                         Document Type=CONST(Order)) Location WHERE (Brand Code=FILTER(SALE));

            trigger OnValidate()
            begin
                TestStatusOpen;
                VALIDATE("Location Code","Pick Location");
            end;
        }
        field(50202;"Delivery By location";Code[10])
        {
            Description = 'APNT-HRU1.0';
            TableRelation = Location WHERE (Use As Pick Location=CONST(Yes));

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(50203;"Offer Price";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Description = 'APNT-HRU1.0';
        }
        field(50204;"Offer Amount";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Description = 'APNT-HRU1.0';
        }
        field(50205;"SO Line Reversed";Boolean)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50206;"Sales Person Code";Code[20])
        {
            CalcFormula = Lookup("Sales Header"."Salesperson Code" WHERE (Document Type=FIELD(Document Type),
                                                                          No.=FIELD(Document No.)));
            Description = 'APNT-HRU1.0';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50207;"Transfer Order No.";Code[20])
        {
            Description = 'APNT-HRU1.0';
        }
        field(50208;"Transfer Order Line No.";Integer)
        {
            Description = 'APNT-HRU1.0';
        }
        field(50209;"Sales Floor Order No.";Code[20])
        {
            Description = 'APNT-HRU1.0 (Added for DLL function)';
        }
        field(50210;"Linked to Line No.";Integer)
        {
            Caption = 'Linked to Line No.';
            Description = 'APNT-HRU1.0 (Added for DLL function)';
        }
        field(50250;"Assigned Qty.";Decimal)
        {
            Editable = false;
        }
        field(50251;"Unassigned Qty.";Decimal)
        {
            Editable = false;
        }
        field(50800;"Magento Last Entry No.";Integer)
        {
            CalcFormula = Max("eCom Cust. Order Line Status"."Entry No." WHERE (Document ID=FIELD(Document No.),
                                                                                Item No.=FIELD(No.),
                                                                                Line No.=FIELD(Line No.)));
            Description = 'APNT-eCom';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50801;"Magento Last Line Status";Text[100])
        {
            CalcFormula = Lookup("eCom Cust. Order Line Status".eCom-Status WHERE (Document ID=FIELD(Document No.),
                                                                                   Item No.=FIELD(No.)));
            Description = 'APNT-eCom';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50802;"Mark eCom Return Lines";Boolean)
        {
            Description = 'APNT-eCom';
        }
        field(50803;"eCom Buffer Qty.";Decimal)
        {
            Description = 'APNT-eCom';
        }
        field(50850;"eCom Original Sales Order No.";Code[20])
        {
            Description = 'eCom-CR';
        }
        field(50851;"eCom Original Sales Invoice No";Code[20])
        {
            Description = 'eCom-CR';
        }
        field(10000701;"Store No.";Code[10])
        {
            Caption = 'Store No';
            TableRelation = Store;
        }
        field(10000710;"Current Cust. Price Group";Code[20])
        {
            Caption = 'Current Cust. Price Group';
        }
        field(10000711;"Current Store Group";Code[20])
        {
            Caption = 'Current Store Group';
        }
        field(10000720;Division;Code[10])
        {
            Caption = 'Division';
            TableRelation = Division;
        }
        field(10000721;"Offer No.";Code[20])
        {
            Caption = 'Offer No.';
        }
        field(10012700;"Retail Special Order";Boolean)
        {
            Caption = 'Retail Special Order';

            trigger OnValidate()
            begin
                //LS -
                IF "Sourcing Status" = "Sourcing Status"::Sourced THEN BEGIN
                  IF "Retail Special Order" <> xRec."Retail Special Order" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Retail Special Order" := xRec."Retail Special Order";
                END;
                //LS +
            end;
        }
        field(10012701;"Delivering Method";Option)
        {
            Caption = 'Delivering Method';
            OptionCaption = 'None,Collect,Ship';
            OptionMembers = "None",Collect,Ship;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Delivering Method" <> xRec."Delivering Method" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Delivering Method" := xRec."Delivering Method";
                END;
                //LS +
            end;
        }
        field(10012702;"Vendor Delivers to";Option)
        {
            Caption = 'Vendor Delivers to';
            OptionCaption = 'None,Whse,Store,Customer';
            OptionMembers = "None",Whse,Store,Customer;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Vendor Delivers to" <> xRec."Vendor Delivers to" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Vendor Delivers to" := xRec."Vendor Delivers to";
                END;
                IF "Vendor Delivers to" = "Vendor Delivers to"::Store THEN
                  "SPO Whse Location" := '';
                //LS +
            end;
        }
        field(10012703;Sourcing;Option)
        {
            Caption = 'Sourcing';
            OptionCaption = 'None,Vendor,Whse,Store';
            OptionMembers = "None",Vendor,Whse,Store;

            trigger OnValidate()
            var
                lSPOSourcingCheckBatch: Codeunit "10012706";
                lSPOSalesLineStatusLines: Record "10012724";
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF Sourcing <> xRec.Sourcing THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      Sourcing := xRec.Sourcing;
                END;

                IF Sourcing = Sourcing::Store THEN BEGIN
                  IF "Configuration ID" <> '' THEN
                    ERROR(LSText02);
                  "Sourcing Status" := "Sourcing Status"::Sourced;
                  "Delivery Status" := "Delivery Status"::Waiting;
                END;

                IF Sourcing <> Sourcing::Vendor THEN BEGIN
                  "Vendor Delivers to" := "Vendor Delivers to"::None;
                  "Vendor No." := '';
                END;
                //LS +
            end;
        }
        field(10012704;"Deliver from";Option)
        {
            Caption = 'Deliver from';
            OptionCaption = 'None,Vendor,Whse,Store';
            OptionMembers = "None",Vendor,Whse,Store;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Deliver from" <> xRec."Deliver from" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Deliver from" := xRec."Deliver from";
                END;
                IF "Deliver from" <> "Deliver from"::Whse THEN
                  "SPO Whse Location" := '';
                IF "Deliver from" = "Deliver from"::Vendor THEN BEGIN
                  "Delivery Location Code" := '';
                  "Vendor Delivers to" := "Vendor Delivers to"::Customer;
                  "Delivering Method" := "Delivering Method"::Ship;
                END;
                //LS +
            end;
        }
        field(10012705;"Delivery Location Code";Code[10])
        {
            Caption = 'Delivery Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Delivery Location Code" <> xRec."Delivery Location Code" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Delivery Location Code" := xRec."Delivery Location Code";
                END;
                //LS +
            end;
        }
        field(10012707;"SPO Prepayment %";Decimal)
        {
            Caption = 'SPO Prepayment %';
        }
        field(10012708;"Total Payment";Decimal)
        {
            CalcFormula = Sum("SPO Payment Lines".Amount WHERE (Document Type=FIELD(Document Type),
                                                                Document No.=FIELD(Document No.),
                                                                Document Line No.=FIELD(Line No.)));
            Caption = 'Total Payment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012709;"Whse Process";Option)
        {
            Caption = 'Whse Process';
            OptionCaption = ' ,To Customer,To Store';
            OptionMembers = " ","To Customer","To Store";
        }
        field(10012710;Status;Option)
        {
            CalcFormula = Lookup("Sales Header".Status WHERE (Document Type=FIELD(Document Type),
                                                              No.=FIELD(Document No.)));
            Caption = 'Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(10012711;"Delivery Status";Option)
        {
            Caption = 'Delivery Status';
            OptionCaption = 'Sourcing,Waiting,Payment Pending,Warehouse Pick,Ready for Partial Delivery,Ready to Deliver,Delivered,Cancelled';
            OptionMembers = Sourcing,Waiting,"Payment Pending","Warehouse Pick","Ready for Partial Delivery","Ready to Deliver",Delivered,Cancelled;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Delivery Status" <> xRec."Delivery Status" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Delivery Status" := xRec."Delivery Status";
                END;
                //LS +
            end;
        }
        field(10012712;"Configuration ID";Code[30])
        {
            Caption = 'Configuration ID';
            Editable = true;
            TableRelation = "Option Type Value Header"."Configuration ID" WHERE (Configuration ID=FIELD(No.));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                OptionValueHeader: Record "10012712";
            begin
                //Doc RN3396 -
                IF OptionValueHeader.GET("Configuration ID") THEN
                  VALIDATE("Option Value Text", COPYSTR(OptionValueHeader."Option String and Value",1,MAXSTRLEN("Option Value Text")));
                //Doc RN3396 +
            end;
        }
        field(10012713;"Mandatory Options Exist";Boolean)
        {
            CalcFormula = Exist("Item Option Type" WHERE (Item No.=FIELD(No.),
                                                          Mandatory Option=CONST(Yes)));
            Caption = 'Mandatory Options Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10012718;"Whse Status";Option)
        {
            Caption = 'Whse Status';
            OptionCaption = 'Sourcing,Waiting,Payment Pending,Ready for Partial Delivery,Ready to Deliver,Delivered,Cancelled,Ready for Whse';
            OptionMembers = Sourcing,Waiting,"Payment Pending","Ready for Partial Delivery","Ready to Deliver",Delivered,Cancelled,"Ready for Whse";
        }
        field(10012719;"Delivery Reference No";Text[30])
        {
            Caption = 'Delivery Reference No';
        }
        field(10012720;"Delivery User ID";Code[20])
        {
            Caption = 'Delivery User ID';
            TableRelation = User;
        }
        field(10012721;"Delivery Date Time";DateTime)
        {
            Caption = 'Delivery Date Time';
        }
        field(10012724;Counter;Decimal)
        {
            Caption = 'Counter';
            InitValue = 1;
        }
        field(10012739;"Option Value Text";Text[100])
        {
            Caption = 'Option Value Text';
        }
        field(10012750;"Estimated Delivery Date";Date)
        {
            Caption = 'Estimated Delivery Date';
        }
        field(10012751;"No later than Date";Date)
        {
            Caption = 'No later than Date';
        }
        field(10012752;"Payment-At Order Entry-Limit";Decimal)
        {
            Caption = 'Payment-At Order Entry-Limit';
        }
        field(10012753;"Payment-At Delivery-Limit";Decimal)
        {
            Caption = 'Payment-At Delivery-Limit';
        }
        field(10012755;"Return Policy";Option)
        {
            Caption = 'Return Policy';
            OptionCaption = 'Permitted,Not Permitted';
            OptionMembers = Permitted,"Not Permitted";
        }
        field(10012756;"Non Refund Amount";Decimal)
        {
            Caption = 'Non Refund Amount';
        }
        field(10012757;"Sourcing Status";Option)
        {
            Caption = 'Sourcing Status';
            Editable = true;
            OptionCaption = 'New,Info Missing,On Hold,Cancelled,Ready for Sourcing,Sourced';
            OptionMembers = New,"Info Missing","On Hold",Cancelled,"Ready for Sourcing",Sourced;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND (xRec."Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Sourcing Status" := xRec."Sourcing Status";
                END;
                //LS +
            end;
        }
        field(10012758;"Payment-At PurchaseOrder-Limit";Decimal)
        {
            Caption = 'Payment-At PurchaseOrder-Limit';
        }
        field(10012759;"SPO Document Method";Option)
        {
            Caption = 'SPO Document Method';
            OptionCaption = 'None,General,With Options';
            OptionMembers = "None",General,"With Options";

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "SPO Document Method" <> xRec."SPO Document Method" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "SPO Document Method" := xRec."SPO Document Method";
                END;
                //LS +
            end;
        }
        field(10012760;"Store Sales Location";Code[10])
        {
            Caption = 'Store Sales Location';
            TableRelation = Location;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Store Sales Location" <> xRec."Store Sales Location" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Store Sales Location" := xRec."Store Sales Location";
                END;
                //LS +
            end;
        }
        field(10012761;"SPO Whse Location";Code[10])
        {
            Caption = 'SPO Whse Location';
            TableRelation = Location;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "SPO Whse Location" <> xRec."SPO Whse Location" THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "SPO Whse Location" := xRec."SPO Whse Location";
                END;
                //LS +
            end;
        }
        field(10012762;"Vendor No.";Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Vendor No." <> xRec."Vendor No." THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Vendor No." := xRec."Vendor No.";
                END;
                //LS +
            end;
        }
        field(10012763;"Item Tracking No.";Code[20])
        {
            Caption = 'Item Tracking No.';

            trigger OnValidate()
            begin
                //LS -
                IF "Retail Special Order" AND ("Sourcing Status" = "Sourcing Status"::Sourced) THEN BEGIN
                  IF "Item Tracking No." <> xRec."Item Tracking No." THEN
                    IF NOT(CONFIRM(LSText01,FALSE)) THEN
                      "Item Tracking No." := xRec."Item Tracking No.";
                END;
                //LS +
            end;
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
        field(33016802;"Ref. Document Line No.";Integer)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016803;"Element Type";Code[20])
        {
            Description = 'DP6.01.01';
            Editable = false;
            TableRelation = "Agreement Element".Code;

            trigger OnValidate()
            var
                AgreementElementRec: Record "33016812";
            begin
                IF AgreementElementRec.GET("Element Type") THEN BEGIN
                  IF AgreementElementRec."Rental Element" THEN
                    "Rental Element" := TRUE;
                END;
            end;
        }
        field(33016804;"Rental Element";Boolean)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016805;"Agreement Posting Date";Date)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
        field(33016806;"Agreement Due Date";Date)
        {
            Description = 'DP6.01.01';
            Editable = false;
        }
    }

    keys
    {
        key(Key1;"Document Type","Document No.","Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount,"Amount Including VAT","Outstanding Amount","Shipped Not Invoiced","Outstanding Amount (LCY)","Shipped Not Invoiced (LCY)","Line Amount","Offer Amount";
        }
        key(Key2;"Document No.","Line No.","Document Type")
        {
        }
        key(Key3;"Document Type",Type,"No.","Variant Code","Drop Shipment","Location Code","Shipment Date")
        {
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4;"Document Type","Bill-to Customer No.","Currency Code")
        {
            SumIndexFields = "Outstanding Amount","Shipped Not Invoiced","Outstanding Amount (LCY)","Shipped Not Invoiced (LCY)","Return Rcd. Not Invd. (LCY)";
        }
        key(Key5;"Document Type","Blanket Order No.","Blanket Order Line No.")
        {
        }
        key(Key6;"Document Type","Document No.","Location Code")
        {
        }
        key(Key7;"Document Type","Shipment No.","Shipment Line No.")
        {
        }
        key(Key8;Type,"No.","Variant Code","Drop Shipment","Location Code","Document Type","Shipment Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key9;"Document Type","Sell-to Customer No.")
        {
        }
        key(Key10;"Job Contract Entry No.")
        {
        }
        key(Key11;"Retail Special Order")
        {
        }
        key(Key12;"Retail Special Order","Sourcing Status","Location Code","SPO Document Method")
        {
            SumIndexFields = "Payment-At Order Entry-Limit","Payment-At Delivery-Limit","Payment-At PurchaseOrder-Limit","Non Refund Amount";
        }
        key(Key13;"Retail Special Order","Delivery Location Code","Delivery Status")
        {
        }
        key(Key14;"Retail Special Order","SPO Whse Location","Whse Process","Whse Status")
        {
        }
        key(Key15;"No.","Carton No.","Sell-to Customer No.")
        {
        }
        key(Key16;"Carton No.","No.")
        {
        }
        key(Key17;"Document Type","Ref. Document Type","Ref. Document No.","Ref. Document Line No.")
        {
            SumIndexFields = Quantity,Amount,"Line Amount";
        }
        key(Key18;"Document Type","Document No.","Pick Location","Delivery By location")
        {
            SumIndexFields = Quantity,Amount,"Line Amount";
        }
        key(Key19;"Document Type",Type,Division,"Item Category Code","Product Group Code")
        {
            SumIndexFields = Quantity,Amount,"Line Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DocDim: Record "357";
        CapableToPromise: Codeunit "99000886";
        JobCreateInvoice: Codeunit "1002";
        SalesCommentLine: Record "44";
        WorkOrderLine: Record "33016825";
    begin
        TestStatusOpen;
        //DP6.01.01 START
        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Converted Sales. Doc No.","Document No.");
        WorkOrderLine.SETRANGE("Converted Sales. Doc Type","Document Type");
        WorkOrderLine.SETRANGE("Document Line No.","Line No.");
        IF WorkOrderLine.FINDSET THEN REPEAT
          WorkOrderLine."Converted Sales. Doc No." := '';
          WorkOrderLine."Converted Sales. Doc Line No." := 0;
          WorkOrderLine."Converted Sales. Doc Datetime" := 0DT;
          WorkOrderLine."Converted Sales. Doc Type" := 0;
          WorkOrderLine."Convert to Sales Doc Type" := 0;
          WorkOrderLine.MODIFY;
        UNTIL WorkOrderLine.NEXT = 0;

        IF "Ref. Document No." <> '' THEN BEGIN
          ModifyAgreementBalance;
        END;
        //DP6.01.01 STOP
        IF NOT StatusCheckSuspended AND (SalesHeader.Status = SalesHeader.Status::Released) AND
           (Type IN [Type::"G/L Account",Type::"Charge (Item)",Type::Resource])
        THEN
          VALIDATE(Quantity,0);
        DocDim.LOCKTABLE;

        IF(SalesHeader."HRU Document" = FALSE) THEN  //Mj 12feb20
        CheckWMSExported;  //APNT-T030380

        IF (Quantity <> 0) AND ItemExists("No.") THEN BEGIN
          ReserveSalesLine.DeleteLine(Rec);
          //APNT-eCOM +
          //eComIntegrationWebServices.HandleSalesLineReserveStock(Rec,xRec,FALSE);
          //APNT-eCOM -
          CALCFIELDS("Reserved Qty. (Base)");
          TESTFIELD("Reserved Qty. (Base)",0);
          IF "Shipment No." = '' THEN
            TESTFIELD("Qty. Shipped Not Invoiced",0);
          IF "Return Receipt No." = '' THEN
            TESTFIELD("Return Qty. Rcd. Not Invd.",0);
          WhseValidateSourceLine.SalesLineDelete(Rec);
        END;

        IF ("Document Type" = "Document Type"::Order) AND (Quantity <> "Quantity Invoiced") THEN
          TESTFIELD("Prepmt. Amt. Inv.",0);

        CheckAssocPurchOrder('');
        NonstockItemMgt.DelNonStockSales(Rec);

        IF "Document Type" = "Document Type"::"Blanket Order" THEN BEGIN
          SalesLine2.RESET;
          SalesLine2.SETCURRENTKEY("Document Type","Blanket Order No.","Blanket Order Line No.");
          SalesLine2.SETRANGE("Blanket Order No.","Document No.");
          SalesLine2.SETRANGE("Blanket Order Line No.","Line No.");
          IF SalesLine2.FINDFIRST THEN
            SalesLine2.TESTFIELD("Blanket Order Line No.",0);
        END;

        IF Type = Type::Item THEN
          DeleteItemChargeAssgnt("Document Type","Document No.","Line No.");

        IF Type = Type::"Charge (Item)" THEN
          DeleteChargeChargeAssgnt("Document Type","Document No.","Line No.");

        CapableToPromise.RemoveReqLines("Document No.","Line No.",0,FALSE);

        //LS -
        IF "Retail Special Order" THEN
          DeleteSPOLines;
        //LS

        SalesLine2.RESET;
        SalesLine2.SETRANGE("Document Type","Document Type");
        SalesLine2.SETRANGE("Document No.","Document No.");
        SalesLine2.SETRANGE("Attached to Line No.","Line No.");
        SalesLine2.DELETEALL(TRUE);
        DimMgt.DeleteDocDim(DATABASE::"Sales Line","Document Type","Document No.","Line No.");
        IF "Job Contract Entry No." <> 0 THEN
          JobCreateInvoice.DeleteSalesLine(Rec);

        SalesCommentLine.SETRANGE("Document Type","Document Type");
        SalesCommentLine.SETRANGE("No.","Document No.");
        SalesCommentLine.SETRANGE("Document Line No.","Line No.");
        IF NOT SalesCommentLine.ISEMPTY THEN
          SalesCommentLine.DELETEALL;
    end;

    trigger OnInsert()
    var
        DocDim: Record "357";
    begin
        TestStatusOpen;
        IF Quantity <> 0 THEN
          ReserveSalesLine.VerifyQuantity(Rec,xRec);
        DocDim.LOCKTABLE;
        LOCKTABLE;
        SalesHeader."No." := '';
        
        //LS -
        GetSalesHeader();
        IF NOT SalesHeader."Only Two Dimensions" THEN
        //LS +
          DimMgt.InsertDocDim(
            DATABASE::"Sales Line","Document Type","Document No.","Line No.",
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        
        //DP6.01.01 START
        GetSalesHeader();
        "Agreement Posting Date" := SalesHeader."Posting Date";
        //DP6.01.01 STOP
        
        CheckWMSExported;  //APNT-T030380
        
        //APNT-HRU1.0 -
        /* commented APNT-HRU2.0
        IF "Delivery Method" = "Delivery Method"::Showroom THEN BEGIN
          "Pick Location" := SalesHeader."Location Code";
          "Delivery By location" := SalesHeader."Location Code";
        END;
        */
        //APNT-HRU1.0 +

    end;

    trigger OnModify()
    begin
        IF ("Document Type" = "Document Type"::"Blanket Order") AND
           ((Type <> xRec.Type) OR ("No." <> xRec."No."))
        THEN BEGIN
          SalesLine2.RESET;
          SalesLine2.SETCURRENTKEY("Document Type","Blanket Order No.","Blanket Order Line No.");
          SalesLine2.SETRANGE("Blanket Order No.","Document No.");
          SalesLine2.SETRANGE("Blanket Order Line No.","Line No.");
          IF SalesLine2.FINDSET THEN
            REPEAT
              SalesLine2.TESTFIELD(Type,Type);
              SalesLine2.TESTFIELD("No.","No.");
            UNTIL SalesLine2.NEXT = 0;
        END;

        IF ((Quantity <> 0) OR (xRec.Quantity <> 0)) AND ItemExists(xRec."No.") THEN
          ReserveSalesLine.VerifyChange(Rec,xRec);
    end;

    trigger OnRename()
    begin
        ERROR(Text001,TABLECAPTION);
    end;

    var
        Text000: Label 'You cannot delete the order line because it is associated with purchase order %1 line %2.';
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot change %1 because the order line is associated with purchase order %2 line %3.';
        Text003: Label 'must not be less than %1';
        Text005: Label 'You cannot invoice more than %1 units.';
        Text006: Label 'You cannot invoice more than %1 base units.';
        Text007: Label 'You cannot ship more than %1 units.';
        Text008: Label 'You cannot ship more than %1 base units.';
        Text009: Label ' must be 0 when %1 is %2';
        Text011: Label 'Automatic reservation is not possible.\Reserve items manually?';
        Text012: Label 'Change %1 from %2 to %3?';
        Text014: Label '%1 %2 is before work date %3';
        Text016: Label '%1 is required for %2 = %3.';
        Text017: Label '\The entered information will be disregarded by warehouse operations.';
        Text020: Label 'You cannot return more than %1 units.';
        Text021: Label 'You cannot return more than %1 base units.';
        Text026: Label 'You cannot change %1 if the item charge has already been posted.';
        CurrExchRate: Record "330";
        SalesHeader: Record "36";
        SalesLine2: Record "37";
        TempSalesLine: Record "37";
        GLAcc: Record "15";
        Item: Record "27";
        Resource: Record "156";
        Currency: Record "4";
        ItemTranslation: Record "30";
        Res: Record "156";
        ResCost: Record "202";
        WorkType: Record "200";
        JobLedgEntry: Record "169";
        VATPostingSetup: Record "325";
        StdTxt: Record "7";
        GenBusPostingGrp: Record "250";
        GenProdPostingGrp: Record "251";
        ReservEntry: Record "337";
        ItemVariant: Record "5401";
        UnitOfMeasure: Record "204";
        FA: Record "5600";
        ShippingAgentServices: Record "5790";
        NonstockItem: Record "5718";
        PurchasingCode: Record "5721";
        SKU: Record "5700";
        ItemCharge: Record "5800";
        ItemChargeAssgntSales: Record "5809";
        InvtSetup: Record "313";
        Location: Record "14";
        ReturnReason: Record "6635";
        JobLedgEntries: Form "92";
        Reservation: Form "498";
        ItemAvailByDate: Form "157";
        ItemAvailByVar: Form "5414";
        ItemAvailByLoc: Form "492";
        PriceCalcMgt: Codeunit "7000";
        ResFindUnitCost: Codeunit "220";
        CustCheckCreditLimit: Codeunit "312";
        ItemCheckAvail: Codeunit "311";
        SalesTaxCalculate: Codeunit "398";
        ReservMgt: Codeunit "99000845";
        ReservEngineMgt: Codeunit "99000831";
        ReserveSalesLine: Codeunit "99000832";
        UOMMgt: Codeunit "5402";
        AddOnIntegrMgt: Codeunit "5403";
        DimMgt: Codeunit "408";
        ItemSubstitutionMgt: Codeunit "5701";
        DistIntegration: Codeunit "5702";
        NonstockItemMgt: Codeunit "5703";
        WhseValidateSourceLine: Codeunit "5777";
        TransferExtendedText: Codeunit "378";
        JobPostLine: Codeunit "1001";
        FullAutoReservation: Boolean;
        StatusCheckSuspended: Boolean;
        HasBeenShown: Boolean;
        PlannedShipmentDateCalculated: Boolean;
        PlannedDeliveryDateCalculated: Boolean;
        Text028: Label 'You cannot change the %1 when the %2 has been filled in.';
        ItemCategory: Record "5722";
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
        Text031: Label 'You must either specify %1 or %2.';
        CalendarMgmt: Codeunit "7600";
        CalChange: Record "7602";
        Text034: Label 'The value of %1 field must be a whole number for the item included in the service item group if the %2 field in the Service Item Groups window contains a check mark.';
        Text035: Label 'Warehouse ';
        Text036: Label 'Inventory ';
        HideValidationDialog: Boolean;
        Text037: Label 'You cannot change %1 when %2 is %3 and %4 is positive.';
        Text038: Label 'You cannot change %1 when %2 is %3 and %4 is negative.';
        Text039: Label '%1 units for %2 %3 have already been returned. Therefore, only %4 units can be returned.';
        Text040: Label 'You must use form %1 to enter %2, if item tracking is used.';
        Text041: Label 'You must cancel the existing approval for this document to be able to change the %1 field.';
        Text042: Label 'When posting the Applied to Ledger Entry %1 will be opened first';
        Text043: Label 'cannot be %1';
        Text044: Label 'cannot be less than %1';
        Text045: Label 'cannot be more than %1';
        Text046: Label 'You cannot return more than the %1 units that you have shipped for %2 %3.';
        Text047: Label 'must be positive when %1 is not 0.';
        TrackingBlocked: Boolean;
        Text048: Label 'You cannot use item tracking on a %1 created from a %2.';
        Text049: Label 'cannot be %1.';
        "---ls texts ---": ;
        LSText01: Label 'This line has already been sourced.  Continue?';
        LSText02: Label 'Item with option can not be sourced from Store';
        LSText03: Label 'Information missing, check Status Lines';
        LSText04: Label 'Retail Special Orders are not allowed at %1';
        Barcodes: Record "99001451";
        BarcodeNo: Code[20];
        HRUInventory: Decimal;
        ReservedQuantity: Decimal;
        NetAvailability: Decimal;
        RecComp: Record "79";
        RecSH: Record "36";
        SalesHeaderNew: Record "36";
        eComIntegrationWebServices: Codeunit "50151";
 
    procedure InitOutstanding()
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          "Outstanding Quantity" := Quantity - "Return Qty. Received";
          "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Received (Base)";
          "Return Qty. Rcd. Not Invd." := "Return Qty. Received" - "Quantity Invoiced";
          "Ret. Qty. Rcd. Not Invd.(Base)" := "Return Qty. Received (Base)" - "Qty. Invoiced (Base)";
        END ELSE BEGIN
          "Outstanding Quantity" := Quantity - "Quantity Shipped";
          "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
          "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced";
          "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        END;
        CALCFIELDS("Reserved Quantity");
        Planned := "Reserved Quantity" = "Outstanding Quantity";
        "Completely Shipped" := (Quantity <> 0) AND ("Outstanding Quantity" = 0);
        InitOutstandingAmount;
    end;
 
    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        IF Quantity = 0 THEN BEGIN
          "Outstanding Amount" := 0;
          "Outstanding Amount (LCY)" := 0;
          "Shipped Not Invoiced" := 0;
          "Shipped Not Invoiced (LCY)" := 0;
          "Return Rcd. Not Invd." := 0;
          "Return Rcd. Not Invd. (LCY)" := 0;
        END ELSE BEGIN
          GetSalesHeader;
          IF SalesHeader.Status = SalesHeader.Status::Released THEN
            AmountInclVAT := "Amount Including VAT"
          ELSE
            IF SalesHeader."Prices Including VAT" THEN
              AmountInclVAT := "Line Amount" - "Inv. Discount Amount"
            ELSE
              IF "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" THEN
                AmountInclVAT :=
                  "Line Amount" - "Inv. Discount Amount" +
                  ROUND(
                    SalesTaxCalculate.CalculateTax(
                      "Tax Area Code","Tax Group Code","Tax Liable",SalesHeader."Posting Date",
                      "Line Amount" - "Inv. Discount Amount","Quantity (Base)",SalesHeader."Currency Factor"),
                    Currency."Amount Rounding Precision")
              ELSE
                AmountInclVAT :=
                  ROUND(
                    ("Line Amount" - "Inv. Discount Amount") *
                    (1 + "VAT %" / 100 * (1 - SalesHeader."VAT Base Discount %" / 100)),
                    Currency."Amount Rounding Precision");
          VALIDATE(
            "Outstanding Amount",
            ROUND(
              AmountInclVAT * "Outstanding Quantity" / Quantity,
              Currency."Amount Rounding Precision"));
          IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
            VALIDATE(
              "Return Rcd. Not Invd.",
              ROUND(
                AmountInclVAT * "Return Qty. Rcd. Not Invd." / Quantity,
                Currency."Amount Rounding Precision"))
          ELSE
            VALIDATE(
              "Shipped Not Invoiced",
              ROUND(
                AmountInclVAT * "Qty. Shipped Not Invoiced" / Quantity,
                Currency."Amount Rounding Precision"));
        END;
    end;
 
    procedure InitQtyToShip()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        CheckServItemCreation;

        InitQtyToInvoice;
    end;
 
    procedure InitQtyToReceive()
    begin
        "Return Qty. to Receive" := "Outstanding Quantity";
        "Return Qty. to Receive (Base)" := "Outstanding Qty. (Base)";

        InitQtyToInvoice;
    end;
 
    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;
        CalcInvDiscToInvoice;
        IF SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice THEN
          CalcPrepaymentToDeduct;
    end;

    local procedure InitItemAppl(OnlyApplTo: Boolean)
    begin
        "Appl.-to Item Entry" := 0;
        IF NOT OnlyApplTo THEN
          "Appl.-from Item Entry" := 0;
    end;
 
    procedure MaxQtyToInvoice(): Decimal
    begin
        IF "Prepayment Line" THEN
          EXIT(1);
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          EXIT("Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced")
        ELSE
          EXIT("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced");
    end;
 
    procedure MaxQtyToInvoiceBase(): Decimal
    begin
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          EXIT("Return Qty. Received (Base)" + "Return Qty. to Receive (Base)" - "Qty. Invoiced (Base)")
        ELSE
          EXIT("Qty. Shipped (Base)" + "Qty. to Ship (Base)" - "Qty. Invoiced (Base)");
    end;

    local procedure CalcBaseQty(Qty: Decimal): Decimal
    begin
        TESTFIELD("Qty. per Unit of Measure");
        EXIT(ROUND(Qty * "Qty. per Unit of Measure",0.00001));
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "32";
        SalesLine3: Record "37";
    begin
        ItemLedgEntry.SETRANGE("Item No.","No.");
        IF "Location Code" <> '' THEN
          ItemLedgEntry.SETRANGE("Location Code","Location Code");
        ItemLedgEntry.SETRANGE("Variant Code","Variant Code");

        IF CurrentFieldNo = FIELDNO("Appl.-to Item Entry") THEN BEGIN
          ItemLedgEntry.SETCURRENTKEY("Item No.",Open);
          ItemLedgEntry.SETRANGE(Positive,TRUE);
          ItemLedgEntry.SETRANGE(Open,TRUE);
        END ELSE BEGIN
          ItemLedgEntry.SETCURRENTKEY("Item No.",Positive);
          ItemLedgEntry.SETRANGE(Positive,FALSE);
          ItemLedgEntry.SETFILTER("Shipped Qty. Not Returned",'<0');
        END;
        IF FORM.RUNMODAL(FORM::"Item Ledger Entries",ItemLedgEntry) = ACTION::LookupOK THEN BEGIN
          SalesLine3 := Rec;
          IF CurrentFieldNo = FIELDNO("Appl.-to Item Entry") THEN
            SalesLine3.VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No.")
          ELSE
            SalesLine3.VALIDATE("Appl.-from Item Entry",ItemLedgEntry."Entry No.");
          IF Reserve <> Reserve::Always THEN
            CheckItemAvailable(CurrentFieldNo);
          Rec := SalesLine3;
        END;
    end;
 
    procedure SetSalesHeader(NewSalesHeader: Record "36")
    begin
        SalesHeader := NewSalesHeader;

        IF SalesHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE BEGIN
          SalesHeader.TESTFIELD("Currency Factor");
          Currency.GET(SalesHeader."Currency Code");
          Currency.TESTFIELD("Amount Rounding Precision");
        END;
    end;

    local procedure GetSalesHeader()
    begin
        TESTFIELD("Document No.");
        //LS -
        //IF ("Document Type" <> SalesHeader."Document Type") OR ("Document No." <> SalesHeader."No.") THEN BEGIN
        IF ("Document Type" <> SalesHeader."Document Type") OR ("Document No." <> SalesHeader."No.")
        OR ("Store No." <> SalesHeader."Store No.") THEN BEGIN
        //LS +
          SalesHeader.GET("Document Type","Document No.");
          IF SalesHeader."Currency Code" = '' THEN
            Currency.InitRoundingPrecision
          ELSE BEGIN
            SalesHeader.TESTFIELD("Currency Factor");
            Currency.GET(SalesHeader."Currency Code");
            Currency.TESTFIELD("Amount Rounding Precision");
          END;
        END;
    end;

    local procedure GetItem()
    begin
        TESTFIELD("No.");
        IF "No." <> Item."No." THEN
          Item.GET("No.");
    end;
 
    procedure GetResource()
    begin
        TESTFIELD("No.");
        IF "No." <> Resource."No." THEN
          Resource.GET("No.");
    end;

    local procedure UpdateUnitPrice(CalledByFieldNo: Integer)
    var
        Store: Record "99001470";
        GetPosPrice: Codeunit "50030";
        SalesP: Record "7002";
        RecItem: Record "27";
    begin
        IF (CalledByFieldNo <> CurrFieldNo) AND (CurrFieldNo <> 0) THEN
          EXIT;

        GetSalesHeader;
        TESTFIELD("Qty. per Unit of Measure");

        CASE Type OF
          Type::Item,Type::Resource:
            BEGIN
              PriceCalcMgt.FindSalesLineLineDisc(SalesHeader,Rec);
              PriceCalcMgt.FindSalesLinePrice(SalesHeader,Rec,CalledByFieldNo);
              //APNT-HRU1.0 -
              IF SalesHeader."HRU Document" THEN BEGIN //APNT-T003685
                IF ("Document Type" = "Document Type"::Order) OR  ("Document Type" = "Document Type"::"Return Order") OR
                   ("Document Type" = "Document Type"::Quote)THEN BEGIN
                  IF "Location Code" <> ''THEN BEGIN
                    Store.RESET;
                    Store.SETRANGE("Location Code",SalesHeader."Location Code");
                    IF Store.FIND('-') THEN BEGIN
                      CLEAR(GetPosPrice);
                      GetPosPrice.SetCustDiscGroup("Customer Disc. Group");
                      //APNT-VAT1.0 -

                      "Unit Price" := GetPosPrice.GetPOSPrice2(
                                        Store."No.","No.",SalesHeader."Posting Date","Unit of Measure Code","Currency Code",
                                        "Variant Code",'',FALSE);

                      CLEAR(GetPosPrice);
                      GetPosPrice.SetCustDiscGroup("Customer Disc. Group");
                      "Offer Price" := GetPosPrice.GetPOSPrice2(
                                        Store."No.","No.",SalesHeader."Posting Date","Unit of Measure Code","Currency Code",
                                        "Variant Code",'',TRUE);
                      "Offer Amount" := "Offer Price" * Quantity;
                    END;
                  END;
                END;
              END;
              //APNT-HRU1.0 +
            END;
        END;
        VALIDATE("Unit Price");
    end;

    local procedure FindResUnitCost()
    begin
        ResCost.INIT;
        ResCost.Code := "No.";
        ResCost."Work Type Code" := "Work Type Code";
        ResFindUnitCost.RUN(ResCost);
        VALIDATE("Unit Cost (LCY)",ResCost."Unit Cost" * "Qty. per Unit of Measure");
    end;
 
    procedure UpdateAmounts()
    begin
        IF CurrFieldNo <> FIELDNO("Allow Invoice Disc.") THEN
          TESTFIELD(Type);
        GetSalesHeader;

        IF "Line Amount" <> xRec."Line Amount" THEN
          "VAT Difference" := 0;
        IF "Line Amount" <> ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") - "Line Discount Amount" THEN BEGIN
          "Line Amount" := ROUND(Quantity * "Unit Price",Currency."Amount Rounding Precision") - "Line Discount Amount";
          "VAT Difference" := 0;
        END;
        IF SalesHeader.Status = SalesHeader.Status::Released THEN
          UpdateVATAmounts;
        IF "Prepayment %" <> 0 THEN BEGIN
          IF Quantity < 0 THEN
            FIELDERROR(Quantity,STRSUBSTNO(Text047,FIELDCAPTION("Prepayment %")));
          IF "Unit Price" < 0 THEN
            FIELDERROR("Unit Price",STRSUBSTNO(Text047,FIELDCAPTION("Prepayment %")));
        END;
        IF SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice THEN BEGIN
          "Prepayment VAT Difference" := 0;
          IF "Quantity Invoiced" = 0 THEN BEGIN
            "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100,Currency."Amount Rounding Precision");
            IF "Prepmt. Line Amount" < "Prepmt. Amt. Inv." THEN
              FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text049,"Prepmt. Amt. Inv."));
          END ELSE BEGIN
            IF "Prepayment %" <> 0 THEN
              "Prepmt. Line Amount" := "Prepmt. Amt. Inv." +
                ROUND("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity * "Prepayment %" / 100,
                  Currency."Amount Rounding Precision")
            ELSE
              "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100,Currency."Amount Rounding Precision");
            IF "Prepmt. Line Amount" > "Line Amount" THEN
              FIELDERROR("Prepmt. Line Amount",STRSUBSTNO(Text049,"Prepmt. Line Amount"));
          END;
        END;
        InitOutstandingAmount;
        IF (CurrFieldNo <> 0) AND
           NOT ((Type = Type::Item) AND (CurrFieldNo = FIELDNO("No.")) AND (Quantity <> 0) AND
        // a write transaction may have been started
                ("Qty. per Unit of Measure" <> xRec."Qty. per Unit of Measure")) AND            // ...continued condition
           ("Document Type" <= "Document Type"::Invoice) AND
           (("Outstanding Amount" + "Shipped Not Invoiced") > 0)
        THEN
          CustCheckCreditLimit.SalesLineCheck(Rec);

        IF Type = Type::"Charge (Item)" THEN
          UpdateItemChargeAssgnt;
    end;

    local procedure UpdateVATAmounts()
    var
        SalesLine2: Record "37";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalQuantityBase: Decimal;
    begin
        SalesLine2.SETRANGE("Document Type","Document Type");
        SalesLine2.SETRANGE("Document No.","Document No.");
        SalesLine2.SETFILTER("Line No.",'<>%1',"Line No.");
        IF "Line Amount" = 0 THEN
          IF xRec."Line Amount" >= 0 THEN
            SalesLine2.SETFILTER(Amount,'>%1',0)
          ELSE
            SalesLine2.SETFILTER(Amount,'<%1',0)
        ELSE
          IF "Line Amount" > 0 THEN
            SalesLine2.SETFILTER(Amount,'>%1',0)
          ELSE
            SalesLine2.SETFILTER(Amount,'<%1',0);
        SalesLine2.SETRANGE("VAT Identifier","VAT Identifier");
        SalesLine2.SETRANGE("Tax Group Code","Tax Group Code");

        IF "Line Amount" = "Inv. Discount Amount" THEN BEGIN
          Amount := 0;
          "VAT Base Amount" := 0;
          "Amount Including VAT" := 0;
          IF "Line No." <> 0 THEN
            IF MODIFY THEN
              IF SalesLine2.FINDLAST THEN BEGIN
                SalesLine2.UpdateAmounts;
                SalesLine2.MODIFY;
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
          THEN BEGIN
            IF SalesLine2.FINDSET THEN
              REPEAT
                TotalLineAmount := TotalLineAmount + SalesLine2."Line Amount";
                TotalInvDiscAmount := TotalInvDiscAmount + SalesLine2."Inv. Discount Amount";
                TotalAmount := TotalAmount + SalesLine2.Amount;
                TotalAmountInclVAT := TotalAmountInclVAT + SalesLine2."Amount Including VAT";
                TotalQuantityBase := TotalQuantityBase + SalesLine2."Quantity (Base)";
              UNTIL SalesLine2.NEXT = 0;
          END;

          IF SalesHeader."Prices Including VAT" THEN
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
                      Amount * (1 - SalesHeader."VAT Base Discount %" / 100),
                      Currency."Amount Rounding Precision");
                  "Amount Including VAT" :=
                    TotalLineAmount + "Line Amount" +
                    ROUND(
                      (TotalAmount + Amount) * (SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
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
                  SalesHeader.TESTFIELD("VAT Base Discount %",0);
                  Amount :=
                    SalesTaxCalculate.ReverseCalculateTax(
                      "Tax Area Code","Tax Group Code","Tax Liable",SalesHeader."Posting Date",
                      TotalAmountInclVAT + "Amount Including VAT",TotalQuantityBase + "Quantity (Base)",
                      SalesHeader."Currency Factor") -
                    TotalAmount;
                  IF Amount <> 0 THEN
                    "VAT %" :=
                      ROUND(100 * ("Amount Including VAT" - Amount) / Amount,0.00001)
                  ELSE
                    "VAT %" := 0;
                  Amount := ROUND(Amount,Currency."Amount Rounding Precision");
                  "VAT Base Amount" := Amount;
                END;
            END
          ELSE
            CASE "VAT Calculation Type" OF
              "VAT Calculation Type"::"Normal VAT",
              "VAT Calculation Type"::"Reverse Charge VAT":
                BEGIN
                  Amount := ROUND("Line Amount" - "Inv. Discount Amount",Currency."Amount Rounding Precision");
                  "VAT Base Amount" :=
                    ROUND(Amount * (1 - SalesHeader."VAT Base Discount %" / 100),Currency."Amount Rounding Precision");
                  "Amount Including VAT" :=
                    TotalAmount + Amount +
                    ROUND(
                      (TotalAmount + Amount) * (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
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
                  "Amount Including VAT" :=
                    TotalAmount + Amount +
                    ROUND(
                      SalesTaxCalculate.CalculateTax(
                        "Tax Area Code","Tax Group Code","Tax Liable",SalesHeader."Posting Date",
                        (TotalAmount + Amount),(TotalQuantityBase + "Quantity (Base)"),
                        SalesHeader."Currency Factor"),Currency."Amount Rounding Precision") -
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

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    begin
        IF "Shipment Date" = 0D THEN BEGIN
          GetSalesHeader;
          IF SalesHeader."Shipment Date" <> 0D THEN
            VALIDATE("Shipment Date",SalesHeader."Shipment Date")
          ELSE
            VALIDATE("Shipment Date",WORKDATE);
        END;

        IF ((CalledByFieldNo = CurrFieldNo) OR (CalledByFieldNo = FIELDNO("Shipment Date"))) AND GUIALLOWED AND
           ("Document Type" IN ["Document Type"::Order,"Document Type"::Invoice]) AND
           (Type = Type::Item) AND ("No." <> '') AND
           ("Outstanding Quantity" > 0) AND
           ("Job Contract Entry No." = 0) AND
           NOT (Nonstock OR "Special Order")
        THEN
          ItemCheckAvail.SalesLineCheck(Rec);
    end;
 
    procedure ShowReservation()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        TESTFIELD(Reserve);
        CLEAR(Reservation);
        Reservation.SetSalesLine(Rec);
        Reservation.RUNMODAL;
    end;
 
    procedure ShowReservationEntries(Modal: Boolean)
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry,TRUE);
        ReserveSalesLine.FilterReservFor(ReservEntry,Rec);
        IF Modal THEN
          FORM.RUNMODAL(FORM::"Reservation Entries",ReservEntry)
        ELSE
          FORM.RUN(FORM::"Reservation Entries",ReservEntry);
    end;
 
    procedure AutoReserve()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        
        IF ReserveSalesLine.ReservQuantity(Rec) <> 0 THEN BEGIN
          ReservMgt.SetSalesLine(Rec);
          TESTFIELD("Shipment Date");
          //APNT-eCOM +
          /*
          IF (Quantity <> xRec.Quantity) AND (xRec.Quantity <> 0) THEN
            eComIntegrationWebServices.HandleSalesLineReserveStock(Rec,xRec,TRUE);
          */
          //APNT-eCOM -
          ReservMgt.AutoReserve(FullAutoReservation,'',"Shipment Date",ReserveSalesLine.ReservQuantity(Rec));
          FIND;
          IF NOT FullAutoReservation THEN BEGIN
            COMMIT;
            IF NOT HideValidationDialog AND GUIALLOWED THEN BEGIN //APNT-eCOM
              IF CONFIRM(Text011,TRUE) THEN BEGIN
                ShowReservation;
                FIND;
              END;
            END;
          END;
        END;

    end;
 
    procedure GetDate(): Date
    begin
        IF ("Document Type" IN ["Document Type"::"Blanket Order","Document Type"::Quote]) AND
           (SalesHeader."Posting Date" = 0D)
        THEN
          EXIT(WORKDATE);
        EXIT(SalesHeader."Posting Date");
    end;
 
    procedure SignedXX(Value: Decimal): Decimal
    begin
        CASE "Document Type" OF
          "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice,
          "Document Type"::"Blanket Order":
            EXIT(-Value);
          "Document Type"::"Return Order",
          "Document Type"::"Credit Memo":
            EXIT(Value);
        END;
    end;
 
    procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin)
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        Item.RESET;
        Item.GET("No.");
        Item.SETRANGE("No.","No.");
        Item.SETRANGE("Date Filter",0D,"Shipment Date");

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
                IF "Shipment Date" <> ItemAvailByDate.GetLastDate THEN
                  IF CONFIRM(
                       Text012,TRUE,FIELDCAPTION("Shipment Date"),"Shipment Date",
                       ItemAvailByDate.GetLastDate)
                  THEN BEGIN
                    IF CurrFieldNo <> 0 THEN
                      xRec := Rec;
                    VALIDATE("Shipment Date",ItemAvailByDate.GetLastDate);
                  END;
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
                       Text012,TRUE,FIELDCAPTION("Variant Code"),"Variant Code",
                       ItemAvailByVar.GetLastVariant)
                  THEN BEGIN
                    IF CurrFieldNo = 0 THEN
                      xRec := Rec;
                    VALIDATE("Variant Code",ItemAvailByVar.GetLastVariant);
                  END;
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
                       Text012,TRUE,FIELDCAPTION("Location Code"),"Location Code",
                       ItemAvailByLoc.GetLastLocation)
                  THEN BEGIN
                    IF CurrFieldNo = 0 THEN
                      xRec := Rec;
                    VALIDATE("Location Code",ItemAvailByLoc.GetLastLocation);
                  END;
            END;
        END;
    end;
 
    procedure BlanketOrderLookup()
    begin
        SalesLine2.RESET;
        SalesLine2.SETCURRENTKEY("Document Type",Type,"No.");
        SalesLine2.SETRANGE("Document Type","Document Type"::"Blanket Order");
        SalesLine2.SETRANGE(Type,Type);
        SalesLine2.SETRANGE("No.","No.");
        SalesLine2.SETRANGE("Bill-to Customer No.","Bill-to Customer No.");
        SalesLine2.SETRANGE("Sell-to Customer No.","Sell-to Customer No.");
        IF FORM.RUNMODAL(FORM::"Sales Lines",SalesLine2) = ACTION::LookupOK THEN BEGIN
          SalesLine2.TESTFIELD("Document Type","Document Type"::"Blanket Order");
          "Blanket Order No." := SalesLine2."Document No.";
          VALIDATE("Blanket Order Line No.",SalesLine2."Line No.");
        END;
    end;
 
    procedure ShowDimensions()
    var
        DocDim: Record "357";
        DocDimensions: Form "546";
    begin
        TESTFIELD("Document No.");
        TESTFIELD("Line No.");
        DocDim.SETRANGE("Table ID",DATABASE::"Sales Line");
        DocDim.SETRANGE("Document Type","Document Type");
        DocDim.SETRANGE("Document No.","Document No.");
        DocDim.SETRANGE("Line No.","Line No.");
        DocDimensions.SETTABLEVIEW(DocDim);
        DocDimensions.RUNMODAL;
    end;
 
    procedure OpenItemTrackingLines()
    var
        Job: Record "167";
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        TESTFIELD("Quantity (Base)");
        IF "Job Contract Entry No." <> 0 THEN
          ERROR(Text048,TABLECAPTION,Job.TABLECAPTION);
        ReserveSalesLine.CallItemTracking(Rec);
    end;
 
    procedure CreateDim(Type1: Integer;No1: Code[20];Type2: Integer;No2: Code[20];Type3: Integer;No3: Code[20])
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
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        //LS -
        GetSalesHeader();
        IF SalesHeader."Only Two Dimensions" THEN
          BEGIN
            "Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
          END
        ELSE
        //LS +
          DimMgt.GetPreviousDocDefaultDim(
            DATABASE::"Sales Header","Document Type","Document No.",0,
            DATABASE::Customer,"Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        DimMgt.GetDefaultDim(
          TableID,No,SourceCodeSetup.Sales,
          "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");

        IF NOT SalesHeader."Only Two Dimensions" THEN //LS
          IF "Line No." <> 0 THEN
            DimMgt.UpdateDocDefaultDim(
              DATABASE::"Sales Line","Document Type","Document No.","Line No.",
              "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);

        GetSalesHeader();  //LS
        IF NOT SalesHeader."Only Two Dimensions" THEN  //LS
          IF "Line No." <> 0 THEN BEGIN
            DimMgt.SaveDocDim(
              DATABASE::"Sales Line","Document Type","Document No.",
              "Line No.",FieldNumber,ShortcutDimCode);
            MODIFY;
          END ELSE
            DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);

        GetSalesHeader(); //LS
        IF NOT SalesHeader."Only Two Dimensions" THEN //LS
          IF "Line No." <> 0 THEN BEGIN
            DimMgt.SaveDocDim(
              DATABASE::"Sales Line","Document Type","Document No.",
              "Line No.",FieldNumber,ShortcutDimCode);
            MODIFY;
          END ELSE
            DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowShortcutDimCode(var ShortcutDimCode: array [8] of Code[20])
    begin
        IF "Line No." <> 0 THEN
          DimMgt.ShowDocDim(
            DATABASE::"Sales Line","Document Type","Document No.",
            "Line No.",ShortcutDimCode)
        ELSE
          DimMgt.ShowTempDim(ShortcutDimCode);
    end;
 
    procedure ShowItemSub()
    begin
        TestStatusOpen;
        ItemSubstitutionMgt.ItemSubstGet(Rec);
        IF TransferExtendedText.SalesCheckIfAnyExtText(Rec,TRUE) THEN
          TransferExtendedText.InsertSalesExtText(Rec);
    end;
 
    procedure ShowNonstock()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.",'');
        IF FORM.RUNMODAL(FORM::"Nonstock Item List",NonstockItem) = ACTION::LookupOK THEN BEGIN
          NonstockItem.TESTFIELD("Item Category Code");
          ItemCategory.GET(NonstockItem."Item Category Code");
          ItemCategory.TESTFIELD("Def. Gen. Prod. Posting Group");
          ItemCategory.TESTFIELD("Def. Inventory Posting Group");

          "No." := NonstockItem."Entry No.";
          NonstockItemMgt.NonStockSales(Rec);
          VALIDATE("No.","No.");
          VALIDATE("Unit Price",NonstockItem."Unit Price");
        END;
    end;

    local procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "15";
        FASetup: Record "5603";
        FAPostingGr: Record "5606";
        FADeprBook: Record "5612";
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
        FADeprBook.GET("No.","Depreciation Book Code");
        FADeprBook.TESTFIELD("FA Posting Group");
        FAPostingGr.GET(FADeprBook."FA Posting Group");
        FAPostingGr.TESTFIELD("Acq. Cost Acc. on Disposal");
        LocalGLAcc.GET(FAPostingGr."Acq. Cost Acc. on Disposal");
        LocalGLAcc.CheckGLAcc;
        LocalGLAcc.TESTFIELD("Gen. Prod. Posting Group");
        "Posting Group" := FADeprBook."FA Posting Group";
        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
        "Tax Group Code" := LocalGLAcc."Tax Group Code";
        VALIDATE("VAT Prod. Posting Group",LocalGLAcc."VAT Prod. Posting Group");
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "2000000041";
    begin
        Field.GET(DATABASE::"Sales Line",FieldNumber);
        EXIT(Field."Field Caption");
    end;

    local procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        SalesHeader2: Record "36";
    begin
        IF SalesHeader2.GET("Document Type","Document No.") THEN;
        IF SalesHeader2."Prices Including VAT" THEN
          EXIT('2,1,' + GetFieldCaption(FieldNumber))
        ELSE
          EXIT('2,0,' + GetFieldCaption(FieldNumber));
    end;

    local procedure GetSKU(): Boolean
    begin
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
 
    procedure GetUnitCost()
    begin
        TESTFIELD(Type,Type::Item);
        TESTFIELD("No.");
        GetItem;
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item,"Unit of Measure Code");
        IF GetSKU THEN
          VALIDATE("Unit Cost (LCY)",SKU."Unit Cost" * "Qty. per Unit of Measure")
        ELSE
          VALIDATE("Unit Cost (LCY)",Item."Unit Cost" * "Qty. per Unit of Measure");
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "32"): Decimal
    var
        ValueEntry: Record "5802";
        UnitCost: Decimal;
    begin
        WITH ValueEntry DO BEGIN
          SETCURRENTKEY("Item Ledger Entry No.");
          SETRANGE("Item Ledger Entry No.",ItemLedgEntry."Entry No.");
          CALCSUMS("Cost Amount (Actual)","Cost Amount (Expected)");
          UnitCost :=
            ("Cost Amount (Expected)" + "Cost Amount (Actual)") / ItemLedgEntry.Quantity;
        END;

        EXIT(ABS(UnitCost * "Qty. per Unit of Measure"));
    end;
 
    procedure ShowItemChargeAssgnt()
    var
        ItemChargeAssgnts: Form "5814";
        AssignItemChargeSales: Codeunit "5807";
    begin
        GET("Document Type","Document No.","Line No.");
        TESTFIELD(Type,Type::"Charge (Item)");
        TESTFIELD("No.");
        TESTFIELD(Quantity);

        ItemChargeAssgntSales.RESET;
        ItemChargeAssgntSales.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.","Document No.");
        ItemChargeAssgntSales.SETRANGE("Document Line No.","Line No.");
        ItemChargeAssgntSales.SETRANGE("Item Charge No.","No.");
        IF NOT ItemChargeAssgntSales.FINDLAST THEN BEGIN
          ItemChargeAssgntSales."Document Type" := "Document Type";
          ItemChargeAssgntSales."Document No." := "Document No.";
          ItemChargeAssgntSales."Document Line No." := "Line No.";
          ItemChargeAssgntSales."Item Charge No." := "No.";
          GetSalesHeader;
          IF ("Inv. Discount Amount" = 0) AND
             ("Line Discount Amount" = 0) AND
             (NOT SalesHeader."Prices Including VAT")
          THEN
            ItemChargeAssgntSales."Unit Cost" := "Unit Price"
          ELSE
            IF SalesHeader."Prices Including VAT" THEN
              ItemChargeAssgntSales."Unit Cost" :=
                ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity / (1 + "VAT %" / 100),
                  Currency."Unit-Amount Rounding Precision")
            ELSE
              ItemChargeAssgntSales."Unit Cost" :=
                ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity,
                  Currency."Unit-Amount Rounding Precision");
        END;

        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN
          AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales,"Return Receipt No.")
        ELSE
          AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales,"Shipment No.");
        CLEAR(AssignItemChargeSales);
        COMMIT;

        ItemChargeAssgnts.Initialize(Rec,ItemChargeAssgntSales."Unit Cost");
        ItemChargeAssgnts.RUNMODAL;
        CALCFIELDS("Qty. to Assign");
    end;
 
    procedure UpdateItemChargeAssgnt()
    var
        ShareOfVAT: Decimal;
    begin
        CALCFIELDS("Qty. Assigned");
        TESTFIELD("Quantity Invoiced","Qty. Assigned");
        ItemChargeAssgntSales.RESET;
        ItemChargeAssgntSales.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.","Document No.");
        ItemChargeAssgntSales.SETRANGE("Document Line No.","Line No.");
        IF (CurrFieldNo <> 0) AND (Amount <> xRec.Amount) THEN BEGIN
          ItemChargeAssgntSales.SETFILTER("Qty. Assigned",'<>0');
          IF NOT ItemChargeAssgntSales.ISEMPTY THEN
            ERROR(Text026,
              FIELDCAPTION(Amount));
          ItemChargeAssgntSales.SETRANGE("Qty. Assigned");
        END;

        IF ItemChargeAssgntSales.FINDSET THEN BEGIN
          GetSalesHeader;
          REPEAT
            ShareOfVAT := 1;
            IF SalesHeader."Prices Including VAT" THEN
              ShareOfVAT := 1 + "VAT %" / 100;
                IF ItemChargeAssgntSales."Unit Cost" <> ROUND(
                 ("Line Amount" - "Inv. Discount Amount") / Quantity / ShareOfVAT,
                 Currency."Unit-Amount Rounding Precision")
            THEN BEGIN
              ItemChargeAssgntSales."Unit Cost" := ROUND(
                  ("Line Amount" - "Inv. Discount Amount") / Quantity / ShareOfVAT,
                  Currency."Unit-Amount Rounding Precision");
              ItemChargeAssgntSales.VALIDATE("Qty. to Assign");
              ItemChargeAssgntSales.MODIFY;
            END;
          UNTIL ItemChargeAssgntSales.NEXT = 0;
          CALCFIELDS("Qty. to Assign");
        END;
    end;

    local procedure DeleteItemChargeAssgnt(DocType: Option;DocNo: Code[20];DocLineNo: Integer)
    begin
        ItemChargeAssgntSales.SETCURRENTKEY(
          "Applies-to Doc. Type","Applies-to Doc. No.","Applies-to Doc. Line No.");
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type",DocType);
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.",DocNo);
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.",DocLineNo);
        IF NOT ItemChargeAssgntSales.ISEMPTY THEN
          ItemChargeAssgntSales.DELETEALL(TRUE);
    end;

    local procedure DeleteChargeChargeAssgnt(DocType: Option;DocNo: Code[20];DocLineNo: Integer)
    begin
        IF DocType <> "Document Type"::"Blanket Order" THEN
          IF "Quantity Invoiced" <> 0 THEN BEGIN
            CALCFIELDS("Qty. Assigned");
            TESTFIELD("Qty. Assigned","Quantity Invoiced");
          END;
        ItemChargeAssgntSales.RESET;
        ItemChargeAssgntSales.SETRANGE("Document Type",DocType);
        ItemChargeAssgntSales.SETRANGE("Document No.",DocNo);
        ItemChargeAssgntSales.SETRANGE("Document Line No.",DocLineNo);
        IF NOT ItemChargeAssgntSales.ISEMPTY THEN
          ItemChargeAssgntSales.DELETEALL;
    end;
 
    procedure CheckItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "5809";
    begin
        ItemChargeAssgntSales.SETCURRENTKEY(
          "Applies-to Doc. Type","Applies-to Doc. No.","Applies-to Doc. Line No.");
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type","Document Type");
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.","Document No.");
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.","Line No.");
        ItemChargeAssgntSales.SETRANGE("Document Type","Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.","Document No.");
        IF ItemChargeAssgntSales.FINDSET THEN BEGIN
          TESTFIELD("Allow Item Charge Assignment");
          REPEAT
            ItemChargeAssgntSales.TESTFIELD("Qty. to Assign",0);
          UNTIL ItemChargeAssgntSales.NEXT = 0;
        END;
    end;

    local procedure TestStatusOpen()
    begin
        IF StatusCheckSuspended THEN
          EXIT;
        GetSalesHeader;
        IF Type IN [Type::Item,Type::"Fixed Asset"] THEN
          SalesHeader.TESTFIELD(Status,SalesHeader.Status::Open);
    end;
 
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;
 
    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping;var SalesHeader: Record "36";var SalesLine: Record "37";var VATAmountLine: Record "290")
    var
        TempVATAmountLineRemainder: Record "290" temporary;
        Currency: Record "4";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
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
        IF SalesHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE
          Currency.GET(SalesHeader."Currency Code");

        TempVATAmountLineRemainder.DELETEALL;

        WITH SalesLine DO BEGIN
          SETRANGE("Document Type",SalesHeader."Document Type");
          SETRANGE("Document No.",SalesHeader."No.");
          LOCKTABLE;
          IF FINDSET THEN
            REPEAT
              IF NOT ZeroAmountLine(QtyType) THEN BEGIN
                VATAmountLine.GET("VAT Identifier","VAT Calculation Type","Tax Group Code",FALSE,"Line Amount" >= 0);
                IF VATAmountLine.Modified THEN BEGIN
                  xRecRef.GETTABLE(SalesLine);
                  IF NOT TempVATAmountLineRemainder.GET(
                       "VAT Identifier","VAT Calculation Type","Tax Group Code",FALSE,"Line Amount" >= 0)
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
                    IF SalesHeader."Prices Including VAT" THEN BEGIN
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
                          NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
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
                            NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
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
                  IF (QtyType = QtyType::General) AND (SalesHeader.Status = SalesHeader.Status::Released) THEN BEGIN
                    Amount := NewAmount;
                    "Amount Including VAT" := ROUND(NewAmountIncludingVAT,Currency."Amount Rounding Precision");
                    "VAT Base Amount" := NewVATBaseAmount;
                  END;
                  InitOutstanding;
                  IF Type = Type::"Charge (Item)" THEN
                    UpdateItemChargeAssgnt;
                  MODIFY;
                  RecRef.GETTABLE(SalesLine);
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
 
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping;var SalesHeader: Record "36";var SalesLine: Record "37";var VATAmountLine: Record "290")
    var
        PrevVatAmountLine: Record "290";
        Currency: Record "4";
        Cust: Record "18";
        CustPostingGroup: Record "92";
        SalesTaxCalculate: Codeunit "398";
        QtyToHandle: Decimal;
        SalesSetup: Record "311";
        RoundingLineInserted: Boolean;
        TotalVATAmount: Decimal;
    begin
        IF SalesHeader."Currency Code" = '' THEN
          Currency.InitRoundingPrecision
        ELSE
          Currency.GET(SalesHeader."Currency Code");

        VATAmountLine.DELETEALL;

        WITH SalesLine DO BEGIN
          SETRANGE("Document Type",SalesHeader."Document Type");
          SETRANGE("Document No.",SalesHeader."No.");
          SalesSetup.GET;
          IF SalesSetup."Invoice Rounding" THEN BEGIN
            Cust.GET(SalesHeader."Bill-to Customer No.");
            CustPostingGroup.GET(Cust."Customer Posting Group");
          END;
          IF FINDSET THEN
            REPEAT
              IF NOT ZeroAmountLine(QtyType) THEN BEGIN
                IF (Type = Type::"G/L Account") AND NOT "Prepayment Line" THEN
                  RoundingLineInserted := ("No." = CustPostingGroup."Invoice Rounding Account") OR RoundingLineInserted;
                IF "VAT Calculation Type" IN
                   ["VAT Calculation Type"::"Reverse Charge VAT","VAT Calculation Type"::"Sales Tax"]
                THEN
                  "VAT %" := 0;
                IF NOT VATAmountLine.GET(
                     "VAT Identifier","VAT Calculation Type","Tax Group Code",FALSE,"Line Amount" >= 0)
                THEN BEGIN
                  VATAmountLine.INIT;
                  VATAmountLine."VAT Identifier" := "VAT Identifier";
                  VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                  VATAmountLine."Tax Group Code" := "Tax Group Code";
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
                        (NOT SalesHeader.Ship) AND SalesHeader.Invoice AND (NOT "Prepayment Line"):
                          BEGIN
                            IF "Shipment No." = '' THEN BEGIN
                              QtyToHandle := GetAbsMin("Qty. to Invoice","Qty. Shipped Not Invoiced");
                              VATAmountLine.Quantity :=
                                VATAmountLine.Quantity + GetAbsMin("Qty. to Invoice (Base)","Qty. Shipped Not Invd. (Base)");
                            END ELSE BEGIN
                              QtyToHandle := "Qty. to Invoice";
                              VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Invoice (Base)";
                            END;
                          END;
                        ("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]) AND
                        (NOT SalesHeader.Receive) AND SalesHeader.Invoice:
                          BEGIN
                            QtyToHandle := GetAbsMin("Qty. to Invoice","Return Qty. Rcd. Not Invd.");
                            VATAmountLine.Quantity :=
                              VATAmountLine.Quantity + GetAbsMin("Qty. to Invoice (Base)","Ret. Qty. Rcd. Not Invd.(Base)");
                          END;
                        ELSE
                          BEGIN
                          QtyToHandle := "Qty. to Invoice";
                          VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Invoice (Base)";
                        END;
                      END;
                      VATAmountLine."Line Amount" :=
                        VATAmountLine."Line Amount" +
                        (ROUND(QtyToHandle * "Unit Price" - ("Line Discount Amount" * QtyToHandle / Quantity),
                        Currency."Amount Rounding Precision"));
                      IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" :=
                          VATAmountLine."Inv. Disc. Base Amount" +
                          (ROUND(QtyToHandle * "Unit Price" - ("Line Discount Amount" * QtyToHandle / Quantity),
                          Currency."Amount Rounding Precision"));
                      IF (SalesHeader."Invoice Discount Calculation" <> SalesHeader."Invoice Discount Calculation"::Amount) THEN
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
                        QtyToHandle := "Return Qty. to Receive";
                        VATAmountLine.Quantity := VATAmountLine.Quantity + "Return Qty. to Receive (Base)";
                      END ELSE BEGIN
                        QtyToHandle := "Qty. to Ship";
                        VATAmountLine.Quantity := VATAmountLine.Quantity + "Qty. to Ship (Base)";
                      END;
                      VATAmountLine."Line Amount" :=
                        VATAmountLine."Line Amount" +
                        (ROUND(QtyToHandle * "Unit Price" - ("Line Discount Amount" * QtyToHandle / Quantity),
                        Currency."Amount Rounding Precision"));
                      IF "Allow Invoice Disc." THEN
                        VATAmountLine."Inv. Disc. Base Amount" :=
                          VATAmountLine."Inv. Disc. Base Amount" +
                          (ROUND(QtyToHandle * "Unit Price" - ("Line Discount Amount" * QtyToHandle / Quantity),
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
              IF SalesHeader."Prices Including VAT" THEN BEGIN
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
                          (1 - SalesHeader."VAT Base Discount %" / 100),
                          Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Amount Including VAT" := "VAT Base" + "VAT Amount";
                      IF Positive THEN
                        PrevVatAmountLine.INIT
                      ELSE BEGIN
                        PrevVatAmountLine := VATAmountLine;
                        PrevVatAmountLine."VAT Amount" :=
                          ("Line Amount" - "Invoice Discount Amount" - "VAT Base" - "VAT Difference") *
                          (1 - SalesHeader."VAT Base Discount %" / 100);
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
                      "VAT Base" :=
                        ROUND(
                          SalesTaxCalculate.ReverseCalculateTax(
                            SalesHeader."Tax Area Code","Tax Group Code",SalesHeader."Tax Liable",
                            SalesHeader."Posting Date","Amount Including VAT",Quantity,SalesHeader."Currency Factor"),
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
                          "VAT Base" * "VAT %" / 100 * (1 - SalesHeader."VAT Base Discount %" / 100),
                          Currency."Amount Rounding Precision",Currency.VATRoundingDirection);
                      "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount" + "VAT Amount";
                      IF Positive THEN
                        PrevVatAmountLine.INIT
                      ELSE BEGIN
                        PrevVatAmountLine := VATAmountLine;
                        PrevVatAmountLine."VAT Amount" :=
                          "VAT Base" * "VAT %" / 100 * (1 - SalesHeader."VAT Base Discount %" / 100);
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
                      "VAT Amount" :=
                        SalesTaxCalculate.CalculateTax(
                          SalesHeader."Tax Area Code","Tax Group Code",SalesHeader."Tax Liable",
                          SalesHeader."Posting Date","VAT Base",Quantity,SalesHeader."Currency Factor");
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
          IF VATAmountLine.GET(SalesLine."VAT Identifier",SalesLine."VAT Calculation Type",
               SalesLine."Tax Group Code",FALSE,SalesLine."Line Amount" >= 0)
          THEN BEGIN
            VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + TotalVATAmount;
            VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + TotalVATAmount;
            VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + TotalVATAmount;
            VATAmountLine.MODIFY;
          END;
    end;

    local procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetSalesHeader;
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
          IF SalesHeader.Status = SalesHeader.Status::Released THEN
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
          "VAT Difference" := 0;
        END;
    end;
 
    procedure UpdateWithWarehouseShip()
    begin
        IF Type = Type::Item THEN
          CASE TRUE OF
            ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND (Quantity >= 0):
              IF Location.RequireShipment("Location Code") THEN
                VALIDATE("Qty. to Ship",0)
              ELSE
                VALIDATE("Qty. to Ship","Outstanding Quantity");
            ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND (Quantity < 0):
              IF Location.RequireReceive("Location Code") THEN
                VALIDATE("Qty. to Ship",0)
              ELSE
                VALIDATE("Qty. to Ship","Outstanding Quantity");
            ("Document Type" = "Document Type"::"Return Order") AND (Quantity >= 0):
              IF Location.RequireReceive("Location Code") THEN
                VALIDATE("Return Qty. to Receive",0)
              ELSE
                VALIDATE("Return Qty. to Receive","Outstanding Quantity");
            ("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0):
              IF Location.RequireShipment("Location Code") THEN
                VALIDATE("Return Qty. to Receive",0)
              ELSE
                VALIDATE("Return Qty. to Receive","Outstanding Quantity");
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

        DialogText := Text035;
        IF ("Document Type" IN ["Document Type"::Order,"Document Type"::"Return Order"]) AND
           Location2."Directed Put-away and Pick"
        THEN BEGIN
          ShowDialog := ShowDialog::Error;
          IF (("Document Type" = "Document Type"::Order) AND (Quantity >= 0)) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0))
          THEN
            DialogText :=
              DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Shipment"))
          ELSE
            DialogText :=
              DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Receive"));
        END ELSE BEGIN
          IF (("Document Type" = "Document Type"::Order) AND (Quantity >= 0) AND
              (Location2."Require Shipment" OR Location2."Require Pick")) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity < 0) AND
              (Location2."Require Shipment" OR Location2."Require Pick"))
          THEN BEGIN
            IF WhseValidateSourceLine.WhseLinesExist(
                 DATABASE::"Sales Line",
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
              DialogText := Text036;
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Pick"));
            END;
          END;

          IF (("Document Type" = "Document Type"::Order) AND (Quantity < 0) AND
              (Location2."Require Receive" OR Location2."Require Put-away")) OR
             (("Document Type" = "Document Type"::"Return Order") AND (Quantity >= 0) AND
              (Location2."Require Receive" OR Location2."Require Put-away"))
          THEN BEGIN
            IF WhseValidateSourceLine.WhseLinesExist(
                 DATABASE::"Sales Line",
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
              DialogText := Text036;
              DialogText :=
                DialogText + Location2.GetRequirementText(Location2.FIELDNO("Require Put-away"));
            END;
          END;
        END;

        CASE ShowDialog OF
          ShowDialog::Message:
            MESSAGE(Text016 + Text017,DialogText,FIELDCAPTION("Line No."),"Line No.");
          ShowDialog::Error:
            ERROR(Text016,DialogText,FIELDCAPTION("Line No."),"Line No.");
        END;
    end;
 
    procedure UpdateDates()
    begin
        IF CurrFieldNo = 0 THEN BEGIN
          PlannedShipmentDateCalculated := FALSE;
          PlannedDeliveryDateCalculated := FALSE;
        END;
        IF "Promised Delivery Date" <> 0D THEN
          VALIDATE("Promised Delivery Date")
        ELSE
          IF "Requested Delivery Date" <> 0D THEN
            VALIDATE("Requested Delivery Date")
          ELSE BEGIN
            VALIDATE("Shipment Date");
            VALIDATE("Planned Delivery Date");
          END;
    end;
 
    procedure GetItemTranslation()
    begin
        GetSalesHeader;
        IF ItemTranslation.GET("No.","Variant Code",SalesHeader."Language Code") THEN BEGIN
          Description := ItemTranslation.Description;
          "Description 2" := ItemTranslation."Description 2";
        END;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        IF LocationCode = '' THEN
          CLEAR(Location)
        ELSE
          IF Location.Code <> LocationCode THEN
            Location.GET(LocationCode);
    end;
 
    procedure PriceExists(): Boolean
    begin
        IF "Document No." <> '' THEN BEGIN
          GetSalesHeader;
          EXIT(PriceCalcMgt.SalesLinePriceExists(SalesHeader,Rec,TRUE));
        END ELSE
          EXIT(FALSE);
    end;
 
    procedure LineDiscExists(): Boolean
    begin
        IF "Document No." <> '' THEN BEGIN
          GetSalesHeader;
          EXIT(PriceCalcMgt.SalesLineLineDiscExists(SalesHeader,Rec,TRUE));
        END ELSE
          EXIT(FALSE);
    end;
 
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "6500";
    begin
        EXIT(ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Line","Document Type",
            "Document No.",'',0,"Line No."));
    end;
 
    procedure GetItemCrossRef(CalledByFieldNo: Integer)
    begin
        IF CalledByFieldNo <> 0 THEN
          DistIntegration.EnterSalesItemCrossRef(Rec);
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
 
    procedure CheckAssocPurchOrder(TheFieldCaption: Text[250])
    begin
        IF TheFieldCaption = '' THEN BEGIN // If sales line is being deleted
          IF "Purch. Order Line No." <> 0 THEN
            ERROR(
              Text000,
              "Purchase Order No.",
              "Purch. Order Line No.");
          IF "Special Order Purch. Line No." <> 0 THEN
            ERROR(
              Text000,
              "Special Order Purchase No.",
              "Special Order Purch. Line No.");
        END;
        IF "Purch. Order Line No." <> 0 THEN
          ERROR(
            Text002,
            TheFieldCaption,
            "Purchase Order No.",
            "Purch. Order Line No.");
        IF "Special Order Purch. Line No." <> 0 THEN
          ERROR(
            Text002,
            TheFieldCaption,
            "Special Order Purchase No.",
            "Special Order Purch. Line No.");
    end;
 
    procedure CrossReferenceNoLookUp()
    var
        ItemCrossReference: Record "5717";
        ICGLAcc: Record "410";
    begin
        CASE Type OF
          Type::Item:
            BEGIN
              GetSalesHeader;
              ItemCrossReference.RESET;
              ItemCrossReference.SETCURRENTKEY("Cross-Reference Type","Cross-Reference Type No.");
              ItemCrossReference.SETFILTER(
                "Cross-Reference Type",'%1|%2',
                ItemCrossReference."Cross-Reference Type"::Customer,
                ItemCrossReference."Cross-Reference Type"::" ");
              ItemCrossReference.SETFILTER("Cross-Reference Type No.",'%1|%2',SalesHeader."Sell-to Customer No.",'');
              IF FORM.RUNMODAL(FORM::"Cross Reference List",ItemCrossReference) = ACTION::LookupOK THEN BEGIN
                VALIDATE("Cross-Reference No.",ItemCrossReference."Cross-Reference No.");
                PriceCalcMgt.FindSalesLineLineDisc(SalesHeader,Rec);
                PriceCalcMgt.FindSalesLinePrice(SalesHeader,Rec,FIELDNO("Cross-Reference No."));
                VALIDATE("Unit Price");
              END;
            END;
          Type::"G/L Account",Type::Resource:
            BEGIN
              GetSalesHeader;
              SalesHeader.TESTFIELD("Sell-to IC Partner Code");
              IF FORM.RUNMODAL(FORM::"IC G/L Account List") = ACTION::LookupOK THEN
                "Cross-Reference No." := ICGLAcc."No.";
            END;
        END;
    end;
 
    procedure CheckServItemCreation()
    var
        ServItemGroup: Record "5904";
    begin
        IF CurrFieldNo = 0 THEN
          EXIT;
        IF Type <> Type::Item THEN
          EXIT;
        Item.GET("No.");
        IF Item."Service Item Group" = '' THEN
          EXIT;
        IF ServItemGroup.GET(Item."Service Item Group") THEN
          IF ServItemGroup."Create Service Item" THEN
            IF "Qty. to Ship (Base)" <> ROUND("Qty. to Ship (Base)",1) THEN
              ERROR(
                Text034,
                FIELDCAPTION("Qty. to Ship (Base)"),
                ServItemGroup.FIELDCAPTION("Create Service Item"));
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
 
    procedure IsShipment(): Boolean
    begin
        EXIT(SignedXX("Quantity (Base)") < 0);
    end;

    local procedure GetAbsMin(QtyToHandle: Decimal;QtyHandled: Decimal): Decimal
    begin
        IF ABS(QtyHandled) < ABS(QtyToHandle) THEN
          EXIT(QtyHandled)
        ELSE
          EXIT(QtyToHandle);
    end;
 
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgEntry: Record "32")
    var
        ItemTrackingLines: Form "6510";
        QtyBase: Decimal;
        QtyNotReturned: Decimal;
        QtyReturned: Decimal;
    begin
        IF "Appl.-from Item Entry" = 0 THEN
          EXIT;

        IF "Shipment No." <> '' THEN
          EXIT;

        TESTFIELD(Type,Type::Item);
        TESTFIELD(Quantity);
        IF "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"] THEN BEGIN
          IF Quantity < 0 THEN
            FIELDERROR(Quantity,Text029);
        END ELSE BEGIN
          IF Quantity > 0 THEN
            FIELDERROR(Quantity,Text030);
        END;

        ItemLedgEntry.GET("Appl.-from Item Entry");
        ItemLedgEntry.TESTFIELD(Positive,FALSE);
        ItemLedgEntry.TESTFIELD("Item No.","No.");
        ItemLedgEntry.TESTFIELD("Variant Code","Variant Code");
        IF (ItemLedgEntry."Lot No." <> '') OR (ItemLedgEntry."Serial No." <> '') THEN
          ERROR(Text040,ItemTrackingLines.CAPTION,FIELDCAPTION("Appl.-from Item Entry"));

        CASE TRUE OF
          CurrFieldNo = Rec.FIELDNO(Quantity):
            QtyBase := "Quantity (Base)";
          "Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]:
            QtyBase := "Return Qty. to Receive (Base)"
          ELSE
            QtyBase := "Qty. to Ship (Base)";
        END;

        IF ABS(QtyBase) > -ItemLedgEntry.Quantity THEN
          ERROR(
            Text046,
            -ItemLedgEntry.Quantity,ItemLedgEntry.FIELDCAPTION("Document No."),
            ItemLedgEntry."Document No.");

        IF ABS(QtyBase) > -ItemLedgEntry."Shipped Qty. Not Returned" THEN BEGIN
          IF "Qty. per Unit of Measure" = 0 THEN BEGIN
            QtyNotReturned := ItemLedgEntry."Shipped Qty. Not Returned";
            QtyReturned := ItemLedgEntry.Quantity - ItemLedgEntry."Shipped Qty. Not Returned";
          END ELSE BEGIN
            QtyNotReturned :=
              ROUND(ItemLedgEntry."Shipped Qty. Not Returned" / "Qty. per Unit of Measure",0.00001);
            QtyReturned :=
              ROUND(
                (ItemLedgEntry.Quantity - ItemLedgEntry."Shipped Qty. Not Returned") /
                "Qty. per Unit of Measure",0.00001);
          END;
          ERROR(
            Text039,
            -QtyReturned,ItemLedgEntry.FIELDCAPTION("Document No."),
            ItemLedgEntry."Document No.",-QtyNotReturned);
        END;
    end;
 
    procedure CalcPrepaymentToDeduct()
    begin
        IF (Quantity - "Quantity Invoiced") <> 0 THEN BEGIN
          GetSalesHeader;
          IF SalesHeader."Prices Including VAT" THEN
            "Prepmt Amt to Deduct" :=
              ROUND(
                ROUND(
                  ROUND(
                    ROUND("Unit Price" * "Qty. to Invoice",Currency."Amount Rounding Precision") *
                    (1 - ("Line Discount %" / 100)),Currency."Amount Rounding Precision") *
                  ("Prepayment %" / 100) / (1 + ("VAT %" / 100)),Currency."Amount Rounding Precision") *
                (1 + ("VAT %" / 100)),Currency."Amount Rounding Precision")
          ELSE
            "Prepmt Amt to Deduct" :=
              ROUND(
                ROUND(
                  ROUND("Unit Price" * "Qty. to Invoice",Currency."Amount Rounding Precision") *
                  (1 - ("Line Discount %" / 100)),Currency."Amount Rounding Precision") *
                "Prepayment %" / 100 ,Currency."Amount Rounding Precision")
        END ELSE
          "Prepmt Amt to Deduct" := 0
    end;
 
    procedure SetHasBeenShown()
    begin
        HasBeenShown := TRUE;
    end;
 
    procedure TestJobPlanningLine()
    begin
        IF "Job Contract Entry No." = 0 THEN
          EXIT;
        JobPostLine.TestSalesLine(Rec);
    end;
 
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        ReserveSalesLine.Block(SetBlock);
    end;
 
    procedure InitQtyToShip2()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        CheckServItemCreation;

        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;

        CalcInvDiscToInvoice;

        CalcPrepaymentToDeduct;
    end;
 
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "44";
        SalesCommentSheet: Form "67";
    begin
        TESTFIELD("Document No.");
        TESTFIELD("Line No.");
        SalesCommentLine.SETRANGE("Document Type","Document Type");
        SalesCommentLine.SETRANGE("No.","Document No.");
        SalesCommentLine.SETRANGE("Document Line No.","Line No.");
        SalesCommentSheet.SETTABLEVIEW(SalesCommentLine);
        SalesCommentSheet.RUNMODAL;
    end;
 
    procedure SetDefaultQuantity()
    var
        SalesSetup: Record "311";
    begin
        SalesSetup.GET;
        IF SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank THEN BEGIN
          IF ("Document Type" = "Document Type"::Order) OR ("Document Type" = "Document Type"::Quote) THEN BEGIN
            "Qty. to Ship" := 0;
            "Qty. to Ship (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
          END;
          IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
            "Return Qty. to Receive" := 0;
            "Return Qty. to Receive (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
          END;
        END;
    end;
 
    procedure UpdatePrePaymentAmounts()
    var
        ShipmentLine: Record "111";
        SalesOrderLine: Record "37";
    begin
        IF NOT ShipmentLine.GET("Shipment No.","Shipment Line No.") THEN BEGIN
          "Prepmt Amt to Deduct" := 0;
          "Prepmt VAT Diff. to Deduct" := 0;
        END ELSE BEGIN
          IF SalesOrderLine.GET(SalesOrderLine."Document Type"::Order,ShipmentLine."Order No.",ShipmentLine."Order Line No.") THEN BEGIN
            "Prepmt Amt to Deduct" :=
              ROUND((SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted") *
                     Quantity / (SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced"),Currency."Amount Rounding Precision");
            "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
          END ELSE BEGIN
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
          END;
        END;

        GetSalesHeader;
        IF SalesHeader."Prices Including VAT" THEN BEGIN
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
 
    procedure ZeroAmountLine(QtyType: Option General,Invoicing,Shipping): Boolean
    begin
        IF Type = Type::" " THEN
          EXIT(TRUE);
        IF Quantity = 0 THEN
          EXIT(TRUE);
        IF ("Unit Price" = 0) OR ("Line Discount %" = 100) THEN
          EXIT(TRUE);
        IF QtyType = QtyType::Invoicing THEN
          IF "Qty. to Invoice" = 0 THEN
            EXIT(TRUE);
        EXIT(FALSE);
    end;
 
    procedure DeleteSPOLines()
    var
        SPOPaymentLine: Record "10012727";
        OptTypeValueHeader: Record "10012712";
        SPOSalesLineStatLine: Record "10012724";
    begin
        //LS
        SPOPaymentLine.SETRANGE("Document Type","Document Type");
        SPOPaymentLine.SETRANGE("Document No.","Document No.");
        SPOPaymentLine.SETRANGE("Document Line No.","Line No.");
        IF NOT SPOPaymentLine.ISEMPTY THEN
          SPOPaymentLine.DELETEALL(TRUE);

        SPOSalesLineStatLine.SETRANGE("Document Type","Document Type");
        SPOSalesLineStatLine.SETRANGE("No.","Document No.");
        SPOSalesLineStatLine.SETRANGE("Document Line No.","Line No.");
        IF NOT SPOSalesLineStatLine.ISEMPTY THEN
          SPOSalesLineStatLine.DELETEALL(TRUE);

        OptTypeValueHeader.SETFILTER("Configuration ID","Document No." + '.' + FORMAT("Line No."));
        IF NOT OptTypeValueHeader.ISEMPTY THEN
          OptTypeValueHeader.DELETEALL(TRUE);
    end;
 
    procedure ModifyAgreementBalance()
    var
        PaymentScheduleLine: Record "33016824";
        AgrmtLine: Record "33016816";
    begin
        //DP6.01.01 START
        IF "Document Type" = "Document Type"::Invoice THEN BEGIN
          PaymentScheduleLine.SETRANGE("Agreement Type","Ref. Document Type");
          PaymentScheduleLine.SETRANGE("Agreement No.","Ref. Document No.");
          PaymentScheduleLine.SETRANGE("Agreement Line No.","Ref. Document Line No.");
          PaymentScheduleLine.SETRANGE("Invoice No.","Document No.");
          PaymentScheduleLine.SETRANGE("Due Date","Agreement Due Date");
          IF PaymentScheduleLine.FINDFIRST THEN BEGIN
            PaymentScheduleLine."Invoice No." := '';
            PaymentScheduleLine.MODIFY;
          END;
          AgrmtLine.RESET;
          AgrmtLine.SETRANGE("Agreement Type","Ref. Document Type");
          AgrmtLine.SETRANGE("Agreement No.","Ref. Document No.");
          AgrmtLine.SETRANGE("Line No.","Ref. Document Line No.");
          IF AgrmtLine.FINDFIRST THEN BEGIN
            AgrmtLine."Balanced Amount" := AgrmtLine."Balanced Amount" + Amount;
            AgrmtLine.MODIFY;
          END;
        END
        ELSE BEGIN
          IF "Document Type" = "Document Type"::"Credit Memo" THEN BEGIN
            PaymentScheduleLine.SETRANGE("Agreement Type","Ref. Document Type");
            PaymentScheduleLine.SETRANGE("Agreement No.","Ref. Document No.");
            PaymentScheduleLine.SETRANGE("Agreement Line No.","Ref. Document Line No.");
            PaymentScheduleLine.SETRANGE("Credit Memo No.","Document No.");
            PaymentScheduleLine.SETRANGE("Due Date","Agreement Due Date");
            IF PaymentScheduleLine.FINDFIRST THEN BEGIN
              PaymentScheduleLine."Credit Memo No." := '';
              PaymentScheduleLine.MODIFY;
            END;
            AgrmtLine.RESET;
            AgrmtLine.SETRANGE("Agreement Type","Ref. Document Type");
            AgrmtLine.SETRANGE("Agreement No.","Ref. Document No.");
            AgrmtLine.SETRANGE("Line No.","Ref. Document Line No.");
            IF AgrmtLine.FINDFIRST THEN BEGIN
              AgrmtLine."Balanced Amount" := AgrmtLine."Balanced Amount" - Amount;
              AgrmtLine.MODIFY;
            END;
          END;
        END;
        //DP6.01.01 STOP
    end;
 
    procedure ShowLineBincodes()
    var
        DocumentBin: Record "50082";
        DocumentBinList: Form "50138";
    begin
        //APNT-T009914
        TESTFIELD(Barcode);
        TESTFIELD("Line No.");
        DocumentBin.SETRANGE(Type,DocumentBin.Type::"Sales Return");
        DocumentBin.SETRANGE("Document Type",DocumentBin."Document Type"::"Return Order");
        DocumentBin.SETRANGE("Document No.","Document No.");
        DocumentBin.SETRANGE("Document Line No.","Line No.");
        DocumentBin.SETRANGE("Barcode No.",Barcode);
        DocumentBin.SETRANGE("Location Code","Location Code");
        DocumentBinList.SETTABLEVIEW(DocumentBin);
        DocumentBinList.RUNMODAL;
        //APNT-T009914
    end;
 
    procedure ShowLineBincodesCrMemo()
    var
        DocumentBin: Record "50082";
        DocumentBinList: Form "50138";
    begin
        //APNT-T009914
        TESTFIELD(Barcode);
        TESTFIELD("Line No.");
        DocumentBin.SETRANGE(Type,DocumentBin.Type::"Credit Memo");
        DocumentBin.SETRANGE("Document Type",DocumentBin."Document Type"::"Credit Memo");
        DocumentBin.SETRANGE("Document No.","Document No.");
        DocumentBin.SETRANGE("Document Line No.","Line No.");
        DocumentBin.SETRANGE("Barcode No.",Barcode);
        DocumentBin.SETRANGE("Location Code","Location Code");
        DocumentBinList.SETTABLEVIEW(DocumentBin);
        DocumentBinList.RUNMODAL;
        //APNT-T009914
    end;
 
    procedure DiscardCarton()
    var
        Info: Dialog;
        BoxNo: Code[20];
        SalesLine: Record "37";
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
        CALCFIELDS(Status);
        TESTFIELD(Status,Status::Open);
        IF NOT CONFIRM('Do you want to Discard Carton No.?') THEN
          EXIT;

        SalesLine.RESET;
        SalesLine.SETRANGE("Document No.","Document No.");
        SalesLine.SETRANGE("Line No.","Line No.");
        IF SalesLine.FINDFIRST THEN BEGIN
          REPEAT
            HHTTransactions.RESET;
            HHTTransactions.SETRANGE("Transaction Type",'TRO');
            HHTTransactions.SETRANGE("Transaction No.","Document No.");
            HHTTransactions.SETRANGE(Closed,FALSE);
            HHTTransactions.SETRANGE("Box No.",SalesLine."Carton No.");
            HHTTransactions.SETRANGE(Discarded,FALSE);
            IF HHTTransactions.FINDFIRST THEN REPEAT
              HHTTransactions.Discarded := TRUE;
              HHTTransactions."Discarded By" := USERID;
              HHTTransactions."Discarded Date" := WORKDATE;
              HHTTransactions."Discarded Time" := TIME;
              HHTTransactions.MODIFY;
            UNTIL HHTTransactions.NEXT = 0;
            SalesLine.DELETE(TRUE);
          UNTIL SalesLine.NEXT = 0;
        END ELSE
          ERROR('Box No. %1 not found.',BoxNo);
    end;
 
    procedure CheckWMSExported()
    var
        RecSH: Record "36";
    begin
        //APNT-T030380
        RecSH.GET("Document Type","Document No.");
        IF NOT RecSH."eCOM Order" THEN
          RecSH.TESTFIELD(RecSH."WMS Exported",FALSE);
        //APNT-T030380
    end;
}

