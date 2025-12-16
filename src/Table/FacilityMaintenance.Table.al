table 33016840 "Facility Maintenance"
{
    Caption = 'Facility Maintenance';
    LookupFormID = Form33016838;

    fields
    {
        field(1; "Facility Code"; Code[20])
        {
            TableRelation = Facility;
        }
        field(2; "Job Code"; Code[20])
        {
            NotBlank = true;
            TableRelation = "Job Type";

            trigger OnValidate()
            begin
                TESTFIELD("Maint. Cal. Created", FALSE);
            end;
        }
        field(4; "Service Period"; DateFormula)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Maint. Cal. Created", FALSE);
            end;
        }
        field(5; "Start Date-Time"; DateTime)
        {

            trigger OnValidate()
            begin
                IF "End Date-Time" <> 0DT THEN
                    IF "Start Date-Time" > "End Date-Time" THEN
                        ERROR(Text33016800);
                IF "Start Date-Time" = 0DT THEN
                    "End Date-Time" := 0DT;

                TESTFIELD("Maint. Cal. Created", FALSE);
            end;
        }
        field(6; "End Date-Time"; DateTime)
        {

            trigger OnValidate()
            begin
                IF "End Date-Time" <> 0DT THEN BEGIN
                    IF "Start Date-Time" = 0DT THEN
                        ERROR(Text33016801);
                    IF "Start Date-Time" > "End Date-Time" THEN
                        ERROR(Text33016800);
                END;
                TESTFIELD("Maint. Cal. Created", FALSE);
            end;
        }
        field(7; "Maintenance Done"; Boolean)
        {
        }
        field(8; "No. of Periods"; Integer)
        {

            trigger OnValidate()
            begin
                IF "No. of Periods" < 0 THEN
                    ERROR(Text33016871);

                TESTFIELD("Maint. Cal. Created", FALSE);
            end;
        }
        field(9; "Task Code"; Code[20])
        {
            TableRelation = "Task Code";

            trigger OnValidate()
            var
                TaskCode: Record "Task Code";
            begin
                TESTFIELD("Maint. Cal. Created", FALSE);
                IF TaskCode.GET("Task Code") THEN
                    "Task Description" := TaskCode.Description;
            end;
        }
        field(10; "Task Description"; Text[50])
        {
        }
        field(11; "Maint. Cal. Created"; Boolean)
        {
            Caption = 'Maint. Cal. Created';
            Editable = false;
        }
        field(12; "Line No"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Facility Code", "Job Code", "Task Code", "Line No")
        {
            Clustered = true;
        }
        key(Key2; "Facility Code", "Maint. Cal. Created")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TESTFIELD("Maint. Cal. Created", FALSE);
    end;

    var
        Text33016800: Label 'End DateTime must be greater than Start DateTime';
        Text33016801: Label 'Start DateTime must not be blank';
        Text33016822: Label 'Calendar created for facility %1';
        Text33016871: Label 'No. of Periods must not be negative';

    procedure CreateMaintenaceCalendar()
    var
        FacilityRec: Record Facility;
        FacilityMaintenanceRec: Record "Facility Maintenance";
        MaintenanceCalendar: Record "Maintenance Calendar";
        ServiceStartingDate: Date;
        NewPeriodDate: Date;
        i: Integer;
        ServiceEndDate: Date;
        FacilityMaintenanceRec1: Record "Facility Maintenance";
        ServiceStartTime: Time;
        ServiceEndDateTime: DateTime;
    begin
        FacilityMaintenanceRec.RESET;
        FacilityMaintenanceRec.SETCURRENTKEY("Facility Code", "Maint. Cal. Created");
        FacilityMaintenanceRec.SETRANGE("Facility Code", "Facility Code");
        FacilityMaintenanceRec.SETRANGE("Maint. Cal. Created", FALSE);
        IF FacilityMaintenanceRec.FINDSET THEN BEGIN
            REPEAT
                FacilityMaintenanceRec.TESTFIELD("Task Code");
                FacilityMaintenanceRec.TESTFIELD("Service Period");
                FacilityMaintenanceRec.TESTFIELD("No. of Periods");
                FacilityMaintenanceRec.TESTFIELD(FacilityMaintenanceRec."Start Date-Time");

                ServiceStartingDate := DT2DATE(FacilityMaintenanceRec."Start Date-Time");
                ServiceStartTime := DT2TIME(FacilityMaintenanceRec."Start Date-Time");

                NewPeriodDate := ServiceStartingDate;
                FOR i := 1 TO FacilityMaintenanceRec."No. of Periods" DO BEGIN
                    NewPeriodDate := CALCDATE(FacilityMaintenanceRec."Service Period", NewPeriodDate);
                    MaintenanceCalendar.INIT;
                    MaintenanceCalendar.VALIDATE("Facility Code", FacilityMaintenanceRec."Facility Code");
                    MaintenanceCalendar.VALIDATE("Job Code", FacilityMaintenanceRec."Job Code");
                    MaintenanceCalendar.VALIDATE("Task Code", FacilityMaintenanceRec."Task Code");
                    MaintenanceCalendar."Maintenance Line No" := FacilityMaintenanceRec."Line No";
                    MaintenanceCalendar.VALIDATE("Task Description", FacilityMaintenanceRec."Task Description");
                    MaintenanceCalendar.VALIDATE("Service Starting Date", NewPeriodDate);
                    MaintenanceCalendar.INSERT(TRUE);
                END;
                FacilityMaintenanceRec1.RESET;
                FacilityMaintenanceRec1.SETRANGE("Facility Code", FacilityMaintenanceRec."Facility Code");
                FacilityMaintenanceRec1.SETRANGE("Job Code", FacilityMaintenanceRec."Job Code");
                FacilityMaintenanceRec1.SETRANGE("Task Code", FacilityMaintenanceRec."Task Code");
                FacilityMaintenanceRec1.SETRANGE("Line No", FacilityMaintenanceRec."Line No");
                IF FacilityMaintenanceRec1.FINDFIRST THEN BEGIN
                    FacilityMaintenanceRec1."End Date-Time" := CREATEDATETIME(NewPeriodDate, ServiceStartTime);
                    FacilityMaintenanceRec1.VALIDATE("Maint. Cal. Created", TRUE);
                    FacilityMaintenanceRec1.MODIFY(TRUE);
                END;
            UNTIL FacilityMaintenanceRec.NEXT = 0;
            MESSAGE(Text33016822, "Facility Code");
        END;
    end;
}

