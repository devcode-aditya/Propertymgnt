table 33016863 "WO Res. Allocation"
{
    DrillDownFormID = Form33016905;
    LookupFormID = Form33016905;

    fields
    {
        field(1; "Work Order No."; Code[20])
        {
        }
        field(2; "Work Order Line No."; Integer)
        {
            Editable = false;
        }
        field(3; "Task Code"; Code[20])
        {
            Editable = false;
        }
        field(4; "Planned Date"; Date)
        {
            Editable = false;
        }
        field(5; "Resource No."; Code[20])
        {
            TableRelation = Resource WHERE(Blocked = FILTER(No));

            trigger OnValidate()
            var
                Res: Record Resource;
            begin
                IF "Resource No." <> '' THEN BEGIN
                    Res.GET("Resource No.");
                    "Resource Name" := Res.Name;
                    UOM := Res."Base Unit of Measure";
                END ELSE BEGIN
                    "Resource Name" := '';
                    UOM := '';
                END;

                IF "Resource No." <> xRec."Resource No." THEN
                    CheckWOResAllocationEntries;
            end;
        }
        field(6; "Resource Name"; Text[30])
        {
        }
        field(7; UOM; Code[10])
        {
            TableRelation = "Unit of Measure".Code;
        }
        field(8; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }
        field(9; "Assigned Qty."; Decimal)
        {
            CalcFormula = Sum("WO Res. Allocation Entries"."Assigned Qty." WHERE(Resource No.=FIELD(Resource No.),
                                                                                  Work Order No.=FIELD(Work Order No.),
                                                                                  Task Code=FIELD(Task Code),
                                                                                  Date=FIELD(Date Filter)));
            DecimalPlaces = 0:5;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TESTFIELD("Resource No.");
            end;
        }
        field(10;"Line  No.";Integer)
        {
        }
        field(11;"Task Type";Option)
        {
            OptionCaption = ' ,Labour,Material';
            OptionMembers = " ",Labour,Material;
        }
    }

    keys
    {
        key(Key1;"Work Order No.","Work Order Line No.","Task Code","Planned Date","Line  No.")
        {
            Clustered = true;
        }
        key(Key2;"Work Order No.","Work Order Line No.","Resource No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WOResAllocationEntries: Record "WO Res. Allocation Entries";
    begin
        TestWOStatus;

        WOResAllocationEntries.RESET;
        WOResAllocationEntries.SETRANGE("Work Order No.","Work Order No.");
        WOResAllocationEntries.SETRANGE("Task Code","Task Code");
        IF "Resource No." <> '' THEN
          WOResAllocationEntries.SETRANGE("Resource No.","Resource No.");
        WOResAllocationEntries.DELETEALL;
    end;

    trigger OnModify()
    begin
        TestWOStatus;
    end;
 
    procedure TestWOStatus()
    var
        WorkOrderHeader: Record "Work Order Header";
    begin
        WorkOrderHeader.GET(WorkOrderHeader."Document Type"::"Work Order","Work Order No.");
        WorkOrderHeader.TESTFIELD("WO Status",WorkOrderHeader."WO Status"::New);
    end;
 
    procedure CheckWOResAllocationEntries()
    var
        WOResAlloctationEntry: Record "WO Res. Allocation Entries";
    begin
        WOResAlloctationEntry.SETRANGE("Work Order No.","Work Order No.");
        WOResAlloctationEntry.SETRANGE("Task Code","Task Code");
        WOResAlloctationEntry.SETRANGE("Resource No.",xRec."Resource No.");
        WOResAlloctationEntry.DELETEALL;
    end;
}

