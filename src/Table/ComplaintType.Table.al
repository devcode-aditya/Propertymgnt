table 33016837 "Complaint Type"
{
    Caption = 'Complaint Type';
    LookupFormID = Form33016832;

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
        field(3; "Job Type"; Code[10])
        {
            TableRelation = "Job Type".Code;
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
}

