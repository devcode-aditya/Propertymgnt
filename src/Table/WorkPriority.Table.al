table 33016803 "Work Priority"
{
    Caption = 'Work Priority';
    LookupFormID = Form33016831;

    fields
    {
        field(1; "Code"; Code[10])
        {
        }
        field(2; Description; Text[50])
        {
        }
        field(3; Default; Boolean)
        {

            trigger OnValidate()
            begin
                WorkPriorityRec.RESET;
                WorkPriorityRec.SETRANGE(Default, TRUE);
                WorkPriorityRec.SETFILTER(Code, '<>%1', Code);
                IF WorkPriorityRec.FINDFIRST THEN
                    ERROR(Text001);
            end;
        }
        field(4; "Response Time"; Duration)
        {
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        WorkPriorityRec: Record "Work Priority";
        Text001: Label 'Only One Default Code allowed';
}

