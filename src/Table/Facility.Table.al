table 33016802 Facility
{
    Caption = 'Facility';
    LookupFormID = Form33016802;

    fields
    {
        field(1; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgtSetup.GET;
                    NoSeriesMgt.TestManual(PremiseMgtSetup."Facility No.");
                    "No. Series" := '';
                END;
            end;
        }
        field(2; Name; Text[50])
        {
        }
        field(3; "Facility Type"; Code[20])
        {
            TableRelation = "Facility Type";

            trigger OnValidate()
            var
                FaclityType: Record "Facility Type";
            begin
                IF "Facility Type" <> '' THEN BEGIN
                    FaclityType.GET("Facility Type");
                    Utility := FaclityType.Utility;
                END;
            end;
        }
        field(4; "Facility Resource"; Code[20])
        {
            TableRelation = Resource;
        }
        field(5; "Linked Premise Code"; Code[20])
        {
            TableRelation = Premise.No. WHERE(Blocked = CONST(No));

            trigger OnValidate()
            var
                Premise: Record Premise;
            begin
                IF Premise.GET("Linked Premise Code") THEN BEGIN
                    "Floor No." := Premise."Floor No.";
                END;
            end;
        }
        field(6; "Maintenance Vendor"; Code[20])
        {
            TableRelation = Vendor;
        }
        field(8; "Under Maintenance"; Boolean)
        {
        }
        field(9; Picture; BLOB)
        {
            SubType = Bitmap;
        }
        field(10; "Linked Fixed Asset"; Code[20])
        {
            TableRelation = "Fixed Asset";
        }
        field(11; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(12; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(13; "No. Series"; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = Exist("Comment Line" WHERE(Table Name=CONST(16),
                                                      No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(15;"Revenue Account";Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(16;"Expense Account";Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(17;"Facility Vendor";Code[20])
        {
            TableRelation = Vendor;

            trigger OnValidate()
            var
                UnitConsumptionRec: Record "Utility Unit Consumption";
            begin
                IF xRec."Facility Vendor" <> "Facility Vendor" THEN BEGIN
                  UnitConsumptionRec.RESET;
                  UnitConsumptionRec.SETRANGE("Facility No.","No.");
                  IF UnitConsumptionRec.FINDFIRST THEN BEGIN
                    IF CONFIRM(Text010,FALSE,UnitConsumptionRec."Facility No.") THEN
                      REPEAT
                        UnitConsumptionRec.VALIDATE("Facility Vendor No.","Facility Vendor");
                        UnitConsumptionRec.MODIFY;
                      UNTIL UnitConsumptionRec.NEXT = 0;
                  END;
                END;
            end;
        }
        field(18;"Due Date Calculation";DateFormula)
        {
        }
        field(19;"Grace Period";DateFormula)
        {
        }
        field(20;"Total Unit Consumption";Decimal)
        {
            CalcFormula = Sum("Utility Unit Consumption"."Unit Consumed" WHERE (Facility No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(22;"Floor No.";Code[10])
        {
            TableRelation = "Premise Floor"."Floor No.";
        }
        field(33;"Main/Component Facility";Option)
        {
            Editable = false;
            OptionCaption = ' ,Main,Component';
            OptionMembers = " ",Main,Component;
        }
        field(34;"Ref Main Facility";Code[20])
        {
            Editable = false;
            TableRelation = Facility;
        }
        field(35;Planned;Boolean)
        {
        }
        field(36;"Facility Group";Code[20])
        {
            TableRelation = "Facility Group"."Facility Group";

            trigger OnValidate()
            begin
                IF "Facility Group" <> xRec."Facility Group" THEN
                  "Facility Sub Group" := '';
            end;
        }
        field(37;"Facility Sub Group";Code[20])
        {
            TableRelation = "Facility Sub Group"."Facility Sub Group" WHERE (Facility Group=FIELD(Facility Group));
        }
        field(38;"Contract A/C No.";Text[20])
        {
        }
        field(39;"Consumer No.";Text[20])
        {
        }
        field(40;"Issued By Authority";Text[30])
        {
        }
        field(41;Utility;Boolean)
        {
            Editable = false;
        }
        field(42;"Calculation Priority";Option)
        {
            OptionCaption = 'Unit Wise,Slab Wise';
            OptionMembers = "Unit Wise","Slab Wise";
        }
        field(43;"Meter No.";Text[30])
        {
        }
        field(44;"Surcharge Exp. G/L Account";Code[20])
        {
            TableRelation = "G/L Account".No.;
        }
        field(45;"Surcharge Inc. G/L Account";Code[20])
        {
            TableRelation = "G/L Account".No.;
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Ref Main Facility")
        {
        }
        key(Key3;Planned)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine.SETRANGE("Table Name",CommentLine."Table Name"::"16");
        CommentLine.SETRANGE("No.","No.");
        CommentLine.DELETEALL;

        DimMgt.DeleteDefaultDim(DATABASE::Facility,"No.");
    end;

    trigger OnInsert()
    begin
        IF "No." = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Facility No.");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Facility No.",xRec."No. Series",0D,"No.","No. Series");
        END;

        DimMgt.UpdateDefaultDim(DATABASE::Facility,"No.","Global Dimension 1 Code","Global Dimension 2 Code");
    end;

    var
        PremiseMgtSetup: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        DimMgt: Codeunit "408";
        Text001: Label 'You cannot change Start Date %1. Service Calendar contains both closed & unclosed entries  for Facility %2';
        Text002: Label 'You cannot change Start Date %1. Service Calendar contains both open & completed entries  for Facility %2';
        Text003: Label 'You cannot change Start Date %1. Service Calendar contains unclosed entries for Facility %2';
        Text004: Label 'You cannot change Service Period Length %1. Service Calendar contains both closed & unclosed entries  for Facility %2';
        Text005: Label 'You cannot change Service Period Length %1. Service Calendar contains both open & completed entries  for Facility %2';
        Text006: Label 'You cannot change Service Period Length %1. Service Calendar contains unclosed entries for Facility %2';
        Text007: Label 'You cannot change No. of Periods %1. Service Calendar contains both closed & unclosed entries  for Facility %2';
        Text008: Label 'You cannot change No. of Periods %1. Service Calendar contains both open & completed entries  for Facility %2';
        Text009: Label 'You cannot change No. of Periods %1. Service Calendar contains unclosed entries for Facility %2';
        Text010: Label 'Unit Consumption Entries exists for Facility %1. Do you want to update the Facility Vendor?';
 
    procedure AssistEdit(OldFacility: Record Facility): Boolean
    var
        FacilityRec: Record Facility;
    begin
        WITH FacilityRec DO BEGIN
          FacilityRec := Rec;
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Facility No.");
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup."Facility No.",OldFacility."No. Series","No. Series") THEN BEGIN
            NoSeriesMgt.SetSeries("No.");
            Rec := FacilityRec;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::Facility,"No.",FieldNumber,ShortcutDimCode);
        MODIFY;
    end;
 
    procedure ValidateFacilityMaintenance(FacilityCode: Code[20]): Boolean
    var
        FacilityMaintenanceRec: Record "Facility Maintenance";
    begin
        FacilityMaintenanceRec.RESET;
        FacilityMaintenanceRec.SETRANGE("Facility Code",FacilityCode);
        FacilityMaintenanceRec.SETRANGE("Maintenance Done",FALSE);
        FacilityMaintenanceRec.SETFILTER("Start Date-Time",'<=%1',CREATEDATETIME(TODAY,000000T));
        FacilityMaintenanceRec.SETFILTER("End Date-Time",'>=%1',CREATEDATETIME(TODAY,235900T));
        IF FacilityMaintenanceRec.FINDFIRST THEN
          EXIT(TRUE);
        EXIT(FALSE);
    end;
 
    procedure ValidateFacilityCalendar()
    begin
    end;
}

