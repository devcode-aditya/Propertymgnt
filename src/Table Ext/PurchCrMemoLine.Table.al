table 125 "Purch. Cr. Memo Line"
{
    // Code            Date      Name            Description
    // APNT-1.0        11.08.10  Tanweer         Added field
    // APNT-CO1.0      16.08.10  Tanweer         Added fields for Costing Customization
    // APNT-1.0        07.09.11  Tanweer         Added Barcode field
    // APNT-HHT1.0     01.11.12  Sujith          Added fields for HHT Customization
    // APNT-T001586    13.10.13  Sujith          Renamed field from Box No.to Carton No. for HHT Customization
    // DP = changes made by DVS
    // APNT-HRU1.0     10.03.14  Sangeeta        Added fields for HRU Customization.
    // APNT-WMS1.0 T015451     03.05.17    Shameema        Added changes for WMS Changes - CR
    // T034121       11.08.20    Deepak         Added field to handle the HHT Qty. to Receive Updated for Duplicate item selected in Order

    Caption = 'Purch. Cr. Memo Line';
    DrillDownFormID = Form530;
    LookupFormID = Form530;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purch. Cr. Memo Hdr.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,,"Fixed Asset","Charge (Item)";
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(G/L Account)) "G/L Account"
                            ELSE IF (Type=CONST(Item)) Item
                            ELSE IF (Type=CONST(Fixed Asset)) "Fixed Asset"
                            ELSE IF (Type=CONST("Charge (Item)")) "Item Charge";
        }
        field(7;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE (Use As In-Transit=CONST(No));
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
        }
        field(22;"Direct Unit Cost";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FIELDNO("Direct Unit Cost"));
            Caption = 'Direct Unit Cost';
        }
        field(23;"Unit Cost (LCY)";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
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
        }
        field(28;"Line Discount Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        field(29;Amount;Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30;"Amount Including VAT";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
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
        }
        field(40;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));
        }
        field(41;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));
        }
        field(45;"Job No.";Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(54;"Indirect Cost %";Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0:5;
            MinValue = 0;
        }
        field(68;"Pay-to Vendor No.";Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(69;"Inv. Discount Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
        }
        field(70;"Vendor Item No.";Text[20])
        {
            Caption = 'Vendor Item No.';
        }
        field(74;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(77;"VAT Calculation Type";Option)
        {
            Caption = 'VAT Calculation Type';
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
            TableRelation = "Purch. Cr. Memo Line"."Line No." WHERE (Document No.=FIELD(Document No.));
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
        }
        field(86;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(87;"Tax Group Code";Code[10])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(88;"Use Tax";Boolean)
        {
            Caption = 'Use Tax';
        }
        field(89;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(90;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(97;"Blanket Order No.";Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Purchase Header".No. WHERE (Document Type=CONST(Blanket Order));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(98;"Blanket Order Line No.";Integer)
        {
            Caption = 'Blanket Order Line No.';
            TableRelation = "Purchase Line"."Line No." WHERE (Document Type=CONST(Blanket Order),
                                                              Document No.=FIELD(Blanket Order No.));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(99;"VAT Base Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100;"Unit Cost";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
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
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FIELDNO("Line Amount"));
            Caption = 'Line Amount';
        }
        field(104;"VAT Difference";Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        field(106;"VAT Identifier";Code[10])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107;"IC Partner Ref. Type";Option)
        {
            Caption = 'IC Partner Ref. Type';
            OptionCaption = ' ,G/L Account,Item,,,Charge (Item),Cross reference,Common Item No.';
            OptionMembers = " ","G/L Account",Item,,,"Charge (Item)","Cross reference","Common Item No.";
        }
        field(108;"IC Partner Reference";Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        field(123;"Prepayment Line";Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(130;"IC Partner Code";Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(131;"Posting Date";Date)
        {
            Caption = 'Posting Date';
        }
        field(1001;"Job Task No.";Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE (Job No.=FIELD(Job No.));
        }
        field(1002;"Job Line Type";Option)
        {
            Caption = 'Job Line Type';
            OptionCaption = ' ,Schedule,Contract,Both Schedule and Contract';
            OptionMembers = " ",Schedule,Contract,"Both Schedule and Contract";
        }
        field(1003;"Job Unit Price";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price';
        }
        field(1004;"Job Total Price";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price';
        }
        field(1005;"Job Line Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount';
        }
        field(1006;"Job Line Discount Amount";Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Discount Amount';
        }
        field(1007;"Job Line Discount %";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Line Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(1008;"Job Unit Price (LCY)";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price (LCY)';
        }
        field(1009;"Job Total Price (LCY)";Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price (LCY)';
        }
        field(1010;"Job Line Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount (LCY)';
        }
        field(1011;"Job Line Disc. Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Disc. Amount (LCY)';
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
        }
        field(5402;"Variant Code";Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type=CONST(Item)) "Item Variant".Code WHERE (Item No.=FIELD(No.));
        }
        field(5403;"Bin Code";Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE (Location Code=FIELD(Location Code),
                                            Item Filter=FIELD(No.),
                                            Variant Filter=FIELD(Variant Code));
        }
        field(5404;"Qty. per Unit of Measure";Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(5407;"Unit of Measure Code";Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type=CONST(Item)) "Item Unit of Measure".Code WHERE (Item No.=FIELD(No.))
                            ELSE "Unit of Measure";
        }
        field(5415;"Quantity (Base)";Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0:5;
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
        }
        field(5602;"Depreciation Book Code";Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
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
        }
        field(5612;"Duplicate in Depreciation Book";Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613;"Use Duplication List";Boolean)
        {
            Caption = 'Use Duplication List';
        }
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5705;"Cross-Reference No.";Code[20])
        {
            Caption = 'Cross-Reference No.';
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
            TableRelation = IF (Type=CONST(Item)) "Item Category";
        }
        field(5710;Nonstock;Boolean)
        {
            Caption = 'Nonstock';
        }
        field(5711;"Purchasing Code";Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5712;"Product Group Code";Code[10])
        {
            Caption = 'Product Group Code';
            TableRelation = "Product Group".Code WHERE (Item Category Code=FIELD(Item Category Code));
        }
        field(6608;"Return Reason Code";Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(50000;Packing;Text[30])
        {
            Description = 'APNT-1.0';
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
    }

    keys
    {
        key(Key1;"Document No.","Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
            SumIndexFields = Amount,"Amount Including VAT";
        }
        key(Key2;"Blanket Order No.","Blanket Order Line No.")
        {
        }
        key(Key3;"Buy-from Vendor No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PurchDocLineComments: Record "43";
    begin
        DimMgt.DeletePostedDocDim(DATABASE::"Purch. Cr. Memo Line","Document No.","Line No.");
        PurchDocLineComments.SETRANGE("Document Type",PurchDocLineComments."Document Type"::"Posted Credit Memo");
        PurchDocLineComments.SETRANGE("No.","Document No.");
        PurchDocLineComments.SETRANGE("Document Line No.","Line No.");
        IF NOT PurchDocLineComments.ISEMPTY THEN
          PurchDocLineComments.DELETEALL;
    end;

    var
        DimMgt: Codeunit "408";
 
    procedure GetCurrencyCode(): Code[10]
    var
        PurchCrMemoHeader: Record "124";
    begin
        IF "Document No." = PurchCrMemoHeader."No." THEN
          EXIT(PurchCrMemoHeader."Currency Code");
        IF PurchCrMemoHeader.GET("Document No.") THEN
          EXIT(PurchCrMemoHeader."Currency Code");
        EXIT('');
    end;
 
    procedure ShowDimensions()
    var
        PostedDocDim: Record "359";
        PostedDocDimensions: Form "547";
    begin
        TESTFIELD("No.");
        TESTFIELD("Line No.");
        PostedDocDim.SETRANGE("Table ID",DATABASE::"Purch. Cr. Memo Line");
        PostedDocDim.SETRANGE("Document No.","Document No.");
        PostedDocDim.SETRANGE("Line No.","Line No.");
        PostedDocDimensions.SETTABLEVIEW(PostedDocDim);
        PostedDocDimensions.RUNMODAL;
    end;
 
    procedure ShowItemTrackingLines()
    var
        ItemTrackingMgt: Codeunit "6500";
    begin
        ItemTrackingMgt.CallPostedItemTrackingForm3(RowID1);
    end;
 
    procedure CalcVATAmountLines(var PurchCrMemoHeader: Record "124";var VATAmountLine: Record "290")
    begin
        VATAmountLine.DELETEALL;
        SETRANGE("Document No.",PurchCrMemoHeader."No.");
        IF FIND('-') THEN
          REPEAT
            VATAmountLine.INIT;
            VATAmountLine."VAT Identifier" := "VAT Identifier";
            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
            VATAmountLine."Tax Group Code" := "Tax Group Code";
            VATAmountLine."Use Tax" := "Use Tax";
            VATAmountLine."VAT %" := "VAT %";
            VATAmountLine."VAT Base" := Amount;
            VATAmountLine."VAT Amount" := "Amount Including VAT" - Amount;
            VATAmountLine."Amount Including VAT" := "Amount Including VAT";
            VATAmountLine."Line Amount" := "Line Amount";
            IF "Allow Invoice Disc." THEN
              VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
            VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
            VATAmountLine.Quantity := "Quantity (Base)";
            VATAmountLine."Calculated VAT Amount" := "Amount Including VAT" - Amount - "VAT Difference";
            VATAmountLine."VAT Difference" := "VAT Difference";
            VATAmountLine.InsertLine;
          UNTIL NEXT = 0;
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "2000000041";
    begin
        Field.GET(DATABASE::"Purch. Cr. Memo Line",FieldNumber);
        EXIT(Field."Field Caption");
    end;

    local procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        PurchCrMemoHeader: Record "124";
    begin
        IF NOT PurchCrMemoHeader.GET("Document No.") THEN
          PurchCrMemoHeader.INIT;
        IF PurchCrMemoHeader."Prices Including VAT" THEN
          EXIT('2,1,' + GetFieldCaption(FieldNumber))
        ELSE
          EXIT('2,0,' + GetFieldCaption(FieldNumber));
    end;
 
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "6500";
    begin
        EXIT(ItemTrackingMgt.ComposeRowID(DATABASE::"Purch. Cr. Memo Line",
          0,"Document No.",'',0,"Line No."));
    end;
 
    procedure GetReturnShptLines(var TempReturnShptLine: Record "6651" temporary)
    var
        ReturnShptLine: Record "6651";
        ItemLedgEntry: Record "32";
        ValueEntry: Record "5802";
    begin
        TempReturnShptLine.RESET;
        TempReturnShptLine.DELETEALL;

        IF Type <> Type::Item THEN
          EXIT;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SETFILTER("Invoiced Quantity",'<>0');
        IF ValueEntry.FINDSET THEN
          REPEAT
            ItemLedgEntry.GET(ValueEntry."Item Ledger Entry No.");
            IF ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Purchase Return Shipment" THEN
              IF ReturnShptLine.GET(ItemLedgEntry."Document No.",ItemLedgEntry."Document Line No.") THEN BEGIN
                TempReturnShptLine.INIT;
                TempReturnShptLine := ReturnShptLine;
                IF TempReturnShptLine.INSERT THEN;
              END;
          UNTIL ValueEntry.NEXT = 0;
    end;
 
    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "32";SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "32";
        ValueEntry: Record "5802";
    begin
        IF SetQuantity THEN BEGIN
          TempItemLedgEntry.RESET;
          TempItemLedgEntry.DELETEALL;

          IF Type <> Type::Item THEN
            EXIT;
        END;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SETFILTER("Invoiced Quantity",'<>0');
        IF ValueEntry.FINDSET THEN
          REPEAT
            ItemLedgEntry.GET(ValueEntry."Item Ledger Entry No.");
            TempItemLedgEntry := ItemLedgEntry;
            IF SetQuantity THEN BEGIN
              TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
              IF ABS(TempItemLedgEntry."Remaining Quantity") > ABS(TempItemLedgEntry.Quantity) THEN
                TempItemLedgEntry."Remaining Quantity" := ABS(TempItemLedgEntry.Quantity);
            END;
            IF TempItemLedgEntry.INSERT THEN;
          UNTIL ValueEntry.NEXT = 0;
    end;
 
    procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "5802")
    begin
        ValueEntry.RESET;
        ValueEntry.SETCURRENTKEY("Document No.");
        ValueEntry.SETRANGE("Document No.","Document No.");
        ValueEntry.SETRANGE("Document Type",ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.SETRANGE("Document Line No.","Line No.");
    end;
 
    procedure ShowItemLedgEntries()
    var
        TempItemLedgEntry: Record "32" temporary;
    begin
        IF Type = Type::Item THEN BEGIN
          GetItemLedgEntries(TempItemLedgEntry,FALSE);
          FORM.RUNMODAL(0,TempItemLedgEntry);
        END;
    end;
 
    procedure ShowItemReturnShptLines()
    var
        TempReturnShptLine: Record "6651" temporary;
    begin
        IF Type = Type::Item THEN BEGIN
          GetReturnShptLines(TempReturnShptLine);
          FORM.RUNMODAL(0,TempReturnShptLine);
        END;
    end;
 
    procedure ShowLineComments()
    var
        PurchDocLineComments: Record "43";
        PurchDocCommentSheet: Form "66";
    begin
        PurchDocLineComments.SETRANGE("Document Type",PurchDocLineComments."Document Type"::"Posted Credit Memo");
        PurchDocLineComments.SETRANGE("No.","Document No.");
        PurchDocLineComments.SETRANGE("Document Line No.","Line No.");
        PurchDocCommentSheet.SETTABLEVIEW(PurchDocLineComments);
        PurchDocCommentSheet.RUNMODAL;
    end;
}

