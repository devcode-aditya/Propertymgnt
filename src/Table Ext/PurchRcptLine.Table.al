table 121 "Purch. Rcpt. Line"
{
    // LS = changes made by LS Retail
    // Code            Date      Name            Description
    // APNT-1.0        11.08.10  Tanweer         Added field
    // APNT-CO1.0      16.08.10  Tanweer         Added fields for Costing Customization
    // APNT-1.0        07.09.11  Tanweer         Added Barcode field
    // APNT-HHT1.0     01.11.12  Sujith          Added fields for HHT Customization
    // APNT-T001586    13.10.13  Sujith          Renamed field from Box No.to Carton No. for HHT Customization
    // DP = changes made by DVS
    // APNT-HRU1.0     10.03.14  Sangeeta        Added fields for HRU Customization.
    // APNT-WMS1.0 T015451     03.05.17    Shameema        Added changes for WMS Changes - CR
    // T034121        11.08.20   Deepak          Added field to handle the HHT Qty. to Receive Updated for Duplicate item selected in Order

    Caption = 'Purch. Rcpt. Line';
    LookupFormID = Form528;
    Permissions = TableData 32 = r,
                  TableData 5802 = r;

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
            TableRelation = "Purch. Rcpt. Header";
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
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 2;
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
        field(39;"Item Rcpt. Entry No.";Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
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
        field(58;"Qty. Rcd. Not Invoiced";Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(61;"Quantity Invoiced";Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0:5;
            Editable = false;
        }
        field(65;"Order No.";Code[20])
        {
            Caption = 'Order No.';
        }
        field(66;"Order Line No.";Integer)
        {
            Caption = 'Order Line No.';
        }
        field(68;"Pay-to Vendor No.";Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(70;"Vendor Item No.";Text[20])
        {
            Caption = 'Vendor Item No.';
        }
        field(71;"Sales Order No.";Code[20])
        {
            Caption = 'Sales Order No.';
        }
        field(72;"Sales Order Line No.";Integer)
        {
            Caption = 'Sales Order Line No.';
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
            TableRelation = "Purch. Rcpt. Line"."Line No." WHERE (Document No.=FIELD(Document No.));
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
        field(91;"Currency Code";Code[10])
        {
            CalcFormula = Lookup("Purch. Rcpt. Header"."Currency Code" WHERE (No.=FIELD(Document No.)));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
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
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100;"Unit Cost";Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
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
            TableRelation = "Production Order".No. WHERE (Status=FILTER(Released|Finished));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
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
        field(5461;"Qty. Invoiced (Base)";Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0:5;
            Editable = false;
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
        field(5714;"Special Order Sales No.";Code[20])
        {
            Caption = 'Special Order Sales No.';
        }
        field(5715;"Special Order Sales Line No.";Integer)
        {
            Caption = 'Special Order Sales Line No.';
        }
        field(5790;"Requested Receipt Date";Date)
        {
            Caption = 'Requested Receipt Date';
        }
        field(5791;"Promised Receipt Date";Date)
        {
            Caption = 'Promised Receipt Date';
        }
        field(5792;"Lead Time Calculation";DateFormula)
        {
            Caption = 'Lead Time Calculation';
        }
        field(5793;"Inbound Whse. Handling Time";DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';
        }
        field(5794;"Planned Receipt Date";Date)
        {
            Caption = 'Planned Receipt Date';
        }
        field(5795;"Order Date";Date)
        {
            Caption = 'Order Date';
        }
        field(5811;"Item Charge Base Amount";Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        field(5817;Correction;Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        field(6608;"Return Reason Code";Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
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
        field(99000750;"Routing No.";Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(99000751;"Operation No.";Code[10])
        {
            Caption = 'Operation No.';
            TableRelation = "Prod. Order Routing Line"."Operation No." WHERE (Status=FILTER(Released..),
                                                                              Prod. Order No.=FIELD(Prod. Order No.),
                                                                              Routing No.=FIELD(Routing No.));
        }
        field(99000752;"Work Center No.";Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";
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
        }
        field(99000759;"Routing Reference No.";Integer)
        {
            Caption = 'Routing Reference No.';
        }
    }

    keys
    {
        key(Key1;"Document No.","Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Order No.","Order Line No.")
        {
        }
        key(Key3;"Blanket Order No.","Blanket Order Line No.")
        {
        }
        key(Key4;"Item Rcpt. Entry No.")
        {
        }
        key(Key5;"Pay-to Vendor No.")
        {
        }
        key(Key6;"Buy-from Vendor No.")
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
        DimMgt.DeletePostedDocDim(DATABASE::"Purch. Rcpt. Line","Document No.","Line No.");
        PurchDocLineComments.SETRANGE("Document Type",PurchDocLineComments."Document Type"::Receipt);
        PurchDocLineComments.SETRANGE("No.","Document No.");
        PurchDocLineComments.SETRANGE("Document Line No.","Line No.");
        IF NOT PurchDocLineComments.ISEMPTY THEN
          PurchDocLineComments.DELETEALL;
    end;

    var
        Text000: Label 'Receipt No. %1:';
        Text001: Label 'The program cannot find this purchase line.';
        Currency: Record "4";
        PurchRcptHeader: Record "120";
        DimMgt: Codeunit "408";
        CurrencyRead: Boolean;
 
    procedure GetCurrencyCodeFromHeader(): Code[10]
    begin
        IF "Document No." = PurchRcptHeader."No." THEN
          EXIT(PurchRcptHeader."Currency Code");
        IF PurchRcptHeader.GET("Document No.") THEN
          EXIT(PurchRcptHeader."Currency Code");
        EXIT('');
    end;
 
    procedure ShowDimensions()
    var
        PostedDocDim: Record "359";
        PostedDocDimensions: Form "547";
    begin
        TESTFIELD("No.");
        TESTFIELD("Line No.");
        PostedDocDim.SETRANGE("Table ID",DATABASE::"Purch. Rcpt. Line");
        PostedDocDim.SETRANGE("Document No.","Document No.");
        PostedDocDim.SETRANGE("Line No.","Line No.");
        PostedDocDimensions.SETTABLEVIEW(PostedDocDim);
        PostedDocDimensions.RUNMODAL;
    end;
 
    procedure ShowItemTrackingLines()
    var
        ItemTrackingMgt: Codeunit "6500";
    begin
        ItemTrackingMgt.CallPostedItemTrackingForm(DATABASE::"Purch. Rcpt. Line",0,"Document No.",'',0,"Line No.");
    end;
 
    procedure InsertInvLineFromRcptLine(var PurchLine: Record "39";var TempFromDocDim: Record "357" temporary)
    var
        PurchInvHeader: Record "38";
        PurchOrderHeader: Record "38";
        PurchOrderLine: Record "39";
        TempPurchLine: Record "39";
        ToDocDim: Record "357";
        FromDocDim: Record "357";
        PurchSetup: Record "312";
        TransferOldExtLines: Codeunit "379";
        ItemTrackingMgt: Codeunit "6500";
        NextLineNo: Integer;
        ExtTextLine: Boolean;
    begin
        SETRANGE("Document No.","Document No.");

        TempPurchLine := PurchLine;
        IF PurchLine.FIND('+') THEN
          NextLineNo := PurchLine."Line No." + 10000
        ELSE
          NextLineNo := 10000;

        IF PurchInvHeader."No." <> TempPurchLine."Document No." THEN
          PurchInvHeader.GET(TempPurchLine."Document Type",TempPurchLine."Document No.");

        IF PurchLine."Receipt No." <> "Document No." THEN BEGIN
          PurchLine.INIT;
          PurchLine."Line No." := NextLineNo;
          PurchLine."Document Type" := TempPurchLine."Document Type";
          PurchLine."Document No." := TempPurchLine."Document No.";
          PurchLine.Description := STRSUBSTNO(Text000,"Document No.");
          PurchLine.INSERT;
          NextLineNo := NextLineNo + 10000;
        END;

        TransferOldExtLines.ClearLineNumbers;

        REPEAT
          ExtTextLine := (TransferOldExtLines.GetNewLineNumber("Attached to Line No.") <> 0);

          IF PurchOrderLine.GET(
              PurchOrderLine."Document Type"::Order,"Order No.","Order Line No.")
          THEN BEGIN
            IF (PurchOrderHeader."Document Type" <> PurchOrderLine."Document Type"::Order) OR
               (PurchOrderHeader."No." <> PurchOrderLine."Document No.")
            THEN
              PurchOrderHeader.GET(PurchOrderLine."Document Type"::Order,"Order No.");

            InitCurrency("Currency Code");

            IF PurchInvHeader."Prices Including VAT" THEN BEGIN
              IF NOT PurchOrderHeader."Prices Including VAT" THEN
                PurchOrderLine."Direct Unit Cost" :=
                  ROUND(
                    PurchOrderLine."Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100),
                    Currency."Unit-Amount Rounding Precision");
            END ELSE BEGIN
              IF PurchOrderHeader."Prices Including VAT" THEN
                PurchOrderLine."Direct Unit Cost" :=
                  ROUND(
                    PurchOrderLine."Direct Unit Cost" / (1 + PurchOrderLine."VAT %" / 100),
                    Currency."Unit-Amount Rounding Precision");
            END;
          END ELSE BEGIN
            IF ExtTextLine THEN BEGIN
              PurchOrderLine.INIT;
              PurchOrderLine."Line No." := "Order Line No.";
              PurchOrderLine.Description := Description;
              PurchOrderLine."Description 2" := "Description 2";
            END ELSE
              ERROR(Text001);
          END;
          PurchLine := PurchOrderLine;
          PurchLine."Line No." := NextLineNo;
          PurchLine."Document Type" := TempPurchLine."Document Type";
          PurchLine."Document No." := TempPurchLine."Document No.";
          PurchLine."Variant Code" := "Variant Code";
          PurchLine."Location Code" := "Location Code";
          PurchLine."Quantity (Base)" := 0;
          PurchLine.Quantity := 0;
          PurchLine."Outstanding Qty. (Base)" := 0;
          PurchLine."Outstanding Quantity" := 0;
          PurchLine."Quantity Received" := 0;
          PurchLine."Qty. Received (Base)" := 0;
          PurchLine."Quantity Invoiced" := 0;
          PurchLine."Qty. Invoiced (Base)" := 0;
          PurchLine.Amount := 0;
          PurchLine."Amount Including VAT" := 0;
          PurchLine."Sales Order No." := '';
          PurchLine."Sales Order Line No." := 0;
          PurchLine."Drop Shipment" := FALSE;
          PurchLine."Special Order Sales No." := '';
          PurchLine."Special Order Sales Line No." := 0;
          PurchLine."Special Order" := FALSE;
          PurchLine."Receipt No." := "Document No.";
          PurchLine."Receipt Line No." := "Line No.";
          IF NOT ExtTextLine THEN BEGIN
            PurchLine.VALIDATE(Quantity,Quantity - "Quantity Invoiced");
            PurchLine.VALIDATE("Direct Unit Cost",PurchOrderLine."Direct Unit Cost");
            PurchLine.VALIDATE("Line Discount %",PurchOrderLine."Line Discount %");
            PurchSetup.GET;
            IF NOT PurchSetup."Calc. Inv. Discount" THEN
              IF PurchOrderLine.Quantity = 0 THEN
                PurchLine.VALIDATE("Inv. Discount Amount",0)
              ELSE
                PurchLine.VALIDATE(
                  "Inv. Discount Amount",
                  ROUND(
                    PurchOrderLine."Inv. Discount Amount" * PurchLine.Quantity / PurchOrderLine.Quantity,
                    Currency."Amount Rounding Precision"));
          END;

          PurchLine."Attached to Line No." :=
            TransferOldExtLines.TransferExtendedText(
              "Line No.",
              NextLineNo,
              "Attached to Line No.");
          PurchLine."Shortcut Dimension 1 Code" := PurchOrderLine."Shortcut Dimension 1 Code";
          PurchLine."Shortcut Dimension 2 Code" := PurchOrderLine."Shortcut Dimension 2 Code";

          IF "Sales Order No." = '' THEN
            PurchLine."Drop Shipment" := FALSE
          ELSE
            PurchLine."Drop Shipment" := TRUE;

          PurchLine.INSERT;

          ItemTrackingMgt.CopyHandledItemTrkgToInvLine2(PurchOrderLine,PurchLine);

          FromDocDim.SETRANGE("Table ID",DATABASE::"Purchase Line");
          FromDocDim.SETRANGE("Document Type",PurchOrderLine."Document Type");
          FromDocDim.SETRANGE("Document No.",PurchOrderLine."Document No.");
          FromDocDim.SETRANGE("Line No.",PurchOrderLine."Line No.");

          ToDocDim.SETRANGE("Table ID",DATABASE::"Purchase Line");
          ToDocDim.SETRANGE("Document Type",PurchLine."Document Type");
          ToDocDim.SETRANGE("Document No.",PurchLine."Document No.");
          ToDocDim.SETRANGE("Line No.", PurchLine."Line No.");
          ToDocDim.DELETEALL;

          IF FromDocDim.FIND('-') THEN
            REPEAT
              TempFromDocDim.INIT;
              TempFromDocDim := FromDocDim;
              TempFromDocDim."Table ID" := DATABASE::"Purchase Line";
              TempFromDocDim."Document Type" := PurchLine."Document Type";
              TempFromDocDim."Document No." := PurchLine."Document No.";
              TempFromDocDim."Line No." := PurchLine."Line No.";
              TempFromDocDim.INSERT;
            UNTIL FromDocDim.NEXT = 0;

          NextLineNo := NextLineNo + 10000;
          //LS -
          IF ("Attached to Line No." = 0) OR
             ("Attached to Line No." <> 0) AND ("Variant Code" <> '')
          THEN
            SETRANGE("Attached to Line No.","Line No.");
          //LS +
        UNTIL (NEXT = 0) OR ("Attached to Line No." = 0);
    end;
 
    procedure GetPurchInvLines(var TempPurchInvLine: Record "123" temporary)
    var
        PurchInvLine: Record "123";
        ItemLedgEntry: Record "32";
        ValueEntry: Record "5802";
    begin
        TempPurchInvLine.RESET;
        TempPurchInvLine.DELETEALL;

        IF Type <> Type::Item THEN
          EXIT;

        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        ItemLedgEntry.SETFILTER("Invoiced Quantity",'<>0');
        IF ItemLedgEntry.FINDSET THEN BEGIN
          ValueEntry.SETCURRENTKEY("Item Ledger Entry No.","Entry Type");
          ValueEntry.SETRANGE("Entry Type",ValueEntry."Entry Type"::"Direct Cost");
          ValueEntry.SETFILTER("Invoiced Quantity",'<>0');
          REPEAT
            ValueEntry.SETRANGE("Item Ledger Entry No.",ItemLedgEntry."Entry No.");
            IF ValueEntry.FINDSET THEN
              REPEAT
                IF ValueEntry."Document Type" = ValueEntry."Document Type"::"Purchase Invoice" THEN
                  IF PurchInvLine.GET(ValueEntry."Document No.",ValueEntry."Document Line No.") THEN BEGIN
                    TempPurchInvLine.INIT;
                    TempPurchInvLine := PurchInvLine;
                    IF TempPurchInvLine.INSERT THEN;
                  END;
              UNTIL ValueEntry.NEXT = 0;
          UNTIL ItemLedgEntry.NEXT = 0;
        END;
    end;
 
    procedure CalcReceivedPurchNotReturned(var RemainingQty: Decimal;var RevUnitCostLCY: Decimal;ExactCostReverse: Boolean)
    var
        ItemLedgEntry: Record "32";
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
    begin
        RemainingQty := 0;
        IF (Type <> Type::Item) OR (Quantity <= 0) THEN BEGIN
          RevUnitCostLCY := "Unit Cost (LCY)";
          EXIT;
        END;

        RevUnitCostLCY := 0;
        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        IF ItemLedgEntry.FINDSET THEN
          REPEAT
            RemainingQty := RemainingQty + ItemLedgEntry."Remaining Quantity";
            IF ExactCostReverse THEN BEGIN
              ItemLedgEntry.CALCFIELDS("Cost Amount (Expected)","Cost Amount (Actual)");
              TotalCostLCY :=
                TotalCostLCY + ItemLedgEntry."Cost Amount (Expected)" + ItemLedgEntry."Cost Amount (Actual)";
              TotalQtyBase := TotalQtyBase + ItemLedgEntry.Quantity;
            END;
          UNTIL ItemLedgEntry.NEXT = 0;

        IF ExactCostReverse AND (RemainingQty <> 0) AND (TotalQtyBase <> 0) THEN
          RevUnitCostLCY := ABS(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        ELSE
          RevUnitCostLCY := "Unit Cost (LCY)";

        RemainingQty := CalcQty(RemainingQty);
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        IF "Qty. per Unit of Measure" = 0 THEN
          EXIT(QtyBase);
        EXIT(ROUND(QtyBase / "Qty. per Unit of Measure",0.00001));
    end;
 
    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "32")
    begin
        ItemLedgEntry.RESET;
        ItemLedgEntry.SETCURRENTKEY("Document No.");
        ItemLedgEntry.SETRANGE("Document No.","Document No.");
        ItemLedgEntry.SETRANGE("Document Type",ItemLedgEntry."Document Type"::"Purchase Receipt");
        ItemLedgEntry.SETRANGE("Document Line No.","Line No.");
    end;
 
    procedure ShowItemLedgEntries()
    var
        ItemLedgEntry: Record "32";
    begin
        IF Type = Type::Item THEN BEGIN
          FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
          FORM.RUNMODAL(0,ItemLedgEntry);
        END;
    end;
 
    procedure ShowItemPurchInvLines()
    var
        TempPurchInvLine: Record "123" temporary;
    begin
        IF Type = Type::Item THEN BEGIN
          GetPurchInvLines(TempPurchInvLine);
          FORM.RUNMODAL(FORM::"Posted Purchase Invoice Lines",TempPurchInvLine);
        END;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        IF (Currency.Code = CurrencyCode) AND CurrencyRead THEN
          EXIT;

        IF CurrencyCode <> '' THEN
          Currency.GET(CurrencyCode)
        ELSE
          Currency.InitRoundingPrecision;
        CurrencyRead := TRUE;
    end;
 
    procedure ShowLineComments()
    var
        PurchDocLineComments: Record "43";
        PurchDocCommentSheet: Form "66";
    begin
        PurchDocLineComments.SETRANGE("Document Type",PurchDocLineComments."Document Type"::Receipt);
        PurchDocLineComments.SETRANGE("No.","Document No.");
        PurchDocLineComments.SETRANGE("Document Line No.","Line No.");
        PurchDocCommentSheet.SETTABLEVIEW(PurchDocLineComments);
        PurchDocCommentSheet.RUNMODAL;
    end;
 
    procedure ShowLineBincodes()
    var
        DocumentBin: Record "50082";
        DocumentBinList: Form "50140";
    begin
        //APNT-T009914
        TESTFIELD(Barcode);
        TESTFIELD("Line No.");
        DocumentBin.SETRANGE(Type,DocumentBin.Type::GRN);
        DocumentBin.SETRANGE("Document Type",DocumentBin."Document Type"::Order);
        DocumentBin.SETRANGE("Document No.","Order No.");
        DocumentBin.SETRANGE("Purchase Receipt No.","Document No.");
        DocumentBin.SETRANGE("Document Line No.","Order Line No.");
        DocumentBin.SETRANGE("Barcode No.",Barcode);
        DocumentBin.SETRANGE("Location Code","Location Code");
        DocumentBinList.SETTABLEVIEW(DocumentBin);
        DocumentBinList.RUNMODAL;
        //APNT-T009914
    end;
}

