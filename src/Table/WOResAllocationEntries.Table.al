table 33016864 "WO Res. Allocation Entries"
{
    DrillDownFormID = Form33016906;
    LookupFormID = Form33016906;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(2; "Resource No."; Code[20])
        {
        }
        field(3; Date; Date)
        {
        }
        field(4; "Assigned Qty."; Decimal)
        {
        }
        field(5; "Work Order No."; Code[20])
        {
        }
        field(6; "Task Code"; Code[20])
        {
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Work Order No.", "Task Code", "Resource No.", Date)
        {
            SumIndexFields = "Assigned Qty.";
        }
    }

    fieldgroups
    {
    }
}

