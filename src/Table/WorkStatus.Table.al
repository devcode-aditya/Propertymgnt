table 33016821 "Work Status"
{
    LookupFormID = Form33016835;

    fields
    {
        field(1; "Work Status Code"; Code[10])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
        field(3; Cancelled; Boolean)
        {

            trigger OnValidate()
            begin
                IF Cancelled THEN BEGIN
                    WorkStatus.RESET;
                    WorkStatus.SETFILTER("Work Status Code", '<>%1', "Work Status Code");
                    WorkStatus.SETRANGE(Cancelled, TRUE);
                    IF WorkStatus.FINDFIRST THEN
                        ERROR(Text001, WorkStatus."Work Status Code");
                END;
            end;
        }
        field(4; Closed; Boolean)
        {

            trigger OnValidate()
            begin
                IF Closed THEN BEGIN
                    WorkStatus.RESET;
                    WorkStatus.SETFILTER("Work Status Code", '<>%1', "Work Status Code");
                    WorkStatus.SETRANGE(Closed, TRUE);
                    IF WorkStatus.FINDFIRST THEN
                        ERROR(Text002, WorkStatus."Work Status Code");
                END;
            end;
        }
        field(5; Default; Boolean)
        {

            trigger OnValidate()
            begin
                IF Default THEN BEGIN
                    WorkStatus.RESET;
                    WorkStatus.SETFILTER("Work Status Code", '<>%1', "Work Status Code");
                    WorkStatus.SETRANGE(Default, TRUE);
                    IF WorkStatus.FINDFIRST THEN
                        ERROR(Text003, WorkStatus."Work Status Code");
                END;
            end;
        }
        field(6; Active; Boolean)
        {

            trigger OnValidate()
            begin
                IF Active THEN BEGIN
                    WorkStatus.RESET;
                    WorkStatus.SETFILTER("Work Status Code", '<>%1', "Work Status Code");
                    WorkStatus.SETRANGE(Active, TRUE);
                    IF WorkStatus.FINDFIRST THEN
                        ERROR(Text004, WorkStatus."Work Status Code");
                END;
            end;
        }
    }

    keys
    {
        key(Key1; "Work Status Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        WorkStatus: Record "Work Status";
        Text001: Label 'Cancelled Status is already linked to Work Status %1';
        Text002: Label 'Closed Status is already linked to Work Status %1';
        Text003: Label 'Default Status is already linked to Work Status %1';
        Text004: Label 'Active Status is already linked to Work Status %1';
}

