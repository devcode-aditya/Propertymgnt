table 33016835 "Premise Floor"
{
    Caption = 'Premise Floor';
    LookupFormID = Form33016829;

    fields
    {
        field(1; "Floor No."; Code[10])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
    }

    keys
    {
        key(Key1; "Floor No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

