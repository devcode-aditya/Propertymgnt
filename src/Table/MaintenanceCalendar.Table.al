table 33016852 "Maintenance Calendar"
{
    Caption = 'Maintenance Calendar';

    fields
    {
        field(1; "Facility Code"; Code[20])
        {
            TableRelation = Facility;
        }
        field(2; "Job Code"; Code[20])
        {
            Editable = false;
            TableRelation = "Job Type";
        }
        field(3; "Task Code"; Code[20])
        {
            Editable = false;
            TableRelation = "Task Code";
        }
        field(4; "Task Description"; Text[50])
        {
            Editable = false;
        }
        field(5; "Service Starting Date"; Date)
        {
            Caption = 'Planned Date';
            Editable = false;

            trigger OnValidate()
            begin
                Name := FORMAT("Service Starting Date", 0, Text33016851);
            end;
        }
        field(6; Name; Text[10])
        {
            Editable = false;
        }
        field(7; "Work Order No."; Code[20])
        {
            Editable = false;
        }
        field(8; "WO Closed/Cancelled"; Boolean)
        {
            Editable = false;
        }
        field(9; "Maintenance Line No"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Facility Code", "Job Code", "Task Code", "Maintenance Line No", "Service Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Work Order No.")
        {
        }
        key(Key3; "WO Closed/Cancelled")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TESTFIELD("WO Closed/Cancelled", FALSE);
        TESTFIELD("Work Order No.", '');

        DeleteCalendarLines;
    end;

    var
        Text33016851: Label '<Month Text>';
        Text33016852: Label 'You cannot delete calendar partially for Facility = %1, Job No = %2 and Task No = %3';
        Text33016853: Label 'This action will Delete all Lines of the Task. Do you want to continue?';

    procedure DeleteCalendarLines()
    var
        MCalendar: Record "Maintenance Calendar";
        FacilityMaintenanceLine: Record "Facility Maintenance";
    begin
        IF CONFIRM(Text33016853, TRUE) THEN BEGIN
            MCalendar.SETRANGE("Facility Code", "Facility Code");
            MCalendar.SETRANGE("Job Code", "Job Code");
            MCalendar.SETRANGE("Task Code", "Task Code");
            MCalendar.SETRANGE("Maintenance Line No", "Maintenance Line No");
            IF MCalendar.FINDSET THEN BEGIN
                REPEAT
                    IF MCalendar."Service Starting Date" <> "Service Starting Date" THEN BEGIN
                        MCalendar.TESTFIELD("Work Order No.", '');
                        MCalendar.TESTFIELD("WO Closed/Cancelled", FALSE);
                        MCalendar.DELETE;
                    END;
                UNTIL MCalendar.NEXT = 0;
            END;

            FacilityMaintenanceLine.SETRANGE("Facility Code", "Facility Code");
            FacilityMaintenanceLine.SETRANGE("Job Code", "Job Code");
            FacilityMaintenanceLine.SETRANGE("Task Code", "Task Code");
            FacilityMaintenanceLine.SETRANGE("Line No", "Maintenance Line No");
            IF FacilityMaintenanceLine.FINDFIRST THEN BEGIN
                FacilityMaintenanceLine."End Date-Time" := 0DT;
                FacilityMaintenanceLine."Maint. Cal. Created" := FALSE;
                FacilityMaintenanceLine.MODIFY;
            END;
        END ELSE
            ERROR('');
    end;
}

