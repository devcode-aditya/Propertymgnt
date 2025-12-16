table 156 Resource
{
    // LS = changes made by LS Retail
    // DP = changes made by DVS

    Caption = 'Resource';
    DataCaptionFields = "No.", Name;
    DrillDownFormID = Form77;
    LookupFormID = Form77;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    ResSetup.GET;
                    NoSeriesMgt.TestManual(ResSetup."Resource Nos.");
                    "No. Series" := '';
                END;
            end;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Person,Machine';
            OptionMembers = Person,Machine;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                IF ("Search Name" = UPPERCASE(xRec.Name)) OR ("Search Name" = '') THEN
                    "Search Name" := Name;
            end;
        }
        field(4; "Search Name"; Code[50])
        {
            Caption = 'Search Name';
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[50])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity(City, "Post Code", TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code");
            end;
        }
        field(9; "Social Security No."; Text[30])
        {
            Caption = 'Social Security No.';
        }
        field(10; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(11; Education; Text[30])
        {
            Caption = 'Education';
        }
        field(12; "Contract Class"; Text[30])
        {
            Caption = 'Contract Class';
        }
        field(13; "Employment Date"; Date)
        {
            Caption = 'Employment Date';
        }
        field(14; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                IF "Resource Group No." = xRec."Resource Group No." THEN
                    EXIT;

                IF xRec."Resource Group No." <> '' THEN BEGIN
                    IF NOT
                       CONFIRM(
                         Text001, FALSE,
                         FIELDCAPTION("Resource Group No."))
                    THEN BEGIN
                        "Resource Group No." := xRec."Resource Group No.";
                        EXIT;
                    END;
                END;

                IF xRec.GETFILTER("Resource Group No.") <> '' THEN
                    SETFILTER("Resource Group No.", "Resource Group No.");


                // Resource Capacity Entries
                ResCapacityEntry.SETCURRENTKEY("Resource No.");
                ResCapacityEntry.SETRANGE("Resource No.", "No.");
                ResCapacityEntry.MODIFYALL("Resource Group No.", "Resource Group No.");

                PlanningLine.SETCURRENTKEY(Type, "No.");
                PlanningLine.SETRANGE(Type, PlanningLine.Type::Resource);
                PlanningLine.SETRANGE("No.", "No.");
                PlanningLine.SETRANGE("Schedule Line", TRUE);
                PlanningLine.MODIFYALL("Resource Group No.", "Resource Group No.");
            end;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(18; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Resource Unit of Measure".Code WHERE(Resource No.=FIELD(No.));

            trigger OnValidate()
            var
                ResUnitOfMeasure: Record "205";
                ResLedgEnty: Record "203";
            begin
                IF "Base Unit of Measure" <> xRec."Base Unit of Measure" THEN BEGIN
                  ResLedgEnty.SETCURRENTKEY("Resource No.");
                  ResLedgEnty.SETRANGE("Resource No.","No.");
                  IF ResLedgEnty.FIND('-') THEN
                    ERROR(Text002,FIELDCAPTION("Base Unit of Measure"));
                END;

                ResUnitOfMeasure.GET("No.","Base Unit of Measure");
                ResUnitOfMeasure.TESTFIELD("Qty. per Unit of Measure",1);
                ResUnitOfMeasure.TESTFIELD("Related to Base Unit of Meas.");
            end;
        }
        field(19;"Direct Unit Cost";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                VALIDATE("Indirect Cost %");
            end;
        }
        field(20;"Indirect Cost %";Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 2:2;

            trigger OnValidate()
            begin
                VALIDATE("Unit Cost",ROUND("Direct Unit Cost" * (1 + "Indirect Cost %" / 100)));
            end;
        }
        field(21;"Unit Cost";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                VALIDATE("Price/Profit Calculation");
            end;
        }
        field(22;"Profit %";Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0:5;

            trigger OnValidate()
            begin
                VALIDATE("Price/Profit Calculation");
            end;
        }
        field(23;"Price/Profit Calculation";Option)
        {
            Caption = 'Price/Profit Calculation';
            OptionCaption = 'Profit=Price-Cost,Price=Cost+Profit,No Relationship';
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";

            trigger OnValidate()
            begin
                CASE "Price/Profit Calculation" OF
                  "Price/Profit Calculation"::"Profit=Price-Cost":
                    IF "Unit Price" <> 0 THEN
                      "Profit %" := ROUND(100 * (1 - "Unit Cost" / "Unit Price"),0.00001)
                    ELSE
                      "Profit %" := 0;
                  "Price/Profit Calculation"::"Price=Cost+Profit":
                    IF "Profit %" < 100 THEN
                      "Unit Price" := ROUND("Unit Cost" / (1 - "Profit %" / 100),0.00001);
                END;
            end;
        }
        field(24;"Unit Price";Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                VALIDATE("Price/Profit Calculation");
            end;
        }
        field(25;"Vendor No.";Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(26;"Last Date Modified";Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(27;Comment;Boolean)
        {
            CalcFormula = Exist("Comment Line" WHERE (Table Name=CONST(Resource),
                                                      No.=FIELD(No.)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38;Blocked;Boolean)
        {
            Caption = 'Blocked';
        }
        field(39;"Date Filter";Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(40;"Unit of Measure Filter";Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(41;Capacity;Decimal)
        {
            CalcFormula = Sum("Res. Capacity Entry".Capacity WHERE (Resource No.=FIELD(No.),
                                                                    Date=FIELD(Date Filter)));
            Caption = 'Capacity';
            DecimalPlaces = 0:5;
            FieldClass = FlowField;
        }
        field(42;"Qty. on Order (Job)";Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE (Status=CONST(Order),
                                                                           Schedule Line=CONST(Yes),
                                                                           Type=CONST(Resource),
                                                                           No.=FIELD(No.),
                                                                           Planning Date=FIELD(Date Filter)));
            Caption = 'Qty. on Order (Job)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(43;"Qty. Quoted (Job)";Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE (Status=CONST(Quote),
                                                                           Schedule Line=CONST(Yes),
                                                                           Type=CONST(Resource),
                                                                           No.=FIELD(No.),
                                                                           Planning Date=FIELD(Date Filter)));
            Caption = 'Qty. Quoted (Job)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(44;"Usage (Qty.)";Decimal)
        {
            CalcFormula = Sum("Res. Ledger Entry"."Quantity (Base)" WHERE (Entry Type=CONST(Usage),
                                                                           Chargeable=FIELD(Chargeable Filter),
                                                                           Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                           Resource No.=FIELD(No.),
                                                                           Posting Date=FIELD(Date Filter)));
            Caption = 'Usage (Qty.)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(45;"Usage (Cost)";Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = Sum("Res. Ledger Entry"."Total Cost" WHERE (Entry Type=CONST(Usage),
                                                                      Chargeable=FIELD(Chargeable Filter),
                                                                      Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                      Resource No.=FIELD(No.),
                                                                      Posting Date=FIELD(Date Filter)));
            Caption = 'Usage (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(46;"Usage (Price)";Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = Sum("Res. Ledger Entry"."Total Price" WHERE (Entry Type=CONST(Usage),
                                                                       Chargeable=FIELD(Chargeable Filter),
                                                                       Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                       Resource No.=FIELD(No.),
                                                                       Posting Date=FIELD(Date Filter)));
            Caption = 'Usage (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47;"Sales (Qty.)";Decimal)
        {
            CalcFormula = -Sum("Res. Ledger Entry"."Quantity (Base)" WHERE (Entry Type=CONST(Sale),
                                                                            Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                            Resource No.=FIELD(No.),
                                                                            Posting Date=FIELD(Date Filter)));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(48;"Sales (Cost)";Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = -Sum("Res. Ledger Entry"."Total Cost" WHERE (Entry Type=CONST(Sale),
                                                                       Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                       Resource No.=FIELD(No.),
                                                                       Posting Date=FIELD(Date Filter)));
            Caption = 'Sales (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(49;"Sales (Price)";Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = -Sum("Res. Ledger Entry"."Total Price" WHERE (Entry Type=CONST(Sale),
                                                                        Unit of Measure Code=FIELD(Unit of Measure Filter),
                                                                        Resource No.=FIELD(No.),
                                                                        Posting Date=FIELD(Date Filter)));
            Caption = 'Sales (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50;"Chargeable Filter";Boolean)
        {
            Caption = 'Chargeable Filter';
            FieldClass = FlowFilter;
        }
        field(51;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                IF xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" THEN
                  IF GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp,"Gen. Prod. Posting Group") THEN
                    VALIDATE("VAT Prod. Posting Group",GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(52;Picture;BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(53;"Post Code";Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City,"Post Code");
            end;
        }
        field(54;County;Text[30])
        {
            Caption = 'County';
        }
        field(55;"Automatic Ext. Texts";Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(56;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(57;"Tax Group Code";Code[10])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(58;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(59;"Country/Region Code";Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = Country/Region;
        }
        field(60;"IC Partner Purch. G/L Acc. No.";Code[20])
        {
            Caption = 'IC Partner Purch. G/L Acc. No.';
            TableRelation = "IC G/L Account";
        }
        field(5900;"Qty. on Service Order";Decimal)
        {
            CalcFormula = Sum("Service Order Allocation"."Allocated Hours" WHERE (Posted=CONST(No),
                                                                                  Resource No.=FIELD(No.),
                                                                                  Allocation Date=FIELD(Date Filter),
                                                                                  Status=CONST(Active)));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0:5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5901;"Service Zone Filter";Code[10])
        {
            Caption = 'Service Zone Filter';
            TableRelation = "Service Zone";
        }
        field(5902;"In Customer Zone";Boolean)
        {
            CalcFormula = Exist("Resource Service Zone" WHERE (Resource No.=FIELD(No.),
                                                               Service Zone Code=FIELD(Service Zone Filter)));
            Caption = 'In Customer Zone';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10000700;"Location Filter";Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
        field(10000701;"Global Dimension 1 Filter";Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));
        }
        field(10000702;"Global Dimension 2 Filter";Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));
        }
        field(33016800;"Resource Type";Option)
        {
            Description = 'DP6.01.01';
            OptionCaption = 'Internal,External';
            OptionMembers = Internal,External;

            trigger OnValidate()
            begin
                //DP6.01.01 START
                IF "Resource Type" <> xRec."Resource Type" THEN
                  UpdateExternalVendorDetail;
                //DP6.01.01 STOP
            end;
        }
        field(33016801;"Linked Vendor";Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = IF (Resource Type=CONST(External)) Vendor;

            trigger OnValidate()
            begin
                UpdateExternalVendorDetail;  //DP6.01.01
            end;
        }
        field(33016802;"Resource Mobile No.";Code[20])
        {
            Description = 'DP6.01.01';
        }
        field(33016803;"Qty. On Work Order";Decimal)
        {
            CalcFormula = Sum("WO Res. Allocation Entries"."Assigned Qty." WHERE (Resource No.=FIELD(No.),
                                                                                  Date=FIELD(Date Filter)));
            DecimalPlaces = 0:5;
            Description = 'DP6.01.01';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Search Name")
        {
        }
        key(Key3;"Gen. Prod. Posting Group")
        {
        }
        key(Key4;Name)
        {
        }
        key(Key5;Type)
        {
        }
        key(Key6;"Base Unit of Measure")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"No.",Name,Type,"Base Unit of Measure")
        {
        }
    }

    trigger OnDelete()
    begin
        MoveEntries.MoveResEntries(Rec);

        ResCapacityEntry.SETCURRENTKEY("Resource No.");
        ResCapacityEntry.SETRANGE("Resource No.","No.");
        ResCapacityEntry.DELETEALL;

        ResCost.SETRANGE(Type,ResCost.Type::Resource);
        ResCost.SETRANGE(Code,"No.");
        ResCost.DELETEALL;

        ResPrice.SETRANGE(Type,ResPrice.Type::Resource);
        ResPrice.SETRANGE(Code,"No.");
        ResPrice.DELETEALL;

        CommentLine.SETRANGE("Table Name",CommentLine."Table Name"::Resource);
        CommentLine.SETRANGE("No.","No.");
        CommentLine.DELETEALL;

        ExtTextHeader.SETRANGE("Table Name",ExtTextHeader."Table Name"::Resource);
        ExtTextHeader.SETRANGE("No.","No.");
        ExtTextHeader.DELETEALL(TRUE);

        ResSkill.RESET;
        ResSkill.SETRANGE(Type,ResSkill.Type::Resource);
        ResSkill.SETRANGE("No.","No.");
        ResSkill.DELETEALL;

        ResLoc.RESET;
        ResLoc.SETCURRENTKEY("Resource No.","Starting Date");
        ResLoc.SETRANGE("Resource No.","No.");
        ResLoc.DELETEALL;

        ResServZone.RESET;
        ResServZone.SETRANGE("Resource No.","No.");
        ResServZone.DELETEALL;

        ResUnitMeasure.RESET;
        ResUnitMeasure.SETRANGE("Resource No.","No.");
        ResUnitMeasure.DELETEALL;

        SalesOrderLine.SETCURRENTKEY(Type,"No.");
        SalesOrderLine.SETFILTER("Document Type",'%1|%2',
          SalesOrderLine."Document Type"::Order,
          SalesOrderLine."Document Type"::"Return Order");
        SalesOrderLine.SETRANGE(Type,SalesOrderLine.Type::Resource);
        SalesOrderLine.SETRANGE("No.","No.");
        IF SalesOrderLine.FIND('-') THEN BEGIN
          IF SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::Order THEN
            ERROR(Text000,TABLECAPTION,"No.");
          IF SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::"Return Order" THEN
            ERROR(Text003,TABLECAPTION,"No.");
        END;

        DimMgt.DeleteDefaultDim(DATABASE::Resource,"No.");
    end;

    trigger OnInsert()
    begin
        IF "No." = '' THEN BEGIN
          ResSetup.GET;
          ResSetup.TESTFIELD("Resource Nos.");
          NoSeriesMgt.InitSeries(ResSetup."Resource Nos.",xRec."No. Series",0D,"No.","No. Series");
        END;

        IF GETFILTER("Resource Group No.") <> '' THEN
          IF GETRANGEMIN("Resource Group No.") = GETRANGEMAX("Resource Group No.") THEN
            VALIDATE("Resource Group No.",GETRANGEMIN("Resource Group No."));

        DimMgt.UpdateDefaultDim(
          DATABASE::Resource,"No.",
          "Global Dimension 1 Code","Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := TODAY;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := TODAY;
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because there are one or more outstanding Sales Orders that include this resource.';
        Text001: Label 'Do you want to change %1?';
        ResSetup: Record "314";
        Res: Record "156";
        ResCapacityEntry: Record "160";
        CommentLine: Record "97";
        ResCost: Record "202";
        ResPrice: Record "201";
        SalesOrderLine: Record "37";
        ExtTextHeader: Record "279";
        PostCode: Record "225";
        GenProdPostingGrp: Record "251";
        ResSkill: Record "5956";
        ResLoc: Record "5952";
        ResServZone: Record "5958";
        ResUnitMeasure: Record "205";
        PlanningLine: Record "1003";
        NoSeriesMgt: Codeunit "396";
        MoveEntries: Codeunit "361";
        DimMgt: Codeunit "408";
        Text002: Label 'You cannot change %1 because there are ledger entries for this resource.';
        Text003: Label 'You cannot delete %1 %2 because there are one or more outstanding Sales Return Orders that include this resource.';
        Text004: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
 
    procedure AssistEdit(OldRes: Record "156"): Boolean
    begin
        WITH Res DO BEGIN
          Res := Rec;
          ResSetup.GET;
          ResSetup.TESTFIELD("Resource Nos.");
          IF NoSeriesMgt.SelectSeries(ResSetup."Resource Nos.",OldRes."No. Series","No. Series") THEN BEGIN
            ResSetup.GET;
            ResSetup.TESTFIELD("Resource Nos.");
            NoSeriesMgt.SetSeries("No.");
            Rec := Res;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::Resource,"No.",FieldNumber,ShortcutDimCode);
        MODIFY;
    end;
 
    procedure DisplayMap()
    var
        MapPoint: Record "800";
        MapMgt: Codeunit "802";
    begin
        IF MapPoint.FIND('-') THEN
          MapMgt.MakeSelection(DATABASE::Resource,GETPOSITION)
        ELSE
          MESSAGE(Text004);
    end;
 
    procedure UpdateExternalVendorDetail()
    var
        VendorRec: Record "23";
    begin
        //DP6.01.01 START
        IF ("Resource Type" = "Resource Type"::External) THEN BEGIN
          IF "Linked Vendor" <> '' THEN BEGIN
            VendorRec.GET("Linked Vendor");
            Name := VendorRec.Name;
            "Search Name" := VendorRec."Search Name";
            "Name 2" := VendorRec."Name 2";
            Address := VendorRec.Address;
            "Address 2" := VendorRec."Address 2";
            City := VendorRec.City;
            "Global Dimension 1 Code" := VendorRec."Global Dimension 1 Code";
            "Global Dimension 2 Code" := VendorRec."Global Dimension 2 Code";
            "Post Code" := VendorRec."Post Code";
            County := VendorRec.County;
            "Country/Region Code" := VendorRec."Country/Region Code";
            "Resource Mobile No." := VendorRec."Phone No.";
          END ELSE IF ("Linked Vendor" = '') THEN
            ClearResourceData;
        END ELSE IF  ("Resource Type" = "Resource Type"::Internal) THEN
          ClearResourceData;
        //DP6.01.01 STOP
    end;
 
    procedure ClearResourceData()
    begin
        //DP6.01.01 START
        "Linked Vendor" := '';
        Name := '';
        "Search Name" := '';
        "Name 2" := '';
        Address := '';
        "Address 2" := '';
        City := '';
        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';
        "Post Code" := '';
        County := '';
        "Country/Region Code" := '';
        "Resource Mobile No." := '';
        //DP6.01.01 STOP
    end;
}

