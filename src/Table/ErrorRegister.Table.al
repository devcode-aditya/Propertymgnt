table 33016842 "Error Register"
{
    Caption = 'Error Register';

    fields
    {
        field(1; "Entry Number"; Integer)
        {
        }
        field(2; "Entry Number in Register"; Integer)
        {
        }
        field(3; "Entry Number in Staging"; Integer)
        {
        }
        field(4; "Error String"; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Entry Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

