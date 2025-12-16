table 33016859 "Error while Import"
{
    Caption = 'Error while Import';

    fields
    {
        field(1; "Entry No"; Integer)
        {
            NotBlank = true;
        }
        field(2; "File Name"; Text[250])
        {
        }
        field(3; "Record Number"; Integer)
        {
        }
        field(4; "File Type"; Option)
        {
            OptionCaption = ' ,Sales';
            OptionMembers = " ",Sales;
        }
        field(5; "Error String"; Text[250])
        {
        }
        field(6; "Entry No in Register"; Integer)
        {
        }
        field(7; Exported; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Entry No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

