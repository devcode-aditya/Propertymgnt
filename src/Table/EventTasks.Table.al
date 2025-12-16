table 33016851 "Event Tasks"
{
    DrillDownFormID = Form33016879;
    LookupFormID = Form33016879;

    fields
    {
        field(1; "Event No."; Code[20])
        {
            NotBlank = true;
            TableRelation = "Event Detail".No.;

            trigger OnValidate()
            begin
                IF EventRec.GET("Event No.") THEN
                  "Event Name" := EventRec.Name
                ELSE
                  "Event Name" := '';
            end;
        }
        field(2;"Task Code";Code[20])
        {
            NotBlank = true;
            TableRelation = "Task Code".Code;

            trigger OnValidate()
            begin
                IF TaskCode.GET("Task Code") THEN
                  "Task Name" := TaskCode.Description
                ELSE
                  "Task Name" := '';
            end;
        }
        field(3;"Event Name";Text[50])
        {
        }
        field(4;"Task Name";Text[30])
        {
        }
    }

    keys
    {
        key(Key1;"Event No.","Task Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        EventRec: Record "Event Detail";
        TaskCode: Record "Task Code";
}

