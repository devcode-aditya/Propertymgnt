table 33016805 "Premise Sub Group"
{
    LookupFormID = Form33016805;

    fields
    {
        field(1; "Premise Group"; Code[20])
        {
            TableRelation = "Premise Group".Code;
        }
        field(2; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
        }
    }

    keys
    {
        key(Key1; "Premise Group", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

