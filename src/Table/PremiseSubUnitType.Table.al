table 33016807 "Premise Sub Unit Type"
{
    Caption = 'Premise Sub Unit Type';
    LookupFormID = Form33016807;

    fields
    {
        field(1; "Code"; Code[20])
        {
        }
        field(2; Description; Text[50])
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
}

